// GENERATED: Advisor model for Advisors table
// Fields: advisor_id, user_code, full_name, email, phone_number, avatar_url, unit_id

class Advisor {
  final int advisorId;
  final String userCode;
  final String fullName;
  final String? email;
  final String? phoneNumber;
  final String? avatarUrl;
  final int? unitId;

  Advisor({
    required this.advisorId,
    required this.userCode,
    required this.fullName,
    this.email,
    this.phoneNumber,
    this.avatarUrl,
    this.unitId,
  });

  factory Advisor.fromJson(Map<String, dynamic> json) {
    int? parseInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      return int.tryParse(v.toString());
    }

    return Advisor(
      advisorId: parseInt(json['advisor_id']) ?? 0,
      userCode: json['user_code']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? '',
      email: json['email']?.toString(),
      phoneNumber: json['phone_number']?.toString(),
      avatarUrl: json['avatar_url']?.toString(),
      unitId: parseInt(json['unit_id']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'advisor_id': advisorId,
      'user_code': userCode,
      'full_name': fullName,
      'email': email,
      'phone_number': phoneNumber,
      'avatar_url': avatarUrl,
      'unit_id': unitId,
    };
  }
}
