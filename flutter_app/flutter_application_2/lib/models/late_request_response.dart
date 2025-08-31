class LateRequestResponse {
  final bool? success;
  final String message;
  final int? requestId;
  final String? employeeName;
  final String? requestedTime;
  final String? status;
  final String? requestedAt;
  final String? error;

  LateRequestResponse({
    this.success,
    required this.message,
    this.requestId,
    this.employeeName,
    this.requestedTime,
    this.status,
    this.requestedAt,
    this.error,
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
    };
  }

  // Helper methods for easy status checking
  bool get isSuccess => success == true && error == null;
  bool get hasError => success == false || error != null;
  bool get isPending => status?.toLowerCase() == 'pending';
  bool get isAccepted => status?.toLowerCase() == 'accepted';
  bool get isRejected => status?.toLowerCase() == 'rejected';

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
