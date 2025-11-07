import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'db/notes_database.dart';
import 'services/intent_detector.dart';
import 'services/encryption_helper.dart';
import 'services/groq_service.dart';
import 'screens/ai_assistant_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env"); // 🔒 load API key from env file
  runApp(LocalMindApp());
}

class LocalMindApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LocalMind AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: NotesHomeScreen(),
    );
  }
}

class NotesHomeScreen extends StatefulWidget {
  @override
  State<NotesHomeScreen> createState() => _NotesHomeScreenState();
}

class _NotesHomeScreenState extends State<NotesHomeScreen> {
  final TextEditingController _controller = TextEditingController();
  final db = NotesDatabase.instance;
  final detector = IntentDetector();
  final encryptor = EncryptionHelper();
  final groq = GroqService(); // ✅ loads key automatically from .env

  List<Map<String, dynamic>> _notes = [];
  bool privacyMode = false;
  String? _aiResponse;
  double _lastLatency = 0;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final data = await db.getAllNotes();
    setState(() => _notes = data);
  }

  Future<void> _handleInput() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final intent = detector.detect(text);
    _controller.clear();

    switch (intent) {
      case IntentType.addNote:
        final id = const Uuid().v4();
        final encrypted = await encryptor.encryptText(text);
        await db.insert({
          'id': id,
          'text': encrypted,
          'time': DateTime.now().toString(),
        });
        _loadNotes();
        _showSnack('📝 Note saved securely!');
        break;

      case IntentType.showNotes:
        _showSnack('📋 You have ${_notes.length} notes.');
        break;

      case IntentType.deleteAll:
        for (final n in _notes) {
          await db.delete(n['id']);
        }
        _loadNotes();
        _showSnack('🧹 All notes deleted!');
        break;

      case IntentType.help:
        _showSnack('🤖 Try: "note: buy milk", "summarize notes", or "ask ..."');
        break;

      case IntentType.unknown:
        await _runAIAssist(text);
        break;
    }
  }

  Future<void> _runAIAssist(String userPrompt) async {
    if (_notes.isEmpty) {
      _showSnack('📭 No notes to analyze yet!');
      return;
    }

    // Decrypt all notes for AI context
    final decryptedNotes = <String>[];
    for (final n in _notes) {
      final t = await encryptor.decryptText(n['text']);
      decryptedNotes.add(t);
    }

    final context = decryptedNotes.join("\n- ");

    final start = DateTime.now();
    final response = await groq.getResponse(
      "You are LocalMind, an assistant that helps the user with their personal notes.\n"
      "User notes:\n- $context\n\n"
      "User request: $userPrompt",
    );
    final end = DateTime.now();
    final latency = end.difference(start).inMilliseconds / 1000.0;

    setState(() {
      _aiResponse = response;
      _lastLatency = latency;
    });

    _showSnack('💬 AI ready in ${latency.toStringAsFixed(2)}s');
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  Future<void> _deleteNote(String id) async {
    await db.delete(id);
    _loadNotes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🧠 LocalMind AI'),
        actions: [
          // 🤖 Assistant shortcut
          IconButton(
            icon: const Icon(Icons.smart_toy_outlined),
            tooltip: "Assistant",
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AIAssistantScreen()),
              );
              _loadNotes(); // Refresh when returning
            },
          ),
          Row(
            children: [
              const Text('Privacy', style: TextStyle(fontSize: 14)),
              Switch(
                value: privacyMode,
                onChanged: (v) => setState(() => privacyMode = v),
              ),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Type a note or ask about your notes...',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send, color: Color(0xFF3652F4)),
                  onPressed: _handleInput,
                ),
              ),
              onSubmitted: (_) => _handleInput(),
            ),
            const SizedBox(height: 20),

            if (_aiResponse != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "🤖 $_aiResponse\n⏱ ${_lastLatency.toStringAsFixed(2)}s",
                  style: const TextStyle(color: Colors.black87),
                ),
              ),

            if (privacyMode)
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock, size: 60, color: Colors.grey),
                      SizedBox(height: 10),
                      Text(
                        'Privacy Mode ON 🔒',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              )
            else if (_notes.isEmpty)
              const Text(
                'No notes yet! Add one above 👆',
                style: TextStyle(fontSize: 16),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _notes.length,
                  itemBuilder: (context, i) {
                    final note = _notes[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        title: FutureBuilder<String>(
                          future: encryptor.decryptText(note['text']),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Text('Decrypting...');
                            } else if (snapshot.hasError) {
                              return const Text('Error decrypting');
                            } else {
                              return Text(snapshot.data ?? '');
                            }
                          },
                        ),
                        subtitle: Text(note['time']),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteNote(note['id']),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
