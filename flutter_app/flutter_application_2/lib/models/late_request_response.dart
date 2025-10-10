class LateRequestResponse {
  final bool? success;
  final String message;
  final int? requestId;
  final String? employeeName;
  final String? requestedTime;
  final String? status;
  final String? requestedAt;
  final String? error;

  // New fields for verification
  final bool? match;
  final double? similarity;
  final String? faceVerification;
  final String? locationCheck;
  final String? storeLocation;
  final bool? requestSubmitted;

  LateRequestResponse({
    this.success,
    required this.message,
    this.requestId,
    this.employeeName,
    this.requestedTime,
    this.status,
    this.requestedAt,
    this.error,
    this.match,
    this.similarity,
    this.faceVerification,
    this.locationCheck,
    this.storeLocation,
    this.requestSubmitted,
  });

  factory LateRequestResponse.fromJson(Map<String, dynamic> json) {
    return LateRequestResponse(
      success: json['success'] as bool?,
      message: json['message'] as String? ?? '',
      requestId: json['request_id'] as int?,
      employeeName: json['employee_name'] as String?,
      requestedTime: json['requested_time'] as String?,
      status: json['status'] as String?,
      requestedAt: json['requested_at'] as String?,
      error: json['error'] as String?,
      match: json['match'] as bool?,
      similarity: (json['similarity'] as num?)?.toDouble(),
      faceVerification: json['face_verification'] as String?,
      locationCheck: json['location_check'] as String?,
      storeLocation: json['store_location'] as String?,
      requestSubmitted: json['request_submitted'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'request_id': requestId,
      'employee_name': employeeName,
      'requested_time': requestedTime,
      'status': status,
      'requested_at': requestedAt,
      'error': error,
      'match': match,
      'similarity': similarity,
      'face_verification': faceVerification,
      'location_check': locationCheck,
      'store_location': storeLocation,
      'request_submitted': requestSubmitted,
    };
  }

  // Helper methods for easy status checking
  bool get isSuccess => success == true && error == null;
  bool get hasError => success == false || error != null;
  bool get isPending => status?.toLowerCase() == 'pending';
  bool get isAccepted => status?.toLowerCase() == 'accepted';
  bool get isRejected => status?.toLowerCase() == 'rejected';

  // New helper methods for verification
  bool get isFaceVerified => faceVerification == 'success';
  bool get isLocationVerified => locationCheck == 'success';
  bool get isFullyVerified => isFaceVerified && isLocationVerified;

  // Helper method to get user-friendly error message
  String get displayMessage {
    if (error != null) return error!;
    return message;
  }

  // Helper method to determine if attendance was automatically recorded
  bool get attendanceRecorded => isAccepted;

  // Helper method to check if employee should refresh status
  bool get shouldRefreshStatus => isAccepted || isRejected;
}
