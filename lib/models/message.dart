// GENERATED: MessageModel for Messages table
// Fields: message_id, student_id, advisor_id, sender_type, content, sent_at, is_read

class MessageModel {
  final int messageId;
  final int? studentId;
  final int? advisorId;
  final String senderType;
  final String content;
  final DateTime? sentAt;
  final bool isRead;

  MessageModel({
    required this.messageId,
    this.studentId,
    this.advisorId,
    required this.senderType,
    required this.content,
    this.sentAt,
    required this.isRead,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
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

    bool parseBool(dynamic v) {
      if (v == null) return false;
      if (v is bool) return v;
      final s = v.toString().toLowerCase();
      return s == '1' || s == 'true' || s == 'yes';
    }

    return MessageModel(
      messageId: parseInt(json['message_id']) ?? 0,
      studentId: parseInt(json['student_id']),
      advisorId: parseInt(json['advisor_id']),
      senderType: json['sender_type']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      sentAt: parseDate(json['sent_at']),
      isRead: parseBool(json['is_read']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message_id': messageId,
      'student_id': studentId,
      'advisor_id': advisorId,
      'sender_type': senderType,
      'content': content,
      'sent_at': sentAt?.toIso8601String(),
      'is_read': isRead,
    };
  }
}
