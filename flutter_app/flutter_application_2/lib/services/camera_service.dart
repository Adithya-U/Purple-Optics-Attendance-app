import 'dart:io';
import 'package:image_picker/image_picker.dart';

enum PhotoSource { camera, gallery }

enum CameraStatus { ready, taking, success, error, cancelled, permissionDenied }

class CameraResult {
  final File? imageFile;
  final CameraStatus status;
  final String? errorMessage;

  CameraResult({this.imageFile, required this.status, this.errorMessage});

  bool get isSuccess => status == CameraStatus.success && imageFile != null;
  bool get hasError => status == CameraStatus.error;
  bool get wasCancelled => status == CameraStatus.cancelled;
  bool get isPermissionDenied => status == CameraStatus.permissionDenied;
}

class CameraService {
  static final ImagePicker _picker = ImagePicker();

  /// Takes photo using camera only (for check-in/check-out)
  /// Returns CameraResult with image file and status
  static Future<CameraResult> takePhotoFromCamera() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality:
            100, // Keep original quality, compression handled by ImageService
        preferredCameraDevice: CameraDevice.front, // Front camera for selfies
      );

      if (photo == null) {
        return CameraResult(
          status: CameraStatus.cancelled,
          errorMessage: 'Photo capture cancelled',
        );
      }

      File imageFile = File(photo.path);

      // Validate file exists
      if (!await imageFile.exists()) {
        return CameraResult(
          status: CameraStatus.error,
          errorMessage: 'Failed to save photo',
        );
      }

      return CameraResult(imageFile: imageFile, status: CameraStatus.success);
    } catch (e) {
      // Handle specific error types
      if (e.toString().contains('camera_access_denied') ||
          e.toString().contains('permission')) {
        return CameraResult(
          status: CameraStatus.permissionDenied,
          errorMessage: 'Camera permission denied',
        );
      }

      return CameraResult(
        status: CameraStatus.error,
        errorMessage: 'Failed to take photo: ${e.toString()}',
      );
    }
  }

  /// Selects photo from camera or gallery (for reference photo upload)
  /// Returns CameraResult with image file and status
  static Future<CameraResult> selectPhoto(PhotoSource source) async {
    try {
      ImageSource imageSource = source == PhotoSource.camera
          ? ImageSource.camera
          : ImageSource.gallery;

      final XFile? photo = await _picker.pickImage(
        source: imageSource,
        imageQuality: 100, // Keep original quality
        preferredCameraDevice: source == PhotoSource.camera
            ? CameraDevice.front
            : CameraDevice.rear, // Use rear as default instead of null
      );

      if (photo == null) {
        return CameraResult(
          status: CameraStatus.cancelled,
          errorMessage: source == PhotoSource.camera
              ? 'Photo capture cancelled'
              : 'Photo selection cancelled',
        );
      }

      File imageFile = File(photo.path);

      // Validate file exists
      if (!await imageFile.exists()) {
        return CameraResult(
          status: CameraStatus.error,
          errorMessage: 'Failed to get photo file',
        );
      }

      return CameraResult(imageFile: imageFile, status: CameraStatus.success);
    } catch (e) {
      // Handle specific error types
      if (e.toString().contains('camera_access_denied') ||
          e.toString().contains('photo_access_denied') ||
          e.toString().contains('permission')) {
        String permissionType = source == PhotoSource.camera
            ? 'Camera'
            : 'Photo library';
        return CameraResult(
          status: CameraStatus.permissionDenied,
          errorMessage: '$permissionType permission denied',
        );
      }

      String action = source == PhotoSource.camera
          ? 'take photo'
          : 'select photo';
      return CameraResult(
        status: CameraStatus.error,
        errorMessage: 'Failed to $action: ${e.toString()}',
      );
    }
  }

  /// Shows photo selection bottom sheet (camera vs gallery)
  /// Used for reference photo upload
  static Future<CameraResult> showPhotoSelectionDialog() async {
    // This method would typically show a dialog in the UI layer
    // For now, it returns a helper method to be implemented in the UI
    throw UnimplementedError(
      'showPhotoSelectionDialog should be implemented in the UI layer',
    );
  }

  /// Checks if camera is available on device
  static Future<bool> isCameraAvailable() async {
    try {
      // Try to pick an image to test camera availability
      return true; // ImagePicker handles availability internally
    } catch (e) {
      return false;
    }
  }

  /// Gets user-friendly status message for UI display
  static String getStatusMessage(CameraStatus status) {
    switch (status) {
      case CameraStatus.ready:
        return 'Ready to take photo';
      case CameraStatus.taking:
        return 'Taking photo...';
      case CameraStatus.success:
        return 'Photo captured successfully';
      case CameraStatus.error:
        return 'Failed to capture photo';
      case CameraStatus.cancelled:
        return 'Photo capture cancelled';
      case CameraStatus.permissionDenied:
        return 'Camera permission required';
    }
  }

  /// Validates image file before processing
  static Future<bool> isValidImageFile(File imageFile) async {
    try {
      // Check if file exists
      if (!await imageFile.exists()) {
        return false;
      }

      // Check file size (basic validation)
      int fileSize = await imageFile.length();
      if (fileSize == 0) {
        return false;
      }

      // Check file extension
      String extension = imageFile.path.toLowerCase();
      return extension.endsWith('.jpg') ||
          extension.endsWith('.jpeg') ||
          extension.endsWith('.png');
    } catch (e) {
      return false;
    }
  }

  /// Cleanup temporary image files
  static Future<void> cleanupTempImages() async {
    try {
      // Image picker usually handles cleanup automatically
      // But we can implement custom cleanup if needed
    } catch (e) {
      // Ignore cleanup errors
    }
  }
}
