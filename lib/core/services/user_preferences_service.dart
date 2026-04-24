import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the tiny bit of user state the app needs offline: name, weight
/// (for calorie math), daily distance goal, and whether onboarding is done.
///
/// Singleton + ChangeNotifier so screens can listen for profile edits. Read
/// values synchronously after [load] has completed at app start.
class UserPreferencesService extends ChangeNotifier {
  UserPreferencesService._();
  static final UserPreferencesService instance = UserPreferencesService._();

  static const _kOnboardingComplete = 'onboarding_complete';
  static const _kName = 'user_name';
  static const _kWeightKg = 'user_weight_kg';
  static const _kDailyGoalKm = 'user_daily_goal_km';

  bool _loaded = false;
  bool get isLoaded => _loaded;

  bool _onboardingComplete = false;
  bool get onboardingComplete => _onboardingComplete;

  String _name = 'Runner';
  String get name => _name;

  double _weightKg = 70;
  double get weightKg => _weightKg;

  double _dailyGoalKm = 5;
  double get dailyGoalKm => _dailyGoalKm;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _onboardingComplete = prefs.getBool(_kOnboardingComplete) ?? false;
    _name = prefs.getString(_kName) ?? 'Runner';
    _weightKg = prefs.getDouble(_kWeightKg) ?? 70;
    _dailyGoalKm = prefs.getDouble(_kDailyGoalKm) ?? 5;
    _loaded = true;
    notifyListeners();
  }

  Future<void> completeOnboarding({
    required String name,
    required double weightKg,
    required double dailyGoalKm,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final cleanName = name.trim().isEmpty ? 'Runner' : name.trim();
    await prefs.setString(_kName, cleanName);
    await prefs.setDouble(_kWeightKg, weightKg);
    await prefs.setDouble(_kDailyGoalKm, dailyGoalKm);
    await prefs.setBool(_kOnboardingComplete, true);

    _name = cleanName;
    _weightKg = weightKg;
    _dailyGoalKm = dailyGoalKm;
    _onboardingComplete = true;
    notifyListeners();
  }

  /// For a "reset" action in settings (not yet wired but kept for safety).
  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kOnboardingComplete);
    await prefs.remove(_kName);
    await prefs.remove(_kWeightKg);
    await prefs.remove(_kDailyGoalKm);
    _onboardingComplete = false;
    _name = 'Runner';
    _weightKg = 70;
    _dailyGoalKm = 5;
    notifyListeners();
  }
}
