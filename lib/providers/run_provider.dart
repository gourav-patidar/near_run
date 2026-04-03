import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

enum RunStatus { idle, running, paused, stopped }

class RunData {
  final String id;
  final DateTime date;
  final double distance; // in km
  final int duration; // in seconds
  final int calories;
  final double avgSpeed; // km/hr
  final List<Position> route;

  RunData({
    required this.id,
    required this.date,
    required this.distance,
    required this.duration,
    required this.calories,
    required this.avgSpeed,
    required this.route,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'distance': distance,
      'duration': duration,
      'calories': calories,
      'avgSpeed': avgSpeed,
      'route': route.map((p) => '${p.latitude},${p.longitude}').join(';'),
    };
  }

  factory RunData.fromMap(Map<String, dynamic> map) {
    return RunData(
      id: map['id'],
      date: DateTime.parse(map['date']),
      distance: map['distance'],
      duration: map['duration'],
      calories: map['calories'],
      avgSpeed: map['avgSpeed'],
      route: [], // Parse route if needed
    );
  }
}

class RunProvider extends ChangeNotifier {
  RunStatus _status = RunStatus.idle;
  Timer? _timer;
  StreamSubscription<Position>? _positionStream;
  
  // Current run data
  int _duration = 0; // seconds
  double _distance = 0.0; // km
  int _calories = 0;
  double _currentSpeed = 0.0; // km/hr
  List<Position> _routePoints = [];
  Position? _lastPosition;
  
  // Historical data
  List<RunData> _runHistory = [];
  
  // Getters
  RunStatus get status => _status;
  int get duration => _duration;
  double get distance => _distance;
  int get calories => _calories;
  double get currentSpeed => _currentSpeed;
  List<Position> get routePoints => _routePoints;
  List<RunData> get runHistory => _runHistory;
  
  String get formattedDuration {
    final hours = _duration ~/ 3600;
    final minutes = (_duration % 3600) ~/ 60;
    final seconds = _duration % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
  
  double get avgSpeed => _duration > 0 ? (_distance / _duration) * 3600 : 0.0;
  
  // Weekly stats
  double get weeklyDistance {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    return _runHistory
        .where((run) => run.date.isAfter(weekAgo))
        .fold(0.0, (sum, run) => sum + run.distance);
  }
  
  int get weeklyCalories {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    return _runHistory
        .where((run) => run.date.isAfter(weekAgo))
        .fold(0, (sum, run) => sum + run.calories);
  }
  
  int get totalRuns => _runHistory.length;
  
  double get totalDistance => _runHistory.fold(0.0, (sum, run) => sum + run.distance);
  
  int get totalCalories => _runHistory.fold(0, (sum, run) => sum + run.calories);

  // Check and request location permissions
  Future<bool> checkPermissions() async {
    LocationPermission permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return false;
    }
    
    return true;
  }
  
  // Start tracking run
  Future<void> startRun() async {
    final hasPermission = await checkPermissions();
    if (!hasPermission) {
      throw Exception('Location permission denied');
    }
    
    _status = RunStatus.running;
    _duration = 0;
    _distance = 0.0;
    _calories = 0;
    _routePoints.clear();
    _lastPosition = null;
    
    // Start timer
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _duration++;
      _updateCalories();
      notifyListeners();
    });
    
    // Start location tracking
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5, // Update every 5 meters
    );
    
    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      _updatePosition(position);
    });
    
    notifyListeners();
  }
  
  // Update position and calculate distance
  void _updatePosition(Position position) {
    _routePoints.add(position);
    _currentSpeed = position.speed * 3.6; // m/s to km/hr
    
    if (_lastPosition != null) {
      final distanceInMeters = Geolocator.distanceBetween(
        _lastPosition!.latitude,
        _lastPosition!.longitude,
        position.latitude,
        position.longitude,
      );
      _distance += distanceInMeters / 1000; // Convert to km
    }
    
    _lastPosition = position;
    notifyListeners();
  }
  
  // Calculate calories (rough estimate: 0.75 kcal per kg per km)
  void _updateCalories() {
    const double userWeight = 70; // kg - should be customizable
    _calories = (_distance * userWeight * 0.75).round();
  }
  
  // Pause run
  void pauseRun() {
    if (_status == RunStatus.running) {
      _status = RunStatus.paused;
      _timer?.cancel();
      _positionStream?.pause();
      notifyListeners();
    }
  }
  
  // Resume run
  void resumeRun() {
    if (_status == RunStatus.paused) {
      _status = RunStatus.running;
      
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _duration++;
        _updateCalories();
        notifyListeners();
      });
      
      _positionStream?.resume();
      notifyListeners();
    }
  }
  
  // Stop and save run
  Future<void> stopRun() async {
    _timer?.cancel();
    _positionStream?.cancel();
    
    if (_distance > 0.1) { // Only save if distance > 100m
      final runData = RunData(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        date: DateTime.now(),
        distance: _distance,
        duration: _duration,
        calories: _calories,
        avgSpeed: avgSpeed,
        route: List.from(_routePoints),
      );
      
      _runHistory.insert(0, runData);
      // TODO: Save to database
    }
    
    _status = RunStatus.idle;
    _duration = 0;
    _distance = 0.0;
    _calories = 0;
    _currentSpeed = 0.0;
    _routePoints.clear();
    _lastPosition = null;
    
    notifyListeners();
  }
  
  // Load run history from database
  Future<void> loadRunHistory() async {
    // TODO: Load from database
    // For now, add some mock data
    _runHistory = [
      RunData(
        id: '1',
        date: DateTime.now().subtract(const Duration(days: 0)),
        distance: 10.12,
        duration: 3684,
        calories: 701,
        avgSpeed: 11.2,
        route: [],
      ),
      RunData(
        id: '2',
        date: DateTime.now().subtract(const Duration(days: 5)),
        distance: 9.89,
        duration: 3480,
        calories: 669,
        avgSpeed: 10.8,
        route: [],
      ),
      RunData(
        id: '3',
        date: DateTime.now().subtract(const Duration(days: 10)),
        distance: 9.12,
        duration: 3480,
        calories: 608,
        avgSpeed: 10.0,
        route: [],
      ),
    ];
    notifyListeners();
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    _positionStream?.cancel();
    super.dispose();
  }
}