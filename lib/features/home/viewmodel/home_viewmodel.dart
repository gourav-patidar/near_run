import 'package:flutter/foundation.dart';

// ─── Data Models (lightweight, home-screen scoped) ────────────────────────────

class LastRunModel {
  final double distanceKm;
  final String duration; // e.g. "28'"
  final String pace; // e.g. "5:24"
  final String dateLabel; // e.g. "Tuesday, 6:15 AM"

  const LastRunModel({
    required this.distanceKm,
    required this.duration,
    required this.pace,
    required this.dateLabel,
  });
}

class WeatherModel {
  final double temperatureCelsius;
  final String city;
  final String windSpeed; // e.g. "4 km/h NW"
  final int humidityPercent;
  final String condition; // e.g. "Partly Cloudy"

  const WeatherModel({
    required this.temperatureCelsius,
    required this.city,
    required this.windSpeed,
    required this.humidityPercent,
    required this.condition,
  });
}

class QuickTipModel {
  final String title;
  final String body;

  const QuickTipModel({required this.title, required this.body});
}

// ─── ViewModel ────────────────────────────────────────────────────────────────

class HomeViewModel extends ChangeNotifier {
  // ── State ──────────────────────────────────────────────────────────────────

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _userName = 'Marcus';
  String get userName => _userName;

  String _greetingSubtitle = 'The air is crisp, perfect for a 5k today.';
  String get greetingSubtitle => _greetingSubtitle;

  LastRunModel? _lastRun;
  LastRunModel? get lastRun => _lastRun;

  WeatherModel? _weather;
  WeatherModel? get weather => _weather;

  QuickTipModel? _quickTip;
  QuickTipModel? get quickTip => _quickTip;

  bool _isRunActive = false;
  bool get isRunActive => _isRunActive;

  // ── Initialization ─────────────────────────────────────────────────────────

  HomeViewModel() {
    _init();
  }

  Future<void> _init() async {
    _setLoading(true);

    // Simulated async data load — replace with sqflite / API calls later
    await Future.delayed(const Duration(milliseconds: 600));

    _lastRun = const LastRunModel(
      distanceKm: 5.2,
      duration: "28'",
      pace: '5:24',
      dateLabel: 'Tuesday, 6:15 AM',
    );

    _weather = const WeatherModel(
      temperatureCelsius: 18,
      city: 'San Francisco',
      windSpeed: '4 km/h NW',
      humidityPercent: 62,
      condition: 'Partly Cloudy',
    );

    _quickTip = const QuickTipModel(
      title: 'Pace yourself early.',
      body:
          'Starting 10% slower than your target pace helps build stamina for a stronger finish.',
    );

    _greetingSubtitle = _buildSubtitle();

    _setLoading(false);
  }

  // ── Computed ───────────────────────────────────────────────────────────────

  /// Personalised greeting e.g. "Good morning, Marcus"
  String get greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning, $_userName!';
    if (hour < 17) return 'Good afternoon, $_userName!';
    return 'Good evening, $_userName!';
  }

  /// Formatted temperature string e.g. "18°C"
  String get temperatureLabel {
    if (_weather == null) return '--';
    return '${_weather!.temperatureCelsius.toStringAsFixed(0)}°C';
  }

  /// Formatted distance e.g. "5.2"
  String get lastRunDistance {
    if (_lastRun == null) return '--';
    return _lastRun!.distanceKm.toStringAsFixed(1);
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  /// Called when user taps the big Start Run button
  void onStartRunTapped() {
    _isRunActive = true;
    notifyListeners();
    // Navigation happens in the view layer
  }

  /// Called when user taps notification bell
  void onNotificationTapped() {
    // TODO: Navigate to NotificationsScreen
    debugPrint('Notifications tapped');
  }

  /// Refresh home data (pull-to-refresh or re-enter)
  Future<void> refresh() async {
    await _init();
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  String _buildSubtitle() {
    final hour = DateTime.now().hour;
    final temp = _weather?.temperatureCelsius ?? 20;

    if (hour >= 5 && hour < 10) {
      return 'The air is crisp — perfect for a morning run!';
    } else if (hour >= 10 && hour < 17) {
      return temp > 25
          ? 'Stay hydrated — it\'s warm out there today.'
          : 'Great conditions for hitting your target pace.';
    } else {
      return 'An evening run sounds like a great idea tonight.';
    }
  }
}
