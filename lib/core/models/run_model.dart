import 'package:latlong2/latlong.dart';

// ─── Run Model ────────────────────────────────────────────────────────────────

class RunModel {
  final int? id;
  final DateTime startTime;
  final DateTime endTime;
  final double distanceMeters;
  final int durationSeconds;
  final List<LatLng> routePoints;
  final double? avgPaceSecondsPerKm;
  final double? elevationGainMeters;
  final int? avgHeartRate;
  final int? caloriesBurned;

  RunModel({
    this.id,
    required this.startTime,
    required this.endTime,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.routePoints,
    this.avgPaceSecondsPerKm,
    this.elevationGainMeters,
    this.avgHeartRate,
    this.caloriesBurned,
  });

  // Getters for formatted values
  double get distanceKm => distanceMeters / 1000;

  String get distanceFormatted => distanceKm.toStringAsFixed(2);

  String get durationFormatted {
    final h = durationSeconds ~/ 3600;
    final m = (durationSeconds % 3600) ~/ 60;
    final s = durationSeconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String? get paceFormatted {
    if (avgPaceSecondsPerKm == null) return null;
    final m = avgPaceSecondsPerKm! ~/ 60;
    final s = (avgPaceSecondsPerKm! % 60).round();
    return '$m\'${s.toString().padLeft(2, '0')}"';
  }

  // Convert to map for database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'start_time': startTime.millisecondsSinceEpoch,
      'end_time': endTime.millisecondsSinceEpoch,
      'distance_meters': distanceMeters,
      'duration_seconds': durationSeconds,
      'route_points': _encodeRoutePoints(routePoints),
      'avg_pace_seconds_per_km': avgPaceSecondsPerKm,
      'elevation_gain_meters': elevationGainMeters,
      'avg_heart_rate': avgHeartRate,
      'calories_burned': caloriesBurned,
    };
  }

  // Create from database map
  factory RunModel.fromMap(Map<String, dynamic> map) {
    return RunModel(
      id: map['id'] as int?,
      startTime: DateTime.fromMillisecondsSinceEpoch(map['start_time'] as int),
      endTime: DateTime.fromMillisecondsSinceEpoch(map['end_time'] as int),
      distanceMeters: map['distance_meters'] as double,
      durationSeconds: map['duration_seconds'] as int,
      routePoints: _decodeRoutePoints(map['route_points'] as String),
      avgPaceSecondsPerKm: map['avg_pace_seconds_per_km'] as double?,
      elevationGainMeters: map['elevation_gain_meters'] as double?,
      avgHeartRate: map['avg_heart_rate'] as int?,
      caloriesBurned: map['calories_burned'] as int?,
    );
  }

  // Encode route points as "lat,lon;lat,lon;..."
  static String _encodeRoutePoints(List<LatLng> points) {
    return points.map((p) => '${p.latitude},${p.longitude}').join(';');
  }

  // Decode route points from string
  static List<LatLng> _decodeRoutePoints(String encoded) {
    if (encoded.isEmpty) return [];
    return encoded.split(';').map((str) {
      final parts = str.split(',');
      return LatLng(double.parse(parts[0]), double.parse(parts[1]));
    }).toList();
  }

  RunModel copyWith({
    int? id,
    DateTime? startTime,
    DateTime? endTime,
    double? distanceMeters,
    int? durationSeconds,
    List<LatLng>? routePoints,
    double? avgPaceSecondsPerKm,
    double? elevationGainMeters,
    int? avgHeartRate,
    int? caloriesBurned,
  }) {
    return RunModel(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      routePoints: routePoints ?? this.routePoints,
      avgPaceSecondsPerKm: avgPaceSecondsPerKm ?? this.avgPaceSecondsPerKm,
      elevationGainMeters: elevationGainMeters ?? this.elevationGainMeters,
      avgHeartRate: avgHeartRate ?? this.avgHeartRate,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
    );
  }
}

// ─── Location Point (used during active tracking) ────────────────────────────

class LocationPoint {
  final LatLng position;
  final DateTime timestamp;
  final double? altitude;
  final double? accuracy;
  final double? speed; // meters per second

  LocationPoint({
    required this.position,
    required this.timestamp,
    this.altitude,
    this.accuracy,
    this.speed,
  });
}
