import 'package:flutter/material.dart';
import '../services/groq_service.dart';
import '../services/encryption_helper.dart';
import '../db/notes_database.dart';
import '../services/command_parser.dart';

class AIAssistantScreen extends StatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> {
  final TextEditingController _controller = TextEditingController();
  final groq = GroqService(); // ✅ loads API key from .env automatically
  final encryptor = EncryptionHelper();
  final db = NotesDatabase.instance;

  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  String? _lastAIOutput;

  Future<void> _handleCommand(String input) async {
    if (input.trim().isEmpty) return;

    setState(() {
      _messages.add({"role": "user", "text": input});
      _isLoading = true;
    });

    final cmd = CommandParser.parse(input);
    String reply = "";

    try {
      // Detect compound intent like “and add that as a note”
      final bool wantsToAddResult =
          input.toLowerCase().contains("add that as a note") ||
          input.toLowerCase().contains("add this as a note") ||
          input.toLowerCase().contains("and save it");

      switch (cmd) {
        case CommandType.addNote:
          String noteText = CommandParser.extractNoteText(input);

          // Handle “add those / them / listed”
          if (noteText.toLowerCase().contains("those") ||
              noteText.toLowerCase().contains("them") ||
              noteText.toLowerCase().contains("listed")) {
            if (_lastAIOutput != null && _lastAIOutput!.trim().isNotEmpty) {
              noteText = _lastAIOutput!;
            } else {
              reply = "🤔 I don’t remember anything to add right now.";
              break;
            }
          }

          final encrypted = await encryptor.encryptText(noteText);
          await db.insert({
            'id': DateTime.now().millisecondsSinceEpoch.toString(),
            'text': encrypted,
            'time': DateTime.now().toString(),
          });
          reply = "✅ Added note:\n$noteText";
          break;

        case CommandType.deleteAll:
          final notes = await db.getAllNotes();
          for (final n in notes) {
            await db.delete(n['id']);
          }
          reply = "🧹 All notes deleted.";
          break;

        case CommandType.showNotes:
          // Proper async decryption to avoid "no notes" bug
          final notes = await db.getAllNotes();
          if (notes.isEmpty) {
            reply = "📭 No notes found.";
          } else {
            final decrypted = <String>[];
            for (final n in notes) {
              final d = await encryptor.decryptText(n['text']);
              decrypted.add(d);
            }
            reply = "🗒️ Your notes:\n- ${decrypted.join('\n- ')}";
          }
          break;

        case CommandType.summarizeNotes:
          final notes = await db.getAllNotes();
          if (notes.isEmpty) {
            reply = "📭 Nothing to summarize yet!";
          } else {
            final decrypted = <String>[];
            for (final n in notes) {
              decrypted.add(await encryptor.decryptText(n['text']));
            }
            final context = decrypted.join("\n- ");
            reply = await groq.getResponse(
              "Summarize these notes in a simple, friendly way:\n$context",
            );
          }
          break;

        case CommandType.searchNotes:
          final query = CommandParser.extractSearchQuery(input);
          final notes = await db.getAllNotes();
          final decrypted = <String>[];
          for (final n in notes) {
            decrypted.add(await encryptor.decryptText(n['text']));
          }
          final filtered = decrypted
              .where((n) => n.toLowerCase().contains(query.toLowerCase()))
              .toList();

          if (filtered.isEmpty) {
            reply = "🔍 No notes found about '$query'.";
          } else {
            reply = "📘 Notes about '$query':\n- ${filtered.join("\n- ")}";
          }
          break;

        case CommandType.aiQuery:
          // 1️⃣ Ask Groq normally
          final notes = await db.getAllNotes();
          final decrypted = <String>[];
          for (final n in notes) {
            decrypted.add(await encryptor.decryptText(n['text']));
          }

          final context = decrypted.isEmpty
              ? "No relevant notes yet."
              : decrypted.join("\n- ");

          final fullPrompt =
              """
You are LocalMind, a privacy-focused assistant.
Use notes only if needed. Avoid restating them unless relevant.

User notes:
- $context

User query: $input
""";

          final aiResponse = await groq.getResponse(fullPrompt);
          reply = aiResponse;

          // 2️⃣ If user said “add that as a note” → save AI response
          if (wantsToAddResult) {
            final encrypted = await encryptor.encryptText(aiResponse);
            await db.insert({
              'id': DateTime.now().millisecondsSinceEpoch.toString(),
              'text': encrypted,
              'time': DateTime.now().toString(),
            });
            reply += "\n\n💾 I’ve also added this as a note for you.";
          }
          break;
      }
    } catch (e) {
      reply = "⚠️ Error: $e";
    }

    setState(() {
      _messages.add({"role": "ai", "text": reply});
      _isLoading = false;
      _lastAIOutput = reply;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.indigo[900],
        title: const Text("LocalMind Assistant 🤖"),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A237E), Color(0xFF311B92)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, i) {
                  final m = _messages[i];
                  final isUser = m["role"] == "user";
                  return Align(
                    alignment: isUser
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isUser
                            ? Colors.indigoAccent
                            : Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        m["text"],
                        style: TextStyle(
                          color: isUser ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(8),
                child: CircularProgressIndicator(color: Colors.white),
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Talk to LocalMind...",
                        hintStyle: const TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (value) {
                        _handleCommand(value);
                        _controller.clear();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: () {
                      _handleCommand(_controller.text);
                      _controller.clear();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
