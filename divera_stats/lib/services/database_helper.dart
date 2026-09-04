import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/alarm_model.dart';

/// Singleton-Klasse zur Verwaltung der lokalen SQLite-Datenbank (`divera_alarms.db`).
/// Handhabt Erstellung, Schema-Migrationen (v2) sowie sämtliche CRUD-Zugriffe für Alarme.
class DatabaseHelper {
  // Singleton-Instanz für globalen Zugriff definieren
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  // Privater Konstruktor verhindert versehentliches Instanziieren von außen
  DatabaseHelper._init();

  /// Getter für das Datenbank-Objekt.
  /// Nutzt Lazy Initialization: Öffnet die DB erst bei der ersten Abfrage.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('divera_alarms.db');
    return _database!;
  }

  /// Initialisiert den Dateipfad und öffnet die SQLite-Datenbank inklusive Versionierung.
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2, // Datenbank-Version 2 (inkl. myStatusId)
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  /// Erstellt das Schema bei der Erstinstallation der App.
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

  /// Migrations-Logik für bestehende Nutzer beim Upgrade von älteren DB-Versionen.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Migration von V1 zu V2: Nachträgliches Hinzufügen der myStatusId-Spalte
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE alarms ADD COLUMN myStatusId INTEGER DEFAULT 0');
    }
  }

  /// Speichert eine Liste von Alarmen effizient über eine Batch-Operation in SQLite.
  /// Vorhandene Datensätze werden bei ID-Kollision automatisch aktualisiert (`replace`).
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

    // Führt alle Inserts als zusammenhängende Transaktion aus
    await batch.commit(noResult: true);
  }

  /// Liest alle gespeicherten Alarme absteigend nach Datum (neueste zuerst) aus.
  Future<List<Alarm>> getAllAlarms() async {
    final db = await instance.database;
    final result = await db.query('alarms', orderBy: 'date DESC');

    return result.map((json) => Alarm.fromMap(json)).toList();
  }

  /// Löscht einen spezifischen Einsatz anhand seiner eindeutigen ID (hauptsächlich für den Debug-Modus).
  Future<int> deleteAlarm(int id) async {
    final db = await instance.database;
    return await db.delete(
      'alarms',
      where: 'id = ?',
      whereArgs: [id], // Parametrisierte Abfrage schützt vor SQL-Injections
    );
  }
}