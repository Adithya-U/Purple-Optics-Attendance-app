import 'package:flutter/material.dart';

class AppConstants {
  // App Information
  static const String appName = 'Purple Optics';

  // Colors
  static const Color primaryColor = Colors.purple;
  static const Color primaryLightColor = Color(0xFFE1BEE7);
  static const Color primaryDarkColor = Color(0xFF7B1FA2);
  static const Color successColor = Colors.green;
  static const Color errorColor = Colors.red;
  static const Color warningColor = Colors.orange;
  static const Color backgroundColor = Colors.white;
  static const Color surfaceColor = Color(0xFFF5F5F5);

  // Text Styles
  static const TextStyle titleTextStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: primaryColor,
  );

  static const TextStyle headingTextStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: Colors.black87,
  );

  static const TextStyle bodyTextStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: Colors.black87,
  );

  static const TextStyle captionTextStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: Colors.black54,
  );

  static const TextStyle buttonTextStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  // API Configuration
  static const String baseUrl = 'http://192.168.29.47:5000';
  static const String apiEmployeeStatus = '/api/employee-status';
  static const String apiCheckIn = '/check_in';
  static const String apiCheckOut = '/api/check-out-verify';
  static const String apiUploadPhoto = '/upload_photo';
  static const String apiSubmitLateRequest = '/api/submit-late-request';

  // Timeouts
  static const int apiTimeoutSeconds = 5;
  static const int locationTimeoutSeconds = 15;

  // Location
  static const double defaultLatitude = 12.97828301152951;
  static const double defaultLongitude = 80.13844783758844;
  static const double locationAccuracyMeters = 10.0;

  // Image Configuration
  static const int maxImageSizeBytes = 3 * 1024 * 1024; // 3MB
  static const int imageCompressionQuality = 85; // 85% quality
  static const List<String> allowedImageFormats = ['jpg', 'jpeg'];

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double borderRadius = 8.0;
  static const double buttonHeight = 48.0;
  static const double inputFieldHeight = 56.0;

  // Face Verification
  static const double minFaceSimilarity = 0.9; // 90%
  static const double maxDistanceFromStore = 50.0; // 50 meters

  // Messages
  static const String msgLoading = 'Loading...';
  static const String msgGettingLocation = 'Getting your location...';
  static const String msgUploadingPhoto = 'Uploading photo...';
  static const String msgVerifyingFace = 'Verifying face...';
  static const String msgProcessingCheckIn = 'Processing check-in...';
  static const String msgProcessingCheckOut = 'Processing check-out...';
  static const String msgSubmittingRequest = 'Submitting request...';

  // Error Messages
  static const String errorNoEmployeeId = 'Please enter your Employee ID';
  static const String errorInvalidEmployeeId = 'Invalid Employee ID format';
  static const String errorNoPhoto = 'Please take a photo';
  static const String errorPhotoTooLarge = 'Photo size must be less than 3MB';
  static const String errorInvalidImageFormat = 'Please use JPG format only';
  static const String errorLocationPermission = 'Location permission required';
  static const String errorCameraPermission = 'Camera permission required';
  static const String errorNetworkConnection =
      'Please check your internet connection';
  static const String errorServerUnavailable =
      'Server is currently unavailable';
  static const String errorUnknown = 'Something went wrong. Please try again.';

  // Success Messages
  static const String successPhotoUploaded =
      'Reference photo uploaded successfully';
  static const String successCheckIn = 'Check-in successful';
  static const String successCheckOut = 'Check-out successful';
  static const String successLateRequestSubmitted =
      'Late arrival request submitted';

  // Button Labels
  static const String btnCheckStatus = 'Check Status';
  static const String btnCheckIn = 'Check In';
  static const String btnCheckOut = 'Check Out';
  static const String btnSubmitLateRequest = 'Submit Late Request';
  static const String btnUploadReferencePhoto = 'Upload Reference Photo';
  static const String btnRefresh = 'Refresh';
  static const String btnTakePhoto = 'Take Photo';
  static const String btnChooseFromGallery = 'Choose from Gallery';
  static const String btnSubmit = 'Submit';
  static const String btnCancel = 'Cancel';

  // Input Labels
  static const String labelEmployeeId = 'Employee ID';
  static const String labelArrivalTime = 'Expected Arrival Time';
  static const String hintEmployeeId = 'Enter your Employee ID (e.g., E123)';
  static const String hintArrivalTime = 'Select time';

  // Status Messages
  static const String statusPresent = 'Present';
  static const String statusAbsent = 'Absent';
  static const String statusLate = 'Late';
  static const String statusPending = 'Pending Approval';
  static const String statusApproved = 'Approved';
  static const String statusRejected = 'Rejected';

  // Time Format
  static const String timeFormat24 = 'HH:mm';
  static const String timeFormat12 = 'hh:mm a';
  static const String dateFormat = 'yyyy-MM-dd';
  static const String dateTimeFormat = 'yyyy-MM-dd HH:mm:ss';
}
