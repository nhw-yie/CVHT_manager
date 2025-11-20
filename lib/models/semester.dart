// GENERATED: Semester model for Semesters table
// Fields: semester_id, semester_name, academic_year, start_date, end_date

class Semester {
  final int semesterId;
  final String semesterName;
  final String academicYear;
  final DateTime? startDate;
  final DateTime? endDate;

  Semester({
    required this.semesterId,
    required this.semesterName,
    required this.academicYear,
    this.startDate,
    this.endDate,
  });

  factory Semester.fromJson(Map<String, dynamic> json) {
    int? parseInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      return int.tryParse(v.toString());
    }

    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      if (v is DateTime) return v;
      return DateTime.tryParse(v.toString());
    }

    return Semester(
      semesterId: parseInt(json['semester_id']) ?? 0,
      semesterName: json['semester_name']?.toString() ?? '',
      academicYear: json['academic_year']?.toString() ?? '',
      startDate: parseDate(json['start_date']),
      endDate: parseDate(json['end_date']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'semester_id': semesterId,
      'semester_name': semesterName,
      'academic_year': academicYear,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
    };
  }
}
