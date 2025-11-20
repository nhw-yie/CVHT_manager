import 'package:flutter/foundation.dart';

import '../models/models.dart';
import '../services/api_service.dart';

/// Combines registration with optional activity & role metadata for UI convenience
class RegistrationItem {
  final ActivityRegistration registration;
  final Activity? activity;
  final ActivityRole? role;

  RegistrationItem({required this.registration, this.activity, this.role});
}

class RegistrationsProvider with ChangeNotifier {
  final ApiService _api = ApiService.instance;

  List<RegistrationItem> _items = [];
  bool isLoading = false;
  String? errorMessage;

  String _filter = 'all';

  List<RegistrationItem> get items => List.unmodifiable(_items);

  RegistrationsProvider();

  Future<void> fetchRegistrations({String? filter}) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    _filter = filter ?? _filter;

    try {
      final resp = await _api.myRegistrations();
      // support several shapes: {data: [...]}, {registrations: [...]}, direct list
      dynamic d = resp['data'] ?? resp['registrations'] ?? resp;
      List items = [];
      if (d is Map && d['data'] is List) items = d['data'] as List;
  else if (d is List) items = d;

      final parsed = <RegistrationItem>[];
      for (final e in items) {
        if (e is Map<String, dynamic>) {
          final reg = ActivityRegistration.fromJson(e);
          Activity? activity;
          ActivityRole? role;
          if (e['activity'] is Map) activity = Activity.fromJson(Map<String, dynamic>.from(e['activity']));
          if (e['role'] is Map) role = ActivityRole.fromJson(Map<String, dynamic>.from(e['role']));
          // some APIs nest under 'activity_info' / 'activity_role'
          if (activity == null && e['activity_info'] is Map) activity = Activity.fromJson(Map<String, dynamic>.from(e['activity_info']));
          if (role == null && e['activity_role'] is Map) role = ActivityRole.fromJson(Map<String, dynamic>.from(e['activity_role']));
          parsed.add(RegistrationItem(registration: reg, activity: activity, role: role));
        }
      }

      // apply filter locally if API doesn't support it
      if (_filter != 'all') {
        _items = parsed.where((it) {
          final s = (it.registration.status ?? '').toLowerCase();
          if (_filter == 'active') return s == 'active' || s == 'registered' || s == 'upcoming';
          if (_filter == 'completed') return s == 'completed' || s == 'done';
          if (_filter == 'cancelled') return s == 'cancelled' || s == 'canceled' || s == 'rejected';
          return true;
        }).toList();
      } else {
        _items = parsed;
      }
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async => await fetchRegistrations(filter: _filter);

  /// Cancel registration with reason. Returns true on success.
  Future<bool> cancelRegistration(String registrationId, String reason) async {
    try {
      await _api.cancelRegistration({'registration_id': registrationId, 'reason': reason});
      // update local item if exists
      final idx = _items.indexWhere((it) => it.registration.registrationId.toString() == registrationId.toString());
      if (idx != -1) {
        final old = _items[idx].registration;
        final updated = ActivityRegistration(
          registrationId: old.registrationId,
          activityRoleId: old.activityRoleId,
          studentId: old.studentId,
          registrationTime: old.registrationTime,
          status: 'cancelled',
        );
        _items[idx] = RegistrationItem(registration: updated, activity: _items[idx].activity, role: _items[idx].role);
        notifyListeners();
      }
      return true;
    } catch (e) {
      if (kDebugMode) print('Cancel registration failed: $e');
      return false;
    }
  }
}
