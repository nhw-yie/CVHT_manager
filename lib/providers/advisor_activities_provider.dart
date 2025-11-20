import 'package:flutter/foundation.dart';

import '../models/models.dart';
import '../services/api_service.dart';

/// Provider for advisor activities (CRUD + statistics)
class AdvisorActivitiesProvider with ChangeNotifier {
  final ApiService _api = ApiService.instance;

  List<Activity> _activities = [];
  Activity? _selected;
  List<Student> _assignedStudents = [];
  bool isLoading = false;
  bool isDetailLoading = false;
  String? errorMessage;

  List<Activity> get activities => List.unmodifiable(_activities);
  Activity? get selected => _selected;
  List<Student> get assignedStudents => List.unmodifiable(_assignedStudents);

  AdvisorActivitiesProvider();

  Future<void> fetchActivities({int page = 1, int perPage = 50}) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final resp = await _api.getActivities(query: {'page': page, 'per_page': perPage, 'role': 'advisor'});
      dynamic d = resp['data'] ?? resp;
      List items = [];
      if (d is Map && d['data'] is List) items = d['data'] as List;
      else if (d is List) items = d;

      _activities = items.map<Activity>((e) {
        final map = e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e);
        return Activity.fromJson(map);
      }).toList();
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchDetail(int activityId) async {
    isDetailLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final resp = await _api.getActivityById(activityId.toString());
      final data = resp['data'] ?? resp;
      if (data is Map<String, dynamic>) {
        _selected = Activity.fromJson(data);

        // parse assigned students if present in response
        _assignedStudents = [];
        try {
          if (data['assigned_students'] is List) {
            _assignedStudents = (data['assigned_students'] as List).map<Student>((e) => Student.fromJson(e as Map<String, dynamic>)).toList();
          } else if (data['students'] is List) {
            _assignedStudents = (data['students'] as List).map<Student>((e) => Student.fromJson(e as Map<String, dynamic>)).toList();
          } else if (data['assignments'] is List) {
            // assignments may contain student object inside each item
            _assignedStudents = (data['assignments'] as List).map<Student>((e) {
              final m = e as Map<String, dynamic>;
              if (m['student'] is Map) return Student.fromJson(m['student'] as Map<String, dynamic>);
              return Student.fromJson(m);
            }).toList();
          }
        } catch (_) {
          _assignedStudents = [];
        }
      } else {
        _selected = null;
        _assignedStudents = [];
      }
    } catch (e) {
      errorMessage = e.toString();
      _selected = null;
      _assignedStudents = [];
    } finally {
      isDetailLoading = false;
      notifyListeners();
    }
  }

  /// Create activity. If [assignByAdvisor] is true and [assignments] provided,
  /// this will call the advisor assign endpoint after successful creation.
  Future<bool> createActivity(
    Map<String, dynamic> payload, {
    bool assignByAdvisor = false,
    List<Map<String, dynamic>>? assignments,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final resp = await _api.createActivity(payload);
      // Try to resolve activity id from response
      int? activityId;
      try {
        final data = resp['data'] ?? resp;
        if (data is Map<String, dynamic>) {
          if (data['activity'] is Map && data['activity']['activity_id'] != null) {
            activityId = (data['activity']['activity_id'] as num).toInt();
          } else if (data['activity_id'] != null) {
            activityId = (data['activity_id'] as num).toInt();
          }
        }
      } catch (_) {}

      // If advisor should assign students, call assign endpoint
      if (assignByAdvisor && activityId != null && assignments != null && assignments.isNotEmpty) {
        await _api.assignStudentsToActivity(activityId, assignments);
      }

      await fetchActivities();
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
      await fetchActivities();
      if (_selected?.activityId == activityId) await fetchDetail(activityId);
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
      if (_selected?.activityId == activityId) _selected = null;
      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
