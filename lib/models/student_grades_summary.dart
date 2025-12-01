// lib/models/student_grades_summary.dart
// Model cho API /grades/student/{id}

class StudentGradeSummary {
  final StudentInfo studentInfo;
  final List<CourseGradeDetail> grades;
  final GradeSummary summary;

  StudentGradeSummary({
    required this.studentInfo,
    required this.grades,
    required this.summary,
  });

  factory StudentGradeSummary.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    
    return StudentGradeSummary(
      studentInfo: StudentInfo.fromJson(data['student_info'] ?? {}),
      grades: (data['grades'] as List?)
          ?.map((e) => CourseGradeDetail.fromJson(e))
          .toList() ?? [],
      summary: GradeSummary.fromJson(data['summary'] ?? {}),
    );
  }
}

class StudentInfo {
  final int studentId;
  final String userCode;
  final String fullName;
  final String className;

  StudentInfo({
    required this.studentId,
    required this.userCode,
    required this.fullName,
    required this.className,
  });

  factory StudentInfo.fromJson(Map<String, dynamic> json) {
    return StudentInfo(
      studentId: json['student_id'] ?? 0,
      userCode: json['user_code'] ?? '',
      fullName: json['full_name'] ?? '',
      className: json['class_name'] ?? '',
    );
  }
}

class CourseGradeDetail {
  final int gradeId;
  final String courseCode;
  final String courseName;
  final int credits;
  final String semester;
  final int semesterId;
  final double? grade10;
  final String? gradeLetter;
  final double? grade4;
  final String status; // passed/failed/studying

  CourseGradeDetail({
    required this.gradeId,
    required this.courseCode,
    required this.courseName,
    required this.credits,
    required this.semester,
    required this.semesterId,
    this.grade10,
    this.gradeLetter,
    this.grade4,
    required this.status,
  });

  factory CourseGradeDetail.fromJson(Map<String, dynamic> json) {
    return CourseGradeDetail(
      gradeId: json['grade_id'] ?? 0,
      courseCode: json['course_code'] ?? '',
      courseName: json['course_name'] ?? '',
      credits: json['credits'] ?? 0,
      semester: json['semester'] ?? '',
      semesterId: json['semester_id'] ?? 0,
      grade10: (json['grade_10'] as num?)?.toDouble(),
      gradeLetter: json['grade_letter'],
      grade4: (json['grade_4'] as num?)?.toDouble(),
      status: json['status'] ?? 'studying',
    );
  }
}

class GradeSummary {
  final int totalCourses;
  final int passedCourses;
  final int failedCourses;
  final int studyingCourses;

  GradeSummary({
    required this.totalCourses,
    required this.passedCourses,
    required this.failedCourses,
    required this.studyingCourses,
  });

  factory GradeSummary.fromJson(Map<String, dynamic> json) {
    return GradeSummary(
      totalCourses: json['total_courses'] ?? 0,
      passedCourses: json['passed_courses'] ?? 0,
      failedCourses: json['failed_courses'] ?? 0,
      studyingCourses: json['studying_courses'] ?? 0,
    );
  }
}

// ============================================
// SEMESTER REPORT DETAIL
// ============================================

class SemesterReportDetail {
  final SemesterReportData report;
  final StudentInfo student;
  final SemesterInfo semester;

  SemesterReportDetail({
    required this.report,
    required this.student,
    required this.semester,
  });

  factory SemesterReportDetail.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    
    return SemesterReportDetail(
      report: SemesterReportData.fromJson(data),
      student: StudentInfo.fromJson(data['student'] ?? {}),
      semester: SemesterInfo.fromJson(data['semester'] ?? {}),
    );
  }
}

class SemesterReportData {
  final int reportId;
  final int studentId;
  final int semesterId;
  final double? gpa;
  final double? gpa4Scale;
  final double? cpa10Scale;
  final double? cpa4Scale;
  final int creditsRegistered;
  final int creditsPassed;
  final int trainingPointSummary;
  final int socialPointSummary;
  final String? outcome;

  SemesterReportData({
    required this.reportId,
    required this.studentId,
    required this.semesterId,
    this.gpa,
    this.gpa4Scale,
    this.cpa10Scale,
    this.cpa4Scale,
    required this.creditsRegistered,
    required this.creditsPassed,
    required this.trainingPointSummary,
    required this.socialPointSummary,
    this.outcome,
  });

  factory SemesterReportData.fromJson(Map<String, dynamic> json) {
    return SemesterReportData(
      reportId: json['report_id'] ?? 0,
      studentId: json['student_id'] ?? 0,
      semesterId: json['semester_id'] ?? 0,
      gpa: (json['gpa'] as num?)?.toDouble(),
      gpa4Scale: (json['gpa_4_scale'] as num?)?.toDouble(),
      cpa10Scale: (json['cpa_10_scale'] as num?)?.toDouble(),
      cpa4Scale: (json['cpa_4_scale'] as num?)?.toDouble(),
      creditsRegistered: json['credits_registered'] ?? 0,
      creditsPassed: json['credits_passed'] ?? 0,
      trainingPointSummary: json['training_point_summary'] ?? 0,
      socialPointSummary: json['social_point_summary'] ?? 0,
      outcome: json['outcome'],
    );
  }
}

class SemesterInfo {
  final int semesterId;
  final String semesterName;
  final String academicYear;

  SemesterInfo({
    required this.semesterId,
    required this.semesterName,
    required this.academicYear,
  });

  factory SemesterInfo.fromJson(Map<String, dynamic> json) {
    return SemesterInfo(
      semesterId: json['semester_id'] ?? 0,
      semesterName: json['semester_name'] ?? '',
      academicYear: json['academic_year'] ?? '',
    );
  }
}

// ============================================
// POINT FEEDBACK MODELS (Khiếu nại điểm)
// ============================================

class PointFeedbackDetail {
  final int feedbackId;
  final int studentId;
  final int semesterId;
  final String feedbackContent;
  final String? attachmentPath;
  final String status; // pending/approved/rejected
  final String? advisorResponse;
  final int? advisorId;
  final DateTime? responseAt;
  final DateTime createdAt;
  final StudentInfo? student;
  final SemesterInfo? semester;
  final AdvisorInfo? advisor;

  PointFeedbackDetail({
    required this.feedbackId,
    required this.studentId,
    required this.semesterId,
    required this.feedbackContent,
    this.attachmentPath,
    required this.status,
    this.advisorResponse,
    this.advisorId,
    this.responseAt,
    required this.createdAt,
    this.student,
    this.semester,
    this.advisor,
  });

  factory PointFeedbackDetail.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    
    return PointFeedbackDetail(
      feedbackId: data['feedback_id'] ?? 0,
      studentId: data['student_id'] ?? 0,
      semesterId: data['semester_id'] ?? 0,
      feedbackContent: data['feedback_content'] ?? '',
      attachmentPath: data['attachment_path'],
      status: data['status'] ?? 'pending',
      advisorResponse: data['advisor_response'],
      advisorId: data['advisor_id'],
      responseAt: data['response_at'] != null 
          ? DateTime.tryParse(data['response_at']) 
          : null,
      createdAt: DateTime.tryParse(data['created_at'] ?? '') ?? DateTime.now(),
      student: data['student'] != null 
          ? StudentInfo.fromJson(data['student']) 
          : null,
      semester: data['semester'] != null 
          ? SemesterInfo.fromJson(data['semester']) 
          : null,
      advisor: data['advisor'] != null 
          ? AdvisorInfo.fromJson(data['advisor']) 
          : null,
    );
  }
}

class AdvisorInfo {
  final int advisorId;
  final String fullName;
  final String email;

  AdvisorInfo({
    required this.advisorId,
    required this.fullName,
    required this.email,
  });

  factory AdvisorInfo.fromJson(Map<String, dynamic> json) {
    return AdvisorInfo(
      advisorId: json['advisor_id'] ?? 0,
      fullName: json['full_name'] ?? '',
      email: json['email'] ?? '',
    );
  }
}