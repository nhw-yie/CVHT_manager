// GENERATED: Unit model for Units table
// Fields: unit_id, unit_name, type, description

class Unit {
  final int unitId;
  final String unitName;
  final String type;
  final String? description;

  Unit({
    required this.unitId,
    required this.unitName,
    required this.type,
    this.description,
  });

  factory Unit.fromJson(Map<String, dynamic> json) {
    int? parseInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      return int.tryParse(v.toString());
    }

    return Unit(
      unitId: parseInt(json['unit_id']) ?? 0,
      unitName: json['unit_name']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      description: json['description']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'unit_id': unitId,
      'unit_name': unitName,
      'type': type,
      'description': description,
    };
  }
}
