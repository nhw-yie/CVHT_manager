import '../services/api_service.dart';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'dart:io';
// lib/services/academic_monitoring_extensions.dart

extension AcademicMonitoringAPI on ApiService {
  
  // ==========================================
  // 1. XEM BÁO CÁO HỌC KỲ
  // ==========================================
  
  /// Sinh viên xem báo cáo học kỳ của mình
  Future<Map<String, dynamic>> getMyAcademicReport(int semesterId) async {
    return await get('/academic/my-semester-report/$semesterId');
  }
  
  /// Advisor xem báo cáo học kỳ của sinh viên
  Future<Map<String, dynamic>> getStudentAcademicReport({
    required int studentId,
    required int semesterId,
  }) async {
    return await get('/academic/semester-report/$studentId/$semesterId');
  }
  
  // ==========================================
  // 2. SINH VIÊN NGUY CƠ (AT-RISK STUDENTS)
  // ==========================================
  
  /// ⭐ QUAN TRỌNG: Xem sinh viên có nguy cơ bỏ học
  Future<Map<String, dynamic>> getAtRiskStudents({
    int? semesterId,
  }) async {
    final qp = <String, dynamic>{};
    if (semesterId != null) qp['semester_id'] = semesterId;
    
    return await get('/academic/at-risk-students', query: qp);
  }
  
  // ==========================================
  // 3. CẢNH BÁO HỌC VỤ (ACADEMIC WARNINGS)
  // ==========================================
  
  /// Sinh viên xem danh sách cảnh báo của mình
  Future<Map<String, dynamic>> getMyWarnings() async {
    return await get('/academic/my-warnings');
  }
  
  /// ⭐ Advisor tạo cảnh báo học vụ cho sinh viên
  Future<Map<String, dynamic>> createAcademicWarnings({
    required int semesterId,
    required List<int> studentIds,
  }) async {
    return await post('/academic/create-warnings', {
      'semester_id': semesterId,
      'student_ids': studentIds,
    });
  }
  
  /// Advisor xem danh sách cảnh báo đã tạo
  Future<Map<String, dynamic>> getCreatedWarnings() async {
    return await get('/academic/warnings-created');
  }
  
  // ==========================================
  // 4. THỐNG KÊ HỌC VỤ
  // ==========================================
  
  /// ⭐ Thống kê tổng quan học vụ của lớp
  Future<Map<String, dynamic>> getAcademicStatistics({
    int? semesterId,
  }) async {
    final qp = <String, dynamic>{};
    if (semesterId != null) qp['semester_id'] = semesterId;
    
    return await get('/academic/statistics', query: qp);
  }
  
  // ==========================================
  // 5. CẬP NHẬT BÁO CÁO
  // ==========================================
  
  /// Cập nhật báo cáo học kỳ của 1 sinh viên
  Future<Map<String, dynamic>> updateSemesterReport({
    required int studentId,
    required int semesterId,
  }) async {
    return await post('/academic/update-semester-report', {
      'student_id': studentId,
      'semester_id': semesterId,
    });
  }
  
  /// Cập nhật báo cáo hàng loạt cho cả lớp
  Future<Map<String, dynamic>> batchUpdateSemesterReports({
    required int classId,
    required int semesterId,
  }) async {
    return await post('/academic/batch-update-semester-reports', {
      'class_id': classId,
      'semester_id': semesterId,
    });
  }
  
  // ==========================================
  // 6. IMPORT/EXPORT CẢNH BÁO
  // ==========================================
  
  /// Download template Excel để import cảnh báo
  Future<Uint8List> downloadWarningsTemplate() async {
    final resp = await this.dio.get(
      '/academic/download-warnings-template',
      options: Options(responseType: ResponseType.bytes),
    );
    if (resp.data is Uint8List) return resp.data as Uint8List;
    if (resp.data is List<int>) return Uint8List.fromList(List<int>.from(resp.data as List));
    return Uint8List(0);
  }
  
  /// Import cảnh báo học vụ từ Excel
  Future<Map<String, dynamic>> importWarnings(File file) async {
    final fileName = file.path.split(Platform.pathSeparator).last;
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path, filename: fileName),
    });
    final resp = await this.dio.post('/academic/import-warnings', data: form);
    return this.parseResponse(resp);
  }
}