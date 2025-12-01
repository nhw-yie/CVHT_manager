// ...new file...
import 'package:flutter/foundation.dart';
import '../utils/error_handler.dart';
import '../services/notification_service.dart';
import '../services/meeting_service.dart';
import '../models/meeting.dart';
import '../models/meeting_student.dart';
import '../models/meeting_feedback.dart';

class MeetingProvider extends ChangeNotifier {
  final MeetingService _service = MeetingService();

  List<Meeting> _meetings = [];
  List<Meeting> get meetings => List.unmodifiable(_meetings);

  Meeting? _selected;
  Meeting? get selected => _selected;

  List<MeetingStudent> _students = [];
  List<MeetingStudent> get students => List.unmodifiable(_students);

  List<MeetingFeedback> _feedbacks = [];
  List<MeetingFeedback> get feedbacks => List.unmodifiable(_feedbacks);

  bool _isLoading = false;
  bool _isDetailLoading = false;
  String? _error;

  // Guard to prevent re-entrant fetches and rate-limit repeated calls
  bool _isFetching = false;
  DateTime? _lastFetchTime;

  bool get isLoading => _isLoading;
  bool get isDetailLoading => _isDetailLoading;
  String? get error => _error;

  Future<void> fetchMeetings({Map<String, dynamic>? query}) async {
    final now = DateTime.now();
    if (_isFetching) {
      if (kDebugMode) debugPrint('MeetingProvider.fetchMeetings skipped: already fetching');
      return;
    }
    if (_lastFetchTime != null && now.difference(_lastFetchTime!).inSeconds < 5) {
      if (kDebugMode) debugPrint('MeetingProvider.fetchMeetings skipped: rate-limited');
      return;
    }

    _isFetching = true;
    _lastFetchTime = now;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final resp = await _service.getMeetings(query: query);
      final data = resp['data'] ?? resp;
      List<Meeting> parsed = [];
      if (data is List) {
        parsed = data.map((e) => Meeting.fromJson(e as Map<String, dynamic>)).toList();
      } else if (data is Map && data['data'] is List) {
        parsed = (data['data'] as List).map((e) => Meeting.fromJson(e as Map<String, dynamic>)).toList();
      } else {
        parsed = [];
      }

      // detect newly created meetings
      final existingIds = _meetings.map((m) => m.meetingId).toSet();
      final newOnes = parsed.where((m) => !existingIds.contains(m.meetingId)).toList();
      if (newOnes.isNotEmpty) {
        final first = newOnes.first;
        await NotificationService.instance.showNotification(
          id: first.meetingId,
          title: 'Cuộc họp mới',
          body: first.title,
          payload: 'meeting:${first.meetingId}',
        );
      }

      _meetings = parsed;
    } catch (e) {
      // Provide friendly message for timeout/network issues
      if (e is ApiException && (e.message.toLowerCase().contains('timeout') || e.message.toLowerCase().contains('timed out'))) {
        _error = 'Kết nối tới máy chủ chậm. Vui lòng thử lại hoặc kiểm tra kết nối mạng.';
      } else if (e.toString().toLowerCase().contains('timeout') || e.toString().toLowerCase().contains('timed out')) {
        _error = 'Kết nối tới máy chủ chậm. Vui lòng thử lại hoặc kiểm tra kết nối mạng.';
      } else {
        _error = 'Lỗi khi tải cuộc họp: ${e.toString()}';
      }
      if (kDebugMode) debugPrint('MeetingProvider.fetchMeetings error: $e');
    } finally {
      _isFetching = false;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchDetail(int meetingId) async {
    _isDetailLoading = true;
    _error = null;
    notifyListeners();
    try {
      final resp = await _service.getMeetingDetail(meetingId);
      final data = resp['data'] ?? resp;
      if (data is Map<String, dynamic>) {
        _selected = Meeting.fromJson(data);
      } else {
        _selected = null;
      }
    } catch (e) {
      _error = e.toString();
      _selected = null;
      if (kDebugMode) debugPrint('MeetingProvider.fetchDetail error: $e');
    } finally {
      _isDetailLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createMeeting(Map<String, dynamic> payload) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.createMeeting(payload);
      // optional: refresh list
      await fetchMeetings();
      return true;
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) debugPrint('MeetingProvider.createMeeting error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateMeeting(int meetingId, Map<String, dynamic> payload) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.updateMeeting(meetingId, payload);
      await fetchDetail(meetingId);
      await fetchMeetings();
      return true;
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) debugPrint('MeetingProvider.updateMeeting error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteMeeting(int meetingId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.deleteMeeting(meetingId);
      _meetings.removeWhere((m) => m.meetingId == meetingId);
      if (_selected?.meetingId == meetingId) _selected = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) debugPrint('MeetingProvider.deleteMeeting error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchStudents(int meetingId) async {
    _isDetailLoading = true;
    _error = null;
    notifyListeners();
    try {
      final resp = await _service.getMeetingStudents(meetingId);
      final data = resp['data'] ?? resp;
      if (data is List) {
        _students = data.map((e) => MeetingStudent.fromJson(e as Map<String, dynamic>)).toList();
      } else if (data is Map && data['data'] is List) {
        _students = (data['data'] as List).map((e) => MeetingStudent.fromJson(e as Map<String, dynamic>)).toList();
      } else {
        _students = [];
      }
    } catch (e) {
      _error = e.toString();
      _students = [];
      if (kDebugMode) debugPrint('MeetingProvider.fetchStudents error: $e');
    } finally {
      _isDetailLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addStudent(int meetingId, Map<String, dynamic> payload) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.addStudentToMeeting(meetingId, payload);
      await fetchStudents(meetingId);
      return true;
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) debugPrint('MeetingProvider.addStudent error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> removeStudent(int meetingId, int studentId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.removeStudentFromMeeting(meetingId, studentId);
      _students.removeWhere((s) => s.studentId == studentId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) debugPrint('MeetingProvider.removeStudent error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> submitFeedback(int meetingId, Map<String, dynamic> payload) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.submitFeedback(meetingId, payload);
      await fetchFeedbacks(meetingId);
      return true;
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) debugPrint('MeetingProvider.submitFeedback error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchFeedbacks(int meetingId) async {
    _isDetailLoading = true;
    _error = null;
    notifyListeners();
    try {
      final resp = await _service.getFeedbacks(meetingId);
      final data = resp['data'] ?? resp;
      if (data is List) {
        _feedbacks = data.map((e) => MeetingFeedback.fromJson(e as Map<String, dynamic>)).toList();
      } else if (data is Map && data['data'] is List) {
        _feedbacks = (data['data'] as List).map((e) => MeetingFeedback.fromJson(e as Map<String, dynamic>)).toList();
      } else {
        _feedbacks = [];
      }
    } catch (e) {
      _error = e.toString();
      _feedbacks = [];
      if (kDebugMode) debugPrint('MeetingProvider.fetchFeedbacks error: $e');
    } finally {
      _isDetailLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
// ...new file...