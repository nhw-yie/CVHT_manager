import '../services/api_service.dart';
extension StudentAttendanceAPI on ApiService {
  
  /// ⭐ API MỚI CẦN TẠO - Thống kê chuyên cần của sinh viên
  /// Backend cần implement endpoint này
  Future<Map<String, dynamic>> getStudentAttendanceSummary({
    required int studentId,
    int? semesterId,
    String? fromDate,
    String? toDate,
  }) async {
    final qp = <String, dynamic>{};
    if (semesterId != null) qp['semester_id'] = semesterId;
    if (fromDate != null) qp['from_date'] = fromDate;
    if (toDate != null) qp['to_date'] = toDate;
    
    return await get('/students/$studentId/attendance-summary', query: qp);
  }
  
  /// ⭐ API MỚI - Xu hướng chuyên cần theo tháng
  Future<Map<String, dynamic>> getStudentAttendanceTrend({
    required int studentId,
    int? semesterId,
  }) async {
    final qp = <String, dynamic>{};
    if (semesterId != null) qp['semester_id'] = semesterId;
    
    return await get('/students/$studentId/attendance-trend', query: qp);
  }
}