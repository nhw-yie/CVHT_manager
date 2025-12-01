// lib/providers/enhanced_points_provider.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../utils/error_handler.dart';
import '../services/grades_api_extensions.dart';
import '../models/points.dart';
import '../models/student_grades_summary.dart';
import '../models/semester.dart';
// Import các models mới từ artifact trước

class EnhancedPointsProvider with ChangeNotifier {
  final ApiService _api = ApiService.instance;

  // Loading states
  bool isLoadingPoints = false;
  bool isLoadingGrades = false;
  bool isLoadingSemesters = false;
  bool isLoadingReport = false;
  bool isLoadingFeedbacks = false;
  
  String? error;

  // ============================================
  // DATA STORES
  // ============================================
  
  // Điểm rèn luyện/CTXH
  StudentPointsSummary? _pointsSummary;
  StudentPointsSummary? get pointsSummary => _pointsSummary;

  // Điểm học tập
  StudentGradeSummary? _gradesSummary;
  StudentGradeSummary? get gradesSummary => _gradesSummary;

  // Báo cáo học kỳ
  SemesterReportDetail? _semesterReport;
  SemesterReportDetail? get semesterReport => _semesterReport;

  // Danh sách học kỳ
  List<Semester> _semesters = [];
  List<Semester> get semesters => _semesters;

  // Học kỳ hiện tại
  Semester? _currentSemester;
  Semester? get currentSemester => _currentSemester;

  // Học kỳ đang được chọn (filter)
  int? _selectedSemesterId;
  int? get selectedSemesterId => _selectedSemesterId;

  // Point Feedbacks (khiếu nại)
  List<PointFeedbackDetail> _feedbacks = [];
  List<PointFeedbackDetail> get feedbacks => _feedbacks;

  // ============================================
  // 1. HỌC KỲ MANAGEMENT
  // ============================================

  /// Lấy danh sách tất cả học kỳ
  Future<void> fetchSemesters() async {
    isLoadingSemesters = true;
    error = null;
    notifyListeners();

    try {
      final resp = await _api.getSemesters();
      final data = resp['data'] ?? [];
      _semesters = (data as List).map((e) => Semester.fromJson(e)).toList();
      
      // Auto-select current semester
      if (_selectedSemesterId == null && _currentSemester != null) {
        _selectedSemesterId = _currentSemester!.semesterId;
      }
    } catch (e) {
      error = ErrorHandler.mapToMessage(e);
      _semesters = [];
    } finally {
      isLoadingSemesters = false;
      notifyListeners();
    }
  }

  /// Lấy học kỳ hiện tại
  Future<void> fetchCurrentSemester() async {
    try {
      final resp = await _api.getCurrentSemester();
      final data = resp['data'] ?? resp;
      _currentSemester = Semester.fromJson(data);
      
      // Auto-select current semester if none selected
      if (_selectedSemesterId == null) {
        _selectedSemesterId = _currentSemester!.semesterId;
      }
      
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('Error fetching current semester: $e');
    }
  }

  /// Đổi học kỳ đang xem
  void setSelectedSemester(int? semesterId) {
    _selectedSemesterId = semesterId;
    notifyListeners();
    
    // Auto reload data for new semester
    if (semesterId != null) {
      fetchAllDataForSemester(semesterId);
    }
  }

  /// Load tất cả dữ liệu cho một học kỳ
  Future<void> fetchAllDataForSemester(int semesterId) async {
    await Future.wait([
      fetchPointsForSemester(semesterId),
      fetchGradesForSemester(semesterId),
      fetchSemesterReport(semesterId),
    ]);
  }

  // ============================================
  // 2. ĐIỂM RÈN LUYỆN / CTXH
  // ============================================

  /// Lấy điểm rèn luyện/CTXH (tất cả hoặc theo học kỳ)
  Future<void> fetchPoints({int? semesterId}) async {
    isLoadingPoints = true;
    error = null;
    notifyListeners();

    try {
      final resp = await _api.getStudentPoints(semesterId: semesterId);
      _pointsSummary = StudentPointsSummary.fromJson(resp);
    } catch (e) {
      error = ErrorHandler.mapToMessage(e);
      _pointsSummary = null;
    } finally {
      isLoadingPoints = false;
      notifyListeners();
    }
  }

  /// Lấy điểm rèn luyện cho học kỳ cụ thể
  Future<void> fetchPointsForSemester(int semesterId) async {
    await fetchPoints(semesterId: semesterId);
  }

  // ============================================
  // 3. ĐIỂM HỌC TẬP (GRADES)
  // ============================================

  /// Lấy điểm các môn học (tất cả hoặc theo học kỳ)
  Future<void> fetchGrades({int? semesterId}) async {
    isLoadingGrades = true;
    error = null;
    notifyListeners();

    try {
      final resp = await _api.getMyGrades(semesterId: semesterId);
      _gradesSummary = StudentGradeSummary.fromJson(resp);
    } catch (e) {
      error = ErrorHandler.mapToMessage(e);
      _gradesSummary = null;
    } finally {
      isLoadingGrades = false;
      notifyListeners();
    }
  }

  /// Lấy điểm học tập cho học kỳ cụ thể
  Future<void> fetchGradesForSemester(int semesterId) async {
    await fetchGrades(semesterId: semesterId);
  }

  // ============================================
  // 4. BÁO CÁO HỌC KỲ
  // ============================================

  /// Lấy báo cáo tổng hợp học kỳ (GPA, CPA, outcome...)
  Future<void> fetchSemesterReport(int semesterId) async {
    isLoadingReport = true;
    error = null;
    notifyListeners();

    try {
      // Use API extension which handles student vs advisor endpoints
      final resp = await _api.getSemesterReport(semesterId: semesterId);
      _semesterReport = SemesterReportDetail.fromJson(resp);
    } catch (e) {
      error = ErrorHandler.mapToMessage(e);
      _semesterReport = null;
    } finally {
      isLoadingReport = false;
      notifyListeners();
    }
  }

  // ============================================
  // 5. POINT FEEDBACKS (KHIẾU NẠI ĐIỂM)
  // ============================================

  /// Lấy danh sách khiếu nại của sinh viên
  Future<void> fetchPointFeedbacks({int? semesterId}) async {
    isLoadingFeedbacks = true;
    error = null;
    notifyListeners();

    try {
      final resp = await _api.getPointFeedbacks(semesterId: semesterId);
      final data = resp['data'] ?? [];
      _feedbacks = (data as List).map((e) => PointFeedbackDetail.fromJson(e)).toList();
    } catch (e) {
      error = ErrorHandler.mapToMessage(e);
      _feedbacks = [];
    } finally {
      isLoadingFeedbacks = false;
      notifyListeners();
    }
  }

  /// Tạo khiếu nại mới
  Future<bool> createPointFeedback({
    required int semesterId,
    required String content,
    File? attachmentFile,
  }) async {
    try {
      final payload = <String, dynamic>{
        'semester_id': semesterId,
        'feedback_content': content,
      };

      // TODO: Handle file upload if needed
      // Có thể cần upload file trước rồi lấy path

      await _api.post('/point-feedbacks', payload);
      
      // Reload feedbacks
      await fetchPointFeedbacks(semesterId: semesterId);
      
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Cập nhật khiếu nại (chỉ khi status = pending)
  Future<bool> updatePointFeedback({
    required int feedbackId,
    required String content,
    File? attachmentFile,
  }) async {
    try {
      final payload = <String, dynamic>{
        'feedback_content': content,
      };

      await _api.put('/point-feedbacks/$feedbackId', payload);
      
      // Reload feedbacks
      await fetchPointFeedbacks();
      
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Xóa khiếu nại
  Future<bool> deletePointFeedback(int feedbackId) async {
    try {
      await _api.delete('/point-feedbacks/$feedbackId');
      
      // Reload feedbacks
      await fetchPointFeedbacks();
      
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ============================================
  // 6. HELPER METHODS
  // ============================================

  /// Lấy hoạt động đã tham gia trong học kỳ
  List<ActivityPointItem> getActivitiesForSemester(int semesterId) {
    if (_pointsSummary == null) return [];
    
    // Lọc activities theo semester từ filterInfo
    // Hoặc filter từ activityDate nếu API trả về
    
    return [
      ..._pointsSummary!.trainingActivities,
      ..._pointsSummary!.socialActivities,
    ];
  }

  /// Tính tổng điểm học kỳ
  double getTotalSemesterGPA() {
    return _semesterReport?.report.gpa ?? 0.0;
  }

  /// Tính CPA (điểm tích lũy)
  double getCumulativeGPA() {
    return _semesterReport?.report.cpa10Scale ?? 0.0;
  }

  /// Kiểm tra có đạt yêu cầu không
  bool isEligibleForScholarship() {
    final report = _semesterReport?.report;
    if (report == null) return false;
    
    // Ví dụ: GPA >= 3.2 và training points >= 80
    return (report.gpa4Scale ?? 0) >= 3.2 && 
           report.trainingPointSummary >= 80;
  }

  /// Get classification (Xuất sắc/Giỏi/Khá...)
  String getClassification() {
    final trainingPoints = _pointsSummary?.totalTrainingPoints ?? 0;
    
    if (trainingPoints >= 90) return 'Xuất sắc';
    if (trainingPoints >= 80) return 'Giỏi';
    if (trainingPoints >= 65) return 'Khá';
    if (trainingPoints >= 50) return 'Trung bình';
    return 'Yếu';
  }

  // ============================================
  // CLEAR & RESET
  // ============================================

  void clear() {
    _pointsSummary = null;
    _gradesSummary = null;
    _semesterReport = null;
    _feedbacks = [];
    error = null;
    notifyListeners();
  }

  void clearError() {
    error = null;
    notifyListeners();
  }
}