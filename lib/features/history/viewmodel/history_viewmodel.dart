import 'package:flutter/foundation.dart';

// ─── Run Record Model ─────────────────────────────────────────────────────────

class RunRecord {
  final String id;
  final String title;
  final String dateLabel; // e.g. "YESTERDAY", "OCT 24, 2023"
  final double distanceKm;
  final String pace; // e.g. "5'42\""
  final String? duration; // e.g. "1:52:04" — optional
  final int? heartRateBpm; // optional
  final bool hasAchievement;
  final RunMapStyle mapStyle;

  const RunRecord({
    required this.id,
    required this.title,
    required this.dateLabel,
    required this.distanceKm,
    required this.pace,
    this.duration,
    this.heartRateBpm,
    this.hasAchievement = false,
    this.mapStyle = RunMapStyle.light,
  });

  String get distanceFormatted => distanceKm.toStringAsFixed(2);
}

// Controls the visual style of the map thumbnail in each card
enum RunMapStyle { dark, light, terrain }

// ─── ViewModel ────────────────────────────────────────────────────────────────

class HistoryViewModel extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<RunRecord> _runs = [];
  List<RunRecord> get runs => List.unmodifiable(_runs);

  bool get isEmpty => _runs.isEmpty;

  HistoryViewModel() {
    _loadRuns();
  }

  Future<void> _loadRuns() async {
    _setLoading(true);
    await Future.delayed(const Duration(milliseconds: 500));

    // TODO: Replace with sqflite query — RunRepository.getAllRuns()
    _runs = [
      const RunRecord(
        id: '1',
        title: 'Evening Recovery',
        dateLabel: 'YESTERDAY',
        distanceKm: 5.24,
        pace: "5'42\"",
        mapStyle: RunMapStyle.dark,
      ),
      const RunRecord(
        id: '2',
        title: 'Morning Tempo',
        dateLabel: 'OCT 24, 2023',
        distanceKm: 10.02,
        pace: "4'58\"",
        mapStyle: RunMapStyle.light,
      ),
      const RunRecord(
        id: '3',
        title: 'Sunday Long Run',
        dateLabel: 'OCT 21, 2023',
        distanceKm: 21.1,
        pace: "5'20\"",
        duration: '1:52:04',
        heartRateBpm: 158,
        hasAchievement: true,
        mapStyle: RunMapStyle.terrain,
      ),
    ];

    _setLoading(false);
  }

  Future<void> refresh() => _loadRuns();

  void onRunTapped(RunRecord run) {
    // TODO: Navigate to RunDetailScreen
    debugPrint('Tapped run: ${run.title}');
  }

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }
}
