import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/reminder.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('reminders.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE reminders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        dateTime TEXT NOT NULL,
        isRecurring INTEGER NOT NULL,
        category TEXT NOT NULL,
        isCompleted INTEGER NOT NULL,
        recurrencePattern TEXT
      )
    ''');
  }

  Future<int> insertReminder(Reminder reminder) async {
    final db = await database;
    return await db.insert('reminders', reminder.toMap());
  }

  Future<List<Reminder>> getAllReminders() async {
    final db = await database;
    final result = await db.query('reminders', orderBy: 'dateTime ASC');
    return result.map((map) => Reminder.fromMap(map)).toList();
  }

  Future<List<Reminder>> getActiveReminders() async {
    final db = await database;
    final result = await db.query(
      'reminders',
      where: 'isCompleted = ?',
      whereArgs: [0],
      orderBy: 'dateTime ASC',
    );
    return result.map((map) => Reminder.fromMap(map)).toList();
  }

  Future<List<Reminder>> getCompletedReminders() async {
    final db = await database;
    final result = await db.query(
      'reminders',
      where: 'isCompleted = ?',
      whereArgs: [1],
      orderBy: 'dateTime DESC',
    );
    return result.map((map) => Reminder.fromMap(map)).toList();
  }

  Future<List<Reminder>> getRemindersByCategory(String category) async {
    final db = await database;
    final result = await db.query(
      'reminders',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'dateTime ASC',
    );
    return result.map((map) => Reminder.fromMap(map)).toList();
  }

  Future<List<Reminder>> searchReminders(String query) async {
    final db = await database;
    final result = await db.query(
      'reminders',
      where: 'title LIKE ? OR description LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'dateTime ASC',
    );
    return result.map((map) => Reminder.fromMap(map)).toList();
  }

  Future<int> updateReminder(Reminder reminder) async {
    final db = await database;
    return await db.update(
      'reminders',
      reminder.toMap(),
      where: 'id = ?',
      whereArgs: [reminder.id],
    );
  }

  Future<int> deleteReminder(int id) async {
    final db = await database;
    return await db.delete(
      'reminders',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> toggleCompletion(int id, bool isCompleted) async {
    final db = await database;
    return await db.update(
      'reminders',
      {'isCompleted': isCompleted ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}

