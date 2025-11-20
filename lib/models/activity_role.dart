// GENERATED: ActivityRole model for Activity_Roles table
// Fields: activity_role_id, activity_id, role_name, points_awarded, point_type, max_slots

class ActivityRole {
  final int activityRoleId;
  final int activityId;
  final String roleName;
  final int? pointsAwarded;
  final String? pointType;
  final int? maxSlots;

  ActivityRole({
    required this.activityRoleId,
    required this.activityId,
    required this.roleName,
    this.pointsAwarded,
    this.pointType,
    this.maxSlots,
  });

  factory ActivityRole.fromJson(Map<String, dynamic> json) {
    int? parseInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      return int.tryParse(v.toString());
    }

    return ActivityRole(
      activityRoleId: parseInt(json['activity_role_id']) ?? 0,
      activityId: parseInt(json['activity_id']) ?? 0,
      roleName: json['role_name']?.toString() ?? '',
      pointsAwarded: parseInt(json['points_awarded']),
      pointType: json['point_type']?.toString(),
      maxSlots: parseInt(json['max_slots']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'activity_role_id': activityRoleId,
      'activity_id': activityId,
      'role_name': roleName,
      'points_awarded': pointsAwarded,
      'point_type': pointType,
      'max_slots': maxSlots,
    };
  }
}
