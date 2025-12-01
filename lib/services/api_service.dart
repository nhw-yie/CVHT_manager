import 'dart:async';
import 'package:dio/dio.dart';
import 'dart:io';
// removed explicit import of 'dart:typed_data' because `Uint8List` is available
// via `package:flutter/foundation.dart` in this project
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/error_handler.dart';

/// Token storage abstraction
abstract class TokenStorage {
  Future<String?> getAccessToken();
  Future<String?> getRefreshToken();
  Future<void> saveAccessToken(String token);
  Future<void> saveRefreshToken(String token);
  Future<void> clear();
}

/// FlutterSecureStorage implementation
class SecureTokenStorage implements TokenStorage {
  final FlutterSecureStorage _storage;
  final String _keyAccess = 'access_token';
  final String _keyRefresh = 'refresh_token';

  SecureTokenStorage([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  @override
  Future<String?> getAccessToken() => _storage.read(key: _keyAccess);

  @override
  Future<String?> getRefreshToken() => _storage.read(key: _keyRefresh);

  @override
  Future<void> saveAccessToken(String token) =>
      _storage.write(key: _keyAccess, value: token);

  @override
  Future<void> saveRefreshToken(String token) =>
      _storage.write(key: _keyRefresh, value: token);

  @override
  Future<void> clear() async {
    await _storage.delete(key: _keyAccess);
    await _storage.delete(key: _keyRefresh);
  }
}

/// Queued request holder
class QueuedRequest {
  final RequestOptions requestOptions;
  final Completer<Response<dynamic>> completer;

  QueuedRequest(this.requestOptions, this.completer);
}

/// ApiService with token refresh handling (Dio 5.x)
class ApiService {
  // Compute base URL at runtime so emulator/device differences are handled.
  // - Android emulator: 10.0.2.2 maps to host machine localhost
  // - Desktop/web: use 127.0.0.1
  static String get _baseUrl {
    // Allow compile-time override via `--dart-define=API_BASE_URL=...`
    const env = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (env.isNotEmpty) return env;
    // Keep Android emulator mapping, but default to 127.0.0.1:8000 for all other platforms.
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:8000/api';
    } catch (_) {}
    return 'http://172.17.114.190:8000/api'; // Default API base URL
  }

  static ApiService? _instance;

  /// Public access to the computed base URL for building full resource links
  static String get baseUrl => _baseUrl;

  final Dio _dio;
  final TokenStorage _tokenStorage;

  bool _isRefreshing = false;
  final List<QueuedRequest> _refreshQueue = [];

  ApiService._internal(this._tokenStorage)
    : _dio = Dio(
          BaseOptions(
            baseUrl: _baseUrl,
            // Increase default timeouts from 30s -> 60s to avoid aborting slow requests
            connectTimeout: const Duration(seconds: 60),
            receiveTimeout: const Duration(seconds: 60),
          // ❌ sendTimeout gây lỗi trên web
          // sendTimeout: const Duration(seconds: 30),
          responseType: ResponseType.json,
        ),
      ) {
    if (kDebugMode) debugPrint('ApiService initialized with baseUrl=$_baseUrl');
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokenStorage.getAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (err, handler) async {
          final status = err.response?.statusCode;

          // Nếu lỗi không có response → thường là CORS hoặc network error trên Web
          if (err.response == null) {
            return handler.reject(err);
          }

          // Chỉ xử lý refresh token khi 401 và không phải gọi refresh
          if (status == 401 && !_isRequestToRefresh(err.requestOptions)) {
            try {
              final response = await _handle401AndRefresh(err);
              handler.resolve(response);
              return;
            } catch (_) {
              return handler.reject(err);
            }
          }

          return handler.next(err);
        },
      ),
    );
  }

  static ApiService init({TokenStorage? tokenStorage}) {
    // If a specific TokenStorage is provided, prefer using it so callers
    // (e.g. AuthProvider with SharedPrefTokenStorage) share the same storage.
    if (_instance == null) {
      _instance = ApiService._internal(tokenStorage ?? SecureTokenStorage());
    } else if (tokenStorage != null && _instance!._tokenStorage != tokenStorage) {
      // Recreate the instance to bind to the requested storage.
      _instance = ApiService._internal(tokenStorage);
    }
    return _instance!;
  }

  static ApiService get instance {
    if (_instance == null) {
      throw StateError(
        'ApiService not initialized. Call ApiService.init() first.',
      );
    }
    return _instance!;
  }

  bool _isRequestToRefresh(RequestOptions options) =>
      options.path.contains('/auth/refresh');

  Future<Response<dynamic>> _handle401AndRefresh(DioException err) async {
    final requestOptions = err.requestOptions;

    if (_isRefreshing) {
      final completer = Completer<Response<dynamic>>();
      _refreshQueue.add(QueuedRequest(requestOptions, completer));
      return completer.future;
    }

    _isRefreshing = true;

    try {
      final success = await _refreshToken();
      if (!success) {
        await _tokenStorage.clear();
        _completeQueueWithError(
          ApiException('Unable to refresh token', statusCode: 401),
        );
        throw ApiException('Unable to refresh token', statusCode: 401);
      }

      final newToken = await _tokenStorage.getAccessToken();
      if (newToken != null && newToken.isNotEmpty) {
        requestOptions.headers['Authorization'] = 'Bearer $newToken';
      }

      final response = await _dio.fetch(requestOptions);

      _completeQueueWithResponse(newToken);
      return response;
    } catch (e) {
      _completeQueueWithError(e);
      rethrow;
    } finally {
      _isRefreshing = false;
    }
  }

  void _completeQueueWithResponse(String? token) {
    for (final q in _refreshQueue) {
      if (token != null && token.isNotEmpty) {
        q.requestOptions.headers['Authorization'] = 'Bearer $token';
      }
      _dio
          .fetch(q.requestOptions)
          .then((resp) => q.completer.complete(resp))
          .catchError((e) => q.completer.completeError(e));
    }
    _refreshQueue.clear();
  }

  void _completeQueueWithError(Object error) {
    for (final q in _refreshQueue) {
      q.completer.completeError(error);
    }
    _refreshQueue.clear();
  }

  Future<bool> _refreshToken() async {
    final refresh = await _tokenStorage.getRefreshToken();
    if (refresh == null || refresh.isEmpty) return false;

    try {
      final resp = await Dio(
        BaseOptions(baseUrl: _baseUrl),
      ).post('/auth/refresh', data: {'refresh_token': refresh});
      final data = resp.data;

      if (data == null) return false;

      final access =
          data['access_token'] ?? data['token'] ?? data['accessToken'];
      final refreshToken = data['refresh_token'] ?? data['refreshToken'];

      if (access != null)
        await _tokenStorage.saveAccessToken(access.toString());
      if (refreshToken != null)
        await _tokenStorage.saveRefreshToken(refreshToken.toString());

      return access != null;
    } catch (_) {
      return false;
    }
  }

  // ---------- Auth endpoints ----------
  Future<Map<String, dynamic>> login(
    String email,
    String password,
    String role,
  ) async {
    try {
      final resp = await _dio.post(
        '/auth/login',
        data: {'user_code': email, 'password': password, "role": role},
      );
      final data = _parseData(resp);

      final payload = data['data'] ?? {}; // token nằm trong data
      final accessToken =
          payload['access_token'] ?? payload['token'] ?? payload['accessToken'];
      final refreshToken = payload['refresh_token'] ?? payload['refreshToken'];

      // save tokens if provided
      if (accessToken != null) {
        await _tokenStorage.saveAccessToken(accessToken.toString());
      }
      if (refreshToken != null) {
        await _tokenStorage.saveRefreshToken(refreshToken.toString());
      }

      return payload; // trả về data bên trong
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> getNotificationDetail(String id) async {
    try {
      final resp = await _dio.get('/notifications/$id'); // dùng _dio.get
      return _parseData(resp); // hoặc resp.data nếu bạn không dùng _parseData
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } on DioException catch (e) {
      // even if logout fails, clear local tokens
      await _tokenStorage.clear();
      throw _handleDioError(e);
    }
    await _tokenStorage.clear();
  }

  Future<Map<String, dynamic>> me() async {
    try {
      final resp = await _dio.get('/auth/me');
      return _parseData(resp);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> refresh() async {
    try {
      final resp = await _dio.post('/auth/refresh');
      final data = _parseData(resp);
      if (data['access_token'] != null) {
        await _tokenStorage.saveAccessToken(data['access_token'].toString());
      }
      if (data['refresh_token'] != null) {
        await _tokenStorage.saveRefreshToken(data['refresh_token'].toString());
      }
      return data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // ---------- Notifications ----------
  /// Get notifications with optional extra query parameters (search, filters)
  Future<Map<String, dynamic>> getNotifications({
    int page = 1,
    int perPage = 20,
    Map<String, dynamic>? params,
  }) async {
    try {
      final qp = <String, dynamic>{'page': page, 'per_page': perPage};
      if (params != null) qp.addAll(params);
      final resp = await _dio.get('/notifications', queryParameters: qp);
      return _parseData(resp);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Best-effort single notification mark-as-read endpoint. If your API uses a different route,
  /// adjust this method accordingly.
  Future<void> markNotificationRead(String id) async {
    try {
      await _dio.post('/notifications/$id/read');
    } on DioException catch (e) {
      // don't throw — caller may want to ignore failures
      throw _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> getNotificationById(String id) async {
    try {
      final resp = await _dio.get('/notifications/$id');
      if (resp != null) {
        // Debug: print status and body to help diagnose failures when tapping
        try {
          // Only log in debug mode
          if (kDebugMode) {
            if (resp.statusCode != null) debugPrint('API GET /notifications/$id status=${resp.statusCode}');
            if (resp.data != null) debugPrint('API GET /notifications/$id body=${resp.data}');
          }
        } catch (_) {}
      }
      return _parseData(resp);
    } on DioException catch (e) {
      // Debug info for failed request
      try {
        if (kDebugMode) debugPrint('Notification detail request failed for id=$id: status=${e.response?.statusCode}, data=${e.response?.data}');
      } catch (_) {}
      throw _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> createNotification(
    Map<String, dynamic> payload,
  ) async {
    try {
      final resp = await _dio.post('/notifications', data: payload);
      return _parseData(resp);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Update an existing notification (Advisor only)
  Future<Map<String, dynamic>> updateNotification(
    String id,
    Map<String, dynamic> payload,
  ) async {
    try {
      final resp = await _dio.put('/notifications/$id', data: payload);
      return _parseData(resp);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Delete a notification (Advisor only)
  Future<void> deleteNotification(String id) async {
    try {
      await _dio.delete('/notifications/$id');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Get notification statistics (Advisor only)
  Future<Map<String, dynamic>> getNotificationStatistics() async {
    try {
      final resp = await _dio.get('/notifications/notification-statistics');
      return _parseData(resp);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> respondToNotification(
    String id,
    Map<String, dynamic> payload,
  ) async {
    try {
      final resp = await _dio.post(
        '/notifications/$id/responses',
        data: payload,
      );
      return _parseData(resp);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Get all responses for a notification (Advisor only)
  Future<Map<String, dynamic>> getNotificationResponses(
    String notificationId,
  ) async {
    try {
      final resp = await _dio.get('/notifications/$notificationId/responses');
      return _parseData(resp);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Update a specific notification response (Advisor only)
  Future<Map<String, dynamic>> updateNotificationResponse(
    String responseId,
    Map<String, dynamic> payload,
  ) async {
    try {
      final resp = await _dio.put(
        '/notification-responses/$responseId',
        data: payload,
      );
      return _parseData(resp);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> getStudentUnreadNotifications() async {
    try {
      final resp = await _dio.get('/student/unread-notifications');
      return _parseData(resp);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> markAllStudentNotificationsRead() async {
    try {
      final resp = await _dio.post('/student/mark-all-notifications-read');
      return _parseData(resp);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // ---------- Activities ----------
  Future<Map<String, dynamic>> getActivities({
    Map<String, dynamic>? query,
  }) async {
    try {
      final resp = await _dio.get('/activities', queryParameters: query);
      return _parseData(resp);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> getActivityById(String id) async {
    try {
      final resp = await _dio.get('/activities/$id');
      return _parseData(resp);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Create a new activity (Advisor)
  Future<Map<String, dynamic>> createActivity(Map<String, dynamic> payload) async {
    try {
      final resp = await _dio.post('/activities', data: payload);
      return _parseData(resp);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Update an existing activity (Advisor)
  Future<Map<String, dynamic>> updateActivity(String id, Map<String, dynamic> payload) async {
    try {
      final resp = await _dio.put('/activities/$id', data: payload);
      return _parseData(resp);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Delete an activity (Advisor)
  Future<void> deleteActivity(String id) async {
    try {
      await _dio.delete('/activities/$id');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Assign students to an activity (Advisor endpoint)
  /// Body: { "assignments": [ { "student_id": 1, "activity_role_id": 2 }, ... ] }
  Future<Map<String, dynamic>> assignStudentsToActivity(int activityId, List<Map<String, dynamic>> assignments) async {
    try {
      final resp = await _dio.post('/advisor/activities/$activityId/assign-students', data: {
        'assignments': assignments,
      });
      return _parseData(resp);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Lấy danh sách registrations cho activity (advisor only)
  /// Response shape theo docs: { data: { activity, summary, registrations: [...] } }
  Future<Map<String, dynamic>> getActivityRegistrations(int activityId) async {
    try {
      final resp = await _dio.get('/activities/$activityId/registrations');
      return _parseData(resp);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> registerActivity(
    Map<String, dynamic> payload,
  ) async {
    try {
      final resp = await _dio.post(
        '/activity-registrations/register',
        data: payload,
      );
      return _parseData(resp);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> myRegistrations() async {
    try {
      final resp = await _dio.get('/activity-registrations/my-registrations');
      return _parseData(resp);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> cancelRegistration(
    Map<String, dynamic> payload,
  ) async {
    try {
      final resp = await _dio.post(
        '/activity-registrations/cancel',
        data: payload,
      );
      return _parseData(resp);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Export registrations for an activity as an Excel file (.xlsx)
  Future<Uint8List> exportRegistrations(int activityId) async {
    try {
      final resp = await _dio.get(
        '/activities/$activityId/export-registrations',
        options: Options(responseType: ResponseType.bytes),
      );
      if (resp.data is Uint8List) return resp.data as Uint8List;
      if (resp.data is List<int>) return Uint8List.fromList(List<int>.from(resp.data as List));
      return Uint8List(0);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Export an attendance template (Excel) for an activity
  Future<Uint8List> exportAttendanceTemplate(int activityId) async {
    try {
      final resp = await _dio.get(
        '/activities/$activityId/export-attendance-template',
        options: Options(responseType: ResponseType.bytes),
      );
      if (resp.data is Uint8List) return resp.data as Uint8List;
      if (resp.data is List<int>) return Uint8List.fromList(List<int>.from(resp.data as List));
      return Uint8List(0);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Import attendance file for an activity. `file` should be an .xlsx/.xls file.
  Future<Map<String, dynamic>> importAttendance(int activityId, File file) async {
    try {
      final fileName = file.path.split(Platform.pathSeparator).last;
      final form = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: fileName),
      });
      final resp = await _dio.post('/activities/$activityId/import-attendance', data: form);
      return _parseData(resp);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Get attendance statistics for an activity
  Future<Map<String, dynamic>> getAttendanceStatistics(int activityId) async {
    try {
      final resp = await _dio.get('/activities/$activityId/attendance-statistics');
      return _parseData(resp);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // ---------- Points ----------
Future<Map<String, dynamic>> getStudentPoints({
  int? studentId,      // Bắt buộc nếu role = advisor
  int? semesterId,     // Filter theo kỳ học (optional)
}) async {
  try {
    final qp = <String, dynamic>{};
    if (studentId != null) qp['student_id'] = studentId;
    if (semesterId != null) qp['semester_id'] = semesterId;
    
    final resp = await _dio.get('/student-points', queryParameters: qp);
    return _parseData(resp);
  } on DioException catch (e) {
    throw _handleDioError(e);
  }
}

/// Lấy tổng hợp điểm cả lớp (Advisor only)
Future<Map<String, dynamic>> getClassPointsSummary({
  required int classId,
  int? semesterId,     // Filter theo kỳ học (optional)
}) async {
  try {
    final qp = <String, dynamic>{'class_id': classId};
    if (semesterId != null) qp['semester_id'] = semesterId;
    
    final resp = await _dio.get('/student-points/class-summary', queryParameters: qp);
    return _parseData(resp);
  } on DioException catch (e) {
    throw _handleDioError(e);
  }
}

  /// Get students list. Supports pagination and search.
  /// Example: GET /students?page=1&per_page=50&q=keyword
  Future<Map<String, dynamic>> getStudents({
    int page = 1,
    int perPage = 50,
    String? q,
    int? classId,
  }) async {
    try {
      final qp = <String, dynamic>{'page': page, 'per_page': perPage};
      if (q != null && q.isNotEmpty) qp['q'] = q;
      if (classId != null) qp['class_id'] = classId;
      final resp = await _dio.get('/students', queryParameters: qp);
      return _parseData(resp);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // ---------- Classes / Units ----------
  /// Get classes list (supports pagination)
  Future<Map<String, dynamic>> getClasses({
    int page = 1,
    int perPage = 50,
    Map<String, dynamic>? params,
  }) async {
    try {
      final qp = <String, dynamic>{'page': page, 'per_page': perPage};
      if (params != null) qp.addAll(params);
      final resp = await _dio.get('/classes', queryParameters: qp);
      return _parseData(resp);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> getClassDetail(int classId) async {
    try {
      final resp = await _dio.get('/classes/$classId');
      return _parseData(resp);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Get students by class
  Future<Map<String, dynamic>> getStudentsByClass(int classId, {int page = 1, int perPage = 50}) async {
    try {
      final resp = await _dio.get('/classes/$classId/students', queryParameters: {'page': page, 'per_page': perPage});
      return _parseData(resp);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Create class (admin)
  Future<Map<String, dynamic>> createClass(Map<String, dynamic> payload) async {
    try {
      final resp = await _dio.post('/classes', data: payload);
      return _parseData(resp);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Update class
  Future<Map<String, dynamic>> updateClass(int classId, Map<String, dynamic> payload) async {
    try {
      final resp = await _dio.put('/classes/$classId', data: payload);
      return _parseData(resp);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Delete class
  Future<void> deleteClass(int classId) async {
    try {
      await _dio.delete('/classes/$classId');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Get student details by id
  Future<Map<String, dynamic>> getStudentById(int id) async {
    try {
      final resp = await _dio.get('/students/$id');
      print(resp.data);
      return _parseData(resp);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Create a new student (Admin)
  Future<Map<String, dynamic>> createStudent(Map<String, dynamic> payload) async {
    try {
      final resp = await _dio.post('/students', data: payload);
      return _parseData(resp);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Update student information
  Future<Map<String, dynamic>> updateStudent(String id, Map<String, dynamic> payload) async {
    try {
      final resp = await _dio.put('/students/$id', data: payload);
      return _parseData(resp);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Delete student (Admin)
  Future<void> deleteStudent(String id) async {
    try {
      await _dio.delete('/students/$id');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Change password for student (student role)
  Future<Map<String, dynamic>> changeStudentPassword(Map<String, dynamic> payload) async {
    try {
      final resp = await _dio.post('/students/change-password', data: payload);
      return _parseData(resp);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Get class positions (GET /classes/{classId}/positions)
  Future<Map<String, dynamic>> getClassPositions(int classId) async {
    try {
      final resp = await _dio.get('/classes/$classId/positions');
      return _parseData(resp);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Get available students for assignment to an activity (advisor endpoint)
  /// Supports filtering/search/sorting via query parameters.
  Future<Map<String, dynamic>> getAvailableStudents(
    int activityId, {
    int page = 1,
    int perPage = 50,
    String? search,
    int? classId,
    int? minTrainingPoint,
    int? maxTrainingPoint,
    int? minSocialPoint,
    int? maxSocialPoint,
    String? sortBy,
  }) async {
    try {
      final qp = <String, dynamic>{'page': page, 'per_page': perPage};
      if (search != null && search.isNotEmpty) qp['search'] = search;
      if (classId != null) qp['class_id'] = classId;
      if (minTrainingPoint != null) qp['training_point_min'] = minTrainingPoint;
      if (maxTrainingPoint != null) qp['training_point_max'] = maxTrainingPoint;
      if (minSocialPoint != null) qp['social_point_min'] = minSocialPoint;
      if (maxSocialPoint != null) qp['social_point_max'] = maxSocialPoint;
      if (sortBy != null && sortBy.isNotEmpty) qp['sort_by'] = sortBy;

      final resp = await _dio.get('/activities/$activityId/available-students', queryParameters: qp);
      return _parseData(resp);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // ---------- Messages ----------
  Future<Map<String, dynamic>> getMessages({
    Map<String, dynamic>? query,
  }) async {
    try {
      final resp = await _dio.get('/messages', queryParameters: query);
      return _parseData(resp);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> getMessagesWithUser(String userId) async {
    try {
      final resp = await _dio.get('/messages/$userId');
      return _parseData(resp);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> sendMessage(Map<String, dynamic> payload) async {
    try {
      final resp = await _dio.post('/messages', data: payload);
      return _parseData(resp);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> markMessageRead(String id) async {
    try {
      final resp = await _dio.put('/messages/$id/read');
      return _parseData(resp);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // ---------- Helpers ----------
  Map<String, dynamic> _parseData(Response<dynamic> resp) {
    if (resp.data is Map<String, dynamic>)
      return resp.data as Map<String, dynamic>;
    return {'data': resp.data};
  }

  /// Public accessor for Dio client for advanced use-cases (file downloads/uploads).
  /// Prefer using the high-level helpers (`get`, `post`, `put`, `delete`) when possible.
  Dio get dio => _dio;

  /// Public wrapper around internal response parser for extensions that need the parsed Map.
  Map<String, dynamic> parseResponse(Response<dynamic> resp) => _parseData(resp);

  ApiException _handleDioError(DioException e) {
    final status = e.response?.statusCode;
    String message = 'Unknown error';
    try {
      final d = e.response?.data;
      // Common web/network errors (XMLHttpRequest onError) are surfaced as DioException with no response.
      final lowMsg = (e.message ?? '').toString().toLowerCase();
      final errStr = (e.error ?? '').toString().toLowerCase();
      if (lowMsg.contains('xmlhttprequest') || errStr.contains('xmlhttprequest') || lowMsg.contains('onerror')) {
        message = 'Lỗi mạng hoặc CORS: không thể kết nối tới API từ trình duyệt. Kiểm tra backend đang chạy và cấu hình CORS.';
        return ApiException(message, statusCode: status);
      }

      if (d is Map && d['message'] != null)
        message = d['message'].toString();
      else if (e.message != null)
        message = e.message!;
    } catch (_) {}
    // try to extract validation errors
    Map<String, dynamic>? errors;
    try {
      final d = e.response?.data;
      if (d is Map && d['errors'] is Map)
        errors = Map<String, dynamic>.from(d['errors']);
    } catch (_) {}
    return ApiException(message, statusCode: status, errors: errors);
  }

  // Generic helpers (convenience wrappers) so callers can use _api.get/post/put/delete
  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? query}) async {
    try {
      final resp = await _dio.get(path, queryParameters: query);
      return _parseData(resp);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic>? data) async {
    try {
      final resp = await _dio.post(path, data: data);
      return _parseData(resp);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> put(String path, Map<String, dynamic>? data) async {
    try {
      final resp = await _dio.put(path, data: data);
      return _parseData(resp);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> delete(String path) async {
    try {
      await _dio.delete(path);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> getConversations() async {
  try {
    final resp = await _dio.get('/dialogs/conversations');
    return _parseData(resp);
  } on DioException catch (e) {
    throw _handleDioError(e);
  }
}

/// Get messages in a conversation with a specific partner
/// - Student: partner_id = advisor_id
/// - Advisor: partner_id = student_id
/// AUTO marks messages as read from partner
Future<Map<String, dynamic>> getDialogMessages({
  required int partnerId,
}) async {
  try {
    final resp = await _dio.get(
      '/dialogs/messages',
      queryParameters: {'partner_id': partnerId},
    );
    return _parseData(resp);
  } on DioException catch (e) {
    throw _handleDioError(e);
  }
}

/// Send a message to partner
/// - Student: partner_id = advisor_id
/// - Advisor: partner_id = student_id
Future<Map<String, dynamic>> sendDialogMessage({
  required int partnerId,
  required String content,
  String? attachmentPath,
}) async {
  try {
    final resp = await _dio.post(
      '/dialogs/messages',
      data: {
        'partner_id': partnerId,
        'content': content,
        if (attachmentPath != null) 'attachment_path': attachmentPath,
      },
    );
    return _parseData(resp);
  } on DioException catch (e) {
    throw _handleDioError(e);
  }
}

/// Mark a specific message as read (usually not needed, getMessages auto-marks)
Future<void> markDialogMessageRead(int messageId) async {
  try {
    await _dio.put('/dialogs/messages/$messageId/read');
  } on DioException catch (e) {
    throw _handleDioError(e);
  }
}

/// Delete a message (only sender can delete)
Future<void> deleteDialogMessage(int messageId) async {
  try {
    await _dio.delete('/dialogs/messages/$messageId');
  } on DioException catch (e) {
    throw _handleDioError(e);
  }
}

/// Get unread message count
Future<Map<String, dynamic>> getUnreadMessageCount() async {
  try {
    final resp = await _dio.get('/dialogs/unread-count');
    return _parseData(resp);
  } on DioException catch (e) {
    throw _handleDioError(e);
  }
}

/// Search messages in a conversation
Future<Map<String, dynamic>> searchDialogMessages({
  required int partnerId,
  required String keyword,
}) async {
  try {
    final resp = await _dio.get(
      '/dialogs/messages/search',
      queryParameters: {
        'partner_id': partnerId,
        'keyword': keyword,
      },
    );
    return _parseData(resp);
  } on DioException catch (e) {
    throw _handleDioError(e);
  }
}
}
