// lib/models/semester_report.dart
// Model cho Semester_Reports table

class SemesterReport {
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

  SemesterReport({
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

  factory SemesterReport.fromJson(Map<String, dynamic> json) {
    int? parseInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      return int.tryParse(v.toString());
    }

    double? parseDouble(dynamic v) {
      if (v == null) return null;
      if (v is double) return v;
      if (v is int) return v.toDouble();
      return double.tryParse(v.toString());
    }

    return SemesterReport(
      reportId: parseInt(json['report_id']) ?? 0,
      studentId: parseInt(json['student_id']) ?? 0,
      semesterId: parseInt(json['semester_id']) ?? 0,
      gpa: parseDouble(json['gpa']),
      gpa4Scale: parseDouble(json['gpa_4_scale']),
      cpa10Scale: parseDouble(json['cpa_10_scale']),
      cpa4Scale: parseDouble(json['cpa_4_scale']),
      creditsRegistered: parseInt(json['credits_registered']) ?? 0,
      creditsPassed: parseInt(json['credits_passed']) ?? 0,
      trainingPointSummary: parseInt(json['training_point_summary']) ?? 0,
      socialPointSummary: parseInt(json['social_point_summary']) ?? 0,
      outcome: json['outcome']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'report_id': reportId,
      'student_id': studentId,
      'semester_id': semesterId,
      'gpa': gpa,
      'gpa_4_scale': gpa4Scale,
      'cpa_10_scale': cpa10Scale,
      'cpa_4_scale': cpa4Scale,
      'credits_registered': creditsRegistered,
      'credits_passed': creditsPassed,
      'training_point_summary': trainingPointSummary,
      'social_point_summary': socialPointSummary,
      'outcome': outcome,
    };
  }
}