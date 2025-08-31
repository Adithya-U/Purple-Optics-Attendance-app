import 'package:flutter/material.dart';

class EmployeeStatus {
  final bool success;
  final String employeeName;
  final String action;
  final String? currentStatus;
  final String? checkInTime;
  final String? checkOutTime;
  final String? currentTime;
  final int? requestId;
  final String? requestedAt;
  final bool? lateApproval;
  final String message;

  EmployeeStatus({
    required this.success,
    required this.employeeName,
    required this.action,
    this.currentStatus,
    this.checkInTime,
    this.checkOutTime,
    this.currentTime,
    this.requestId,
    this.requestedAt,
    this.lateApproval,
    required this.message,
  });

  /// Creates EmployeeStatus from JSON response
  factory EmployeeStatus.fromJson(Map<String, dynamic> json) {
    return EmployeeStatus(
      success: json['success'] ?? false,
      employeeName: json['employee_name'] ?? '',
      action: json['action'] ?? '',
      currentStatus: json['current_status'],
      checkInTime: json['check_in_time'],
      checkOutTime: json['check_out_time'],
      currentTime: json['current_time'],
      requestId: json['request_id'],
      requestedAt: json['requested_at'],
      lateApproval: json['late_approval'],
      message: json['message'] ?? '',
    );
  }

  /// Converts EmployeeStatus to JSON
  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'employee_name': employeeName,
      'action': action,
      'current_status': currentStatus,
      'check_in_time': checkInTime,
      'check_out_time': checkOutTime,
      'current_time': currentTime,
      'request_id': requestId,
      'requested_at': requestedAt,
      'late_approval': lateApproval,
      'message': message,
    };
  }

  /// Creates a copy of EmployeeStatus with updated values
  EmployeeStatus copyWith({
    bool? success,
    String? employeeName,
    String? action,
    String? currentStatus,
    String? checkInTime,
    String? checkOutTime,
    String? currentTime,
    int? requestId,
    String? requestedAt,
    bool? lateApproval,
    String? message,
  }) {
    return EmployeeStatus(
      success: success ?? this.success,
      employeeName: employeeName ?? this.employeeName,
      action: action ?? this.action,
      currentStatus: currentStatus ?? this.currentStatus,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      currentTime: currentTime ?? this.currentTime,
      requestId: requestId ?? this.requestId,
      requestedAt: requestedAt ?? this.requestedAt,
      lateApproval: lateApproval ?? this.lateApproval,
      message: message ?? this.message,
    );
  }

  /// Checks if employee can check in
  bool get canCheckIn {
    return action == 'check_in';
  }

  /// Checks if employee can check out
  bool get canCheckOut {
    return action == 'check_out';
  }

  /// Checks if employee needs to submit late arrival request
  bool get needsLateRequest {
    return action == 'late_arrival_request';
  }

  /// Checks if employee has already completed attendance for the day
  bool get hasCompletedDay {
    return action == 'already_completed';
  }

  /// Checks if employee is waiting for late request approval
  bool get isWaitingForApproval {
    return action == 'wait_for_approval';
  }

  /// Checks if late request was rejected
  bool get isRequestRejected {
    return action == 'request_rejected';
  }

  /// Gets display-friendly status text
  String get statusDisplayText {
    switch (currentStatus?.toLowerCase()) {
      case 'present':
        return 'Present';
      case 'absent':
        return 'Absent';
      case 'late':
        return 'Late';
      default:
        return currentStatus ?? 'Unknown';
    }
  }

  /// Gets action display text for UI buttons
  String get actionDisplayText {
    switch (action) {
      case 'check_in':
        return 'Ready to Check In';
      case 'check_out':
        return 'Ready to Check Out';
      case 'late_arrival_request':
        return 'Submit Late Request';
      case 'already_completed':
        return 'Completed for Today';
      case 'wait_for_approval':
        return 'Waiting for Approval';
      case 'request_rejected':
        return 'Request Rejected';
      default:
        return action;
    }
  }

  /// Gets the primary action color for UI
  Color get actionColor {
    switch (action) {
      case 'check_in':
        return Colors.green;
      case 'check_out':
        return Colors.blue;
      case 'late_arrival_request':
        return Colors.orange;
      case 'already_completed':
        return Colors.grey;
      case 'wait_for_approval':
        return Colors.amber;
      case 'request_rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Gets appropriate icon for the current action
  IconData get actionIcon {
    switch (action) {
      case 'check_in':
        return Icons.login;
      case 'check_out':
        return Icons.logout;
      case 'late_arrival_request':
        return Icons.schedule;
      case 'already_completed':
        return Icons.check_circle;
      case 'wait_for_approval':
        return Icons.hourglass_empty;
      case 'request_rejected':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  /// Checks if employee is currently checked in (present but not checked out)
  bool get isCurrentlyCheckedIn {
    return currentStatus?.toLowerCase() == 'present' && checkOutTime == null;
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

  /// Gets formatted check-out time for display
  String? get formattedCheckOutTime {
    if (checkOutTime == null) return null;
    try {
      // Handle time format from API (HH:MM:SS or HH:MM)
      final parts = checkOutTime!.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return checkOutTime;
    }
  }

  /// Gets work duration if both check-in and check-out times are available
  String? get workDuration {
    if (checkInTime == null || checkOutTime == null) return null;

    try {
      final checkInParts = checkInTime!.split(':');
      final checkOutParts = checkOutTime!.split(':');

      final checkInMinutes =
          int.parse(checkInParts[0]) * 60 + int.parse(checkInParts[1]);
      final checkOutMinutes =
          int.parse(checkOutParts[0]) * 60 + int.parse(checkOutParts[1]);

      final durationMinutes = checkOutMinutes - checkInMinutes;
      if (durationMinutes < 0) return null; // Invalid duration

      final hours = durationMinutes ~/ 60;
      final minutes = durationMinutes % 60;

      if (hours == 0) {
        return '${minutes}m';
      } else if (minutes == 0) {
        return '${hours}h';
      } else {
        return '${hours}h ${minutes}m';
      }
    } catch (e) {
      return null;
    }
  }

  @override
  String toString() {
    return 'EmployeeStatus{success: $success, employeeName: $employeeName, action: $action, currentStatus: $currentStatus, message: $message}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EmployeeStatus &&
        other.success == success &&
        other.employeeName == employeeName &&
        other.action == action &&
        other.currentStatus == currentStatus &&
        other.checkInTime == checkInTime &&
        other.checkOutTime == checkOutTime &&
        other.requestId == requestId &&
        other.message == message;
  }

  @override
  int get hashCode {
    return Object.hash(
      success,
      employeeName,
      action,
      currentStatus,
      checkInTime,
      checkOutTime,
      requestId,
      message,
    );
  }
}
