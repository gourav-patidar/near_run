import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:latlong2/latlong.dart';
import '../models/run_model.dart';

// ─── Permission Result ────────────────────────────────────────────────────────

enum GpsPermissionState {
  granted,
  deniedTemporarily,
  deniedPermanently,
  serviceDisabled,
}

class GpsPermissionResult {
  final GpsPermissionState state;
  final bool hasBackground;
  const GpsPermissionResult(this.state, {this.hasBackground = false});

  bool get isGranted => state == GpsPermissionState.granted;
  bool get shouldOpenSettings => state == GpsPermissionState.deniedPermanently;
  bool get shouldOpenLocationSettings =>
      state == GpsPermissionState.serviceDisabled;
}

// ─── GPS Tracking Service ─────────────────────────────────────────────────────

class GpsTrackingService {
  static final GpsTrackingService instance = GpsTrackingService._init();
  GpsTrackingService._init();

  StreamController<LocationPoint>? _locationController;
  StreamSubscription<Position>? _positionSubscription;

  bool _isTracking = false;
  bool get isTracking => _isTracking;

  Stream<LocationPoint>? get locationStream => _locationController?.stream;

  // ── Foreground task init ────────────────────────────────────────────────────

  Future<void> initForegroundTask() async {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'near_run_gps',
        channelName: 'NearRun GPS Tracking',
        channelDescription: 'Running tracking in progress',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(5000),
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: false,
        allowWakeLock: true,
        allowWifiLock: false,
      ),
    );
  }

  // ── Permission request ──────────────────────────────────────────────────────
  //
  // Android 10+ (especially Samsung One UI) will not show a dialog for
  // `locationAlways` if asked back-to-back with `locationWhenInUse` — it
  // silently returns denied and sends the user to Settings. So we only block
  // on the foreground permission; background is best-effort after the run
  // has successfully started. This also fixes the Samsung case where no
  // prompt ever appeared.
  Future<GpsPermissionResult> requestPermissions() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('GPS service disabled');
      return const GpsPermissionResult(GpsPermissionState.serviceDisabled);
    }

    // Notifications (Android 13+) — foreground service needs a visible
    // notification, so this is required on newer Samsungs. Failure here is
    // not fatal; Android will still allow the service to run without the
    // user-visible notification in many OEM builds.
    if (Platform.isAndroid) {
      final notifStatus = await Permission.notification.status;
      if (notifStatus.isDenied) {
        await Permission.notification.request();
      }
    }

    var status = await Permission.locationWhenInUse.status;
    debugPrint('locationWhenInUse initial: $status');

    if (status.isDenied) {
      status = await Permission.locationWhenInUse.request();
      debugPrint('locationWhenInUse after request: $status');
    }

    if (status.isPermanentlyDenied) {
      return const GpsPermissionResult(GpsPermissionState.deniedPermanently);
    }
    if (!status.isGranted && !status.isLimited) {
      return const GpsPermissionResult(GpsPermissionState.deniedTemporarily);
    }

    // Background is optional. We do NOT await a prompt — that fails silently
    // on Android 11+. Just read current status and report it.
    final alwaysStatus = await Permission.locationAlways.status;
    final hasBackground = alwaysStatus.isGranted || alwaysStatus.isLimited;
    debugPrint('locationAlways status: $alwaysStatus (background=$hasBackground)');

    return GpsPermissionResult(
      GpsPermissionState.granted,
      hasBackground: hasBackground,
    );
  }

  // Ask for background permission separately. On Android 11+ this opens the
  // Settings screen rather than showing a dialog; caller should display an
  // explanation first.
  Future<bool> requestBackgroundPermission() async {
    final status = await Permission.locationAlways.request();
    return status.isGranted || status.isLimited;
  }

  Future<void> openSettings() async {
    await openAppSettings();
  }

  Future<void> openLocationServiceSettings() async {
    await Geolocator.openLocationSettings();
  }

  // ── Start / stop tracking ───────────────────────────────────────────────────

  Future<bool> startTracking() async {
    if (_isTracking) return true;

    try {
      await FlutterForegroundTask.startService(
        serviceId: 256,
        notificationTitle: 'NearRun Active',
        notificationText: 'Tracking your run...',
        notificationIcon: null,
        notificationButtons: const [],
        callback: startCallback,
      );
    } catch (e) {
      debugPrint('Foreground service start failed: $e');
      // Keep going — the GPS stream still works without the foreground
      // notification; the user just loses background survival.
    }

    _locationController = StreamController<LocationPoint>.broadcast();

    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    );

    _positionSubscription =
        Geolocator.getPositionStream(locationSettings: settings).listen(
      (position) {
        _locationController?.add(
          LocationPoint(
            position: LatLng(position.latitude, position.longitude),
            timestamp: DateTime.now(),
            altitude: position.altitude,
            accuracy: position.accuracy,
            speed: position.speed,
          ),
        );
      },
      onError: (error) => debugPrint('GPS stream error: $error'),
      cancelOnError: false,
    );

    _isTracking = true;
    return true;
  }

  Future<void> stopTracking() async {
    if (!_isTracking) return;
    _isTracking = false;

    await _positionSubscription?.cancel();
    _positionSubscription = null;

    try {
      await FlutterForegroundTask.stopService();
    } catch (e) {
      debugPrint('Foreground service stop failed: $e');
    }

    await _locationController?.close();
    _locationController = null;
  }

  Future<void> updateNotification({
    required String distance,
    required String duration,
    required String pace,
  }) async {
    if (!_isTracking) return;
    try {
      await FlutterForegroundTask.updateService(
        notificationTitle: 'NearRun Active',
        notificationText: '$distance km • $duration • $pace/km',
      );
    } catch (_) {
      // Notification updates are cosmetic; ignore failures.
    }
  }

  Future<LatLng?> getCurrentPosition() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 10));
      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      debugPrint('getCurrentPosition failed: $e');
      // Fall back to last-known position — better than nothing for map centering.
      try {
        final last = await Geolocator.getLastKnownPosition();
        if (last != null) return LatLng(last.latitude, last.longitude);
      } catch (_) {}
      return null;
    }
  }
}

// ─── Foreground Task Callback ─────────────────────────────────────────────────

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(_GpsTaskHandler());
}

class _GpsTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp) async {}

  @override
  void onNotificationButtonPressed(String id) {}

  @override
  void onNotificationPressed() {
    FlutterForegroundTask.launchApp('/');
  }
}
