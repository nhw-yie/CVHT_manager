// lib/models/conversation.dart

class Conversation {
  final int conversationId;
  final int partnerId;
  final String partnerName;
  final String? partnerAvatar;
  final String partnerType; // 'student' or 'advisor'
  final String? partnerCode; // mã sinh viên (advisor only)
  final String? className; // tên lớp (advisor only)
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final int unreadCount;

  Conversation({
    required this.conversationId,
    required this.partnerId,
    required this.partnerName,
    this.partnerAvatar,
    required this.partnerType,
    this.partnerCode,
    this.className,
    this.lastMessage,
    this.lastMessageTime,
    required this.unreadCount,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
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

    return Conversation(
      conversationId: parseInt(json['conversation_id']) ?? 0,
      partnerId: parseInt(json['partner_id']) ?? 0,
      partnerName: json['partner_name']?.toString() ?? '',
      partnerAvatar: json['partner_avatar']?.toString(),
      partnerType: json['partner_type']?.toString() ?? 'student',
      partnerCode: json['partner_code']?.toString(),
      className: json['class_name']?.toString(),
      lastMessage: json['last_message']?.toString(),
      lastMessageTime: parseDate(json['last_message_time']),
      unreadCount: parseInt(json['unread_count']) ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'conversation_id': conversationId,
      'partner_id': partnerId,
      'partner_name': partnerName,
      'partner_avatar': partnerAvatar,
      'partner_type': partnerType,
      'partner_code': partnerCode,
      'class_name': className,
      'last_message': lastMessage,
      'last_message_time': lastMessageTime?.toIso8601String(),
      'unread_count': unreadCount,
    };
  }
}
