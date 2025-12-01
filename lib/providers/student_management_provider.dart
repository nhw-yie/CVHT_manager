// lib/providers/student_management_provider.dart
import 'package:flutter/material.dart';
import '../models/student.dart';
import '../models/student_detail_model.dart';
import '../models/semester_report.dart';
import '../models/points.dart';
import '../services/api_service.dart';
import '../utils/error_handler.dart';

enum SortType {
  gpa,
  trainingPoints,
  socialPoints,
  status,
  name,
}

class StudentManagementProvider with ChangeNotifier {
  final ApiService _api = ApiService.instance;

  // Data
  List<Student> _students = [];
  Map<int, AcademicSummary> _academicSummaryCache = {};
  Map<int, StudentPointsItem> _pointsCache = {};
  Map<int, List<SemesterReport>> _reportsCache = {};

  // Filters
  int? _selectedClassId;
  int? _selectedSemesterId;
  String _searchQuery = '';
  SortType _sortType = SortType.gpa;
  bool _sortAscending = false;

  // Pagination
  int _currentPage = 1;
  bool _hasMore = true;
  bool _loading = false;
  String? _error;

  // Getters
  List<Student> get students => _sortedAndFilteredStudents();
  Map<int, AcademicSummary> get academicSummaryCache => _academicSummaryCache;
  Map<int, StudentPointsItem> get pointsCache => _pointsCache;
  int? get selectedClassId => _selectedClassId;
  int? get selectedSemesterId => _selectedSemesterId;
  String get searchQuery => _searchQuery;
  SortType get sortType => _sortType;
  bool get sortAscending => _sortAscending;
  bool get loading => _loading;
  bool get hasMore => _hasMore;
  String? get error => _error;

  /// Lấy danh sách sinh viên
  Future<void> fetchStudents({
    int? classId,
    String? search,
    bool reset = false,
  }) async {
    if (_loading) return;
    
    if (reset) {
      _currentPage = 1;
      _students = [];
      _hasMore = true;
    }

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final params = <String, dynamic>{
        'page': _currentPage,
        'per_page': 50,
      };

      if (classId != null) params['class_id'] = classId;
      if (search != null && search.isNotEmpty) params['q'] = search;

      final resp = await _api.get('/students', query: params);
      var data = resp['data'];

      // Support multiple API shapes:
      // 1) { data: { students: [...] } }
      // 2) { data: [...] }
      // 3) [...] (already normalized by ApiService._parseData -> {data: [...]})
      List<dynamic>? list;
      if (data is Map) {
        if (data['students'] is List) list = List<dynamic>.from(data['students']);
        else if (data['data'] is List) list = List<dynamic>.from(data['data']);
      } else if (data is List) {
        list = List<dynamic>.from(data);
      }

      if (list != null) {
        final newStudents = list.map((e) => Student.fromJson(e)).toList();
        if (reset) {
          _students = newStudents;
        } else {
          _students.addAll(newStudents);
        }

        _hasMore = newStudents.length >= 50;
        if (_hasMore) _currentPage++;
      }

      _loading = false;
      notifyListeners();
    } catch (e) {
      _error = ErrorHandler.mapToMessage(e);
      _loading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Load điểm của lớp
  Future<void> loadClassPoints(int classId, {int? semesterId}) async {
    try {
      final params = <String, dynamic>{'class_id': classId};
      if (semesterId != null) params['semester_id'] = semesterId;

      final resp = await _api.get('/student-points/class-summary', query: params);
      final data = resp['data'];

      if (data != null) {
        final summary = ClassPointsSummary.fromJson(data);
        
        // Cache điểm vào Map
        _pointsCache.clear();
        for (var item in summary.students) {
          _pointsCache[item.studentId] = item;
        }
        
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading class points: $e');
    }
  }

  /// Load thông tin học tập chi tiết của sinh viên
  Future<void> loadStudentAcademicInfo(int studentId, {int? semesterId}) async {
    try {
      final params = <String, dynamic>{'student_id': studentId};
      if (semesterId != null) params['semester_id'] = semesterId;

      // Load academic summary từ API grades/faculty-students
      final resp = await _api.get('/grades/student/$studentId', query: params);
      final data = resp['data'];

      if (data != null) {
        if (data['academic_summary'] != null) {
          _academicSummaryCache[studentId] = 
              AcademicSummary.fromJson(data['academic_summary']);
        }
        
        if (data['grades'] != null) {
          // Cache reports nếu có
          // TODO: Convert grades to reports if needed
        }
        
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading student academic info: $e');
    }
  }

  /// Load báo cáo học kỳ của sinh viên
  Future<void> loadStudentReports(int studentId, int semesterId) async {
    try {
      final resp = await _api.get('/semesters/$semesterId/students/$studentId/report');
      final data = resp['data'];

      if (data != null) {
        final report = SemesterReport.fromJson(data);
        
        if (_reportsCache[studentId] == null) {
          _reportsCache[studentId] = [];
        }
        
        // Update hoặc thêm report
        final existingIndex = _reportsCache[studentId]!
            .indexWhere((r) => r.semesterId == semesterId);
        
        if (existingIndex >= 0) {
          _reportsCache[studentId]![existingIndex] = report;
        } else {
          _reportsCache[studentId]!.add(report);
        }
        
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading student reports: $e');
    }
  }

  /// Sắp xếp và lọc sinh viên
  List<Student> _sortedAndFilteredStudents() {
    var result = List<Student>.from(_students);

    // Filter by search
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result.where((s) {
        return s.fullName.toLowerCase().contains(query) ||
               s.userCode.toLowerCase().contains(query);
      }).toList();
    }

    // Sort
    result.sort((a, b) {
      int compare = 0;

      switch (_sortType) {
        case SortType.gpa:
          final gpaA = _academicSummaryCache[a.studentId]?.cpa10 ?? 0;
          final gpaB = _academicSummaryCache[b.studentId]?.cpa10 ?? 0;
          compare = gpaB.compareTo(gpaA);
          break;

        case SortType.trainingPoints:
          final pA = _pointsCache[a.studentId]?.totalTrainingPoints ?? 0;
          final pB = _pointsCache[b.studentId]?.totalTrainingPoints ?? 0;
          compare = pB.compareTo(pA);
          break;

        case SortType.socialPoints:
          final pA = _pointsCache[a.studentId]?.totalSocialPoints ?? 0;
          final pB = _pointsCache[b.studentId]?.totalSocialPoints ?? 0;
          compare = pB.compareTo(pA);
          break;

        case SortType.status:
          compare = (a.status ?? '').compareTo(b.status ?? '');
          break;

        case SortType.name:
          compare = a.fullName.compareTo(b.fullName);
          break;
      }

      return _sortAscending ? compare : -compare;
    });

    return result;
  }

  /// Set filters
  void setClassFilter(int? classId) {
    _selectedClassId = classId;
    _currentPage = 1;
    _students = [];
    _hasMore = true;
    notifyListeners();
  }

  void setSemesterFilter(int? semesterId) {
    _selectedSemesterId = semesterId;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSortType(SortType type) {
    if (_sortType == type) {
      _sortAscending = !_sortAscending;
    } else {
      _sortType = type;
      _sortAscending = false;
    }
    notifyListeners();
  }

  /// Get statistics
  Map<String, dynamic> getStatistics() {
    if (_students.isEmpty) {
      return {
        'total': 0,
        'avgGpa': 0.0,
        'avgTraining': 0.0,
        'avgSocial': 0.0,
      };
    }

    double totalGpa = 0;
    double totalTraining = 0;
    double totalSocial = 0;
    int countGpa = 0;

    for (var student in _students) {
      final summary = _academicSummaryCache[student.studentId];
      final points = _pointsCache[student.studentId];

      if (summary?.cpa10 != null) {
        totalGpa += summary!.cpa10!;
        countGpa++;
      }

      if (points != null) {
        totalTraining += points.totalTrainingPoints;
        totalSocial += points.totalSocialPoints;
      }
    }

    return {
      'total': _students.length,
      'avgGpa': countGpa > 0 ? totalGpa / countGpa : 0.0,
      'avgTraining': _students.isNotEmpty ? totalTraining / _students.length : 0.0,
      'avgSocial': _students.isNotEmpty ? totalSocial / _students.length : 0.0,
    };
  }

  /// Clear cache
  void clearCache() {
    _academicSummaryCache.clear();
    _pointsCache.clear();
    _reportsCache.clear();
    notifyListeners();
  }

  /// Clear all
  void clear() {
    _students = [];
    _academicSummaryCache = {};
    _pointsCache = {};
    _reportsCache = {};
    _selectedClassId = null;
    _selectedSemesterId = null;
    _searchQuery = '';
    _sortType = SortType.gpa;
    _sortAscending = false;
    _currentPage = 1;
    _hasMore = true;
    _loading = false;
    _error = null;
    notifyListeners();
  }
}