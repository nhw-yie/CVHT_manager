// GENERATED: ClassModel for Classes table
// Fields: class_id, class_name, advisor_id, faculty_id, description

class ClassModel {
  final int classId;
  final String className;
  final int? advisorId;
  final int? facultyId;
  final String? description;

  ClassModel({
    required this.classId,
    required this.className,
    this.advisorId,
    this.facultyId,
    this.description,
  });

  factory ClassModel.fromJson(Map<String, dynamic> json) {
    int? parseInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      return int.tryParse(v.toString());
    }

    return ClassModel(
      classId: parseInt(json['class_id']) ?? 0,
      className: json['class_name']?.toString() ?? '',
      advisorId: parseInt(json['advisor_id']),
      facultyId: parseInt(json['faculty_id']),
      description: json['description']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'class_id': classId,
      'class_name': className,
      'advisor_id': advisorId,
      'faculty_id': facultyId,
      'description': description,
    };
  }
}
