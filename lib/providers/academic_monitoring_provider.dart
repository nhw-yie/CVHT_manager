import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../services/academic_monitoring_extensions.dart';
import '../utils/error_handler.dart';

/// Provider quản lý Academic Monitoring (at-risk students, statistics, warnings)
/// Example usage:
/// // final prov = context.watch<AcademicMonitoringProvider>();
/// // prov.fetchAtRiskStudents(semesterId: 1);
class AcademicMonitoringProvider with ChangeNotifier {
  final ApiService _api = ApiService.instance;

  List<Map<String, dynamic>> _atRiskStudents = [];
  Map<String, dynamic>? _academicStatistics;
  List<Map<String, dynamic>> _academicWarnings = [];

  bool isLoading = false;
  String? errorMessage;
  int? selectedSemesterId;
  String riskLevelFilter = 'all'; // all, critical, high, medium, low

  List<Map<String, dynamic>> get atRiskStudents => List.unmodifiable(_atRiskStudents);
  Map<String, dynamic>? get academicStatistics => _academicStatistics == null ? null : Map<String, dynamic>.from(_academicStatistics!);
  List<Map<String, dynamic>> get academicWarnings => List.unmodifiable(_academicWarnings);

  List<Map<String, dynamic>> get filteredAtRiskStudents {
    if (riskLevelFilter == 'all') return atRiskStudents;
    return _atRiskStudents.where((e) {
      final rl = (e['risk_level'] ?? e['riskLevel'] ?? '').toString().toLowerCase();
      return rl == riskLevelFilter.toLowerCase();
    }).toList();
  }

  void _setLoading(bool v) {
    isLoading = v;
    notifyListeners();
  }

  /// Fetch students at risk (optionally for a semester)
  Future<void> fetchAtRiskStudents({int? semesterId}) async {
    _setLoading(true);
    errorMessage = null;

    try {
      final resp = await _api.getAtRiskStudents(semesterId: semesterId);
      final data = resp['data'] ?? resp;
      List items = [];
      if (data is Map && data['students'] is List) {
        items = data['students'] as List;
      } else if (data is List) {
        items = data;
      } else if (data is Map && data['data'] is List) {
        items = data['data'] as List;
      }

      _atRiskStudents = items.map<Map<String, dynamic>>((e) => e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{}).toList();
      errorMessage = null;
    } on ApiException catch (e) {
      errorMessage = ErrorHandler.mapToMessage(e);
      if (kDebugMode) debugPrint('fetchAtRiskStudents ApiException: $e');
    } catch (e) {
      errorMessage = ErrorHandler.mapToMessage(e);
      if (kDebugMode) debugPrint('fetchAtRiskStudents error: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Fetch academic statistics (overview)
  Future<void> fetchAcademicStatistics({int? semesterId}) async {
    _setLoading(true);
    errorMessage = null;

    try {
      final resp = await _api.getAcademicStatistics(semesterId: semesterId);
      final data = resp['data'] ?? resp;
      if (data is Map<String, dynamic>) {
        _academicStatistics = Map<String, dynamic>.from(data);
      } else {
        _academicStatistics = {'summary': data};
      }
      errorMessage = null;
    } on ApiException catch (e) {
      errorMessage = ErrorHandler.mapToMessage(e);
      if (kDebugMode) debugPrint('fetchAcademicStatistics ApiException: $e');
    } catch (e) {
      errorMessage = ErrorHandler.mapToMessage(e);
      if (kDebugMode) debugPrint('fetchAcademicStatistics error: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Fetch warnings created by advisor
  Future<void> fetchCreatedWarnings() async {
    _setLoading(true);
    errorMessage = null;

    try {
      final resp = await _api.getCreatedWarnings();
      final data = resp['data'] ?? resp;
      List items = [];
      if (data is List) items = data;
      else if (data is Map && data['warnings'] is List) items = data['warnings'];
      else if (data is Map && data['data'] is List) items = data['data'];

      _academicWarnings = items.map<Map<String, dynamic>>((e) => e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{}).toList();
      errorMessage = null;
    } on ApiException catch (e) {
      errorMessage = ErrorHandler.mapToMessage(e);
      if (kDebugMode) debugPrint('fetchCreatedWarnings ApiException: $e');
    } catch (e) {
      errorMessage = ErrorHandler.mapToMessage(e);
      if (kDebugMode) debugPrint('fetchCreatedWarnings error: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Create warnings for a list of students, then refresh
  Future<bool> createWarnings({required int semesterId, required List<int> studentIds}) async {
    _setLoading(true);
    errorMessage = null;
    try {
      await _api.createAcademicWarnings(semesterId: semesterId, studentIds: studentIds);
      // Refresh data
      await fetchCreatedWarnings();
      await fetchAtRiskStudents(semesterId: selectedSemesterId ?? semesterId);
      await fetchAcademicStatistics(semesterId: selectedSemesterId ?? semesterId);
      return true;
    } on ApiException catch (e) {
      errorMessage = ErrorHandler.mapToMessage(e);
      if (kDebugMode) debugPrint('createWarnings ApiException: $e');
      return false;
    } catch (e) {
      errorMessage = ErrorHandler.mapToMessage(e);
      if (kDebugMode) debugPrint('createWarnings error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Set filter for risk level and notify
  void setRiskLevelFilter(String level) {
    if (riskLevelFilter == level) return;
    riskLevelFilter = level;
    notifyListeners();
  }

  /// Set semester context and auto refresh relevant data
  void setSemester(int? semesterId) {
    selectedSemesterId = semesterId;
    notifyListeners();
    // Auto refresh
    fetchAtRiskStudents(semesterId: semesterId);
    fetchAcademicStatistics(semesterId: semesterId);
    fetchCreatedWarnings();
  }

  /// Clear error
  void clearError() {
    errorMessage = null;
    notifyListeners();
  }
}
