// ...existing code...
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/models.dart'; 
import '../models/student.dart';
import '../models/class_model.dart';// sử dụng ClassModel, StudentModel nếu có

/// Provider quản lý Class / students trong class
/// Dựa trên API docs: docs/API_CLASS_SEMESTER.md
class ClassProvider extends ChangeNotifier {
  final ApiService _api = ApiService.instance;

  // Danh sách lớp
  List<ClassModel> _classes = [];
  List<ClassModel> get classes => List.unmodifiable(_classes);

  // Chi tiết lớp hiện tại
  ClassModel? _selectedClass;
  ClassModel? get selectedClass => _selectedClass;

  // Danh sách sinh viên trong lớp đã chọn
  List<Student> _students = [];
  List<Student> get students => List.unmodifiable(_students);

  // trạng thái
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isDetailLoading = false;
  bool get isDetailLoading => _isDetailLoading;

  String? _error;
  String? get error => _error;

  // Pagination nếu cần (hiện giữ đơn giản)
  int page = 1;
  int perPage = 20;

  /// Lấy danh sách lớp theo quyền user (Admin/Advisor/Student)
  Future<void> fetchClasses({int? page, int? perPage, bool reset = false}) async {
    if (reset) {
      this.page = 1;
      _classes = [];
      notifyListeners();
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    final usePage = page ?? this.page;
    final usePer = perPage ?? this.perPage;

    try {
      final resp = await _api.getClasses(page: usePage, perPage: usePer);
      // resp có thể là Map { success, data } hoặc List
      final data = resp is Map ? resp['data'] : resp;
      if (data is List) {
        _classes = data.map((e) => ClassModel.fromJson(e as Map<String, dynamic>)).toList();
      } else {
        _classes = [];
      }
      // tăng page nếu cần
      this.page = usePage + 1;
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) debugPrint('ClassProvider.fetchClasses error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Lấy chi tiết lớp
  Future<void> fetchClassDetail(int classId) async {
    _isDetailLoading = true;
    _error = null;
    notifyListeners();
    try {
      final resp = await _api.getClassDetail(classId);
      final data = resp is Map ? resp['data'] : resp;
      if (data is Map<String, dynamic>) {
        _selectedClass = ClassModel.fromJson(data);
      } else {
        _selectedClass = null;
      }
    } catch (e) {
      _error = e.toString();
      _selectedClass = null;
      if (kDebugMode) debugPrint('ClassProvider.fetchClassDetail error: $e');
    } finally {
      _isDetailLoading = false;
      notifyListeners();
    }
  }

  /// Lấy danh sách sinh viên trong lớp
  Future<void> fetchStudentsByClass(int classId) async {
    _isDetailLoading = true;
    _error = null;
    notifyListeners();
    try {
      final resp = await _api.getStudentsByClass(classId);
      final data = resp is Map ? resp['data'] : resp;
      if (data is List) {
        _students = data.map((e) => Student.fromJson(e as Map<String, dynamic>)).toList();
      } else {
        _students = [];
      }
    } catch (e) {
      _error = e.toString();
      _students = [];
      if (kDebugMode) debugPrint('ClassProvider.fetchStudentsByClass error: $e');
    } finally {
      _isDetailLoading = false;
      notifyListeners();
    }
  }

  /// Tạo lớp mới (Admin)
  Future<bool> createClass(Map<String, dynamic> payload) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final resp = await _api.createClass(payload);
      // nếu thành công, refresh list
      await fetchClasses(reset: true);
      return true;
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) debugPrint('ClassProvider.createClass error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cập nhật lớp (Admin)
  Future<bool> updateClass(int classId, Map<String, dynamic> payload) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _api.updateClass(classId, payload);
      // refresh
      await fetchClassDetail(classId);
      await fetchClasses(reset: true);
      return true;
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) debugPrint('ClassProvider.updateClass error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Xóa lớp (Admin)
  Future<bool> deleteClass(int classId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _api.deleteClass(classId);
      _classes.removeWhere((c) => c.classId == classId);
      if (_selectedClass?.classId == classId) _selectedClass = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) debugPrint('ClassProvider.deleteClass error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
// ...existing code...