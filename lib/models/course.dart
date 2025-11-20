// GENERATED: Course model for Courses table
// Fields: course_id, course_code, course_name, credits, unit_id

class Course {
  final int courseId;
  final String courseCode;
  final String courseName;
  final int credits;
  final int? unitId;

  Course({
    required this.courseId,
    required this.courseCode,
    required this.courseName,
    required this.credits,
    this.unitId,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    int? parseInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      return int.tryParse(v.toString());
    }

    return Course(
      courseId: parseInt(json['course_id']) ?? 0,
      courseCode: json['course_code']?.toString() ?? '',
      courseName: json['course_name']?.toString() ?? '',
      credits: parseInt(json['credits']) ?? 0,
      unitId: parseInt(json['unit_id']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'course_id': courseId,
      'course_code': courseCode,
      'course_name': courseName,
      'credits': credits,
      'unit_id': unitId,
    };
  }
}
