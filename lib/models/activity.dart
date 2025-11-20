// GENERATED: Activity model for Activities table
// Fields: activity_id, advisor_id, title, general_description, location, start_time, end_time, status

class Activity {
  final int activityId;
  final int? advisorId;
  final String title;
  final String? generalDescription;
  final String? location;
  final DateTime? startTime;
  final DateTime? endTime;
  final String? status;

  Activity({
    required this.activityId,
    this.advisorId,
    required this.title,
    this.generalDescription,
    this.location,
    this.startTime,
    this.endTime,
    this.status,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
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

    return Activity(
      activityId: parseInt(json['activity_id']) ?? 0,
      advisorId: parseInt(json['advisor_id']),
      title: json['title']?.toString() ?? '',
      generalDescription: json['general_description']?.toString(),
      location: json['location']?.toString(),
      startTime: parseDate(json['start_time']),
      endTime: parseDate(json['end_time']),
      status: json['status']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'activity_id': activityId,
      'advisor_id': advisorId,
      'title': title,
      'general_description': generalDescription,
      'location': location,
      'start_time': startTime?.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'status': status,
    };
  }
}
