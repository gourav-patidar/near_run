import 'package:flutter/foundation.dart';

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

// ─── Weekly Intensity Bar Model ───────────────────────────────────────────────

class WeeklyBarModel {
  final String dayLabel; // e.g. "M", "T"
  final double intensity; // 0.0 – 1.0
  final bool isToday;
  final String colorHex;

  const WeeklyBarModel({
    required this.dayLabel,
    required this.intensity,
    this.isToday = false,
    required this.colorHex,
  });
}

// ─── ViewModel ────────────────────────────────────────────────────────────────

class ProfileViewModel extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // ── User info ───────────────────────────────────────────────────────────────
  String _name = 'Marcus Thorne';
  String get name => _name;

  String _tier = 'MARATHON ELITE';
  String get tier => _tier;

  int _level = 24;
  int get level => _level;

  String get subtitle => '$_tier  •  LEVEL $_level';

  // ── Stats ───────────────────────────────────────────────────────────────────
  double _totalDistanceKm = 187;
  double get totalDistanceKm => _totalDistanceKm;
  String get totalDistanceFormatted =>
      _totalDistanceKm.toStringAsFixed(0);

  int _totalRuns = 24;
  int get totalRuns => _totalRuns;

  // ── Weekly intensity ────────────────────────────────────────────────────────
  List<WeeklyBarModel> _weeklyBars = [];
  List<WeeklyBarModel> get weeklyBars => List.unmodifiable(_weeklyBars);

  // ── Badges ──────────────────────────────────────────────────────────────────
  List<BadgeModel> _badges = [];
  List<BadgeModel> get badges => List.unmodifiable(_badges);

  // ── Daily goal ──────────────────────────────────────────────────────────────
  double _dailyGoalPercent = 0.85;
  double get dailyGoalPercent => _dailyGoalPercent;
  String get dailyGoalLabel =>
      '${(_dailyGoalPercent * 100).toStringAsFixed(0)}%';

  // ── Avg BPM ─────────────────────────────────────────────────────────────────
  int _avgBpm = 142;
  int get avgBpm => _avgBpm;

  String get bpmZoneLabel {
    if (_avgBpm < 115) return 'ZONE 1 EASY';
    if (_avgBpm < 135) return 'ZONE 2 FAT BURN';
    if (_avgBpm < 155) return 'ZONE 3 ACTIVE';
    if (_avgBpm < 175) return 'ZONE 4 ANAEROBIC';
    return 'ZONE 5 MAX';
  }

  // ── Init ────────────────────────────────────────────────────────────────────
  ProfileViewModel() {
    _load();
  }

  Future<void> _load() async {
    _setLoading(true);
    await Future.delayed(const Duration(milliseconds: 400));

    _weeklyBars = const [
      WeeklyBarModel(dayLabel: 'M', intensity: 0.55, colorHex: '#48E5D0'),
      WeeklyBarModel(dayLabel: 'T', intensity: 0.70, colorHex: '#48E5D0'),
      WeeklyBarModel(
          dayLabel: 'W', intensity: 0.95, isToday: false, colorHex: '#00C853'),
      WeeklyBarModel(
          dayLabel: 'T', intensity: 1.0, isToday: true, colorHex: '#00C853'),
      WeeklyBarModel(dayLabel: 'F', intensity: 0.60, colorHex: '#40C4FF'),
      WeeklyBarModel(dayLabel: 'S', intensity: 0.15, colorHex: '#BDBDBD'),
      WeeklyBarModel(dayLabel: 'S', intensity: 0.45, colorHex: '#FF5252'),
    ];

    _badges = const [
      BadgeModel(
        id: 'fast_start',
        title: 'FAST\nSTART',
        icon: BadgeIcon.fastStart,
        bgColorHex: '#FFE0E0',
      ),
      BadgeModel(
        id: 'hill_climber',
        title: 'HILL\nCLIMBER',
        icon: BadgeIcon.hillClimber,
        bgColorHex: '#C8F5E8',
      ),
      BadgeModel(
        id: '7_day_streak',
        title: '7 DAY\nSTREAK',
        icon: BadgeIcon.sevenDayStreak,
        bgColorHex: '#E3F2FD',
      ),
    ];

    _setLoading(false);
  }

  Future<void> refresh() => _load();

  void onEditProfile() {
    // TODO: Navigate to EditProfileScreen
    debugPrint('Edit profile tapped');
  }

  void onViewAllBadges() {
    // TODO: Navigate to BadgesScreen
    debugPrint('View all badges tapped');
  }

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }
}
