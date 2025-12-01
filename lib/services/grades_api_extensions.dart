// lib/services/grades_api_extensions.dart
// Thêm vào ApiService hoặc tạo extension

import '../services/api_service.dart';
import 'dart:io';

extension GradesAPIExtension on ApiService {
  // ============================================
  // GRADES (ĐIỂM HỌC TẬP)
  // ============================================

  /// Lấy điểm các môn học của sinh viên
  /// Student: xem điểm của mình
  /// Advisor: xem điểm sinh viên trong lớp
  Future<Map<String, dynamic>> getMyGrades({int? semesterId}) async {
    final qp = <String, dynamic>{};
    if (semesterId != null) qp['semester_id'] = semesterId;
    
    return await get('/grades/my-grades', query: qp);
  }

  /// Advisor xem điểm của một sinh viên cụ thể
  Future<Map<String, dynamic>> getStudentGrades({
    required int studentId,
    int? semesterId,
  }) async {
    final qp = <String, dynamic>{};
    if (semesterId != null) qp['semester_id'] = semesterId;
    
    return await get('/grades/student/$studentId', query: qp);
  }

  /// Lấy danh sách sinh viên kèm điểm (Admin only)
  Future<Map<String, dynamic>> getFacultyStudentsGrades({
    int? semesterId,
    int? classId,
    String? search,
  }) async {
    final qp = <String, dynamic>{};
    if (semesterId != null) qp['semester_id'] = semesterId;
    if (classId != null) qp['class_id'] = classId;
    if (search != null && search.isNotEmpty) qp['search'] = search;
    
    return await get('/grades/faculty-students', query: qp);
  }

  /// Lấy tổng quan điểm của khoa (Admin only)
  Future<Map<String, dynamic>> getFacultyGradesOverview({
    int? semesterId,
  }) async {
    final qp = <String, dynamic>{};
    if (semesterId != null) qp['semester_id'] = semesterId;
    
    return await get('/grades/faculty-overview', query: qp);
  }

  /// Xuất điểm lớp theo học kỳ (Advisor/Admin)
  Future<Map<String, dynamic>> exportClassGrades({
    required int classId,
    required int semesterId,
  }) async {
    return await get('/grades/export-class-grades/$classId/$semesterId');
  }

  // ============================================
  // SEMESTERS (HỌC KỲ)
  // ============================================

  /// Lấy danh sách tất cả học kỳ
  Future<Map<String, dynamic>> getSemesters() async {
    return await get('/semesters');
  }

  /// Lấy học kỳ hiện tại
  Future<Map<String, dynamic>> getCurrentSemester() async {
    return await get('/semesters/current');
  }

  /// Lấy chi tiết một học kỳ
  Future<Map<String, dynamic>> getSemesterById(int semesterId) async {
    return await get('/semesters/$semesterId');
  }

  /// Lấy báo cáo học kỳ của sinh viên
  /// Admin/Advisor: phải truyền studentId
  /// Student: tự động lấy của mình
  Future<Map<String, dynamic>> getSemesterReport({
    required int semesterId,
    int? studentId, // Required cho advisor/admin
  }) async {
    if (studentId != null) {
      return await get('/semesters/$semesterId/students/$studentId/report');
    } else {
      // Student tự xem report của mình
      return await get('/semesters/$semesterId/report');
    }
  }

  /// Lấy tất cả báo cáo trong học kỳ (Admin/Advisor)
  Future<Map<String, dynamic>> getAllSemesterReports(int semesterId) async {
    return await get('/semesters/$semesterId/reports');
  }

  // ============================================
  // COURSES (MÔN HỌC)
  // ============================================

  /// Lấy danh sách môn học (public)
  Future<Map<String, dynamic>> getCourses({
    String? search,
    int? unitId,
  }) async {
    final qp = <String, dynamic>{};
    if (search != null && search.isNotEmpty) qp['search'] = search;
    if (unitId != null) qp['unit_id'] = unitId;
    
    return await get('/courses', query: qp);
  }

  /// Chi tiết môn học
  Future<Map<String, dynamic>> getCourseById(int courseId) async {
    return await get('/courses/$courseId');
  }

  /// Lấy môn học của sinh viên (Student)
  Future<Map<String, dynamic>> getMyCourses({int? semesterId}) async {
    final qp = <String, dynamic>{};
    if (semesterId != null) qp['semester_id'] = semesterId;
    
    return await get('/courses/my-courses', query: qp);
  }

  /// Xem sinh viên học một môn (Advisor)
  Future<Map<String, dynamic>> getCourseStudents({
    required int courseId,
    required int semesterId,
  }) async {
    final qp = {'semester_id': semesterId};
    return await get('/courses/$courseId/students', query: qp);
  }

  // ============================================
  // POINT FEEDBACKS (KHIẾU NẠI ĐIỂM)
  // ============================================

  /// Lấy danh sách khiếu nại điểm
  Future<Map<String, dynamic>> getPointFeedbacks({
    int? semesterId,
    String? status, // pending/approved/rejected
    int? studentId, // For advisor
  }) async {
    final qp = <String, dynamic>{};
    if (semesterId != null) qp['semester_id'] = semesterId;
    if (status != null) qp['status'] = status;
    if (studentId != null) qp['student_id'] = studentId;
    
    return await get('/point-feedbacks', query: qp);
  }

  /// Chi tiết một khiếu nại
  Future<Map<String, dynamic>> getPointFeedbackById(int feedbackId) async {
    return await get('/point-feedbacks/$feedbackId');
  }

  /// Tạo khiếu nại mới (Student)
  Future<Map<String, dynamic>> createPointFeedback({
    required int semesterId,
    required String feedbackContent,
    File? attachment,
  }) async {
    final payload = <String, dynamic>{
      'semester_id': semesterId,
      'feedback_content': feedbackContent,
    };

    // TODO: Handle file upload nếu có attachment
    // Có thể cần FormData cho multipart/form-data

    return await post('/point-feedbacks', payload);
  }

  /// Cập nhật khiếu nại (Student, chỉ khi pending)
  Future<Map<String, dynamic>> updatePointFeedback({
    required int feedbackId,
    String? feedbackContent,
    File? attachment,
  }) async {
    final payload = <String, dynamic>{};
    if (feedbackContent != null) payload['feedback_content'] = feedbackContent;

    return await put('/point-feedbacks/$feedbackId', payload);
  }

  /// Xóa khiếu nại (Student, chỉ khi pending)
  Future<void> deletePointFeedback(int feedbackId) async {
    await delete('/point-feedbacks/$feedbackId');
  }

  /// Cố vấn phản hồi khiếu nại (Advisor)
  Future<Map<String, dynamic>> respondToPointFeedback({
    required int feedbackId,
    required String status, // approved/rejected
    required String advisorResponse,
  }) async {
    final payload = {
      'status': status,
      'advisor_response': advisorResponse,
    };

    return await post('/point-feedbacks/$feedbackId/respond', payload);
  }

  /// Thống kê khiếu nại (Advisor)
  Future<Map<String, dynamic>> getPointFeedbackStatistics({
    int? semesterId,
  }) async {
    final qp = <String, dynamic>{};
    if (semesterId != null) qp['semester_id'] = semesterId;
    
    return await get('/point-feedbacks/statistics/overview', query: qp);
  }

  // ============================================
  // MONITORING NOTES (GHI CHÚ THEO DÕI)
  // ============================================

  /// Lấy danh sách ghi chú
  Future<Map<String, dynamic>> getMonitoringNotes({
    int? studentId,
    int? semesterId,
    String? category, // academic/personal/attendance/other
  }) async {
    final qp = <String, dynamic>{};
    if (studentId != null) qp['student_id'] = studentId;
    if (semesterId != null) qp['semester_id'] = semesterId;
    if (category != null) qp['category'] = category;
    
    return await get('/monitoring-notes', query: qp);
  }

  /// Chi tiết một ghi chú
  Future<Map<String, dynamic>> getMonitoringNoteById(int noteId) async {
    return await get('/monitoring-notes/$noteId');
  }

  /// Timeline ghi chú của sinh viên
  Future<Map<String, dynamic>> getStudentMonitoringTimeline(int studentId) async {
    return await get('/monitoring-notes/student/$studentId/timeline');
  }

  /// Tạo ghi chú mới (Advisor)
  Future<Map<String, dynamic>> createMonitoringNote({
    required String userCode, // Mã số sinh viên
    required int semesterId,
    required String category,
    required String title,
    required String content,
  }) async {
    final payload = {
      'user_code': userCode,
      'semester_id': semesterId,
      'category': category,
      'title': title,
      'content': content,
    };

    return await post('/monitoring-notes', payload);
  }

  /// Cập nhật ghi chú (Advisor)
  Future<Map<String, dynamic>> updateMonitoringNote({
    required int noteId,
    String? category,
    String? title,
    String? content,
  }) async {
    final payload = <String, dynamic>{};
    if (category != null) payload['category'] = category;
    if (title != null) payload['title'] = title;
    if (content != null) payload['content'] = content;

    return await put('/monitoring-notes/$noteId', payload);
  }

  /// Xóa ghi chú (Advisor)
  Future<void> deleteMonitoringNote(int noteId) async {
    await delete('/monitoring-notes/$noteId');
  }

  /// Thống kê ghi chú (Advisor)
  Future<Map<String, dynamic>> getMonitoringNotesStatistics({
    int? semesterId,
  }) async {
    final qp = <String, dynamic>{};
    if (semesterId != null) qp['semester_id'] = semesterId;
    
    return await get('/monitoring-notes/statistics/overview', query: qp);
  }
}