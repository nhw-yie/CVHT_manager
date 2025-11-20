// Simple User model used by AuthProvider. Adjust fields to match your API's /auth/me response.
class User {
  final int? id;
  final String? userCode;
  final String? fullName;
  final String? email;
  final String? phoneNumber;
  final String? avatarUrl;
  final String? role;

  User({
    this.id,
    this.userCode,
    this.fullName,
    this.email,
    this.phoneNumber,
    this.avatarUrl,
    this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    int? parseInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      return int.tryParse(v.toString());
    }

    return User(
      id: parseInt(json['id'] ?? json['user_id'] ?? json['student_id'] ?? json['advisor_id']),
      userCode: json['user_code']?.toString(),
      fullName: json['full_name']?.toString() ?? json['name']?.toString(),
      email: json['email']?.toString(),
      phoneNumber: json['phone_number']?.toString(),
      avatarUrl: json['avatar_url']?.toString() ?? json['avatar']?.toString(),
      role: json['role']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_code': userCode,
      'full_name': fullName,
      'email': email,
      'phone_number': phoneNumber,
      'avatar_url': avatarUrl,
      'role': role,
    };
  }
}
