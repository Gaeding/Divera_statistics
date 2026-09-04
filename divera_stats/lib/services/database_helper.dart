import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/alarm_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('divera_alarms.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE alarms (
        id INTEGER PRIMARY KEY,
        title TEXT,
        text TEXT,
        date INTEGER,
        address TEXT,
        myStatusId INTEGER
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE alarms ADD COLUMN myStatusId INTEGER DEFAULT 0');
    }
  }

  Future<void> insertAlarms(List<Alarm> alarms) async {
    final db = await instance.database;
    final batch = db.batch();

    for (var alarm in alarms) {
      batch.insert(
        'alarms',
        alarm.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  Future<List<Alarm>> getAllAlarms() async {
    final db = await instance.database;
    final result = await db.query('alarms', orderBy: 'date DESC');

    return result.map((json) => Alarm.fromMap(json)).toList();
  }

  // Einzelnen Alarm anhand der ID löschen (für Debug-Modus)
  Future<int> deleteAlarm(int id) async {
    final db = await instance.database;
    return await db.delete(
      'alarms',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
