// lib/models/dialog_message.dart

/// Model for chat/dialog messages between student and advisor
/// Based on Messages table in database
class DialogMessage {
  final int messageId;
  final int studentId;
  final int advisorId;
  final String senderType; // 'student' or 'advisor'
  final String content;
  final String? attachmentPath;
  final bool isRead;
  final DateTime sentAt;

  DialogMessage({
    required this.messageId,
    required this.studentId,
    required this.advisorId,
    required this.senderType,
    required this.content,
    this.attachmentPath,
    required this.isRead,
    required this.sentAt,
  });

  factory DialogMessage.fromJson(Map<String, dynamic> json) {
    int? parseInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      return int.tryParse(v.toString());
    }

    DateTime parseDate(dynamic v) {
      if (v is DateTime) return v;
      return DateTime.tryParse(v.toString()) ?? DateTime.now();
    }

    bool parseBool(dynamic v) {
      if (v == null) return false;
      if (v is bool) return v;
      if (v is int) return v == 1;
      final s = v.toString().toLowerCase();
      return s == '1' || s == 'true' || s == 'yes';
    }

    return DialogMessage(
      messageId: parseInt(json['message_id']) ?? 0,
      studentId: parseInt(json['student_id']) ?? 0,
      advisorId: parseInt(json['advisor_id']) ?? 0,
      senderType: json['sender_type']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      attachmentPath: json['attachment_path']?.toString(),
      isRead: parseBool(json['is_read']),
      sentAt: parseDate(json['sent_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message_id': messageId,
      'student_id': studentId,
      'advisor_id': advisorId,
      'sender_type': senderType,
      'content': content,
      'attachment_path': attachmentPath,
      'is_read': isRead,
      'sent_at': sentAt.toIso8601String(),
    };
  }

  /// Check if current user is the sender
  /// userRole should be 'student' or 'advisor'
  bool isSentByMe(String userRole) {
    return senderType == userRole;
  }

  /// Check if message has attachment
  bool get hasAttachment => attachmentPath != null && attachmentPath!.isNotEmpty;

  /// Format time for display (HH:mm)
  String get formattedTime {
    final hour = sentAt.hour.toString().padLeft(2, '0');
    final minute = sentAt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Check if message was sent today
  bool get isSentToday {
    final now = DateTime.now();
    return sentAt.year == now.year &&
        sentAt.month == now.month &&
        sentAt.day == now.day;
  }

  /// Copy with method for updating fields
  DialogMessage copyWith({
    int? messageId,
    int? studentId,
    int? advisorId,
    String? senderType,
    String? content,
    String? attachmentPath,
    bool? isRead,
    DateTime? sentAt,
  }) {
    return DialogMessage(
      messageId: messageId ?? this.messageId,
      studentId: studentId ?? this.studentId,
      advisorId: advisorId ?? this.advisorId,
      senderType: senderType ?? this.senderType,
      content: content ?? this.content,
      attachmentPath: attachmentPath ?? this.attachmentPath,
      isRead: isRead ?? this.isRead,
      sentAt: sentAt ?? this.sentAt,
    );
  }

  @override
  String toString() {
    return 'DialogMessage(id: $messageId, sender: $senderType, content: ${content.substring(0, content.length > 20 ? 20 : content.length)}..., read: $isRead)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DialogMessage && other.messageId == messageId;
  }

  @override
  int get hashCode => messageId.hashCode;
}