import 'package:flutter/foundation.dart';

import '../models/models.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';

class ActivitiesProvider with ChangeNotifier {
  final ApiService _api = ApiService.instance;

  List<Activity> _activities = [];
  bool isLoading = false;
  String? errorMessage;

  // filters / search
  String? query;
  DateTime? filterDate;
  int? minPoints;
  String? statusFilter; // e.g. upcoming/registered/history

  List<Activity> get activities => List.unmodifiable(_activities);

  ActivitiesProvider();

  /// Fetch activities from API with optional filters.
  Future<void> fetchActivities({String? q, DateTime? date, int? minPointsFilter, String? status}) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    query = q ?? query;
    filterDate = date ?? filterDate;
    minPoints = minPointsFilter ?? minPoints;
    statusFilter = status ?? statusFilter;

    try {
      final params = <String, dynamic>{};
      if (query != null && query!.isNotEmpty) params['q'] = query;
      if (filterDate != null) params['date'] = filterDate!.toIso8601String();
      if (minPoints != null) params['min_points'] = minPoints;
      if (statusFilter != null) params['status'] = statusFilter;

      final resp = await _api.getActivities(query: params.isEmpty ? null : params);

      // parse multiple shapes
      dynamic d = resp['data'] ?? resp['items'] ?? resp;
      List items = [];
      if (d is Map && d['data'] is List) items = d['data'] as List;
      else if (d is Map && d['items'] is List) items = d['items'] as List;
      else if (d is List) items = d;

      // detect new activities by id
      final existingIds = _activities.map((a) => a.activityId).toSet();

      final parsedItems = items.map<Activity>((e) {
        if (e is Activity) return e;
        if (e is Map<String, dynamic>) return Activity.fromJson(e);
        return Activity.fromJson(Map<String, dynamic>.from(e));
      }).toList();

      final newOnes = parsedItems.where((a) => !existingIds.contains(a.activityId)).toList();
      if (newOnes.isNotEmpty) {
        final first = newOnes.first;
        await NotificationService.instance.showNotification(
          id: first.activityId,
          title: 'Hoạt động mới',
          body: first.title,
          payload: 'activity:${first.activityId}',
        );
      }

      _activities = parsedItems;
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await fetchActivities(q: query, date: filterDate, minPointsFilter: minPoints, status: statusFilter);
  }

  /// Register for activity. payload should contain necessary fields, e.g. activity_role_id, student_id
  Future<bool> register(Map<String, dynamic> payload) async {
    try {
      await _api.registerActivity(payload);
      // Optionally refresh list or update local item state
      await refresh();
      return true;
    } catch (e) {
      if (kDebugMode) print('Register error: $e');
      return false;
    }
  }

  Future<bool> cancelRegistration(Map<String, dynamic> payload) async {
    try {
      await _api.cancelRegistration(payload);
      await refresh();
      return true;
    } catch (e) {
      if (kDebugMode) print('Cancel registration error: $e');
      return false;
    }
  }
}
