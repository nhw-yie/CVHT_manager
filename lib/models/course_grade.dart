// GENERATED: CourseGrade model for Course_Grades table
// Fields: grade_id, student_id, course_id, semester_id, grade_value, grade_letter, grade_4_scale, status

class CourseGrade {
  final int gradeId;
  final int studentId;
  final int courseId;
  final int semesterId;
  final double? gradeValue;
  final String? gradeLetter;
  final double? grade4Scale;
  final String status;

  CourseGrade({
    required this.gradeId,
    required this.studentId,
    required this.courseId,
    required this.semesterId,
    this.gradeValue,
    this.gradeLetter,
    this.grade4Scale,
    required this.status,
  });

  factory CourseGrade.fromJson(Map<String, dynamic> json) {
    int? parseInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      return int.tryParse(v.toString());
    }

    double? parseDouble(dynamic v) {
      if (v == null) return null;
      if (v is double) return v;
      return double.tryParse(v.toString());
    }

    return CourseGrade(
      gradeId: parseInt(json['grade_id']) ?? 0,
      studentId: parseInt(json['student_id']) ?? 0,
      courseId: parseInt(json['course_id']) ?? 0,
      semesterId: parseInt(json['semester_id']) ?? 0,
      gradeValue: parseDouble(json['grade_value']),
      gradeLetter: json['grade_letter']?.toString(),
      grade4Scale: parseDouble(json['grade_4_scale']),
      status: json['status']?.toString() ?? 'studying',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'grade_id': gradeId,
      'student_id': studentId,
      'course_id': courseId,
      'semester_id': semesterId,
      'grade_value': gradeValue,
      'grade_letter': gradeLetter,
      'grade_4_scale': grade4Scale,
      'status': status,
    };
  }
}
