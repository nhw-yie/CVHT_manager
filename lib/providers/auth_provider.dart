import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';
import '../services/api_service.dart';
import '../utils/error_handler.dart';

/// SharedPreferences-backed TokenStorage to persist tokens as requested.
class SharedPrefTokenStorage implements TokenStorage {
  static const _kAccess = 'access_token';
  static const _kRefresh = 'refresh_token';

  SharedPrefTokenStorage();

  Future<SharedPreferences> get _prefs async =>
      await SharedPreferences.getInstance();

  @override
  Future<String?> getAccessToken() async => (await _prefs).getString(_kAccess);

  @override
  Future<String?> getRefreshToken() async =>
      (await _prefs).getString(_kRefresh);

  @override
  Future<void> saveAccessToken(String token) async =>
      await (await _prefs).setString(_kAccess, token);

  @override
  Future<void> saveRefreshToken(String token) async =>
      await (await _prefs).setString(_kRefresh, token);

  @override
  Future<void> clear() async {
    final p = await _prefs;
    await p.remove(_kAccess);
    await p.remove(_kRefresh);
  }
}

/// AuthProvider manages authentication state and exposes login/logout/refresh
class AuthProvider with ChangeNotifier {
  User? currentUser;
  String? token;
  bool isAuthenticated = false;
  bool isLoading = false;
  String? errorMessage;

  // Broadcast stream to notify listeners about auth state changes (true=authenticated)
  final StreamController<bool> _authStateController = StreamController<bool>.broadcast();

  /// Stream of authentication state changes. Subscribe to react to login/logout.
  Stream<bool> get authStateChanges => _authStateController.stream;

  late final SharedPrefTokenStorage _storage;
  late final ApiService _api;

  AuthProvider() {
    _storage = SharedPrefTokenStorage();
    // Initialize ApiService with SharedPrefTokenStorage so both use same storage
    _api = ApiService.init(tokenStorage: _storage);
    _init();
  }

  Future<void> _init() async {
    await checkAuthStatus();
  }

  Future<void> login(String email, String password, String role) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final data = await _api.login(email, password, role); // data là payload
      final access = data['token'] ?? data['access_token'];

      if (access != null) {
        token = access.toString();
        // _api.setToken(token!); // quan trọng: set token cho header nếu cần
        await _storage.saveAccessToken(token!);
      }

      final me = await _api.me();
      currentUser = User.fromJson(me['data']);
      isAuthenticated = true;
      // notify any stream subscribers that auth is now true
      try {
        _authStateController.add(true);
      } catch (_) {}
      print('Login successful! Token: $token, User: ${currentUser?.fullName}');
    } on Exception catch (e) {
      // Network or unexpected
      errorMessage = 'Network error';
      isAuthenticated = false;
      if (kDebugMode) print('Login error: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _api.logout();
    } on ApiException catch (e) {
      // Even if server logout fails, we still clear local tokens
      if (kDebugMode) print('Logout API error: ${e.message}');
    } catch (e) {
      if (kDebugMode) print('Logout error: $e');
    } finally {
      await _storage.clear();
      token = null;
      currentUser = null;
      isAuthenticated = false;
      try {
        _authStateController.add(false);
      } catch (_) {}
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> checkAuthStatus() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final t = await _storage.getAccessToken();
      if (t == null || t.isEmpty) {
        isAuthenticated = false;
        token = null;
        currentUser = null;
        try {
          _authStateController.add(false);
        } catch (_) {}
      } else {
        token = t;
        isAuthenticated = true;
        // set token in ApiService via saving in storage (already same storage) and fetch me
        try {
            final me = await _api.me();
            final Map<String, dynamic> meData = me['data'] != null
              ? Map<String, dynamic>.from(me['data'])
              : Map<String, dynamic>.from(me);
            currentUser = User.fromJson(meData);
        } on ApiException catch (e) {
          // If unauthorized, try refresh
          if (e.statusCode == 401) {
            await refreshToken();
          } else {
            throw e;
          }
        }
      }
    } on ApiException catch (e) {
      errorMessage = e.message;
      isAuthenticated = false;
    } catch (e) {
      errorMessage = 'Network error';
      isAuthenticated = false;
      if (kDebugMode) print('checkAuthStatus error: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshToken() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final data = await _api.refresh();
      final access =
          data['access_token'] ?? data['token'] ?? data['accessToken'];
      if (access != null) {
        token = access.toString();
        await _storage.saveAccessToken(token!);
        isAuthenticated = true;
        // fetch me
        final me = await _api.me();
        final Map<String, dynamic> meData = me['data'] != null
          ? Map<String, dynamic>.from(me['data'])
          : Map<String, dynamic>.from(me);
        currentUser = User.fromJson(meData);
        try {
          _authStateController.add(true);
        } catch (_) {}
      } else {
        // refresh failed
        await _storage.clear();
        token = null;
        currentUser = null;
        isAuthenticated = false;
        errorMessage = 'Unable to refresh token';
      }
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        errorMessage = 'Session expired';
      } else if (e.statusCode != null && e.statusCode! >= 500) {
        errorMessage = 'Server error (${e.statusCode})';
      } else {
        errorMessage = e.message;
      }
      await _storage.clear();
      token = null;
      currentUser = null;
      isAuthenticated = false;
      try {
        _authStateController.add(false);
      } catch (_) {}
    } catch (e) {
      errorMessage = 'Network error';
      if (kDebugMode) print('refreshToken error: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    try {
      _authStateController.close();
    } catch (_) {}
    super.dispose();
  }
}
