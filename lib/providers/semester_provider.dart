// lib/providers/semester_provider.dart
import 'package:flutter/material.dart';
import '../models/semester.dart';
import '../services/api_service.dart';
import '../utils/error_handler.dart';

class SemesterProvider with ChangeNotifier {
  List<Semester> _semesters = [];
  Semester? _currentSemester;
  bool _loading = false;
  String? _error;

  List<Semester> get semesters => _semesters;
  Semester? get currentSemester => _currentSemester;
  bool get loading => _loading;
  String? get error => _error;

  final ApiService _api = ApiService.instance;

  /// Lấy danh sách học kỳ
  Future<void> fetchSemesters() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final resp = await _api.get('/semesters');
      final data = resp['data'] as List?;
      
      if (data != null) {
        _semesters = data.map((e) => Semester.fromJson(e)).toList();
        
        // Sắp xếp theo năm học và học kỳ giảm dần
        _semesters.sort((a, b) {
          final yearCompare = b.academicYear.compareTo(a.academicYear);
          if (yearCompare != 0) return yearCompare;
          return b.semesterName.compareTo(a.semesterName);
        });
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

  /// Lấy học kỳ hiện tại
  Future<void> fetchCurrentSemester() async {
    try {
      final resp = await _api.get('/semesters/current');
      final data = resp['data'];
      
      if (data != null) {
        _currentSemester = Semester.fromJson(data);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching current semester: $e');
      // Không throw error để không ảnh hưởng đến UI
    }
  }

  /// Lấy học kỳ theo ID
  Semester? getSemesterById(int semesterId) {
    try {
      return _semesters.firstWhere((s) => s.semesterId == semesterId);
    } catch (_) {
      return null;
    }
  }

  /// Clear data
  void clear() {
    _semesters = [];
    _currentSemester = null;
    _loading = false;
    _error = null;
    notifyListeners();
  }
}