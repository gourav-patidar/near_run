import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show BuildContext, Navigator;
import '../../../core/models/run_model.dart';
import '../../../core/services/database_service.dart';
import '../../../core/services/user_preferences_service.dart';

class RunSummaryViewModel extends ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;
  final UserPreferencesService _prefs = UserPreferencesService.instance;

  RunModel _run;
  RunModel get run => _run;

  final bool isReadOnly;

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  bool _isDeleting = false;
  bool get isDeleting => _isDeleting;

  RunSummaryViewModel({required RunModel run, required this.isReadOnly})
      : _run = run {
    if (!isReadOnly && _run.id == null) {
      _autoSaveRun();
    }
  }

  Future<void> _autoSaveRun() async {
    _isSaving = true;
    notifyListeners();

    try {
      _run = await _db.createRun(_run);
    } catch (e) {
      debugPrint('Auto save run failed: $e');
    }

    _isSaving = false;
    notifyListeners();
  }

  String get runName {
    final h = _run.startTime.hour;
    if (h < 10) return 'Morning Run';
    if (h < 14) return 'Midday Run';
    if (h < 18) return 'Afternoon Run';
    if (h < 22) return 'Evening Run';
    return 'Night Run';
  }

  int get estimatedCalories => (_run.distanceKm * _prefs.weightKg).round();

  Future<void> saveRun(BuildContext context) async {
    if (context.mounted) {
      Navigator.of(context).pop(true);
    }
  }

  void discardRun(BuildContext context) {
    if (_run.id != null) {
      _db.deleteRun(_run.id!).then((_) {
        if (context.mounted) Navigator.of(context).pop(false);
      });
    } else {
      Navigator.of(context).pop(false);
    }
  }

  Future<void> deleteRun(BuildContext context) async {
    if (_run.id == null || _isDeleting) return;
    _isDeleting = true;
    notifyListeners();
    try {
      await _db.deleteRun(_run.id!);
    } catch (e) {
      debugPrint('Delete run failed: $e');
      _isDeleting = false;
      notifyListeners();
      return;
    }
    if (context.mounted) {
      Navigator.of(context).pop(true);
    }
  }
}
