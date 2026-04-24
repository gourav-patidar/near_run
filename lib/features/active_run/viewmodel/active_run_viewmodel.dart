import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../../core/models/run_model.dart';
import '../../../core/services/gps_tracking_service.dart';

// ─── Heart rate zones (no BT sensor — kept for future use) ───────────────────

enum HeartRateZone {
  easy(1, 'EASY'),
  fatBurn(2, 'FAT BURN'),
  aerobic(3, 'AEROBIC'),
  anaerobic(4, 'ANAEROBIC'),
  maximal(5, 'MAX EFFORT');

  final int number;
  final String label;
  const HeartRateZone(this.number, this.label);

  static HeartRateZone fromBpm(int bpm) {
    if (bpm < 115) return HeartRateZone.easy;
    if (bpm < 135) return HeartRateZone.fatBurn;
    if (bpm < 155) return HeartRateZone.aerobic;
    if (bpm < 175) return HeartRateZone.anaerobic;
    return HeartRateZone.maximal;
  }
}

// ─── Run state ────────────────────────────────────────────────────────────────

enum RunState { initializing, running, paused, stopped, error }

// ─── ViewModel ────────────────────────────────────────────────────────────────

class ActiveRunViewModel extends ChangeNotifier {
  final GpsTrackingService _gps = GpsTrackingService.instance;
  final MapController mapController = MapController();

  // ── State ───────────────────────────────────────────────────────────────────
  RunState _state = RunState.initializing;
  RunState get state => _state;

  bool get isInitializing => _state == RunState.initializing;
  bool get isRunning => _state == RunState.running;
  bool get isPaused => _state == RunState.paused;
  bool get isStopped => _state == RunState.stopped;
  bool get hasError => _state == RunState.error;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _needsAppSettings = false;
  bool get needsAppSettings => _needsAppSettings;

  bool _needsLocationService = false;
  bool get needsLocationService => _needsLocationService;

  // ── Route + position ────────────────────────────────────────────────────────
  final List<LocationPoint> _routePoints = [];
  List<LatLng> get routeLatLngs => _routePoints.map((p) => p.position).toList();

  LatLng? _currentPosition;
  LatLng? get currentPosition => _currentPosition;

  StreamSubscription<LocationPoint>? _locationSub;

  // ── Metrics ─────────────────────────────────────────────────────────────────
  DateTime? _startTime;
  DateTime? _pauseStart;
  int _pausedSeconds = 0;

  double _distanceMeters = 0;
  double get distanceKm => _distanceMeters / 1000;

  double _elevationGainMeters = 0;
  int get elevationMeters => _elevationGainMeters.round();
  double get elevationProgress => (_elevationGainMeters / 300).clamp(0.0, 1.0);

  int get elapsedSeconds {
    if (_startTime == null) return 0;
    final now = (_state == RunState.paused && _pauseStart != null)
        ? _pauseStart!
        : DateTime.now();
    return now.difference(_startTime!).inSeconds - _pausedSeconds;
  }

  int get paceSeconds {
    if (distanceKm == 0) return 0;
    return (elapsedSeconds / distanceKm).round();
  }

  // ── Formatters ──────────────────────────────────────────────────────────────
  String get distanceWhole => distanceKm.toStringAsFixed(0);
  String get distanceDecimal =>
      '.${distanceKm.toStringAsFixed(2).split('.')[1]}';

  String get durationFormatted {
    final s = elapsedSeconds;
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    final sec = s % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  String get paceFormatted {
    if (paceSeconds == 0) return '--\'--"';
    final m = paceSeconds ~/ 60;
    final s = paceSeconds % 60;
    return '$m\'${s.toString().padLeft(2, '0')}"';
  }

  // Heart rate is placeholder until BT HR sensor is added.
  final int _heartRateBpm = 0;
  int get heartRateBpm => _heartRateBpm;
  HeartRateZone get heartRateZone => HeartRateZone.fromBpm(_heartRateBpm);
  int get filledZoneSegments => heartRateZone.number;

  Timer? _uiTimer;

  // ── Lifecycle ───────────────────────────────────────────────────────────────
  ActiveRunViewModel() {
    _initialize();
  }

  Future<void> _initialize() async {
    _state = RunState.initializing;
    _errorMessage = null;
    _needsAppSettings = false;
    _needsLocationService = false;
    notifyListeners();

    try {
      WakelockPlus.enable();
      await _gps.initForegroundTask();

      final result = await _gps.requestPermissions();
      if (!result.isGranted) {
        switch (result.state) {
          case GpsPermissionState.serviceDisabled:
            _errorMessage =
                'Location services are off. Please turn on GPS in your device settings.';
            _needsLocationService = true;
          case GpsPermissionState.deniedPermanently:
            _errorMessage =
                'Location access is blocked for NearRun. Open settings and allow Location (ideally "Allow all the time") to track runs.';
            _needsAppSettings = true;
          case GpsPermissionState.deniedTemporarily:
            _errorMessage =
                'Location access was denied. Tap Start Run again and allow location to record your route.';
          case GpsPermissionState.granted:
            break;
        }
        _state = RunState.error;
        notifyListeners();
        return;
      }

      // Try to center the map early. It's fine if this takes a moment.
      final initial = await _gps.getCurrentPosition();
      if (initial != null) {
        _currentPosition = initial;
      }

      final started = await _gps.startTracking();
      if (!started) {
        _errorMessage =
            'Failed to start GPS tracking. Try toggling GPS off and on, then retry.';
        _state = RunState.error;
        notifyListeners();
        return;
      }

      _locationSub = _gps.locationStream?.listen(
        _onLocationUpdate,
        onError: (e) => debugPrint('Location stream error: $e'),
      );

      _startTime = DateTime.now();
      _state = RunState.running;

      _uiTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_state == RunState.running) {
          _pushNotification();
          notifyListeners();
        }
      });

      notifyListeners();
    } catch (e) {
      debugPrint('Run init failed: $e');
      _errorMessage = 'Something went wrong starting your run: $e';
      _state = RunState.error;
      notifyListeners();
    }
  }

  void _onLocationUpdate(LocationPoint point) {
    if (_state != RunState.running) {
      // Keep the current position fresh even while paused, so the map
      // doesn't feel frozen if the user is still moving.
      _currentPosition = point.position;
      notifyListeners();
      return;
    }

    _currentPosition = point.position;

    if (_routePoints.isNotEmpty) {
      final last = _routePoints.last;
      final meters = const Distance().as(
        LengthUnit.Meter,
        last.position,
        point.position,
      );

      // Ignore jitter. 3m is tighter than our 5m GPS filter and catches
      // the few duplicate points that still slip through on some chipsets.
      if (meters < 3) {
        _currentPosition = point.position;
        notifyListeners();
        return;
      }

      _distanceMeters += meters;

      if (point.altitude != null && last.altitude != null) {
        final delta = point.altitude! - last.altitude!;
        if (delta > 0) _elevationGainMeters += delta;
      }
    }

    _routePoints.add(point);
    _safeMoveMap(point.position);
    notifyListeners();
  }

  void _safeMoveMap(LatLng target) {
    try {
      final currentZoom = mapController.camera.zoom;
      mapController.move(target, currentZoom < 14 ? 16.0 : currentZoom);
    } catch (_) {
      // Map widget may not be mounted on the very first tick.
    }
  }

  void _pushNotification() {
    _gps.updateNotification(
      distance: distanceKm.toStringAsFixed(2),
      duration: durationFormatted,
      pace: paceFormatted,
    );
  }

  // ── Actions ─────────────────────────────────────────────────────────────────

  void togglePause() {
    if (_state == RunState.running) {
      _state = RunState.paused;
      _pauseStart = DateTime.now();
    } else if (_state == RunState.paused) {
      if (_pauseStart != null) {
        _pausedSeconds += DateTime.now().difference(_pauseStart!).inSeconds;
      }
      _pauseStart = null;
      _state = RunState.running;
    }
    notifyListeners();
  }

  void recenterMap() {
    if (_currentPosition != null) _safeMoveMap(_currentPosition!);
  }

  /// Stops tracking and returns an unsaved RunModel so the caller can
  /// navigate to the summary. Returns null if the run was too short to
  /// be meaningful (<50m recorded).
  Future<RunModel?> stopAndBuildRun() async {
    if (_state == RunState.stopped) return null;
    _state = RunState.stopped;
    notifyListeners();

    _uiTimer?.cancel();
    await _locationSub?.cancel();
    await _gps.stopTracking();
    WakelockPlus.disable();

    if (_startTime == null || _distanceMeters < 50 || _routePoints.length < 2) {
      return null;
    }

    return RunModel(
      startTime: _startTime!,
      endTime: DateTime.now(),
      distanceMeters: _distanceMeters,
      durationSeconds: elapsedSeconds,
      routePoints: routeLatLngs,
      avgPaceSecondsPerKm: paceSeconds.toDouble(),
      elevationGainMeters: _elevationGainMeters,
      avgHeartRate: _heartRateBpm > 0 ? _heartRateBpm : null,
    );
  }

  @override
  void dispose() {
    _uiTimer?.cancel();
    _locationSub?.cancel();
    _gps.stopTracking();
    WakelockPlus.disable();
    super.dispose();
  }
}
