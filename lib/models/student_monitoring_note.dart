// GENERATED: StudentMonitoringNote model for Student_Monitoring_Notes table
// Fields: note_id, student_id, advisor_id, semester_id, category, title, content, created_at

class StudentMonitoringNote {
  final int noteId;
  final int studentId;
  final int advisorId;
  final int semesterId;
  final String category;
  final String title;
  final String content;
  final DateTime createdAt;

  StudentMonitoringNote({
    required this.noteId,
    required this.studentId,
    required this.advisorId,
    required this.semesterId,
    required this.category,
    required this.title,
    required this.content,
    required this.createdAt,
  });

  factory StudentMonitoringNote.fromJson(Map<String, dynamic> json) {
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

    return StudentMonitoringNote(
      noteId: parseInt(json['note_id']) ?? 0,
      studentId: parseInt(json['student_id']) ?? 0,
      advisorId: parseInt(json['advisor_id']) ?? 0,
      semesterId: parseInt(json['semester_id']) ?? 0,
      category: json['category']?.toString() ?? 'other',
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      createdAt: parseDate(json['created_at']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'note_id': noteId,
      'student_id': studentId,
      'advisor_id': advisorId,
      'semester_id': semesterId,
      'category': category,
      'title': title,
      'content': content,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
