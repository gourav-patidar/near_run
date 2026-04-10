import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import '../../../core/models/run_model.dart';
import '../../../core/services/gps_tracking_service.dart';
import '../../../core/services/database_service.dart';

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
  final GpsTrackingService _gpsService = GpsTrackingService.instance;
  final DatabaseService _dbService = DatabaseService.instance;

  // Map controller
  final MapController mapController = MapController();

  // ── Run state ───────────────────────────────────────────────────────────────
  RunState _runState = RunState.idle;
  RunState get runState => _runState;

  bool get isRunning => _runState == RunState.running;
  bool get isPaused => _runState == RunState.paused;
  bool get isStopped => _runState == RunState.stopped;
  bool get isIdle => _runState == RunState.idle;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // ── GPS & Route data ────────────────────────────────────────────────────────
  final List<LocationPoint> _routePoints = [];
  List<LatLng> get routeLatLngs => _routePoints.map((p) => p.position).toList();

  LatLng? _currentPosition;
  LatLng? get currentPosition => _currentPosition;

  StreamSubscription<LocationPoint>? _locationSubscription;

  // ── Run metrics ─────────────────────────────────────────────────────────────
  DateTime? _startTime;
  DateTime? _pauseTime;
  int _pausedDuration = 0; // Total paused duration in seconds

  double _distanceMeters = 0.0;
  double get distanceKm => _distanceMeters / 1000;

  int get elapsedSeconds {
    if (_startTime == null) return 0;
    if (_runState == RunState.paused && _pauseTime != null) {
      return _pauseTime!.difference(_startTime!).inSeconds - _pausedDuration;
    }
    return DateTime.now().difference(_startTime!).inSeconds - _pausedDuration;
  }

  // ── Distance formatting ─────────────────────────────────────────────────────
  String get distanceFormatted => distanceKm.toStringAsFixed(2);
  String get distanceWhole => distanceKm.toStringAsFixed(0);
  String get distanceDecimal =>
      '.${distanceKm.toStringAsFixed(2).split('.')[1]}';

  // ── Duration formatting ─────────────────────────────────────────────────────
  String get durationFormatted {
    final h = elapsedSeconds ~/ 3600;
    final m = (elapsedSeconds % 3600) ~/ 60;
    final s = elapsedSeconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  // ── Pace ────────────────────────────────────────────────────────────────────
  int get paceSeconds {
    if (distanceKm == 0) return 0;
    return (elapsedSeconds / distanceKm).round();
  }

  String get paceFormatted {
    if (paceSeconds == 0) return '--\'--"';
    final m = paceSeconds ~/ 60;
    final s = paceSeconds % 60;
    return '$m\'${s.toString().padLeft(2, '0')}"';
  }

  // ── Elevation ───────────────────────────────────────────────────────────────
  double _elevationGainMeters = 0.0;
  int get elevationMeters => _elevationGainMeters.round();
  double get elevationProgress => (_elevationGainMeters / 300).clamp(0.0, 1.0);

  // ── Heart Rate (placeholder - would need bluetooth HR monitor) ──────────────
  int _heartRateBpm = 0;
  int get heartRateBpm => _heartRateBpm;
  HeartRateZone get heartRateZone => HeartRateZone.fromBpm(_heartRateBpm);
  int get filledZoneSegments => heartRateZone.number;

  // ── Timers ──────────────────────────────────────────────────────────────────
  Timer? _updateTimer;

  // ── Init ────────────────────────────────────────────────────────────────────
  ActiveRunViewModel() {
    _initializeRun();
  }

  Future<void> _initializeRun() async {
    _runState = RunState.idle;
    _errorMessage = null;
    notifyListeners();

    // Initialize foreground task
    await _gpsService.initForegroundTask();

    // Check and request permissions first
    final hasPermission = await _gpsService.checkPermissions();
    if (!hasPermission) {
      _errorMessage =
          'Location permission denied. Please enable location access in settings.';
      _runState = RunState.stopped;
      notifyListeners();
      return;
    }

    // Get initial position
    final initialPosition = await _gpsService.getCurrentPosition();
    if (initialPosition != null) {
      _currentPosition = initialPosition;
      mapController.move(initialPosition, 16.0);
    }

    // Start tracking
    final started = await _gpsService.startTracking();
    if (!started) {
      _errorMessage = 'Failed to start GPS tracking. Please try again.';
      _runState = RunState.stopped;
      notifyListeners();
      return;
    }

    // Listen to location updates
    _locationSubscription = _gpsService.locationStream?.listen((locationPoint) {
      _onLocationUpdate(locationPoint);
    });

    // Start the run
    _startTime = DateTime.now();
    _runState = RunState.running;

    // UI update timer (every second)
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_runState == RunState.running) {
        _updateNotification();
        notifyListeners();
      }
    });

    debugPrint('Run initialized successfully');
    notifyListeners();
  }

  // ── Handle location updates ─────────────────────────────────────────────────
  void _onLocationUpdate(LocationPoint point) {
    if (_runState != RunState.running) return;

    _currentPosition = point.position;

    // Calculate distance if we have a previous point
    if (_routePoints.isNotEmpty) {
      final lastPoint = _routePoints.last;
      final distance = const Distance().as(
        LengthUnit.Meter,
        lastPoint.position,
        point.position,
      );

      // Only add point if moved at least 5 meters (reduces noise)
      if (distance >= 5) {
        _distanceMeters += distance;

        // Calculate elevation gain
        if (point.altitude != null && lastPoint.altitude != null) {
          final elevationChange = point.altitude! - lastPoint.altitude!;
          if (elevationChange > 0) {
            _elevationGainMeters += elevationChange;
          }
        }

        _routePoints.add(point);

        // Center map on current position
        mapController.move(point.position, mapController.camera.zoom);
      }
    } else {
      // First point
      _routePoints.add(point);
      mapController.move(point.position, 16.0);
    }

    notifyListeners();
  }

  // ── Update notification ─────────────────────────────────────────────────────
  void _updateNotification() {
    _gpsService.updateNotification(
      distance: distanceKm.toStringAsFixed(2),
      duration: durationFormatted,
      pace: paceFormatted,
    );
  }

  // ── Actions ─────────────────────────────────────────────────────────────────

  void togglePause() {
    if (_runState == RunState.running) {
      _runState = RunState.paused;
      _pauseTime = DateTime.now();
    } else if (_runState == RunState.paused) {
      if (_pauseTime != null && _startTime != null) {
        _pausedDuration += DateTime.now().difference(_pauseTime!).inSeconds;
      }
      _runState = RunState.running;
      _pauseTime = null;
    }
    notifyListeners();
  }

  Future<void> stopRun() async {
    if (_runState == RunState.stopped || _startTime == null) return;

    _runState = RunState.stopped;

    // Stop GPS tracking
    await _gpsService.stopTracking();
    _updateTimer?.cancel();
    _locationSubscription?.cancel();

    // Save run to database
    if (_routePoints.isNotEmpty && _distanceMeters > 50) {
      final run = RunModel(
        startTime: _startTime!,
        endTime: DateTime.now(),
        distanceMeters: _distanceMeters,
        durationSeconds: elapsedSeconds,
        routePoints: routeLatLngs,
        avgPaceSecondsPerKm: paceSeconds.toDouble(),
        elevationGainMeters: _elevationGainMeters,
        avgHeartRate: _heartRateBpm > 0 ? _heartRateBpm : null,
      );

      await _dbService.createRun(run);
      debugPrint(
        'Run saved: ${distanceKm.toStringAsFixed(2)} km in $durationFormatted',
      );
    }

    notifyListeners();
  }

  void recenterMap() {
    if (_currentPosition != null) {
      try {
        final currentZoom = mapController.camera.zoom;
        mapController.move(
          _currentPosition!,
          currentZoom > 14 ? currentZoom : 16.0,
        );
        debugPrint(
          'Map recentered to: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}',
        );
      } catch (e) {
        debugPrint('Error recentering map: $e');
      }
    } else {
      debugPrint('No current position to recenter to');
    }
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _locationSubscription?.cancel();
    _gpsService.stopTracking();
    super.dispose();
  }
}
