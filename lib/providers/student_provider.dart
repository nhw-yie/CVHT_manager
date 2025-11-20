import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

/// Provider to manage student listing and student CRUD operations.
class StudentProvider extends ChangeNotifier {
  final ApiService _api = ApiService.instance;

  List<Map<String, dynamic>> students = [];
  Map<String, dynamic>? studentDetail;

  bool loading = false;
  String? error;

  // Pagination
  int page = 1;
  int perPage = 20;
  bool hasMore = true;

  Future<void> fetchStudents({
    int? page,
    int? perPage,
    String? search,
    int? classId,
    String? status,
    bool reset = false,
  }) async {
    if (reset) {
      this.page = 1;
      students = [];
      hasMore = true;
      notifyListeners();
    }

    if (!hasMore && page == null) return;

    loading = true;
    error = null;
    notifyListeners();

    final int usePage = page ?? this.page;
    final int usePer = perPage ?? this.perPage;

    try {
      final resp = await _api.getStudents(page: usePage, perPage: usePer, q: search, classId: classId);
      dynamic data = resp['data'];
      // support both envelope and direct list
      if (data is Map && data['data'] is List) data = data['data'];

      if (data is List) {
        final list = List<Map<String, dynamic>>.from(data.map((e) => Map<String, dynamic>.from(e as Map)));
        if (usePage == 1) students = list; else students.addAll(list);
        hasMore = list.length >= usePer;
        this.page = usePage + 1;
      } else {
        // unexpected shape
        students = [];
        hasMore = false;
      }
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> fetchStudentDetail(String id) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final resp = await _api.getStudentById(id);
      dynamic data = resp['data'];
      if (data is Map) studentDetail = Map<String, dynamic>.from(data);
      else studentDetail = {'data': data};
    } catch (e) {
      error = e.toString();
      studentDetail = null;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> createStudent(Map<String, dynamic> payload) async {
    loading = true;
    notifyListeners();
    try {
      final resp = await _api.createStudent(payload);
      // optionally refresh list
      return resp;
    } catch (e) {
      rethrow;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> updateStudent(String id, Map<String, dynamic> payload) async {
    loading = true;
    notifyListeners();
    try {
      final resp = await _api.updateStudent(id, payload);
      return resp;
    } catch (e) {
      rethrow;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> deleteStudent(String id) async {
    loading = true;
    notifyListeners();
    try {
      await _api.deleteStudent(id);
      students.removeWhere((s) => s['student_id'].toString() == id.toString() || s['id']?.toString() == id.toString());
    } catch (e) {
      rethrow;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> changePassword(Map<String, dynamic> payload) async {
    loading = true;
    notifyListeners();
    try {
      final resp = await _api.changeStudentPassword(payload);
      return resp;
    } catch (e) {
      rethrow;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> getClassPositions(int classId) async {
    loading = true;
    notifyListeners();
    try {
      final resp = await _api.getClassPositions(classId);
      return resp;
    } catch (e) {
      rethrow;
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
