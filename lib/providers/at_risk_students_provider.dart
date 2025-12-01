import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../services/academic_monitoring_extensions.dart';
import '../utils/error_handler.dart';

/// Provider managing at-risk students list, selection and sorting.
class AtRiskStudentsProvider with ChangeNotifier {
  final ApiService _api = ApiService.instance;

  // Public state
  List<Map<String, dynamic>> students = [];
  Map<String, dynamic>? selectedStudent;
  bool isLoading = false;
  String? errorMessage;

  // Sorting state
  String sortBy = 'risk_level'; // risk_level, cpa, absence_rate, name
  bool sortAscending = false;

  // Helper to set loading state and notify
  void _setLoading(bool v) {
    isLoading = v;
    notifyListeners();
  }

  /// Fetch at-risk students (optionally filtered by semester).
  /// After fetching, the students list is auto-sorted by current `sortBy`.
  Future<void> fetchAtRiskStudents({int? semesterId}) async {
    _setLoading(true);
    errorMessage = null;

    try {
      final resp = await _api.getAtRiskStudents(semesterId: semesterId);
      final data = resp['data'] ?? resp;

      List items = [];
      if (data is List) {
        items = data;
      } else if (data is Map && data['students'] is List) {
        items = data['students'];
      } else if (data is Map && data['data'] is List) {
        items = data['data'];
      }

      students = items.map<Map<String, dynamic>>((e) => e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{}).toList();

      // Auto-sort after fetching
      _sortStudents();
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

  /// Select a student for detail / actions.
  void selectStudent(Map<String, dynamic> student) {
    selectedStudent = Map<String, dynamic>.from(student);
    notifyListeners();
  }

  /// Update sorting field and direction, re-sort and notify listeners.
  /// `field` expected to be one of: 'risk_level', 'cpa', 'absence_rate', 'name'.
  void setSortOrder(String field, bool ascending) {
    sortBy = field;
    sortAscending = ascending;
    _sortStudents();
    notifyListeners();
  }

  /// Internal sorter using current `sortBy` and `sortAscending`.
  void _sortStudents() {
    int compare(Map<String, dynamic> a, Map<String, dynamic> b) {
      switch (sortBy) {
        case 'cpa':
          // numeric comparison (nulls last)
          final na = _toDouble(a['cpa']);
          final nb = _toDouble(b['cpa']);
          return _numCompare(na, nb);
        case 'absence_rate':
          final na = _toDouble(a['absence_rate']);
          final nb = _toDouble(b['absence_rate']);
          return _numCompare(na, nb);
        case 'name':
          final sa = (a['full_name'] ?? a['name'] ?? '').toString().toLowerCase();
          final sb = (b['full_name'] ?? b['name'] ?? '').toString().toLowerCase();
          return sa.compareTo(sb);
        case 'risk_level':
        default:
          // custom risk order: critical > high > medium > low
          final order = {'critical': 4, 'high': 3, 'medium': 2, 'low': 1};
          final ra = (a['risk_level'] ?? a['riskLevel'] ?? '').toString().toLowerCase();
          final rb = (b['risk_level'] ?? b['riskLevel'] ?? '').toString().toLowerCase();
          final va = order[ra] ?? 0;
          final vb = order[rb] ?? 0;
          return va.compareTo(vb);
      }
    }

    students.sort((a, b) {
      final res = compare(a, b);
      return sortAscending ? res : -res;
    });
  }

  // Helper: safely parse numeric-like values to double
  double? _toDouble(Object? v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    final s = v.toString();
    return double.tryParse(s);
  }

  // Helper: compare doubles where nulls are considered less/equal
  int _numCompare(double? a, double? b) {
    if (a == null && b == null) return 0;
    if (a == null) return -1;
    if (b == null) return 1;
    return a.compareTo(b);
  }

  /// Filter students by risk level (exact match).
  List<Map<String, dynamic>> getStudentsByRiskLevel(String level) {
    final lvl = level.toLowerCase();
    return students.where((s) => ((s['risk_level'] ?? s['riskLevel'] ?? '').toString().toLowerCase() == lvl)).toList();
  }

  /// Count students by risk level.
  int getRiskLevelCount(String level) => getStudentsByRiskLevel(level).length;

  /// Average absence_rate across students. Returns 0.0 if none available.
  double getAverageAbsenceRate() {
    final rates = students.map((s) => _toDouble(s['absence_rate'] ?? s['absenceRate'])).where((e) => e != null).map((e) => e!).toList();
    if (rates.isEmpty) return 0.0;
    final sum = rates.reduce((a, b) => a + b);
    return sum / rates.length;
  }

  // Computed properties
  int get totalAtRisk => students.length;
  int get criticalCount => getRiskLevelCount('critical');
  int get highCount => getRiskLevelCount('high');
  int get mediumCount => getRiskLevelCount('medium');
}
