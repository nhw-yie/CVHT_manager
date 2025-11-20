// GENERATED: ActivityRegistration model for Activity_Registrations table
// Fields: registration_id, activity_role_id, student_id, registration_time, status

class ActivityRegistration {
  final int registrationId;
  final int activityRoleId;
  final int studentId;
  final DateTime? registrationTime;
  final String? status;

  ActivityRegistration({
    required this.registrationId,
    required this.activityRoleId,
    required this.studentId,
    this.registrationTime,
    this.status,
  });

  factory ActivityRegistration.fromJson(Map<String, dynamic> json) {
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

    return ActivityRegistration(
      registrationId: parseInt(json['registration_id']) ?? 0,
      activityRoleId: parseInt(json['activity_role_id']) ?? 0,
      studentId: parseInt(json['student_id']) ?? 0,
      registrationTime: parseDate(json['registration_time']),
      status: json['status']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'registration_id': registrationId,
      'activity_role_id': activityRoleId,
      'student_id': studentId,
      'registration_time': registrationTime?.toIso8601String(),
      'status': status,
    };
  }
}
