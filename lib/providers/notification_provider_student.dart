import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class NotificationsProvider with ChangeNotifier {
  final ApiService _api = ApiService.instance;

  List<NotificationModel> _allNotifications = [];
  List<NotificationModel> _unreadNotifications = [];

  bool isLoading = false;
  String? errorMessage;

  List<NotificationModel> get allNotifications => List.unmodifiable(_allNotifications);
  List<NotificationModel> get unreadNotifications => List.unmodifiable(_unreadNotifications);

  int get unreadCount => _unreadNotifications.length;

  NotificationsProvider();

  // Selected notification detail state
  NotificationModel? _selectedNotification;
  bool _detailLoading = false;
  String? _detailError;

  NotificationModel? get selectedNotification => _selectedNotification;
  bool get isDetailLoading => _detailLoading;
  String? get detailError => _detailError;

  /// Fetch all notifications (both read and unread)
  Future<void> fetchAll() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final resp = await _api.getNotifications(page: 1, perPage: 100);
      dynamic d = resp['data'] ?? resp['notifications'] ?? [];
      if (d is! List) d = [];

      _allNotifications = d.map<NotificationModel>((e) {
        final map = e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e);
        final notif = NotificationModel.fromJson(map['notification'] ?? map);
        final isRead = map['is_read'] ?? false;
        return notif.copyWith(isRead: isRead);
      }).toList();
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch unread notifications only
  Future<void> fetchUnread() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final resp = await _api.getStudentUnreadNotifications();
      dynamic d = resp['data'] ?? [];
      if (d is! List) d = [];

      _unreadNotifications = d.map<NotificationModel>((e) {
        final map = e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e);
        final notif = NotificationModel.fromJson(map['notification'] ?? map);
        return notif.copyWith(isRead: false);
      }).toList();
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Mark a single notification as read
  Future<void> markAsRead(NotificationModel notification) async {
    try {
      _unreadNotifications.removeWhere((n) => n.notificationId == notification.notificationId);

      final idx = _allNotifications.indexWhere((n) => n.notificationId == notification.notificationId);
      if (idx != -1) {
        _allNotifications[idx] = _allNotifications[idx].copyWith(isRead: true);
      }

      notifyListeners();

      await _api.markNotificationRead(notification.notificationId.toString());
    } catch (_) {
      // Optionally revert local state
    }
  }

  /// Mark all unread notifications as read
  Future<void> markAllAsRead() async {
    try {
      _allNotifications = _allNotifications.map((n) => n.copyWith(isRead: true)).toList();
      _unreadNotifications.clear();
      notifyListeners();

      await _api.markAllStudentNotificationsRead();
    } catch (_) {}
  }



  /// Fetch detailed notification by ID and store in provider
  Future<void> fetchDetail(int notificationId) async {
    _detailLoading = true;
    _detailError = null;
    notifyListeners();

    try {
      final resp = await _api.getNotificationById(notificationId.toString());
      dynamic data = resp['data'] ?? resp;
      if (data is Map<String, dynamic>) {
        _selectedNotification = NotificationModel.fromJson(data);
      } else {
        _selectedNotification = null;
      }
    } catch (e) {
      _detailError = e.toString();
      _selectedNotification = null;
    } finally {
      _detailLoading = false;
      notifyListeners();
    }
  }

  /// Clear selected notification (optional)
  void clearSelected() {
    _selectedNotification = null;
    _detailError = null;
    _detailLoading = false;
    notifyListeners();
  }

  // ----------------- Advisor CRUD helpers -----------------
  /// Create notification (Advisor)
  Future<Map<String, dynamic>> createNotification(Map<String, dynamic> payload) async {
    isLoading = true;
    notifyListeners();
    try {
      final resp = await _api.createNotification(payload);
      // refresh list
      await fetchAll();
      return resp;
    } catch (e) {
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Update notification (Advisor)
  Future<Map<String, dynamic>> updateNotification(int id, Map<String, dynamic> payload) async {
    isLoading = true;
    notifyListeners();
    try {
      final resp = await _api.updateNotification(id.toString(), payload);
      await fetchAll();
      // if selected was this id, refresh detail
      if (_selectedNotification?.notificationId == id) await fetchDetail(id);
      return resp;
    } catch (e) {
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Delete notification (Advisor)
  Future<void> deleteNotification(int id) async {
    isLoading = true;
    notifyListeners();
    try {
      await _api.deleteNotification(id.toString());
      // remove from local lists
      _allNotifications.removeWhere((n) => n.notificationId == id);
      _unreadNotifications.removeWhere((n) => n.notificationId == id);
      if (_selectedNotification?.notificationId == id) _selectedNotification = null;
      notifyListeners();
    } catch (e) {
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}