import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class NotesDatabase {
  static final NotesDatabase instance = NotesDatabase._init();
  static Database? _database;

  NotesDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('notes.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    // openDatabase creates if not exists
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE notes (
        id TEXT PRIMARY KEY,
        text TEXT NOT NULL,
        time TEXT NOT NULL
      )
    ''');
  }

  Future<void> insert(Map<String, dynamic> note) async {
    final db = await instance.database;
    await db.insert(
      'notes',
      note,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getAllNotes() async {
    final db = await instance.database;
    return await db.query('notes', orderBy: 'time DESC');
  }

  Future<void> delete(String id) async {
    final db = await instance.database;
    await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
