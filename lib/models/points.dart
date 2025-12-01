class ActivityPointItem {
  final String activityTitle;
  final String roleName;
  final double pointsAwarded;
  final String pointType; // 'ren_luyen' or 'ctxh'
  final DateTime? activityDate;

  ActivityPointItem({
    required this.activityTitle,
    required this.roleName,
    required this.pointsAwarded,
    required this.pointType,
    this.activityDate,
  });

  factory ActivityPointItem.fromJson(Map<String, dynamic> json) {
    return ActivityPointItem(
      activityTitle: json['activity_title']?.toString() ?? '',
      roleName: json['role_name']?.toString() ?? '',
      pointsAwarded: (json['points_awarded'] is num) ? (json['points_awarded'] as num).toDouble() : double.tryParse(json['points_awarded']?.toString() ?? '') ?? 0.0,
      pointType: json['point_type']?.toString() ?? '',
      activityDate: json['activity_date'] != null ? DateTime.tryParse(json['activity_date'].toString()) : null,
    );
  }
}

class StudentPointsSummary {
  final int? studentId;
  final Map<String, dynamic>? filterInfo;
  final double totalTrainingPoints;
  final double totalSocialPoints;
  final List<ActivityPointItem> trainingActivities;
  final List<ActivityPointItem> socialActivities;

  StudentPointsSummary({
    this.studentId,
    this.filterInfo,
    required this.totalTrainingPoints,
    required this.totalSocialPoints,
    required this.trainingActivities,
    required this.socialActivities,
  });

  factory StudentPointsSummary.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    final summary = data['summary'] ?? {};

    List<ActivityPointItem> parseList(dynamic src) {
      if (src is! List) return [];
      return src.map<ActivityPointItem>((e) => ActivityPointItem.fromJson(e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e))).toList();
    }

    return StudentPointsSummary(
      studentId: data['student_info'] != null ? (data['student_info']['student_id'] is int ? data['student_info']['student_id'] as int : int.tryParse(data['student_info']['student_id'].toString())) : null,
      filterInfo: data['filter_info'] is Map<String, dynamic> ? Map<String, dynamic>.from(data['filter_info']) : null,
      totalTrainingPoints: (summary['total_training_points'] is num) ? (summary['total_training_points'] as num).toDouble() : double.tryParse(summary['total_training_points']?.toString() ?? '') ?? 0.0,
      totalSocialPoints: (summary['total_social_points'] is num) ? (summary['total_social_points'] as num).toDouble() : double.tryParse(summary['total_social_points']?.toString() ?? '') ?? 0.0,
      trainingActivities: parseList(data['training_activities'] ?? []),
      socialActivities: parseList(data['social_activities'] ?? []),
    );
  }
}
// ============================================
// THÊM MỚI - Models cho Class Points Summary
// ============================================

class StudentPointsItem {
  final int studentId;
  final String userCode;
  final String fullName;
  final double totalTrainingPoints;
  final double totalSocialPoints;

  StudentPointsItem({
    required this.studentId,
    required this.userCode,
    required this.fullName,
    required this.totalTrainingPoints,
    required this.totalSocialPoints,
  });

  factory StudentPointsItem.fromJson(Map<String, dynamic> json) {
    return StudentPointsItem(
      studentId: json['student_id'] is int 
          ? json['student_id'] 
          : int.tryParse(json['student_id']?.toString() ?? '0') ?? 0,
      userCode: json['user_code']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? '',
      totalTrainingPoints: (json['total_training_points'] is num) 
          ? (json['total_training_points'] as num).toDouble() 
          : double.tryParse(json['total_training_points']?.toString() ?? '') ?? 0.0,
      totalSocialPoints: (json['total_social_points'] is num) 
          ? (json['total_social_points'] as num).toDouble() 
          : double.tryParse(json['total_social_points']?.toString() ?? '') ?? 0.0,
    );
  }
}

class ClassPointsSummary {
  final String className;
  final Map<String, dynamic>? filterInfo;
  final int totalStudents;
  final List<StudentPointsItem> students;

  ClassPointsSummary({
    required this.className,
    this.filterInfo,
    required this.totalStudents,
    required this.students,
  });

  factory ClassPointsSummary.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    
    List<StudentPointsItem> parseStudents(dynamic src) {
      if (src is! List) return [];
      return src.map<StudentPointsItem>((e) => 
        StudentPointsItem.fromJson(
          e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e)
        )
      ).toList();
    }

    return ClassPointsSummary(
      className: data['class_name']?.toString() ?? '',
      filterInfo: data['filter_info'] is Map<String, dynamic> 
          ? Map<String, dynamic>.from(data['filter_info']) 
          : null,
      totalStudents: data['total_students'] is int 
          ? data['total_students'] 
          : int.tryParse(data['total_students']?.toString() ?? '0') ?? 0,
      students: parseStudents(data['students'] ?? []),
    );
  }
}