// GENERATED: Student model for Students table
// Fields: student_id, user_code, full_name, email, phone_number, avatar_url, class_id, status

class Student {
  final int studentId;
  final String userCode;
  final String fullName;
  final String? email;
  final String? phoneNumber;
  final String? avatarUrl;
  final int? classId;
  final String? status;

  Student({
    required this.studentId,
    required this.userCode,
    required this.fullName,
    this.email,
    this.phoneNumber,
    this.avatarUrl,
    this.classId,
    this.status,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    int? parseInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      return int.tryParse(v.toString());
    }

    return Student(
      studentId: parseInt(json['student_id']) ?? 0,
      userCode: json['user_code']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? '',
      email: json['email']?.toString(),
      phoneNumber: json['phone_number']?.toString(),
      avatarUrl: json['avatar_url']?.toString(),
      classId: parseInt(json['class_id']),
      status: json['status']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'student_id': studentId,
      'user_code': userCode,
      'full_name': fullName,
      'email': email,
      'phone_number': phoneNumber,
      'avatar_url': avatarUrl,
      'class_id': classId,
      'status': status,
    };
  }
}
