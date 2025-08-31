import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';
import 'constants.dart';

class Helpers {
  /// Formats date/time in 24-hour format
  static String formatTime24(DateTime dateTime) {
    return DateFormat('HH:mm').format(dateTime);
  }

  /// Formats date in YYYY-MM-DD format
  static String formatDate(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd').format(dateTime);
  }

  /// Formats datetime for API (ISO format with current timezone)
  static String formatDateTimeForApi(DateTime dateTime) {
    return DateFormat("yyyy-MM-ddTHH:mm:ss").format(dateTime);
  }

  /// Gets current timestamp in ISO format for API
  static String getCurrentTimestamp() {
    return formatDateTimeForApi(DateTime.now());
  }

  /// Displays relative time (e.g., "2 hours ago", "Today at 15:30")
  static String getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    final today = DateTime(now.year, now.month, now.day);
    final inputDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (inputDate == today) {
      // Same day - show "Today at HH:MM"
      return "Today at ${formatTime24(dateTime)}";
    } else if (inputDate == today.subtract(Duration(days: 1))) {
      // Yesterday
      return "Yesterday at ${formatTime24(dateTime)}";
    } else if (difference.inDays < 7) {
      // Within a week - show day name
      return "${DateFormat('EEEE').format(dateTime)} at ${formatTime24(dateTime)}";
    } else if (difference.inDays < 30) {
      // Within a month - show "X days ago"
      return "${difference.inDays} days ago";
    } else {
      // Older - show full date
      return DateFormat('dd MMM yyyy').format(dateTime);
    }
  }

  /// Parses API timestamp string to DateTime
  static DateTime? parseApiTimestamp(String? timestamp) {
    if (timestamp == null || timestamp.isEmpty) return null;

    try {
      // Handle various timestamp formats from API
      if (timestamp.contains('T')) {
        // ISO format: 2025-08-21T17:30:00
        return DateTime.parse(timestamp);
      } else if (timestamp.contains(' ')) {
        // Space format: 2025-08-21 17:30:00
        return DateTime.parse(timestamp.replaceFirst(' ', 'T'));
      } else {
        // Time only format: 17:30:00
        final now = DateTime.now();
        final timeParts = timestamp.split(':');
        return DateTime(
          now.year,
          now.month,
          now.day,
          int.parse(timeParts[0]),
          int.parse(timeParts[1]),
          timeParts.length > 2 ? int.parse(timeParts[2]) : 0,
        );
      }
    } catch (e) {
      debugPrint('Error parsing timestamp: $timestamp - $e');
      return null;
    }
  }

  /// Compresses image if it exceeds 3MB limit
  /// Returns compressed image file or original if under limit
  static Future<File?> processImageForUpload(File originalFile) async {
    try {
      // Check current file size
      int originalSizeBytes = await originalFile.length();

      // If under 3MB, return original file
      if (originalSizeBytes <= AppConstants.maxImageSizeBytes) {
        debugPrint(
          'Image size OK: ${(originalSizeBytes / 1024 / 1024).toStringAsFixed(2)}MB',
        );
        return originalFile;
      }

      debugPrint(
        'Image too large: ${(originalSizeBytes / 1024 / 1024).toStringAsFixed(2)}MB, compressing...',
      );

      // Read and decode image
      Uint8List imageBytes = await originalFile.readAsBytes();
      img.Image? image = img.decodeImage(imageBytes);

      if (image == null) {
        debugPrint('Failed to decode image');
        return null;
      }

      // Compress with 85% quality
      Uint8List compressedBytes = img.encodeJpg(
        image,
        quality: AppConstants.imageCompressionQuality,
      );

      // Check if compression was enough
      if (compressedBytes.length > AppConstants.maxImageSizeBytes) {
        debugPrint(
          'Image still too large after compression: ${(compressedBytes.length / 1024 / 1024).toStringAsFixed(2)}MB',
        );
        return null; // Still too large, reject
      }

      // Save compressed image to temporary file
      String originalPath = originalFile.path;
      String directory = originalPath.substring(
        0,
        originalPath.lastIndexOf('/'),
      );
      String fileName =
          'compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';
      String newPath = '$directory/$fileName';

      File compressedFile = File(newPath);
      await compressedFile.writeAsBytes(compressedBytes);

      debugPrint(
        'Image compressed successfully: ${(compressedBytes.length / 1024 / 1024).toStringAsFixed(2)}MB',
      );
      return compressedFile;
    } catch (e) {
      debugPrint('Error processing image: $e');
      return null;
    }
  }

  /// Shows success toast message
  static void showSuccessToast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppConstants.successColor,
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Shows error toast message
  static void showErrorToast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppConstants.errorColor,
        duration: Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Shows warning toast message
  static void showWarningToast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.warning, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppConstants.warningColor,
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Shows info toast message
  static void showInfoToast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.info, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppConstants.primaryColor,
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Extracts error message from API response
  static String extractErrorMessage(dynamic error) {
    if (error == null) return AppConstants.errorUnknown;

    // If it's already a string
    if (error is String) return error;

    // If it's a Map (JSON response)
    if (error is Map<String, dynamic>) {
      // Try common error field names
      if (error.containsKey('error')) {
        return error['error'].toString();
      }
      if (error.containsKey('message')) {
        return error['message'].toString();
      }
      if (error.containsKey('details')) {
        return error['details'].toString();
      }
    }

    return AppConstants.errorUnknown;
  }

  /// Validates phone number (10 digits)
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }

    String cleanNumber = value.replaceAll(
      RegExp(r'[^\d]'),
      '',
    ); // Remove non-digits

    if (cleanNumber.length != 10) {
      return 'Phone number must be exactly 10 digits';
    }

    return null; // Valid
  }

  /// Formats phone number for display (XXX-XXX-XXXX)
  static String formatPhoneNumber(String phoneNumber) {
    String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanNumber.length == 10) {
      return '${cleanNumber.substring(0, 3)}-${cleanNumber.substring(3, 6)}-${cleanNumber.substring(6)}';
    }
    return phoneNumber; // Return original if not 10 digits
  }

  /// Converts coordinates to string format for API
  static String formatCoordinate(double coordinate) {
    return coordinate.toStringAsFixed(6); // 6 decimal places for good precision
  }

  /// Calculates file size in human readable format
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Capitalizes first letter of each word
  static String capitalizeWords(String text) {
    return text
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }

  /// Truncates text to specified length with ellipsis
  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  /// Shows loading dialog
  static void showLoadingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }

  /// Hides loading dialog
  static void hideLoadingDialog(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }

  /// Checks if string represents a valid integer
  static bool isValidInteger(String? value) {
    if (value == null || value.trim().isEmpty) return false;
    return int.tryParse(value.trim()) != null;
  }

  /// Formats employee ID for display (adds "E" prefix if numeric)
  static String formatEmployeeIdForDisplay(String employeeId) {
    // If it's just numbers, add "E" prefix for display
    if (isValidInteger(employeeId)) {
      return 'E$employeeId';
    }
    return employeeId;
  }

  /// Clean up temporary files
  static Future<void> cleanupTempFiles(List<String> filePaths) async {
    for (String path in filePaths) {
      try {
        File file = File(path);
        if (await file.exists()) {
          await file.delete();
          debugPrint('Cleaned up temp file: $path');
        }
      } catch (e) {
        debugPrint('Error cleaning up file $path: $e');
      }
    }
  }
}

/// Extension methods for easy usage
extension StringHelper on String? {
  String? get asPhoneNumber => Helpers.validatePhoneNumber(this);
  String get capitalized => this != null ? Helpers.capitalizeWords(this!) : '';
  String truncate(int maxLength) =>
      this != null ? Helpers.truncateText(this!, maxLength) : '';
}

extension DateTimeHelper on DateTime {
  String get relativeTime => Helpers.getRelativeTime(this);
  String get time24 => Helpers.formatTime24(this);
  String get apiFormat => Helpers.formatDateTimeForApi(this);
}
