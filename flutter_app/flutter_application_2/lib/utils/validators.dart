import 'dart:io';
import 'dart:typed_data';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'constants.dart';

class Validators {
  /// Validates employee ID - must be numeric only
  /// Returns null if valid, error message if invalid
  static String? validateEmployeeId(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppConstants.errorNoEmployeeId;
    }

    String trimmedValue = value.trim();

    // Check if it contains only numbers
    if (!RegExp(r'^\d+$').hasMatch(trimmedValue)) {
      return 'Employee ID must contain only numbers';
    }

    // Check reasonable length (1-10 digits)
    if (trimmedValue.length > 10) {
      return 'Employee ID is too long';
    }

    return null; // Valid
  }

  /// Validates time format for late arrival requests
  /// Accepts HH:MM or HH:MM:SS format and validates business hours
  /// Returns null if valid, error message if invalid
  static String? validateTime(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Time is required';
    }

    String trimmedValue = value.trim();

    // Check HH:MM or HH:MM:SS format
    RegExp timeRegex = RegExp(
      r'^([01]?[0-9]|2[0-3]):([0-5][0-9])(:([0-5][0-9]))?$',
    );
    if (!timeRegex.hasMatch(trimmedValue)) {
      return 'Invalid time format. Use HH:MM or HH:MM:SS';
    }

    // Parse time to validate business hours
    try {
      List<String> parts = trimmedValue.split(':');
      int hours = int.parse(parts[0]);
      int minutes = int.parse(parts[1]);

      // Business hours validation (6 AM to 11 PM)
      if (hours < 6 || hours > 23) {
        return 'Time must be between 6:00 AM and 11:00 PM';
      }

      // Additional validation: time should be reasonable for late arrival
      // (typically between 9 AM and 2 PM for late requests)
      if (hours < 9 && minutes < 35 || hours > 14) {
        return 'Late arrival time should be between 9:30 AM and 2:00 PM';
      }
    } catch (e) {
      return 'Invalid time format';
    }

    return null; // Valid
  }

  /// Validates image file size
  /// Returns null if valid, error message if invalid
  static String? validateImageSize(File imageFile) {
    try {
      int fileSizeBytes = imageFile.lengthSync();

      if (fileSizeBytes > AppConstants.maxImageSizeBytes) {
        double fileSizeMB = fileSizeBytes / (1024 * 1024);
        return 'Image size (${fileSizeMB.toStringAsFixed(1)}MB) exceeds 3MB limit';
      }

      return null; // Valid size
    } catch (e) {
      return 'Unable to read image file';
    }
  }

  /// Validates image format (JPEG only)
  /// Returns null if valid, error message if invalid
  static String? validateImageFormat(File imageFile) {
    try {
      String fileName = imageFile.path.toLowerCase();
      String extension = fileName.split('.').last;

      if (!AppConstants.allowedImageFormats.contains(extension)) {
        return AppConstants.errorInvalidImageFormat;
      }

      return null; // Valid format
    } catch (e) {
      return 'Unable to determine image format';
    }
  }

  /// Validates if image file is not corrupted by checking JPEG header
  /// Returns null if valid, error message if invalid
  static String? validateImageIntegrity(File imageFile) {
    try {
      Uint8List bytes = imageFile.readAsBytesSync();

      // Check minimum file size (JPEG should be at least a few KB)
      if (bytes.length < 100) {
        return 'Image file appears to be corrupted or too small';
      }

      // Check JPEG magic numbers (FF D8 at start, FF D9 at end)
      if (bytes.length >= 2) {
        // JPEG files start with 0xFF 0xD8
        if (bytes[0] != 0xFF || bytes[1] != 0xD8) {
          return 'Invalid JPEG file format';
        }
      }

      if (bytes.length >= 4) {
        // JPEG files typically end with 0xFF 0xD9
        int endIndex = bytes.length - 2;
        if (bytes[endIndex] != 0xFF || bytes[endIndex + 1] != 0xD9) {
          // This is a warning, not necessarily corruption
          // Some editing tools might not preserve the proper ending
          // We'll allow it but could log it for debugging
        }
      }

      return null; // Valid integrity
    } catch (e) {
      return 'Unable to verify image integrity: ${e.toString()}';
    }
  }

  /// Comprehensive image validation combining size, format, and integrity
  /// Returns null if valid, error message if invalid
  static String? validateImage(File imageFile) {
    // Check file exists
    if (!imageFile.existsSync()) {
      return 'Image file does not exist';
    }

    // Check format first (fastest check)
    String? formatError = validateImageFormat(imageFile);
    if (formatError != null) return formatError;

    // Check size
    String? sizeError = validateImageSize(imageFile);
    if (sizeError != null) return sizeError;

    // Check integrity (most expensive check)
    String? integrityError = validateImageIntegrity(imageFile);
    if (integrityError != null) return integrityError;

    return null; // All validations passed
  }

  /// Validates network connectivity
  /// Returns null if connected, error message if no connection
  static Future<String?> validateNetworkConnectivity() async {
    try {
      var connectivityResult = await Connectivity().checkConnectivity();

      if (connectivityResult == ConnectivityResult.none) {
        return AppConstants.errorNetworkConnection;
      }

      // Additional check: try to resolve a domain (optional, more thorough)
      try {
        final result = await InternetAddress.lookup('google.com');
        if (result.isEmpty) {
          return 'No internet access available';
        }
      } catch (e) {
        return 'No internet access available';
      }

      return null; // Connected
    } catch (e) {
      return AppConstants.errorNetworkConnection;
    }
  }

  /// Validates if a string is not empty after trimming
  /// Generic validator for required fields
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Validates coordinates (latitude and longitude)
  /// Returns null if valid, error message if invalid
  static String? validateCoordinates(double? latitude, double? longitude) {
    if (latitude == null || longitude == null) {
      return 'Location coordinates are required';
    }

    // Validate latitude range (-90 to +90)
    if (latitude < -90 || latitude > 90) {
      return 'Invalid latitude: must be between -90 and +90';
    }

    // Validate longitude range (-180 to +180)
    if (longitude < -180 || longitude > 180) {
      return 'Invalid longitude: must be between -180 and +180';
    }

    return null; // Valid coordinates
  }

  /// Helper method to format validation errors consistently
  static String formatValidationError(String fieldName, String error) {
    return '$fieldName: $error';
  }
}

/// Extension methods for easy validation on Form fields
extension StringValidation on String? {
  String? get asEmployeeId => Validators.validateEmployeeId(this);
  String? get asTime => Validators.validateTime(this);
  String? asRequired(String fieldName) =>
      Validators.validateRequired(this, fieldName);
}

/// Extension methods for File validation
extension FileValidation on File {
  String? get asValidImage => Validators.validateImage(this);
  String? get imageSizeValidation => Validators.validateImageSize(this);
  String? get imageFormatValidation => Validators.validateImageFormat(this);
  String? get imageIntegrityValidation =>
      Validators.validateImageIntegrity(this);
}
