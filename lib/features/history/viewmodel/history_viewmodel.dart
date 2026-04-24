import 'package:flutter/foundation.dart';
import '../../../core/models/run_model.dart';
import '../../../core/services/database_service.dart';

class HistoryViewModel extends ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  List<RunModel> _runs = [];
  List<RunModel> get runs => List.unmodifiable(_runs);

  bool get isEmpty => _runs.isEmpty;

  HistoryViewModel() {
    _loadRuns();
  }

  Future<void> _loadRuns() async {
    _isLoading = true;
    notifyListeners();
    try {
      _runs = await _db.getAllRuns();
    } catch (e) {
      debugPrint('HistoryViewModel load failed: $e');
      _runs = [];
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> refresh() => _loadRuns();

  Future<void> deleteRun(int id) async {
    await _db.deleteRun(id);
    _runs = _runs.where((r) => r.id != id).toList();
    notifyListeners();
  }
}
