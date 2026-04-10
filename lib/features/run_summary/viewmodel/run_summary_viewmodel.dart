import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show BuildContext;

// ─── Summary Model ────────────────────────────────────────────────────────────

class RunSummaryData {
  final double distanceKm;
  final int totalSeconds;
  final int avgPaceSeconds; // sec/km
  final int calories;
  final int avgHeartRate;
  final String location;
  final String runName;
  final DateTime date;

  const RunSummaryData({
    required this.distanceKm,
    required this.totalSeconds,
    required this.avgPaceSeconds,
    required this.calories,
    required this.avgHeartRate,
    required this.location,
    required this.runName,
    required this.date,
  });

  String get distanceFormatted => distanceKm.toStringAsFixed(2);

  String get timeFormatted {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    if (h > 0) {
      return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String get paceFormatted {
    final m = avgPaceSeconds ~/ 60;
    final s = avgPaceSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  String get dateFormatted {
    const months = [
      'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

// ─── ViewModel ────────────────────────────────────────────────────────────────

class RunSummaryViewModel extends ChangeNotifier {
  final RunSummaryData summary;

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  bool _saved = false;
  bool get saved => _saved;

  RunSummaryViewModel({RunSummaryData? data})
      : summary = data ??
            RunSummaryData(
              distanceKm: 8.42,
              totalSeconds: 42 * 60 + 15,
              avgPaceSeconds: 5 * 60 + 1,
              calories: 642,
              avgHeartRate: 158,
              location: 'MISSION DISTRICT',
              runName: 'Morning Blaze',
              date: DateTime(2023, 10, 24),
            );

  Future<void> saveRun(BuildContext context) async {
    if (_isSaving) return;
    _isSaving = true;
    notifyListeners();

    // TODO: await RunRepository.insert(summary) using sqflite
    await Future.delayed(const Duration(milliseconds: 800));

    _isSaving = false;
    _saved = true;
    notifyListeners();

    debugPrint('Run saved: ${summary.distanceFormatted} km');
    // TODO: Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
  }

  void discardRun(BuildContext context) {
    // TODO: Navigator.pop(context)
    debugPrint('Run discarded');
  }
}
