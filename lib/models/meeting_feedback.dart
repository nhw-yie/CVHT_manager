// lib/models/meeting_feedback.dart
// GENERATED: MeetingFeedback model for Meeting_Feedbacks table
// Fields: feedback_id, meeting_id, student_id, feedback_content, created_at

class MeetingFeedback {
  final int feedbackId;
  final int meetingId;
  final int studentId;
  final String feedbackContent;
  final DateTime createdAt;
  
  // Relations
  final Map<String, dynamic>? student;

  MeetingFeedback({
    required this.feedbackId,
    required this.meetingId,
    required this.studentId,
    required this.feedbackContent,
    required this.createdAt,
    this.student,
  });

  factory MeetingFeedback.fromJson(Map<String, dynamic> json) {
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

    return MeetingFeedback(
      feedbackId: parseInt(json['feedback_id']) ?? 0,
      meetingId: parseInt(json['meeting_id']) ?? 0,
      studentId: parseInt(json['student_id']) ?? 0,
      feedbackContent: json['feedback_content']?.toString() ?? '',
      createdAt: parseDate(json['created_at']) ?? DateTime.now(),
      student: json['student'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'feedback_id': feedbackId,
      'meeting_id': meetingId,
      'student_id': studentId,
      'feedback_content': feedbackContent,
      'created_at': createdAt.toIso8601String(),
      if (student != null) 'student': student,
    };
  }

  String get studentName => student?['full_name']?.toString() ?? 'Unknown';
  String get studentPosition => student?['position']?.toString() ?? 'member';
}