import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show BuildContext, Navigator;
import '../../../core/models/run_model.dart';
import '../../../core/services/database_service.dart';

class RunSummaryViewModel extends ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;

  RunModel _run;
  RunModel get run => _run;

  /// True if the run is already persisted (viewing from history).
  /// False after a just-completed run — then the view shows Save / Discard.
  final bool isReadOnly;

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  bool _isDeleting = false;
  bool get isDeleting => _isDeleting;

  RunSummaryViewModel({required RunModel run, required this.isReadOnly})
      : _run = run;

  String get runName {
    final h = _run.startTime.hour;
    if (h < 10) return 'Morning Run';
    if (h < 14) return 'Midday Run';
    if (h < 18) return 'Afternoon Run';
    if (h < 22) return 'Evening Run';
    return 'Night Run';
  }

  /// Rough calorie estimate — without a real user weight we approximate at
  /// 70kg and ~1 kcal/kg/km, which lands within ~15% of most trackers.
  int get estimatedCalories {
    const kgAssumed = 70;
    return (_run.distanceKm * kgAssumed).round();
  }

  Future<void> saveRun(BuildContext context) async {
    if (_isSaving || isReadOnly) return;
    _isSaving = true;
    notifyListeners();

    try {
      _run = await _db.createRun(_run);
    } catch (e) {
      debugPrint('Save run failed: $e');
      _isSaving = false;
      notifyListeners();
      return;
    }

    _isSaving = false;
    notifyListeners();
    if (context.mounted) {
      Navigator.of(context).pop(true);
    }
  }

  void discardRun(BuildContext context) {
    Navigator.of(context).pop(false);
  }

  Future<void> deleteRun(BuildContext context) async {
    if (!isReadOnly || _run.id == null || _isDeleting) return;
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
