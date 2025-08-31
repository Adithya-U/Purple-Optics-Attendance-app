class CheckOutResponse {
  final String? faceVerification;
  final bool? checkOutRecorded;
  final double? similarity;
  final bool? match;
  final String? timeValidation;
  final String? employeeName;
  final String? checkInTime;
  final String? checkOutTime;
  final String? attendanceStatus;
  final String? location;
  final double? hoursWorked;
  final String message;
  final String? error;

  CheckOutResponse({
    this.faceVerification,
    this.checkOutRecorded,
    this.similarity,
    this.match,
    this.timeValidation,
    this.employeeName,
    this.checkInTime,
    this.checkOutTime,
    this.attendanceStatus,
    this.location,
    this.hoursWorked,
    required this.message,
    this.error,
  });

  factory CheckOutResponse.fromJson(Map<String, dynamic> json) {
    return CheckOutResponse(
      faceVerification: json['face_verification'] as String?,
      checkOutRecorded: json['check_out_recorded'] as bool?,
      similarity: json['similarity']?.toDouble(),
      match: json['match'] as bool?,
      timeValidation: json['time_validation'] as String?,
      employeeName: json['employee_name'] as String?,
      checkInTime: json['check_in_time'] as String?,
      checkOutTime: json['check_out_time'] as String?,
      attendanceStatus: json['attendance_status'] as String?,
      location: json['location'] as String?,
      hoursWorked: json['hours_worked']?.toDouble(),
      message: json['message'] as String? ?? '',
      error: json['error'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'face_verification': faceVerification,
      'check_out_recorded': checkOutRecorded,
      'similarity': similarity,
      'match': match,
      'time_validation': timeValidation,
      'employee_name': employeeName,
      'check_in_time': checkInTime,
      'check_out_time': checkOutTime,
      'attendance_status': attendanceStatus,
      'location': location,
      'hours_worked': hoursWorked,
      'message': message,
      'error': error,
    };
  }

  // Helper methods for easy status checking
  bool get isSuccess => checkOutRecorded == true && error == null;
  bool get isFaceVerificationSuccess => faceVerification == 'success';
  bool get hasError => error != null || checkOutRecorded == false;

  // Helper method to get user-friendly error message
  String get displayMessage {
    if (error != null) return error!;
    return message;
  }
}
