import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:latlong2/latlong.dart';
import '../models/run_model.dart';

// ─── GPS Tracking Service ─────────────────────────────────────────────────────

class GpsTrackingService {
  static final GpsTrackingService instance = GpsTrackingService._init();
  GpsTrackingService._init();

  StreamController<LocationPoint>? _locationController;
  Stream<LocationPoint>? _locationStream;

  bool _isTracking = false;
  bool get isTracking => _isTracking;

  // Get location stream
  Stream<LocationPoint>? get locationStream => _locationStream;

  // ── Initialize foreground service ───────────────────────────────────────────

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

  // ── Check and request permissions ───────────────────────────────────────────

  Future<bool> checkPermissions() async {
    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('Location services are disabled');
      return false;
    }

    // Check current permission status
    var status = await Permission.location.status;
    debugPrint('Initial location permission status: $status');

    // If not granted, request permission
    if (!status.isGranted) {
      debugPrint('Requesting location permission...');
      status = await Permission.location.request();
      debugPrint('Location permission after request: $status');
    }

    if (status.isDenied) {
      debugPrint('Location permission denied by user');
      return false;
    }

    if (status.isPermanentlyDenied) {
      debugPrint('Location permission permanently denied');
      return false;
    }

    debugPrint('Location permission granted: ${status.isGranted}');
    return status.isGranted || status.isLimited;
  }

  // Check if permissions are already granted (without requesting)
  Future<bool> hasPermissions() async {
    final status = await Permission.location.status;
    return status.isGranted || status.isLimited;
  }

  // Open app settings for user to manually enable permissions
  Future<void> openSettings() async {
    await openAppSettings();
  }

  // ── Start tracking ──────────────────────────────────────────────────────────

  Future<bool> startTracking() async {
    if (_isTracking) return true;

    // Check permissions
    final hasPermission = await checkPermissions();
    if (!hasPermission) return false;

    // Start foreground service
    try {
      await FlutterForegroundTask.startService(
        serviceId: 256,
        notificationTitle: 'NearRun Active',
        notificationText: 'Tracking your run...',
        notificationIcon: null,
        notificationButtons: [],
        callback: startCallback,
      );
    } catch (e) {
      debugPrint('Failed to start foreground service: $e');
      return false;
    }

    // Create location stream
    _locationController = StreamController<LocationPoint>.broadcast();
    _locationStream = _locationController!.stream;

    // Start listening to GPS
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update every 10 meters
    );

    Geolocator.getPositionStream(locationSettings: locationSettings).listen(
      (Position position) {
        final locationPoint = LocationPoint(
          position: LatLng(position.latitude, position.longitude),
          timestamp: DateTime.now(),
          altitude: position.altitude,
          accuracy: position.accuracy,
          speed: position.speed,
        );
        _locationController?.add(locationPoint);
      },
      onError: (error) {
        debugPrint('GPS Error: $error');
      },
    );

    _isTracking = true;
    return true;
  }

  // ── Stop tracking ───────────────────────────────────────────────────────────

  Future<void> stopTracking() async {
    if (!_isTracking) return;

    // Stop foreground service
    await FlutterForegroundTask.stopService();

    // Close stream
    await _locationController?.close();
    _locationController = null;
    _locationStream = null;

    _isTracking = false;
  }

  // ── Update notification ─────────────────────────────────────────────────────

  Future<void> updateNotification({
    required String distance,
    required String duration,
    required String pace,
  }) async {
    if (_isTracking) {
      await FlutterForegroundTask.updateService(
        notificationTitle: 'NearRun Active',
        notificationText: '$distance km • $duration • $pace/km',
      );
    }
  }

  // ── Get current position ────────────────────────────────────────────────────

  Future<LatLng?> getCurrentPosition() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      debugPrint('Error getting current position: $e');
      return null;
    }
  }
}

// ─── Foreground Task Callback ─────────────────────────────────────────────────

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(GpsTaskHandler());
}

class GpsTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    // Initialize if needed
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // This is called every 5 seconds (from ForegroundTaskEventAction)
    // The actual GPS updates happen via Geolocator stream in the main isolate
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    // Clean up
  }

  @override
  void onNotificationButtonPressed(String id) {
    // Handle notification button press if you add buttons later
  }

  @override
  void onNotificationPressed() {
    // Bring app to foreground when notification is tapped
    FlutterForegroundTask.launchApp('/');
  }
}
