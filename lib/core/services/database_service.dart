import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/run_model.dart';

// ─── Database Service ─────────────────────────────────────────────────────────

class DatabaseService extends ChangeNotifier {
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
    final newRun = run.copyWith(id: id);
    notifyListeners();
    return newRun;
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
    final count = await db.update('runs', run.toMap(), where: 'id = ?', whereArgs: [run.id]);
    notifyListeners();
    return count;
  }

  // ── Delete run ──────────────────────────────────────────────────────────────

  Future<int> deleteRun(int id) async {
    final db = await database;
    final count = await db.delete('runs', where: 'id = ?', whereArgs: [id]);
    notifyListeners();
    return count;
  }

  // ── Get statistics ──────────────────────────────────────────────────────────

  Future<RunStats> getStats() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT
        COUNT(*) as total_runs,
        COALESCE(SUM(distance_meters), 0) as total_distance,
        COALESCE(SUM(duration_seconds), 0) as total_duration,
        AVG(avg_pace_seconds_per_km) as avg_pace,
        AVG(avg_heart_rate) as avg_heart_rate
      FROM runs
    ''');

    final row = result.first;
    return RunStats(
      totalRuns: (row['total_runs'] as int?) ?? 0,
      totalDistanceMeters: (row['total_distance'] as num?)?.toDouble() ?? 0,
      totalDurationSeconds: (row['total_duration'] as int?) ?? 0,
      avgPaceSecondsPerKm: (row['avg_pace'] as num?)?.toDouble(),
      avgHeartRate: (row['avg_heart_rate'] as num?)?.round(),
    );
  }

  // ── Weekly distance (last 7 days, oldest → newest) ─────────────────────────

  Future<List<DailyDistance>> getLast7DaysDistance() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = today.subtract(const Duration(days: 6));

    final db = await database;
    final runs = await db.query(
      'runs',
      columns: ['start_time', 'distance_meters'],
      where: 'start_time >= ?',
      whereArgs: [start.millisecondsSinceEpoch],
    );

    final buckets = List<double>.filled(7, 0);
    for (final run in runs) {
      final startMs = run['start_time'] as int;
      final runDate = DateTime.fromMillisecondsSinceEpoch(startMs);
      final dayStart = DateTime(runDate.year, runDate.month, runDate.day);
      final index = dayStart.difference(start).inDays;
      if (index >= 0 && index < 7) {
        buckets[index] += (run['distance_meters'] as num).toDouble();
      }
    }

    return List.generate(
      7,
      (i) => DailyDistance(
        date: start.add(Duration(days: i)),
        distanceMeters: buckets[i],
      ),
    );
  }

  // ── Current daily streak (consecutive days ending today with a run) ────────

  Future<int> getCurrentStreak() async {
    final db = await database;
    final rows = await db.query(
      'runs',
      columns: ['start_time'],
      orderBy: 'start_time DESC',
      limit: 365,
    );
    if (rows.isEmpty) return 0;

    final days = rows
        .map((r) {
          final d = DateTime.fromMillisecondsSinceEpoch(r['start_time'] as int);
          return DateTime(d.year, d.month, d.day);
        })
        .toSet();

    final now = DateTime.now();
    var cursor = DateTime(now.year, now.month, now.day);
    if (!days.contains(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
      if (!days.contains(cursor)) return 0;
    }

    var streak = 0;
    while (days.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  // ── Close database ──────────────────────────────────────────────────────────

  Future close() async {
    final db = await database;
    db.close();
  }
}
