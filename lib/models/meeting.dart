// GENERATED: Meeting model for Meetings table
// Fields: meeting_id, advisor_id, class_id, title, summary, class_feedback, meeting_link, location, meeting_time, end_time, status, minutes_file_path

class Meeting {
  final int meetingId;
  final int advisorId;
  final int classId;
  final String title;
  final String? summary;
  final String? classFeedback;
  final String? meetingLink;
  final String? location;
  final DateTime meetingTime;
  final DateTime? endTime;
  final String status;
  final String? minutesFilePath;

  Meeting({
    required this.meetingId,
    required this.advisorId,
    required this.classId,
    required this.title,
    this.summary,
    this.classFeedback,
    this.meetingLink,
    this.location,
    required this.meetingTime,
    this.endTime,
    required this.status,
    this.minutesFilePath,
  });

  factory Meeting.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      if (v is DateTime) return v;
      return DateTime.tryParse(v.toString());
    }

    int? parseInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      return int.tryParse(v.toString());
    }

    return Meeting(
      meetingId: parseInt(json['meeting_id']) ?? 0,
      advisorId: parseInt(json['advisor_id']) ?? 0,
      classId: parseInt(json['class_id']) ?? 0,
      title: json['title']?.toString() ?? '',
      summary: json['summary']?.toString(),
      classFeedback: json['class_feedback']?.toString(),
      meetingLink: json['meeting_link']?.toString(),
      location: json['location']?.toString(),
      meetingTime: parseDate(json['meeting_time']) ?? DateTime.now(),
      endTime: parseDate(json['end_time']),
      status: json['status']?.toString() ?? 'scheduled',
      minutesFilePath: json['minutes_file_path']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'meeting_id': meetingId,
      'advisor_id': advisorId,
      'class_id': classId,
      'title': title,
      'summary': summary,
      'class_feedback': classFeedback,
      'meeting_link': meetingLink,
      'location': location,
      'meeting_time': meetingTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'status': status,
      'minutes_file_path': minutesFilePath,
    };
  }
}
