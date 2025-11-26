import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class ActivitiesProvider with ChangeNotifier {
  final ApiService _api = ApiService.instance;

  List<Activity> _activities = [];
  Activity? _selectedActivity;
  List<ActivityRole> _roles = [];
  List<Student> _availableStudents = [];
  List<Map<String, dynamic>> _registrations = [];
  Map<String, dynamic>? _registrationsSummary;
  Map<String, dynamic>? _registrationsActivity;
  
  bool isLoading = false;
  bool isDetailLoading = false;
  String? errorMessage;

  // Filters
  String? statusFilter;
  DateTime? fromDate;
  DateTime? toDate;
  String? searchQuery;

  List<Activity> get activities => List.unmodifiable(_activities);
  Activity? get selectedActivity => _selectedActivity;
  // Backwards-compatible alias expected by many screens
  Activity? get selected => _selectedActivity;
  List<ActivityRole> get roles => List.unmodifiable(_roles);
  List<Student> get availableStudents => List.unmodifiable(_availableStudents);
  List<Map<String, dynamic>> get registrations => List.unmodifiable(_registrations);
  Map<String, dynamic>? get registrationsSummary => _registrationsSummary == null ? null : Map<String, dynamic>.from(_registrationsSummary!);
  Map<String, dynamic>? get registrationsActivity => _registrationsActivity == null ? null : Map<String, dynamic>.from(_registrationsActivity!);
  // Expose assigned students as a List<Student> by attempting to map registrations
  List<Student> get assignedStudents {
    final List<Student> out = [];
    for (final e in _registrations) {
      try {
        final Map<String, dynamic> item = Map<String, dynamic>.from(e);
        if (item['student'] is Map) {
          out.add(Student.fromJson(Map<String, dynamic>.from(item['student'] as Map)));
          continue;
        }

        // If the registration object itself looks like a Student
        if (item.containsKey('student_id') || item.containsKey('user_code') || item.containsKey('full_name')) {
          out.add(Student.fromJson(item));
          continue;
        }

        // Fallback: try to find nested student-like map under common keys
        for (final key in ['studentInfo', 'student_data', 'student_detail']) {
          if (item[key] is Map) {
            out.add(Student.fromJson(Map<String, dynamic>.from(item[key] as Map)));
            break;
          }
        }
      } catch (err) {
        if (kDebugMode) print('assignedStudents parse error: $err');
        // skip problematic entry
        continue;
      }
    }
    return out;
  }

  // Backwards-compatible aliases for CRUD used in screens
  Future<void> fetchDetail(int activityId) async => await fetchActivityDetail(activityId);

  Future<bool> createActivity(Map<String, dynamic> payload) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _api.createActivity(payload);
      await fetchActivities(reset: true);
      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateActivity(int activityId, Map<String, dynamic> payload) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _api.updateActivity(activityId.toString(), payload);
      await fetchActivities(reset: true);
      if (_selectedActivity?.activityId == activityId) {
        await fetchActivityDetail(activityId);
      }
      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteActivity(int activityId) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _api.deleteActivity(activityId.toString());
      _activities.removeWhere((a) => a.activityId == activityId);
      if (_selectedActivity?.activityId == activityId) _selectedActivity = null;
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch activities với các filters
  Future<void> fetchActivities({
    String? status,
    DateTime? from,
    DateTime? to,
    String? search,
    bool reset = false,
  }) async {
    if (reset) {
      statusFilter = null;
      fromDate = null;
      toDate = null;
      searchQuery = null;
    }

    statusFilter = status ?? statusFilter;
    fromDate = from ?? fromDate;
    toDate = to ?? toDate;
    searchQuery = search ?? searchQuery;

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final params = <String, dynamic>{};
      if (statusFilter != null) params['status'] = statusFilter;
      if (fromDate != null) params['from_date'] = fromDate!.toIso8601String();
      if (toDate != null) params['to_date'] = toDate!.toIso8601String();
      if (searchQuery != null && searchQuery!.isNotEmpty) {
        params['title'] = searchQuery;
      }

      final resp = await _api.getActivities(query: params);
      final data = resp['data'] ?? resp;
      
      List items = [];
      if (data is Map && data['data'] is List) {
        items = data['data'];
      } else if (data is List) {
        items = data;
      }

      _activities = items.map<Activity>((e) {
        if (e is Activity) return e;
        return Activity.fromJson(e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e));
      }).toList();
    } catch (e) {
      errorMessage = e.toString();
      if (kDebugMode) print('Fetch activities error: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch chi tiết activity
  Future<void> fetchActivityDetail(int activityId) async {
    isDetailLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final resp = await _api.getActivityById(activityId.toString());
      final data = resp['data'] ?? resp;
      
      if (data is Map<String, dynamic>) {
        _selectedActivity = Activity.fromJson(data);
        
        // Parse roles
        if (data['roles'] is List) {
          _roles = (data['roles'] as List)
              .map<ActivityRole>((e) => ActivityRole.fromJson(e as Map<String, dynamic>))
              .toList();
        } else {
          _roles = [];
        }
      }
    } catch (e) {
      errorMessage = e.toString();
      if (kDebugMode) print('Fetch activity detail error: $e');
    } finally {
      isDetailLoading = false;
      notifyListeners();
    }
  }

  /// Fetch danh sách sinh viên có thể assign
  Future<void> fetchAvailableStudents(int activityId, {
    String? search,
    int? classId,
    int? minTrainingPoint,
    int? maxTrainingPoint,
    int? minSocialPoint,
    int? maxSocialPoint,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final resp = await _api.getAvailableStudents(
        activityId,
        search: search,
        classId: classId,
        minTrainingPoint: minTrainingPoint,
        maxTrainingPoint: maxTrainingPoint,
        minSocialPoint: minSocialPoint,
        maxSocialPoint: maxSocialPoint,
      );

      final data = resp['data'] ?? resp;
      if (data is Map) {
        final available = data['available_students'];
        if (available is List) {
          _availableStudents = available
              .map<Student>((e) => Student.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      errorMessage = e.toString();
      if (kDebugMode) print('Fetch available students error: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch registrations của activity
  Future<void> fetchRegistrations(int activityId) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final resp = await _api.getActivityRegistrations(activityId);
      final data = resp['data'] ?? resp;

      // Debug print to help diagnose payload shape
      if (kDebugMode) print('fetchRegistrations resp data shape: ${data.runtimeType}');

      // Expecting shape: { activity: {...}, summary: {...}, registrations: [ ... ] }
      if (data is Map) {
        if (data['activity'] is Map) {
          _registrationsActivity = Map<String, dynamic>.from(data['activity'] as Map);
        }
        if (data['summary'] is Map) {
          _registrationsSummary = Map<String, dynamic>.from(data['summary'] as Map);
        }

        final regs = data['registrations'] ?? data['data'] ?? data['items'];
        if (regs is List) {
          _registrations = List<Map<String, dynamic>>.from(
            regs.map((e) => Map<String, dynamic>.from(e))
          );
        }
      } else if (data is List) {
        _registrations = List<Map<String, dynamic>>.from(
          data.map((e) => Map<String, dynamic>.from(e))
        );
        _registrationsSummary = null;
        _registrationsActivity = null;
      }
    } catch (e) {
      errorMessage = e.toString();
      if (kDebugMode) print('Fetch registrations error: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Assign students to activity (Advisor)
  Future<bool> assignStudents(
    int activityId,
    List<Map<String, dynamic>> assignments,
  ) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _api.assignStudentsToActivity(activityId, assignments);
      await fetchRegistrations(activityId);
      return true;
    } catch (e) {
      errorMessage = e.toString();
      if (kDebugMode) print('Assign students error: $e');
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Register activity (Student)
  Future<bool> registerActivity(int activityRoleId) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _api.registerActivity({'activity_role_id': activityRoleId});
      return true;
    } catch (e) {
      errorMessage = e.toString();
      if (kDebugMode) print('Register activity error: $e');
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Cancel registration (Student)
  Future<bool> cancelRegistration(int registrationId, String reason) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _api.cancelRegistration({
        'registration_id': registrationId,
        'reason': reason,
      });
      return true;
    } catch (e) {
      errorMessage = e.toString();
      if (kDebugMode) print('Cancel registration error: $e');
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Cập nhật điểm danh (Advisor)
  Future<bool> updateAttendance(
    int activityId,
    List<Map<String, dynamic>> attendances,
  ) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _api.post(
        '/activities/$activityId/attendance',
        {'attendances': attendances},
      );
      await fetchRegistrations(activityId);
      return true;
    } catch (e) {
      errorMessage = e.toString();
      if (kDebugMode) print('Update attendance error: $e');
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }

  void clearSelected() {
    _selectedActivity = null;
    _roles = [];
    _registrations = [];
    notifyListeners();
  }
}