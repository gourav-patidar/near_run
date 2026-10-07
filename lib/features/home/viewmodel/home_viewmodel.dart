import 'package:flutter/foundation.dart';
import '../../../core/models/run_model.dart';
import '../../../core/services/database_service.dart';
import '../../../core/services/user_preferences_service.dart';

// ─── Lightweight tip model (rotated locally, no network) ──────────────────────

class QuickTipModel {
  final String title;
  final String body;
  const QuickTipModel({required this.title, required this.body});
}

const _tips = [
  QuickTipModel(
    title: 'Pace yourself early.',
    body:
        'Starting 10% slower than your target pace builds stamina for a stronger finish.',
  ),
  QuickTipModel(
    title: 'Land mid-foot.',
    body:
        'Heel-striking wastes energy and pounds your joints. Aim for the middle of your foot.',
  ),
  QuickTipModel(
    title: 'Breathe in a rhythm.',
    body:
        'Try a 3:2 pattern — inhale for three steps, exhale for two. It steadies your heart rate.',
  ),
  QuickTipModel(
    title: 'Cool down matters.',
    body:
        'Two minutes of easy walking after a run clears lactate faster than stopping cold.',
  ),
  QuickTipModel(
    title: 'Hydrate the night before.',
    body:
        'Most runners are already dehydrated at the start. Water the evening before helps more than gulping at mile one.',
  ),
];

// ─── ViewModel ────────────────────────────────────────────────────────────────

class HomeViewModel extends ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;
  final UserPreferencesService _prefs = UserPreferencesService.instance;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String get userName => _prefs.name;

  RunModel? _lastRun;
  RunModel? get lastRun => _lastRun;

  QuickTipModel? _quickTip;
  QuickTipModel? get quickTip => _quickTip;

  HomeViewModel() {
    _load();
    _db.addListener(_load);
  }

  Future<void> _load() async {
    try {
      final recent = await _db.getRecentRuns(1);
      _lastRun = recent.isNotEmpty ? recent.first : null;
    } catch (e) {
      debugPrint('HomeViewModel load failed: $e');
      _lastRun = null;
    }

    final dayOfYear = int.parse(
      DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays.toString(),
    );
    _quickTip = _tips[dayOfYear % _tips.length];

    _isLoading = false;
    notifyListeners();
  }

  String get greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning, ${_prefs.name}!';
    if (hour < 17) return 'Good afternoon, ${_prefs.name}!';
    return 'Good evening, ${_prefs.name}!';
  }

  String get greetingSubtitle {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 10) {
      return 'The air is crisp — perfect for a morning run.';
    } else if (hour >= 10 && hour < 17) {
      return 'Great conditions for hitting your target pace.';
    } else if (hour >= 17 && hour < 21) {
      return 'An evening run is a solid way to close out the day.';
    }
    return 'Late night miles hit different. Stay safe out there.';
  }

  Future<void> refresh() => _load();

  @override
  void dispose() {
    _db.removeListener(_load);
    super.dispose();
  }
}
