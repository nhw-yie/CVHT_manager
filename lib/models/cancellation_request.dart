// GENERATED: CancellationRequest model for Cancellation_Requests table
// Fields: request_id, registration_id, reason, status, requested_at

class CancellationRequest {
  final int requestId;
  final int registrationId;
  final String reason;
  final String status;
  final DateTime requestedAt;

  CancellationRequest({
    required this.requestId,
    required this.registrationId,
    required this.reason,
    required this.status,
    required this.requestedAt,
  });

  factory CancellationRequest.fromJson(Map<String, dynamic> json) {
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

    return CancellationRequest(
      requestId: parseInt(json['request_id']) ?? 0,
      registrationId: parseInt(json['registration_id']) ?? 0,
      reason: json['reason']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      requestedAt: parseDate(json['requested_at']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'request_id': requestId,
      'registration_id': registrationId,
      'reason': reason,
      'status': status,
      'requested_at': requestedAt.toIso8601String(),
    };
  }
}
