// lib/models/notification_models.dart

class NotificationModel {
  final int notificationId;
  final int advisorId;
  final String title;
  final String summary;
  final String? link;
  final String type;
  final DateTime createdAt;
  final bool isRead;
  
  // Relations
  final AdvisorInfo? advisor;
  final List<ClassInfo>? classes;
  final List<AttachmentInfo>? attachments;
  final NotificationResponseInfo? myResponse;
  
  // Statistics (for advisor)
  final int? totalRecipients;
  final int? totalRead;
  final int? totalResponses;
  final int? responsesCount;

  NotificationModel({
    required this.notificationId,
    required this.advisorId,
    required this.title,
    required this.summary,
    this.link,
    required this.type,
    required this.createdAt,
    this.isRead = false,
    this.advisor,
    this.classes,
    this.attachments,
    this.myResponse,
    this.totalRecipients,
    this.totalRead,
    this.totalResponses,
    this.responsesCount,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      notificationId: json['notification_id'] ?? 0,
      advisorId: json['advisor_id'] ?? 0,
      title: json['title'] ?? '',
      summary: json['summary'] ?? '',
      link: json['link'],
      type: json['type'] ?? 'general',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      isRead: json['is_read'] ?? false,
      advisor: json['advisor'] != null
          ? AdvisorInfo.fromJson(json['advisor'])
          : null,
      classes: json['classes'] != null
          ? (json['classes'] as List)
              .map((e) => ClassInfo.fromJson(e))
              .toList()
          : null,
      attachments: json['attachments'] != null
          ? (json['attachments'] as List)
              .map((e) => AttachmentInfo.fromJson(e))
              .toList()
          : null,
      myResponse: json['my_response'] != null
          ? NotificationResponseInfo.fromJson(json['my_response'])
          : null,
      totalRecipients: json['total_recipients'],
      totalRead: json['total_read'],
      totalResponses: json['total_responses'],
      responsesCount: json['responses_count'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notification_id': notificationId,
      'advisor_id': advisorId,
      'title': title,
      'summary': summary,
      'link': link,
      'type': type,
      'created_at': createdAt.toIso8601String(),
      'is_read': isRead,
    };
  }

  NotificationModel copyWith({
    int? notificationId,
    int? advisorId,
    String? title,
    String? summary,
    String? link,
    String? type,
    DateTime? createdAt,
    bool? isRead,
    AdvisorInfo? advisor,
    List<ClassInfo>? classes,
    List<AttachmentInfo>? attachments,
    NotificationResponseInfo? myResponse,
    int? totalRecipients,
    int? totalRead,
    int? totalResponses,
    int? responsesCount,
  }) {
    return NotificationModel(
      notificationId: notificationId ?? this.notificationId,
      advisorId: advisorId ?? this.advisorId,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      link: link ?? this.link,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      advisor: advisor ?? this.advisor,
      classes: classes ?? this.classes,
      attachments: attachments ?? this.attachments,
      myResponse: myResponse ?? this.myResponse,
      totalRecipients: totalRecipients ?? this.totalRecipients,
      totalRead: totalRead ?? this.totalRead,
      totalResponses: totalResponses ?? this.totalResponses,
      responsesCount: responsesCount ?? this.responsesCount,
    );
  }

  double get readPercentage {
    if (totalRecipients == null || totalRecipients == 0) return 0;
    return ((totalRead ?? 0) / totalRecipients!) * 100;
  }
}

class AdvisorInfo {
  final int advisorId;
  final String fullName;
  final String? avatarUrl;

  AdvisorInfo({
    required this.advisorId,
    required this.fullName,
    this.avatarUrl,
  });

  factory AdvisorInfo.fromJson(Map<String, dynamic> json) {
    return AdvisorInfo(
      advisorId: json['advisor_id'] ?? 0,
      fullName: json['full_name'] ?? '',
      avatarUrl: json['avatar_url'],
    );
  }
}

class ClassInfo {
  final int classId;
  final String className;

  ClassInfo({
    required this.classId,
    required this.className,
  });

  factory ClassInfo.fromJson(Map<String, dynamic> json) {
    return ClassInfo(
      classId: json['class_id'] ?? 0,
      className: json['class_name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'class_id': classId,
      'class_name': className,
    };
  }
}

class AttachmentInfo {
  final int attachmentId;
  final String filePath;
  final String fileName;

  AttachmentInfo({
    required this.attachmentId,
    required this.filePath,
    required this.fileName,
  });

  factory AttachmentInfo.fromJson(Map<String, dynamic> json) {
    return AttachmentInfo(
      attachmentId: json['attachment_id'] ?? 0,
      filePath: json['file_path'] ?? '',
      fileName: json['file_name'] ?? '',
    );
  }

  String get fileUrl {
    // Adjust base URL based on your API configuration
    const baseUrl = 'http://127.0.0.1:8000/storage/';
    return '$baseUrl$filePath';
  }

  String get fileExtension {
    return fileName.split('.').last.toLowerCase();
  }

  bool get isImage {
    return ['jpg', 'jpeg', 'png', 'gif'].contains(fileExtension);
  }
}

class NotificationResponseInfo {
  final int responseId;
  final int notificationId;
  final int studentId;
  final String content;
  final String status;
  final String? advisorResponse;
  final int? advisorId;
  final DateTime? responseAt;
  final DateTime createdAt;
  
  // Relations
  final AdvisorInfo? advisor;

  NotificationResponseInfo({
    required this.responseId,
    required this.notificationId,
    required this.studentId,
    required this.content,
    required this.status,
    this.advisorResponse,
    this.advisorId,
    this.responseAt,
    required this.createdAt,
    this.advisor,
  });

  factory NotificationResponseInfo.fromJson(Map<String, dynamic> json) {
    return NotificationResponseInfo(
      responseId: json['response_id'] ?? 0,
      notificationId: json['notification_id'] ?? 0,
      studentId: json['student_id'] ?? 0,
      content: json['content'] ?? '',
      status: json['status'] ?? 'pending',
      advisorResponse: json['advisor_response'],
      advisorId: json['advisor_id'],
      responseAt: json['response_at'] != null
          ? DateTime.parse(json['response_at'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      advisor: json['advisor'] != null
          ? AdvisorInfo.fromJson(json['advisor'])
          : null,
    );
  }

  bool get isPending => status == 'pending';
  bool get isResolved => status == 'resolved';
}

// Response with student info (for advisor view)
class StudentResponseInfo extends NotificationResponseInfo {
  final StudentInfo student;

  StudentResponseInfo({
    required super.responseId,
    required super.notificationId,
    required super.studentId,
    required super.content,
    required super.status,
    super.advisorResponse,
    super.advisorId,
    super.responseAt,
    required super.createdAt,
    super.advisor,
    required this.student,
  });

  factory StudentResponseInfo.fromJson(Map<String, dynamic> json) {
    return StudentResponseInfo(
      responseId: json['response_id'] ?? 0,
      notificationId: json['notification_id'] ?? 0,
      studentId: json['student_id'] ?? 0,
      content: json['content'] ?? '',
      status: json['status'] ?? 'pending',
      advisorResponse: json['advisor_response'],
      advisorId: json['advisor_id'],
      responseAt: json['response_at'] != null
          ? DateTime.parse(json['response_at'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      advisor: json['advisor'] != null
          ? AdvisorInfo.fromJson(json['advisor'])
          : null,
      student: StudentInfo.fromJson(json['student'] ?? {}),
    );
  }
}

class StudentInfo {
  final int studentId;
  final String fullName;
  final String userCode;
  final String? avatarUrl;

  StudentInfo({
    required this.studentId,
    required this.fullName,
    required this.userCode,
    this.avatarUrl,
  });

  factory StudentInfo.fromJson(Map<String, dynamic> json) {
    return StudentInfo(
      studentId: json['student_id'] ?? 0,
      fullName: json['full_name'] ?? '',
      userCode: json['user_code'] ?? '',
      avatarUrl: json['avatar_url'],
    );
  }
}

// Statistics model
class NotificationStatistics {
  final int totalNotifications;
  final int totalRecipients;
  final int totalRead;
  final double readPercentage;
  final int totalResponses;
  final int pendingResponses;
  final List<TypeStatistic> byType;

  NotificationStatistics({
    required this.totalNotifications,
    required this.totalRecipients,
    required this.totalRead,
    required this.readPercentage,
    required this.totalResponses,
    required this.pendingResponses,
    required this.byType,
  });

  factory NotificationStatistics.fromJson(Map<String, dynamic> json) {
    return NotificationStatistics(
      totalNotifications: json['total_notifications'] ?? 0,
      totalRecipients: json['total_recipients'] ?? 0,
      totalRead: json['total_read'] ?? 0,
      readPercentage: (json['read_percentage'] ?? 0).toDouble(),
      totalResponses: json['total_responses'] ?? 0,
      pendingResponses: json['pending_responses'] ?? 0,
      byType: json['by_type'] != null
          ? (json['by_type'] as List)
              .map((e) => TypeStatistic.fromJson(e))
              .toList()
          : [],
    );
  }
}

class TypeStatistic {
  final String type;
  final int count;

  TypeStatistic({
    required this.type,
    required this.count,
  });

  factory TypeStatistic.fromJson(Map<String, dynamic> json) {
    return TypeStatistic(
      type: json['type'] ?? '',
      count: json['count'] ?? 0,
    );
  }
}