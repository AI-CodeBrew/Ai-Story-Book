import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  DatabaseService._internal();
  static final DatabaseService instance = DatabaseService._internal();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'ai_storybook.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE feedback (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            feedback_type TEXT NOT NULL,
            selected_feedback TEXT NOT NULL,
            custom_feedback TEXT,
            story_id TEXT,
            rating INTEGER NOT NULL DEFAULT 5,
            synced INTEGER NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL
          )
        ''');
      },
    );
  }

  Future<int> insertFeedback({
    required String feedbackType,
    required String selectedFeedback,
    String? customFeedback,
    String? storyId,
    int rating = 5,
  }) async {
    final db = await database;
    return db.insert('feedback', {
      'feedback_type': feedbackType,
      'selected_feedback': selectedFeedback,
      'custom_feedback': customFeedback,
      'story_id': storyId,
      'rating': rating,
      'synced': 0,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<int> markFeedbackSynced(int id) async {
    final db = await database;
    return db.update('feedback', {'synced': 1}, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getAllFeedback() async {
    final db = await database;
    return db.query('feedback', orderBy: 'created_at DESC');
  }

  Future<List<Map<String, dynamic>>> getUnsyncedFeedback() async {
    final db = await database;
    return db.query('feedback', where: 'synced = 0', orderBy: 'created_at DESC');
  }
}
