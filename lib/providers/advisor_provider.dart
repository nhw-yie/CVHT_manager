import 'package:flutter/foundation.dart';

import '../services/api_service.dart';
import '../models/models.dart';
import '../utils/error_handler.dart';

/// Provider for advisor management (list, detail, create, update, delete)
class AdvisorProvider extends ChangeNotifier {
  final ApiService _api = ApiService.instance;

  List<Advisor> _advisors = [];
  List<Advisor> get advisors => List.unmodifiable(_advisors);

  Advisor? _selectedAdvisor;
  Advisor? get selectedAdvisor => _selectedAdvisor;

  List<ClassModel> _classesOfAdvisor = [];
  List<ClassModel> get classesOfAdvisor => List.unmodifiable(_classesOfAdvisor);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  int page = 1;
  int perPage = 20;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> fetchAdvisors({int? page, int? perPage, String? q, bool reset = false}) async {
    if (reset) {
      this.page = 1;
      _advisors = [];
      notifyListeners();
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    final usePage = page ?? this.page;
    final usePer = perPage ?? this.perPage;

    try {
      final qp = <String, dynamic>{'page': usePage, 'per_page': usePer};
      if (q != null && q.isNotEmpty) qp['q'] = q;

      final resp = await _api.get('/advisors', query: qp);
      final data = resp['data'] ?? resp;
      if (data is List) {
        _advisors = data.map((e) => Advisor.fromJson(e as Map<String, dynamic>)).toList();
      } else {
        _advisors = [];
      }
      this.page = usePage + 1;
    } catch (e) {
      _error = _extractError(e);
      if (kDebugMode) debugPrint('AdvisorProvider.fetchAdvisors error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAdvisorDetail(int advisorId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final resp = await _api.get('/advisors/$advisorId');
      final data = resp['data'] ?? resp;
      if (data is Map<String, dynamic>) {
        _selectedAdvisor = Advisor.fromJson(data);
      } else {
        _selectedAdvisor = null;
      }
    } catch (e) {
      _error = _extractError(e);
      _selectedAdvisor = null;
      if (kDebugMode) debugPrint('AdvisorProvider.fetchAdvisorDetail error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createAdvisor(Map<String, dynamic> payload) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _api.post('/advisors', payload);
      // refresh list
      await fetchAdvisors(reset: true);
      return true;
    } catch (e) {
      _error = _extractError(e);
      if (kDebugMode) debugPrint('AdvisorProvider.createAdvisor error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateAdvisor(int advisorId, Map<String, dynamic> payload) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _api.put('/advisors/$advisorId', payload);
      await fetchAdvisorDetail(advisorId);
      await fetchAdvisors(reset: true);
      return true;
    } catch (e) {
      _error = _extractError(e);
      if (kDebugMode) debugPrint('AdvisorProvider.updateAdvisor error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteAdvisor(int advisorId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _api.delete('/advisors/$advisorId');
      _advisors.removeWhere((a) => a.advisorId == advisorId);
      if (_selectedAdvisor?.advisorId == advisorId) _selectedAdvisor = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _extractError(e);
      if (kDebugMode) debugPrint('AdvisorProvider.deleteAdvisor error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAdvisorClasses(int advisorId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final resp = await _api.get('/advisors/$advisorId/classes');
      final data = resp['data'] ?? resp;
      if (data is List) {
        _classesOfAdvisor = data.map((e) => ClassModel.fromJson(e as Map<String, dynamic>)).toList();
      } else {
        _classesOfAdvisor = [];
      }
    } catch (e) {
      _error = _extractError(e);
      _classesOfAdvisor = [];
      if (kDebugMode) debugPrint('AdvisorProvider.fetchAdvisorClasses error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> fetchStatistics(int advisorId) async {
    _error = null;
    try {
      final resp = await _api.get('/advisors/$advisorId/statistics');
      final data = resp['data'] ?? resp;
      if (data is Map<String, dynamic>) return data;
      return {'data': data};
    } catch (e) {
      _error = _extractError(e);
      if (kDebugMode) debugPrint('AdvisorProvider.fetchStatistics error: $e');
      return null;
    }
  }

  Future<bool> changePassword(Map<String, dynamic> payload) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _api.post('/advisors/change-password', payload);
      return true;
    } catch (e) {
      _error = _extractError(e);
      if (kDebugMode) debugPrint('AdvisorProvider.changePassword error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _extractError(Object e) {
    try {
      return ErrorHandler.mapToMessage(e);
    } catch (_) {
      return e.toString();
    }
  }
}
