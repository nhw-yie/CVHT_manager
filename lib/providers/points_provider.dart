import 'package:flutter/foundation.dart';

import '../services/api_service.dart';
import '../models/points.dart';

class PointsProvider with ChangeNotifier {
  final ApiService _api = ApiService.instance;

  bool isLoading = false;
  String? error;

  // ✅ GIỮ NGUYÊN - Điểm của sinh viên cá nhân (dùng cho Student)
  StudentPointsSummary? _summary;
  StudentPointsSummary? get summary => _summary;

  // ✅ THÊM MỚI - Điểm tổng hợp lớp (dùng cho Advisor)
  ClassPointsSummary? _classSummary;
  ClassPointsSummary? get classSummary => _classSummary;

  // ✅ GIỮ NGUYÊN - Method hiện tại cho Student (backward compatible)
  Future<void> fetchPoints({int? semesterId}) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final qp = <String, dynamic>{};
      if (semesterId != null) qp['semester_id'] = semesterId;

      final resp = await _api.get('/student-points', query: qp);
      final data = resp['data'] ?? resp;

      if (data is Map<String, dynamic>) {
        _summary = StudentPointsSummary.fromJson({'data': data});
      } else {
        _summary = StudentPointsSummary.fromJson({'data': resp});
      }
    } catch (e) {
      error = e.toString();
      _summary = null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ✅ THÊM MỚI - Method cho Advisor xem điểm sinh viên cụ thể
  Future<void> fetchStudentPoints({
    int? studentId, // Advisor cần truyền studentId
    int? semesterId, // Filter theo kỳ học (optional)
  }) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final resp = await _api.getStudentPoints(
        studentId: studentId,
        semesterId: semesterId,
      );

      _summary = StudentPointsSummary.fromJson(resp);
    } catch (e) {
      error = e.toString();
      _summary = null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ✅ THÊM MỚI - Method cho Advisor xem tổng hợp điểm cả lớp
  Future<void> fetchClassPointsSummary({
    required int classId,
    int? semesterId, // Filter theo kỳ học (optional)
  }) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final resp = await _api.getClassPointsSummary(
        classId: classId,
        semesterId: semesterId,
      );

      _classSummary = ClassPointsSummary.fromJson(resp);
    } catch (e) {
      error = e.toString();
      _classSummary = null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ✅ GIỮ NGUYÊN - Clear method (cập nhật thêm _classSummary)
  void clear() {
    _summary = null;
    _classSummary = null;
    error = null;
    notifyListeners();
  }
}
