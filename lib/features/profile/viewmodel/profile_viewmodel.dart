import 'package:flutter/foundation.dart';
import '../../../core/models/run_model.dart';
import '../../../core/services/database_service.dart';
import '../../../core/services/user_preferences_service.dart';

// ─── Badge Model ──────────────────────────────────────────────────────────────

enum BadgeIcon { fastStart, hillClimber, sevenDayStreak, nightOwl, speedDemon }

class BadgeModel {
  final String id;
  final String title;
  final BadgeIcon icon;
  final String bgColorHex;

  const BadgeModel({
    required this.id,
    required this.title,
    required this.icon,
    required this.bgColorHex,
  });
}

// ─── Weekly Bar Model ─────────────────────────────────────────────────────────

class WeeklyBarModel {
  final String dayLabel;
  final double intensity; // 0.0 – 1.0
  final bool isToday;
  final String colorHex;

  const WeeklyBarModel({
    required this.dayLabel,
    required this.intensity,
    required this.colorHex,
    this.isToday = false,
  });
}

const _dayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

// ─── ViewModel ────────────────────────────────────────────────────────────────

class ProfileViewModel extends ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;
  final UserPreferencesService _prefs = UserPreferencesService.instance;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String get name => _prefs.name;

  String get subtitle {
    final dist = _stats.totalDistanceKm;
    final tier = dist >= 500
        ? 'MARATHON ELITE'
        : dist >= 200
            ? 'TRAIL BLAZER'
            : dist >= 50
                ? 'ROAD READY'
                : 'BEGINNER';
    final level = 1 + (dist ~/ 10);
    return '$tier  •  LEVEL $level';
  }

  RunStats _stats = RunStats.empty;
  RunStats get stats => _stats;

  String get totalDistanceFormatted => _stats.totalDistanceKm.toStringAsFixed(0);
  int get totalRuns => _stats.totalRuns;

  int _streakDays = 0;
  int get streakDays => _streakDays;

  List<WeeklyBarModel> _weeklyBars = [];
  List<WeeklyBarModel> get weeklyBars => List.unmodifiable(_weeklyBars);

  List<BadgeModel> _badges = [];
  List<BadgeModel> get badges => List.unmodifiable(_badges);

  int get avgBpm => _stats.avgHeartRate ?? 0;
  String get bpmZoneLabel {
    if (avgBpm == 0) return 'NO HR DATA';
    if (avgBpm < 115) return 'ZONE 1 EASY';
    if (avgBpm < 135) return 'ZONE 2 FAT BURN';
    if (avgBpm < 155) return 'ZONE 3 ACTIVE';
    if (avgBpm < 175) return 'ZONE 4 ANAEROBIC';
    return 'ZONE 5 MAX';
  }

  double _dailyGoalPercent = 0;
  double get dailyGoalPercent => _dailyGoalPercent;
  String get dailyGoalLabel => '${(_dailyGoalPercent * 100).round()}%';
  double get dailyGoalTargetKm => _prefs.dailyGoalKm;

  ProfileViewModel() {
    _load();
    _db.addListener(_load);
    _prefs.addListener(notifyListeners);
  }

  Future<void> updateName(String newName) async {
    await _prefs.updateName(newName);
    notifyListeners();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        _db.getStats(),
        _db.getLast7DaysDistance(),
        _db.getCurrentStreak(),
      ]);
      _stats = results[0] as RunStats;
      final weekly = results[1] as List<DailyDistance>;
      _streakDays = results[2] as int;

      _weeklyBars = _buildWeeklyBars(weekly);
      _badges = _deriveBadges(_stats, _streakDays);
      _dailyGoalPercent = _computeDailyGoal(weekly);
    } catch (e) {
      debugPrint('ProfileViewModel load failed: $e');
      _stats = RunStats.empty;
      _weeklyBars = _buildWeeklyBars(const []);
      _badges = const [];
      _dailyGoalPercent = 0;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> refresh() => _load();

  @override
  void dispose() {
    _db.removeListener(_load);
    _prefs.removeListener(notifyListeners);
    super.dispose();
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  List<WeeklyBarModel> _buildWeeklyBars(List<DailyDistance> daily) {
    if (daily.length != 7) {
      final todayIdx = (DateTime.now().weekday - 1).clamp(0, 6);
      return List.generate(
        7,
        (i) => WeeklyBarModel(
          dayLabel: _dayLetters[i],
          intensity: 0,
          isToday: i == todayIdx,
          colorHex: '#BDBDBD',
        ),
      );
    }

    final maxKm = daily.map((d) => d.distanceKm).fold<double>(
          0,
          (prev, curr) => curr > prev ? curr : prev,
        );

    final today = DateTime.now();
    final todayKey = DateTime(today.year, today.month, today.day);

    return List.generate(7, (i) {
      final day = daily[i];
      final dayKey = DateTime(day.date.year, day.date.month, day.date.day);
      final isToday = dayKey == todayKey;
      final intensity = maxKm == 0 ? 0.0 : (day.distanceKm / maxKm).clamp(0.0, 1.0);

      String color;
      if (intensity == 0) {
        color = '#BDBDBD';
      } else if (intensity < 0.4) {
        color = '#48E5D0';
      } else if (intensity < 0.75) {
        color = '#40C4FF';
      } else {
        color = '#00C853';
      }

      return WeeklyBarModel(
        dayLabel: _dayLetters[day.date.weekday - 1],
        intensity: intensity,
        isToday: isToday,
        colorHex: color,
      );
    });
  }

  double _computeDailyGoal(List<DailyDistance> daily) {
    if (daily.isEmpty) return 0;
    final todayKm = daily.last.distanceKm;
    final target = _prefs.dailyGoalKm;
    if (target <= 0) return 0;
    return (todayKm / target).clamp(0.0, 1.0);
  }

  List<BadgeModel> _deriveBadges(RunStats stats, int streak) {
    final out = <BadgeModel>[];
    if (stats.totalRuns >= 1) {
      out.add(const BadgeModel(
        id: 'first_run',
        title: 'FIRST\nRUN',
        icon: BadgeIcon.fastStart,
        bgColorHex: '#FFE0E0',
      ));
    }
    if (stats.totalDistanceKm >= 50) {
      out.add(const BadgeModel(
        id: 'hill_climber',
        title: '50 KM\nCLUB',
        icon: BadgeIcon.hillClimber,
        bgColorHex: '#C8F5E8',
      ));
    }
    if (streak >= 7) {
      out.add(const BadgeModel(
        id: '7_day_streak',
        title: '7 DAY\nSTREAK',
        icon: BadgeIcon.sevenDayStreak,
        bgColorHex: '#E3F2FD',
      ));
    }
    if (stats.avgPaceSecondsPerKm != null && stats.avgPaceSecondsPerKm! < 330) {
      out.add(const BadgeModel(
        id: 'speed_demon',
        title: 'SUB 5:30\nPACE',
        icon: BadgeIcon.speedDemon,
        bgColorHex: '#FFF0EC',
      ));
    }
    return out.take(3).toList();
  }
}
