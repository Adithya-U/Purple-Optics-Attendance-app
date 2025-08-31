import 'package:flutter/material.dart';

class CheckInResponse {
  final bool match;
  final double? similarity;
  final String faceVerification;
  final String? locationCheck;
  final String? timeCheck;
  final bool attendanceRecorded;
  final String? attendanceStatus;
  final String? checkInTime;
  final String? storeLocation;
  final String message;

  CheckInResponse({
    required this.match,
    this.similarity,
    required this.faceVerification,
    this.locationCheck,
    this.timeCheck,
    required this.attendanceRecorded,
    this.attendanceStatus,
    this.checkInTime,
    this.storeLocation,
    required this.message,
  });

  /// Creates CheckInResponse from JSON response
  factory CheckInResponse.fromJson(Map<String, dynamic> json) {
    return CheckInResponse(
      match: json['match'] ?? false,
      similarity: json['similarity']?.toDouble(),
      faceVerification: json['face_verification'] ?? '',
      locationCheck: json['location_check'],
      timeCheck: json['time_check'],
      attendanceRecorded: json['attendance_recorded'] ?? false,
      attendanceStatus: json['attendance_status'],
      checkInTime: json['check_in_time'],
      storeLocation: json['store_location'],
      message: json['message'] ?? '',
    );
  }

  /// Converts CheckInResponse to JSON
  Map<String, dynamic> toJson() {
    return {
      'match': match,
      'similarity': similarity,
      'face_verification': faceVerification,
      'location_check': locationCheck,
      'time_check': timeCheck,
      'attendance_recorded': attendanceRecorded,
      'attendance_status': attendanceStatus,
      'check_in_time': checkInTime,
      'store_location': storeLocation,
      'message': message,
    };
  }

  /// Creates a copy of CheckInResponse with updated values
  CheckInResponse copyWith({
    bool? match,
    double? similarity,
    String? faceVerification,
    String? locationCheck,
    String? timeCheck,
    bool? attendanceRecorded,
    String? attendanceStatus,
    String? checkInTime,
    String? storeLocation,
    String? message,
  }) {
    return CheckInResponse(
      match: match ?? this.match,
      similarity: similarity ?? this.similarity,
      faceVerification: faceVerification ?? this.faceVerification,
      locationCheck: locationCheck ?? this.locationCheck,
      timeCheck: timeCheck ?? this.timeCheck,
      attendanceRecorded: attendanceRecorded ?? this.attendanceRecorded,
      attendanceStatus: attendanceStatus ?? this.attendanceStatus,
      checkInTime: checkInTime ?? this.checkInTime,
      storeLocation: storeLocation ?? this.storeLocation,
      message: message ?? this.message,
    );
  }

  /// Checks if face verification was successful
  bool get isFaceVerificationSuccess {
    return faceVerification.toLowerCase() == 'success';
  }

  /// Checks if location check was successful
  bool get isLocationCheckSuccess {
    return locationCheck?.toLowerCase() == 'success';
  }

  /// Checks if time check was on time
  bool get isOnTime {
    return timeCheck?.toLowerCase() == 'on_time';
  }

  /// Checks if time check was late but approved
  bool get isLateWithApproval {
    return timeCheck?.toLowerCase() == 'late_with_approval';
  }

  /// Checks if time check was late without approval
  bool get isLateWithoutApproval {
    return timeCheck?.toLowerCase() == 'late_without_approval';
  }

  /// Checks if check-in was completely successful
  bool get isCheckInSuccessful {
    return attendanceRecorded &&
        isFaceVerificationSuccess &&
        (isLocationCheckSuccess || locationCheck == null) &&
        (isOnTime || isLateWithApproval);
  }

  /// Gets formatted similarity percentage
  String get similarityPercentage {
    if (similarity == null) return 'N/A';
    return '${(similarity! * 100).toStringAsFixed(1)}%';
  }

  /// Gets formatted check-in time for display
  String? get formattedCheckInTime {
    if (checkInTime == null) return null;
    try {
      // Handle time format from API (HH:MM:SS or HH:MM)
      final parts = checkInTime!.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return checkInTime;
    }
  }

  /// Gets display-friendly attendance status
  String get attendanceStatusDisplay {
    switch (attendanceStatus?.toLowerCase()) {
      case 'present':
        return 'Present';
      case 'late':
        return 'Late';
      case 'absent':
        return 'Absent';
      default:
        return attendanceStatus ?? 'Unknown';
    }
  }

  /// Gets face verification status display text
  String get faceVerificationDisplay {
    switch (faceVerification.toLowerCase()) {
      case 'success':
        return 'Face Verified Successfully';
      case 'failed':
        return 'Face Verification Failed';
      case 'no_face_detected':
        return 'No Face Detected';
      case 'employee_not_found':
        return 'Employee Not Found';
      case 'verification_service_error':
        return 'Verification Service Error';
      default:
        return faceVerification;
    }
  }

  /// Gets location check status display text
  String get locationCheckDisplay {
    switch (locationCheck?.toLowerCase()) {
      case 'success':
        return 'Location Verified';
      case 'too_far_from_store':
        return 'Too Far from Store';
      case null:
        return 'Location Not Checked';
      default:
        return locationCheck!;
    }
  }

  /// Gets time check status display text
  String get timeCheckDisplay {
    switch (timeCheck?.toLowerCase()) {
      case 'on_time':
        return 'On Time';
      case 'late_with_approval':
        return 'Late (Approved)';
      case 'late_without_approval':
        return 'Late (Not Approved)';
      case null:
        return 'Time Not Checked';
      default:
        return timeCheck!;
    }
  }

  /// Gets overall result color for UI display
  Color get resultColor {
    if (isCheckInSuccessful) {
      return Colors.green;
    } else if (!isFaceVerificationSuccess) {
      return Colors.red;
    } else if (!isLocationCheckSuccess) {
      return Colors.orange;
    } else if (isLateWithoutApproval) {
      return Colors.amber;
    } else {
      return Colors.grey;
    }
  }

  /// Gets result icon for UI display
  IconData get resultIcon {
    if (isCheckInSuccessful) {
      return Icons.check_circle;
    } else if (!isFaceVerificationSuccess) {
      return Icons.face_retouching_off;
    } else if (!isLocationCheckSuccess) {
      return Icons.location_off;
    } else if (isLateWithoutApproval) {
      return Icons.schedule_outlined;
    } else {
      return Icons.error_outline;
    }
  }

  /// Gets a summary of what went wrong (if anything)
  List<String> get issues {
    List<String> issues = [];

    if (!isFaceVerificationSuccess) {
      issues.add('Face verification failed');
    }

    if (locationCheck != null && !isLocationCheckSuccess) {
      issues.add('Location check failed');
    }

    if (timeCheck != null && isLateWithoutApproval) {
      issues.add('Late arrival without approval');
    }

    if (!attendanceRecorded) {
      issues.add('Attendance was not recorded');
    }

    return issues;
  }

  /// Checks if there are any issues with the check-in
  bool get hasIssues {
    return issues.isNotEmpty;
  }

  /// Gets the primary issue (most important one to show)
  String? get primaryIssue {
    if (issues.isEmpty) return null;
    return issues.first;
  }

  /// Gets detailed verification steps for debugging/display
  Map<String, Map<String, dynamic>> get verificationSteps {
    return {
      'face_verification': {
        'status': faceVerification,
        'success': isFaceVerificationSuccess,
        'similarity': similarity,
        'display': faceVerificationDisplay,
      },
      'location_check': {
        'status': locationCheck,
        'success': isLocationCheckSuccess,
        'display': locationCheckDisplay,
      },
      'time_check': {
        'status': timeCheck,
        'success': isOnTime || isLateWithApproval,
        'display': timeCheckDisplay,
      },
    };
  }

  @override
  String toString() {
    return 'CheckInResponse{match: $match, faceVerification: $faceVerification, attendanceRecorded: $attendanceRecorded, message: $message}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CheckInResponse &&
        other.match == match &&
        other.similarity == similarity &&
        other.faceVerification == faceVerification &&
        other.locationCheck == locationCheck &&
        other.timeCheck == timeCheck &&
        other.attendanceRecorded == attendanceRecorded &&
        other.attendanceStatus == attendanceStatus &&
        other.checkInTime == checkInTime &&
        other.storeLocation == storeLocation &&
        other.message == message;
  }

  @override
  int get hashCode {
    return Object.hash(
      match,
      similarity,
      faceVerification,
      locationCheck,
      timeCheck,
      attendanceRecorded,
      attendanceStatus,
      checkInTime,
      storeLocation,
      message,
    );
  }
}
