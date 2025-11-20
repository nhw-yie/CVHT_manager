// GENERATED: MeetingStudent model for Meeting_Student table
// Fields: meeting_student_id, meeting_id, student_id, attended

class MeetingStudent {
  final int meetingStudentId;
  final int meetingId;
  final int studentId;
  final bool attended;

  MeetingStudent({
    required this.meetingStudentId,
    required this.meetingId,
    required this.studentId,
    required this.attended,
  });

  factory MeetingStudent.fromJson(Map<String, dynamic> json) {
    int? parseInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      return int.tryParse(v.toString());
    }

    bool parseBool(dynamic v) {
      if (v == null) return false;
      if (v is bool) return v;
      final s = v.toString().toLowerCase();
      return s == '1' || s == 'true' || s == 'yes';
    }

    return MeetingStudent(
      meetingStudentId: parseInt(json['meeting_student_id']) ?? 0,
      meetingId: parseInt(json['meeting_id']) ?? 0,
      studentId: parseInt(json['student_id']) ?? 0,
      attended: parseBool(json['attended']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'meeting_student_id': meetingStudentId,
      'meeting_id': meetingId,
      'student_id': studentId,
      'attended': attended,
    };
  }
}
