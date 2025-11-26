import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import '../services/api_service.dart';

class ActivityAttendanceProvider with ChangeNotifier {
  final ApiService _api = ApiService.instance;

  bool isLoading = false;
  String? errorMessage;

  Uint8List? lastExportedFile;
  Uint8List? lastTemplateFile;
  Map<String, dynamic>? statistics;

  void _setLoading(bool v) {
    isLoading = v;
    notifyListeners();
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }

  Future<Uint8List> exportRegistrations(int activityId) async {
    _setLoading(true);
    errorMessage = null;
    try {
      final bytes = await _api.exportRegistrations(activityId);
      lastExportedFile = bytes;
      return bytes;
    } catch (e) {
      errorMessage = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<Uint8List> exportAttendanceTemplate(int activityId) async {
    _setLoading(true);
    errorMessage = null;
    try {
      final bytes = await _api.exportAttendanceTemplate(activityId);
      lastTemplateFile = bytes;
      return bytes;
    } catch (e) {
      errorMessage = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<Map<String, dynamic>> importAttendance(int activityId, File file) async {
    _setLoading(true);
    errorMessage = null;
    try {
      final resp = await _api.importAttendance(activityId, file);
      return resp;
    } catch (e) {
      errorMessage = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<Map<String, dynamic>> getAttendanceStatistics(int activityId) async {
    _setLoading(true);
    errorMessage = null;
    try {
      final resp = await _api.getAttendanceStatistics(activityId);
      statistics = resp;
      return resp;
    } catch (e) {
      errorMessage = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
}
