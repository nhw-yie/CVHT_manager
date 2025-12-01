// lib/services/api_service_extensions.dart
// Extension methods để thêm vào ApiService hiện có

import '../services/api_service.dart';

extension StudentManagementAPI on ApiService {
  /// Lấy danh sách học kỳ
  Future<Map<String, dynamic>> getSemesters() async {
    return await get('/semesters');
  }

  /// Lấy học kỳ hiện tại
  Future<Map<String, dynamic>> getCurrentSemester() async {
    return await get('/semesters/current');
  }

  /// Lấy chi tiết học kỳ
  Future<Map<String, dynamic>> getSemesterById(int semesterId) async {
    return await get('/semesters/$semesterId');
  }

  /// Lấy báo cáo học kỳ của sinh viên
  Future<Map<String, dynamic>> getStudentSemesterReport({
    required int semesterId,
    required int studentId,
  }) async {
    return await get('/semesters/$semesterId/students/$studentId/report');
  }

  /// Lấy báo cáo tất cả sinh viên trong học kỳ
  Future<Map<String, dynamic>> getSemesterReports(int semesterId) async {
    return await get('/semesters/$semesterId/reports');
  }

  /// Lấy điểm chi tiết của sinh viên (từ API grades)
  Future<Map<String, dynamic>> getStudentGrades({
    required int studentId,
    int? semesterId,
  }) async {
    final params = <String, dynamic>{};
    if (semesterId != null) params['semester_id'] = semesterId;
    
    return await get('/grades/student/$studentId', query: params);
  }

  /// Lấy danh sách sinh viên với thông tin học tập (Admin only)
  Future<Map<String, dynamic>> getFacultyStudents({
    int? semesterId,
    int? classId,
    String? search,
  }) async {
    final params = <String, dynamic>{};
    if (semesterId != null) params['semester_id'] = semesterId;
    if (classId != null) params['class_id'] = classId;
    if (search != null && search.isNotEmpty) params['search'] = search;
    
    return await get('/grades/faculty-students', query: params);
  }

  /// Lấy tổng quan điểm của khoa (Admin only)
  Future<Map<String, dynamic>> getFacultyOverview({int? semesterId}) async {
    final params = <String, dynamic>{};
    if (semesterId != null) params['semester_id'] = semesterId;
    
    return await get('/grades/faculty-overview', query: params);
  }

  /// Xuất điểm lớp theo học kỳ
  Future<Map<String, dynamic>> exportClassGrades({
    required int classId,
    required int semesterId,
  }) async {
    return await get('/grades/export-class-grades/$classId/$semesterId');
  }

  /// Lấy vị trí lớp trưởng/bí thư
  Future<Map<String, dynamic>> getClassPositions(int classId) async {
    return await get('/classes/$classId/positions');
  }
}