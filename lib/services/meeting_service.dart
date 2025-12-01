// Service wrapper for Meetings endpoints
import 'package:flutter/foundation.dart';
import 'api_service.dart';
import 'package:dio/dio.dart';
import 'dart:typed_data';
import 'dart:io';

/// Service wrapper for Meetings endpoints
class MeetingService {
  final ApiService _api = ApiService.instance;

  Future<Map<String, dynamic>> getMeetings({Map<String, dynamic>? query}) async {
    try {
      final resp = await _api.get('/meetings', query: query);
      return resp;
    } catch (e) {
      if (kDebugMode) debugPrint('MeetingService.getMeetings error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getMeetingDetail(int meetingId) async {
    try {
      final resp = await _api.get('/meetings/$meetingId');
      return resp;
    } catch (e) {
      if (kDebugMode) debugPrint('MeetingService.getMeetingDetail error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createMeeting(Map<String, dynamic> payload) async {
    try {
      final resp = await _api.post('/meetings', payload);
      return resp;
    } catch (e) {
      if (kDebugMode) debugPrint('MeetingService.createMeeting error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateMeeting(int meetingId, Map<String, dynamic> payload) async {
    try {
      final resp = await _api.put('/meetings/$meetingId', payload);
      return resp;
    } catch (e) {
      if (kDebugMode) debugPrint('MeetingService.updateMeeting error: $e');
      rethrow;
    }
  }

  Future<void> deleteMeeting(int meetingId) async {
    try {
      await _api.delete('/meetings/$meetingId');
    } catch (e) {
      if (kDebugMode) debugPrint('MeetingService.deleteMeeting error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getMeetingStudents(int meetingId, {int page = 1, int perPage = 50}) async {
    try {
      final resp = await _api.get('/meetings/$meetingId/students', query: {'page': page, 'per_page': perPage});
      return resp;
    } catch (e) {
      if (kDebugMode) debugPrint('MeetingService.getMeetingStudents error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> addStudentToMeeting(int meetingId, Map<String, dynamic> payload) async {
    try {
      final resp = await _api.post('/meetings/$meetingId/students', payload);
      return resp;
    } catch (e) {
      if (kDebugMode) debugPrint('MeetingService.addStudentToMeeting error: $e');
      rethrow;
    }
  }

  Future<void> removeStudentFromMeeting(int meetingId, int studentId) async {
    try {
      await _api.delete('/meetings/$meetingId/students/$studentId');
    } catch (e) {
      if (kDebugMode) debugPrint('MeetingService.removeStudentFromMeeting error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> submitFeedback(int meetingId, Map<String, dynamic> payload) async {
    try {
      final resp = await _api.post('/meetings/$meetingId/feedbacks', payload);
      return resp;
    } catch (e) {
      if (kDebugMode) debugPrint('MeetingService.submitFeedback error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getFeedbacks(int meetingId, {int page = 1, int perPage = 50}) async {
    try {
      final resp = await _api.get('/meetings/$meetingId/feedbacks', query: {'page': page, 'per_page': perPage});
      return resp;
    } catch (e) {
      if (kDebugMode) debugPrint('MeetingService.getFeedbacks error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> markAttendance({
    required int meetingId,
    required List<Map<String, dynamic>> attendances,
  }) async {
    return await _api.post('/meetings/$meetingId/attendance', {
      'attendances': attendances,
    });
  }
  
  /// Xuất biên bản họp tự động
  Future<Uint8List> exportMinutes(int meetingId) async {
    final resp = await _api.dio.get(
      '/meetings/$meetingId/export-minutes',
      options: Options(responseType: ResponseType.bytes),
    );
    if (resp.data is Uint8List) return resp.data as Uint8List;
    return Uint8List(0);
  }
  
  /// Upload biên bản thủ công
  Future<Map<String, dynamic>> uploadMinutes({
    required int meetingId,
    required File minutesFile,
  }) async {
    final form = FormData.fromMap({
      'minutes_file': await MultipartFile.fromFile(minutesFile.path),
    });
    final resp = await _api.dio.post('/meetings/$meetingId/upload-minutes', data: form);
    return _api.parseResponse(resp);
  }
  
  /// Download biên bản đã lưu
  Future<Uint8List> downloadMinutes(int meetingId) async {
    final resp = await _api.dio.get(
      '/meetings/$meetingId/download-minutes',
      options: Options(responseType: ResponseType.bytes),
    );
    if (resp.data is Uint8List) return resp.data as Uint8List;
    return Uint8List(0);
  }
  
  /// Xóa biên bản
  Future<void> deleteMinutes(int meetingId) async {
    await _api.delete('/meetings/$meetingId/minutes');
  }
  
  /// Cập nhật nội dung họp & ý kiến lớp
  Future<Map<String, dynamic>> updateMeetingSummary({
    required int meetingId,
    String? summary,
    String? classFeedback,
  }) async {
    final payload = <String, dynamic>{};
    if (summary != null) payload['summary'] = summary;
    if (classFeedback != null) payload['class_feedback'] = classFeedback;
    
    return await _api.put('/meetings/$meetingId/summary', payload);
  }
  
  /// ⭐ Thống kê cuộc họp (tổng quan)
  Future<Map<String, dynamic>> getMeetingStatistics({
    String? fromDate,
    String? toDate,
    int? classId,
  }) async {
    final qp = <String, dynamic>{};
    if (fromDate != null) qp['from_date'] = fromDate;
    if (toDate != null) qp['to_date'] = toDate;
    if (classId != null) qp['class_id'] = classId;
    
    return await _api.get('/meetings/statistics/overview', query: qp);
  }
  
  /// ⭐ Google Calendar Integration
  Future<Map<String, dynamic>> getGoogleAttendance(int meetingId) async {
    return await _api.get('/meetings/$meetingId/google-attendance');
  }
  
  Future<Map<String, dynamic>> syncGoogleAttendance(int meetingId) async {
    return await _api.post('/meetings/$meetingId/sync-google-attendance', {});
  }
}
