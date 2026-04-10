import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/run_model.dart';

// ─── Database Service ─────────────────────────────────────────────────────────

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('near_run.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const intType = 'INTEGER NOT NULL';
    const doubleType = 'REAL NOT NULL';
    const textType = 'TEXT NOT NULL';
    const doubleNullableType = 'REAL';
    const intNullableType = 'INTEGER';

    await db.execute('''
      CREATE TABLE runs (
        id $idType,
        start_time $intType,
        end_time $intType,
        distance_meters $doubleType,
        duration_seconds $intType,
        route_points $textType,
        avg_pace_seconds_per_km $doubleNullableType,
        elevation_gain_meters $doubleNullableType,
        avg_heart_rate $intNullableType,
        calories_burned $intNullableType
      )
    ''');
  }

  // ── Insert run ──────────────────────────────────────────────────────────────

  Future<RunModel> createRun(RunModel run) async {
    final db = await database;
    final id = await db.insert('runs', run.toMap());
    return run.copyWith(id: id);
  }

  // ── Get single run ──────────────────────────────────────────────────────────

  Future<RunModel?> getRunById(int id) async {
    final db = await database;
    final maps = await db.query('runs', where: 'id = ?', whereArgs: [id]);

    if (maps.isNotEmpty) {
      return RunModel.fromMap(maps.first);
    }
    return null;
  }

  // ── Get all runs ────────────────────────────────────────────────────────────

  Future<List<RunModel>> getAllRuns() async {
    final db = await database;
    const orderBy = 'start_time DESC';
    final result = await db.query('runs', orderBy: orderBy);
    return result.map((json) => RunModel.fromMap(json)).toList();
  }

  // ── Get runs by date range ──────────────────────────────────────────────────

  Future<List<RunModel>> getRunsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final db = await database;
    final result = await db.query(
      'runs',
      where: 'start_time >= ? AND start_time <= ?',
      whereArgs: [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
      orderBy: 'start_time DESC',
    );
    return result.map((json) => RunModel.fromMap(json)).toList();
  }

  // ── Get recent runs ─────────────────────────────────────────────────────────

  Future<List<RunModel>> getRecentRuns(int limit) async {
    final db = await database;
    final result = await db.query(
      'runs',
      orderBy: 'start_time DESC',
      limit: limit,
    );
    return result.map((json) => RunModel.fromMap(json)).toList();
  }

  // ── Update run ──────────────────────────────────────────────────────────────

  Future<int> updateRun(RunModel run) async {
    final db = await database;
    return db.update('runs', run.toMap(), where: 'id = ?', whereArgs: [run.id]);
  }

  // ── Delete run ──────────────────────────────────────────────────────────────

  Future<int> deleteRun(int id) async {
    final db = await database;
    return await db.delete('runs', where: 'id = ?', whereArgs: [id]);
  }

  // ── Get statistics ──────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getStats() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT 
        COUNT(*) as total_runs,
        SUM(distance_meters) as total_distance,
        SUM(duration_seconds) as total_duration,
        AVG(avg_pace_seconds_per_km) as avg_pace
      FROM runs
    ''');

    return result.first;
  }

  // ── Close database ──────────────────────────────────────────────────────────

  Future close() async {
    final db = await database;
    db.close();
  }
}
