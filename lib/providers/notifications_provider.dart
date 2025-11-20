// lib/providers/advisor_notifications_provider.dart

import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import '../services/api_service.dart';

class AdvisorNotificationsProvider with ChangeNotifier {
  final ApiService _api = ApiService.instance;

  List<NotificationModel> _notifications = [];
  NotificationModel? _selectedNotification;
  List<StudentResponseInfo> _responses = [];
  NotificationStatistics? _statistics;

  bool isLoading = false;
  bool isDetailLoading = false;
  bool isResponsesLoading = false;
  String? errorMessage;

  List<NotificationModel> get notifications =>
      List.unmodifiable(_notifications);
  NotificationModel? get selectedNotification => _selectedNotification;
  List<StudentResponseInfo> get responses => List.unmodifiable(_responses);
  NotificationStatistics? get statistics => _statistics;

  // Filter
  String _typeFilter = 'all';
  String get typeFilter => _typeFilter;

  List<NotificationModel> get filteredNotifications {
    if (_typeFilter == 'all') return _notifications;
    return _notifications.where((n) => n.type == _typeFilter).toList();
  }

  void setTypeFilter(String type) {
    _typeFilter = type;
    notifyListeners();
  }

  /// Fetch all notifications created by this advisor
  Future<void> fetchNotifications() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final resp = await _api.getNotifications(page: 1, perPage: 100);
      dynamic data = resp['data'] ?? [];

      if (data is! List) data = [];

      _notifications =
          data
              .map<NotificationModel>(
                (e) => NotificationModel.fromJson(
                  e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e),
                ),
              )
              .toList();

      // Sort by created_at desc
      _notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch notification detail
  Future<void> fetchDetail(int notificationId) async {
    isDetailLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final resp = await _api.getNotificationById(notificationId.toString());
      dynamic data = resp['data'] ?? resp;

      if (data is Map<String, dynamic>) {
        _selectedNotification = NotificationModel.fromJson(data);
      }
    } catch (e) {
      errorMessage = e.toString();
      _selectedNotification = null;
    } finally {
      isDetailLoading = false;
      notifyListeners();
    }
  }

  /// Fetch responses for a notification
  Future<void> fetchResponses(int notificationId) async {
    isResponsesLoading = true;
    notifyListeners();

    try {
      final resp = await _api.getNotificationResponses(
        notificationId.toString(),
      );
      dynamic data = resp['data'] ?? [];

      if (data is! List) data = [];

      _responses =
          data
              .map<StudentResponseInfo>(
                (e) => StudentResponseInfo.fromJson(
                  e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e),
                ),
              )
              .toList();

      // Sort: pending first, then by created_at desc
      _responses.sort((a, b) {
        if (a.isPending && !b.isPending) return -1;
        if (!a.isPending && b.isPending) return 1;
        return b.createdAt.compareTo(a.createdAt);
      });
    } catch (e) {
      errorMessage = e.toString();
      _responses = [];
    } finally {
      isResponsesLoading = false;
      notifyListeners();
    }
  }

  /// Create new notification
  Future<bool> createNotification({
    required String title,
    required String summary,
    String? link,
    required String type,
    required List<int> classIds,
    List<String>? attachmentPaths,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final payload = {
        'title': title,
        'summary': summary,
        'type': type,
        'class_ids': classIds,
      };

      if (link != null && link.isNotEmpty) {
        payload['link'] = link;
      }

      // Note: For file uploads, you'd need to use FormData with Dio
      // This is a simplified version
      await _api.createNotification(payload);

      // Refresh list
      await fetchNotifications();
      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Update notification
  Future<bool> updateNotification({
    required int notificationId,
    String? title,
    String? summary,
    String? link,
    String? type,
    List<int>? classIds,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final payload = <String, dynamic>{};

      if (title != null) payload['title'] = title;
      if (summary != null) payload['summary'] = summary;
      if (link != null) payload['link'] = link;
      if (type != null) payload['type'] = type;
      if (classIds != null) payload['class_ids'] = classIds;

      await _api.updateNotification(notificationId.toString(), payload);

      // Refresh
      await fetchNotifications();
      if (_selectedNotification?.notificationId == notificationId) {
        await fetchDetail(notificationId);
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

  /// Delete notification
  Future<bool> deleteNotification(int notificationId) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _api.deleteNotification(notificationId.toString());

      // Remove from local list
      _notifications.removeWhere((n) => n.notificationId == notificationId);

      if (_selectedNotification?.notificationId == notificationId) {
        _selectedNotification = null;
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

  /// Reply to student response
  Future<bool> replyToResponse({
    required int responseId,
    required String advisorResponse,
    required String status,
  }) async {
    try {
      final payload = {'advisor_response': advisorResponse, 'status': status};

      await _api.updateNotificationResponse(responseId.toString(), payload);

      // Refresh responses
      if (_selectedNotification != null) {
        await fetchResponses(_selectedNotification!.notificationId);
        await fetchDetail(_selectedNotification!.notificationId);
      }

      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    }
  }

  /// Fetch statistics
  Future<void> fetchStatistics() async {
    try {
      final resp = await _api.getNotificationStatistics();
      dynamic data = resp['data'] ?? resp;

      if (data is Map<String, dynamic>) {
        _statistics = NotificationStatistics.fromJson(data);
        notifyListeners();
      }
    } catch (e) {
      errorMessage = e.toString();
    }
  }

  /// Clear selected notification
  void clearSelected() {
    _selectedNotification = null;
    _responses = [];
    notifyListeners();
  }

  /// Get pending responses count
  int get pendingResponsesCount {
    return _responses.where((r) => r.isPending).length;
  }

  /// Get total responses across all notifications
  int get totalResponsesCount {
    return _notifications.fold(0, (sum, n) => sum + (n.responsesCount ?? 0));
  }
}
