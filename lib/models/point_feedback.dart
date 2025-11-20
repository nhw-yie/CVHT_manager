// GENERATED: PointFeedback model for Point_Feedbacks table
// Fields: feedback_id, student_id, semester_id, feedback_content, attachment_path, status, advisor_response, advisor_id, response_at, created_at

class PointFeedback {
  final int feedbackId;
  final int studentId;
  final int semesterId;
  final String feedbackContent;
  final String? attachmentPath;
  final String status;
  final String? advisorResponse;
  final int? advisorId;
  final DateTime? responseAt;
  final DateTime createdAt;

  PointFeedback({
    required this.feedbackId,
    required this.studentId,
    required this.semesterId,
    required this.feedbackContent,
    this.attachmentPath,
    required this.status,
    this.advisorResponse,
    this.advisorId,
    this.responseAt,
    required this.createdAt,
  });

  factory PointFeedback.fromJson(Map<String, dynamic> json) {
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

    return PointFeedback(
      feedbackId: parseInt(json['feedback_id']) ?? 0,
      studentId: parseInt(json['student_id']) ?? 0,
      semesterId: parseInt(json['semester_id']) ?? 0,
      feedbackContent: json['feedback_content']?.toString() ?? '',
      attachmentPath: json['attachment_path']?.toString(),
      status: json['status']?.toString() ?? 'pending',
      advisorResponse: json['advisor_response']?.toString(),
      advisorId: parseInt(json['advisor_id']),
      responseAt: parseDate(json['response_at']),
      createdAt: parseDate(json['created_at']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'feedback_id': feedbackId,
      'student_id': studentId,
      'semester_id': semesterId,
      'feedback_content': feedbackContent,
      'attachment_path': attachmentPath,
      'status': status,
      'advisor_response': advisorResponse,
      'advisor_id': advisorId,
      'response_at': responseAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}
