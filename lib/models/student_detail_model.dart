// lib/models/student_detail_model.dart
// Model mở rộng cho student với thông tin chi tiết

import 'student.dart';
import 'class_model.dart';
import 'semester_report.dart';

class StudentDetail {
  final Student student;
  final ClassModel? classInfo;
  final List<SemesterReport> reports;
  final AcademicSummary? academicSummary;

  StudentDetail({
    required this.student,
    this.classInfo,
    this.reports = const [],
    this.academicSummary,
  });

  factory StudentDetail.fromJson(Map<String, dynamic> json) {
    return StudentDetail(
      student: Student.fromJson(json['student'] ?? json),
      classInfo: json['class'] != null ? ClassModel.fromJson(json['class']) : null,
      reports: (json['reports'] as List?)
          ?.map((e) => SemesterReport.fromJson(e))
          .toList() ?? [],
      academicSummary: json['academic_summary'] != null
          ? AcademicSummary.fromJson(json['academic_summary'])
          : null,
    );
  }
}

class AcademicSummary {
  final double? cpa10;
  final double? cpa4;
  final int totalCreditsPassed;
  final int passedCourses;
  final int failedCourses;
  final int totalCourses;
  final double? semesterGpa10;
  final double? semesterGpa4;
  final int? semesterCredits;

  AcademicSummary({
    this.cpa10,
    this.cpa4,
    required this.totalCreditsPassed,
    required this.passedCourses,
    required this.failedCourses,
    required this.totalCourses,
    this.semesterGpa10,
    this.semesterGpa4,
    this.semesterCredits,
  });

  factory AcademicSummary.fromJson(Map<String, dynamic> json) {
    double? parseDouble(dynamic v) {
      if (v == null) return null;
      if (v is double) return v;
      if (v is int) return v.toDouble();
      return double.tryParse(v.toString());
    }

    int? parseInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      return int.tryParse(v.toString());
    }

    return AcademicSummary(
      cpa10: parseDouble(json['cpa_10']),
      cpa4: parseDouble(json['cpa_4']),
      totalCreditsPassed: parseInt(json['total_credits_passed']) ?? 0,
      passedCourses: parseInt(json['passed_courses']) ?? 0,
      failedCourses: parseInt(json['failed_courses']) ?? 0,
      totalCourses: parseInt(json['total_courses']) ?? 0,
      semesterGpa10: parseDouble(json['semester_gpa_10']),
      semesterGpa4: parseDouble(json['semester_gpa_4']),
      semesterCredits: parseInt(json['semester_credits']),
    );
  }
}