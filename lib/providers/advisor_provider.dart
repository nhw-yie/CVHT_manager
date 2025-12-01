// Provider for Advisor-related data (advisor detail, classes)
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../models/models.dart';

class AdvisorProvider with ChangeNotifier {
  final ApiService _api = ApiService.instance;

  Advisor? _selectedAdvisor;
  List<ClassModel> _classesOfAdvisor = [];

  bool isLoading = false;
  String? error;

  Advisor? get selectedAdvisor => _selectedAdvisor;
  List<ClassModel> get classesOfAdvisor => List.unmodifiable(_classesOfAdvisor);

  /// Fetch advisor detail by id
  Future<void> fetchAdvisorDetail(int advisorId) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final resp = await _api.get('/advisors/$advisorId');
      dynamic data = resp['data'] ?? resp;

      if (data is Map<String, dynamic>) {
        _selectedAdvisor = Advisor.fromJson(data);
      } else if (data is Map && data['advisor'] != null) {
        _selectedAdvisor = Advisor.fromJson(Map<String, dynamic>.from(data['advisor']));
      }
    } catch (e) {
      error = e.toString();
      _selectedAdvisor = null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch classes that this advisor is responsible for
  Future<void> fetchAdvisorClasses(int advisorId) async {
    try {
      final resp = await _api.get('/advisors/$advisorId/classes');
      dynamic data = resp['data'] ?? [];
      if (data is! List) data = [];

      final listData = List<dynamic>.from(data);
      _classesOfAdvisor = listData.map<ClassModel>((e) {
        final m = e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e);
        return ClassModel.fromJson(m);
      }).toList();
    } catch (e) {
      error = e.toString();
      _classesOfAdvisor = [];
    } finally {
      notifyListeners();
    }
  }

  /// Update advisor data
  Future<bool> updateAdvisor(int advisorId, Map<String, dynamic> payload) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      await _api.put('/advisors/$advisorId', payload);
      await fetchAdvisorDetail(advisorId);
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void clearSelected() {
    _selectedAdvisor = null;
    _classesOfAdvisor = [];
    notifyListeners();
  }
}