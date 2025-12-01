import '../services/api_service.dart';
import 'package:dio/dio.dart';
import 'dart:typed_data';
extension StudentGPATrendAPI on ApiService {
  
  /// ⭐ API MỚI CẦN TẠO - Xu hướng GPA qua các học kỳ
  Future<Map<String, dynamic>> getGPATrend({
    required int studentId,
    int limit = 8, // 8 học kỳ gần nhất
  }) async {
    return await get('/students/$studentId/gpa-trend', query: {
      'limit': limit,
    });
  }
}
extension AutoWarningAPI on ApiService {
  
  /// ⭐ API MỚI CẦN TẠO - Tự động phát hiện sinh viên nguy cơ
  Future<Map<String, dynamic>> autoDetectAtRiskStudents({
    required int classId,
    required int semesterId,
    required Map<String, dynamic> criteria,
  }) async {
    return await post('/academic/auto-detect-at-risk', {
      'class_id': classId,
      'semester_id': semesterId,
      'criteria': criteria,
    });
  }
}
extension PointExportAPI on ApiService {
  
  /// Export điểm rèn luyện theo lớp
  Future<Uint8List> exportTrainingPointsByClass({
    required int classId,
    required int semesterId,
  }) async {
    final resp = await this.dio.get(
      '/admin/export/training-points/class',
      queryParameters: {
        'class_id': classId,
        'semester_id': semesterId,
      },
      options: Options(responseType: ResponseType.bytes),
    );
    if (resp.data is Uint8List) return resp.data as Uint8List;
    return Uint8List(0);
  }
  
  /// Export điểm rèn luyện theo khoa
  Future<Uint8List> exportTrainingPointsByFaculty({
    required int semesterId,
  }) async {
    final resp = await this.dio.get(
      '/admin/export/training-points/faculty',
      queryParameters: {'semester_id': semesterId},
      options: Options(responseType: ResponseType.bytes),
    );
    if (resp.data is Uint8List) return resp.data as Uint8List;
    return Uint8List(0);
  }
  
  /// Export điểm CTXH theo lớp
  Future<Uint8List> exportSocialPointsByClass(int classId) async {
    final resp = await this.dio.get(
      '/admin/export/social-points/class',
      queryParameters: {'class_id': classId},
      options: Options(responseType: ResponseType.bytes),
    );
    if (resp.data is Uint8List) return resp.data as Uint8List;
    return Uint8List(0);
  }
  
  /// Export điểm CTXH theo khoa
  Future<Uint8List> exportSocialPointsByFaculty() async {
    final resp = await this.dio.get(
      '/admin/export/social-points/faculty',
      options: Options(responseType: ResponseType.bytes),
    );
    if (resp.data is Uint8List) return resp.data as Uint8List;
    return Uint8List(0);
  }
}