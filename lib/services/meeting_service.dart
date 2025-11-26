// Service wrapper for Meetings endpoints
import 'package:flutter/foundation.dart';
import 'api_service.dart';

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
}
