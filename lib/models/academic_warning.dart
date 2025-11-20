// GENERATED: AcademicWarning model for Academic_Warnings table
// Fields: warning_id, student_id, advisor_id, semester_id, title, content, advice, created_at

class AcademicWarning {
  final int warningId;
  final int studentId;
  final int advisorId;
  final int? semesterId;
  final String title;
  final String content;
  final String? advice;
  final DateTime createdAt;

  AcademicWarning({
    required this.warningId,
    required this.studentId,
    required this.advisorId,
    this.semesterId,
    required this.title,
    required this.content,
    this.advice,
    required this.createdAt,
  });

  factory AcademicWarning.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      if (v is DateTime) return v;
      return DateTime.tryParse(v.toString());
    }

    int? parseInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      return int.tryParse(v.toString());
    }

    return AcademicWarning(
      warningId: parseInt(json['warning_id']) ?? 0,
      studentId: parseInt(json['student_id']) ?? 0,
      advisorId: parseInt(json['advisor_id']) ?? 0,
      semesterId: parseInt(json['semester_id']),
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      advice: json['advice']?.toString(),
      createdAt: parseDate(json['created_at']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'warning_id': warningId,
      'student_id': studentId,
      'advisor_id': advisorId,
      'semester_id': semesterId,
      'title': title,
      'content': content,
      'advice': advice,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
