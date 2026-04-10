import 'dart:async';
import 'package:flutter/foundation.dart';

// ─── Heart Rate Zone ──────────────────────────────────────────────────────────

enum HeartRateZone {
  easy(1, 'EASY', 'Zone 1'),
  fatBurn(2, 'FAT BURN', 'Zone 2'),
  aerobic(3, 'AEROBIC', 'Zone 3'),
  anaerobic(4, 'ANAEROBIC', 'Zone 4'),
  maximal(5, 'MAX EFFORT', 'Zone 5');

  final int number;
  final String label;
  final String fullLabel;
  const HeartRateZone(this.number, this.label, this.fullLabel);

  static HeartRateZone fromBpm(int bpm) {
    if (bpm < 115) return HeartRateZone.easy;
    if (bpm < 135) return HeartRateZone.fatBurn;
    if (bpm < 155) return HeartRateZone.aerobic;
    if (bpm < 175) return HeartRateZone.anaerobic;
    return HeartRateZone.maximal;
  }
}

// ─── Run State ────────────────────────────────────────────────────────────────

enum RunState { idle, running, paused, stopped }

// ─── ViewModel ────────────────────────────────────────────────────────────────

class ActiveRunViewModel extends ChangeNotifier {
  // ── Run state ───────────────────────────────────────────────────────────────
  RunState _runState = RunState.running;
  RunState get runState => _runState;

  bool get isRunning => _runState == RunState.running;
  bool get isPaused => _runState == RunState.paused;

  // ── Distance ────────────────────────────────────────────────────────────────
  double _distanceKm = 3.42;
  double get distanceKm => _distanceKm;

  String get distanceFormatted {
    // Split at decimal for styled display
    final parts = _distanceKm.toStringAsFixed(2).split('.');
    return '${parts[0]}.${parts[1]}';
  }

  String get distanceWhole => _distanceKm.toStringAsFixed(0);
  String get distanceDecimal =>
      '.${_distanceKm.toStringAsFixed(2).split('.')[1]}';

  // ── Duration ────────────────────────────────────────────────────────────────
  int _elapsedSeconds = 21 * 60 + 30; // 21:30 initial (demo)
  int get elapsedSeconds => _elapsedSeconds;

  String get durationFormatted {
    final h = _elapsedSeconds ~/ 3600;
    final m = (_elapsedSeconds % 3600) ~/ 60;
    final s = _elapsedSeconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  // ── Pace ────────────────────────────────────────────────────────────────────
  // pace in seconds per km
  int _paceSeconds = 6 * 60 + 15; // 6'15" /km
  int get paceSeconds => _paceSeconds;

  String get paceFormatted {
    final m = _paceSeconds ~/ 60;
    final s = _paceSeconds % 60;
    return '$m\'${s.toString().padLeft(2, '0')}"';
  }

  // ── Elevation ───────────────────────────────────────────────────────────────
  int _elevationMeters = 124;
  int get elevationMeters => _elevationMeters;

  // Elevation gain as 0.0–1.0 progress for the bar
  double get elevationProgress => (_elevationMeters / 300).clamp(0.0, 1.0);

  // ── Heart Rate ───────────────────────────────────────────────────────────────
  int _heartRateBpm = 164;
  int get heartRateBpm => _heartRateBpm;

  HeartRateZone get heartRateZone => HeartRateZone.fromBpm(_heartRateBpm);

  // Zone bar: 5 segments, filled up to current zone
  int get filledZoneSegments => heartRateZone.number;

  // ── Timers ──────────────────────────────────────────────────────────────────
  Timer? _durationTimer;
  Timer? _simulationTimer;

  // ── Init ────────────────────────────────────────────────────────────────────
  ActiveRunViewModel() {
    _startTimers();
  }

  void _startTimers() {
    // Tick elapsed time every second
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_runState == RunState.running) {
        _elapsedSeconds++;
        _updatePace();
        notifyListeners();
      }
    });

    // Simulate GPS distance & heart rate every 3s
    _simulationTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (_runState == RunState.running) {
        _distanceKm += 0.012;
        _heartRateBpm = (_heartRateBpm + ((_heartRateBpm < 170) ? 1 : -1))
            .clamp(120, 185);
        _elevationMeters += 1;
        notifyListeners();
      }
    });
  }

  void _updatePace() {
    if (_distanceKm > 0) {
      // pace (sec/km) = elapsed / distance
      _paceSeconds = (_elapsedSeconds / _distanceKm).round();
    }
  }

  // ── Actions ─────────────────────────────────────────────────────────────────

  void togglePause() {
    if (_runState == RunState.running) {
      _runState = RunState.paused;
    } else if (_runState == RunState.paused) {
      _runState = RunState.running;
    }
    notifyListeners();
  }

  /// Hold-to-stop: call after long press confirmed
  void stopRun() {
    _runState = RunState.stopped;
    _durationTimer?.cancel();
    _simulationTimer?.cancel();
    notifyListeners();
    // TODO: trigger save to sqflite + navigate to RunSummaryScreen
    debugPrint('Run stopped — distance: ${distanceKm.toStringAsFixed(2)} km');
  }

  void recenterMap() {
    // TODO: call map controller to animate to current position
    debugPrint('Recentering map');
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _simulationTimer?.cancel();
    super.dispose();
  }
}
