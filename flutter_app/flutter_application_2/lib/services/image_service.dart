import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ImageService {
  static const int maxSizeBytes = 3 * 1024 * 1024; // 3MB in bytes
  static const int initialQuality = 85;
  static const int minQuality = 20;
  static const int qualityStep = 10;

  /// Processes image file to meet 3MB limit
  /// Option 2: Compress only if over 3MB
  /// Images under 3MB stay original quality
  /// Images over 3MB get compressed until they're under 3MB
  static Future<File> processImage(File imageFile) async {
    try {
      // Check original file size
      int originalSize = await imageFile.length();

      // If under 3MB, return original file
      if (originalSize <= maxSizeBytes) {
        return imageFile;
      }

      // File is over 3MB, need to compress
      return await _compressImage(imageFile);
    } catch (e) {
      throw Exception('Failed to process image: $e');
    }
  }

  /// Compresses image until it's under 3MB
  static Future<File> _compressImage(File imageFile) async {
    try {
      // Read and decode the image
      Uint8List imageBytes = await imageFile.readAsBytes();
      img.Image? image = img.decodeImage(imageBytes);

      if (image == null) {
        throw Exception('Could not decode image');
      }

      // Start with initial quality and reduce until under 3MB
      int currentQuality = initialQuality;
      Uint8List? compressedBytes;

      while (currentQuality >= minQuality) {
        // Encode image with current quality
        compressedBytes = img.encodeJpg(image, quality: currentQuality);

        // Check if size is now under 3MB
        if (compressedBytes.length <= maxSizeBytes) {
          break;
        }

        // Reduce quality for next iteration
        currentQuality -= qualityStep;
      }

      // If still over 3MB even at minimum quality, resize the image
      if (compressedBytes == null || compressedBytes.length > maxSizeBytes) {
        compressedBytes = await _resizeAndCompress(image);
      }

      // Save compressed image to temporary file
      return await _saveCompressedImage(compressedBytes, imageFile);
    } catch (e) {
      throw Exception('Failed to compress image: $e');
    }
  }

  /// Resize image and compress if quality reduction isn't enough
  static Future<Uint8List> _resizeAndCompress(img.Image image) async {
    // Calculate new dimensions (reduce by 20% each iteration)
    int newWidth = (image.width * 0.8).round();
    int newHeight = (image.height * 0.8).round();

    // Keep resizing until under 3MB or minimum size reached
    while (newWidth > 300 && newHeight > 300) {
      img.Image resizedImage = img.copyResize(
        image,
        width: newWidth,
        height: newHeight,
      );

      Uint8List compressedBytes = img.encodeJpg(
        resizedImage,
        quality: minQuality,
      );

      if (compressedBytes.length <= maxSizeBytes) {
        return compressedBytes;
      }

      // Reduce dimensions for next iteration
      newWidth = (newWidth * 0.8).round();
      newHeight = (newHeight * 0.8).round();
    }

    // Final attempt with minimum dimensions
    img.Image finalImage = img.copyResize(
      image,
      width: newWidth,
      height: newHeight,
    );

    return img.encodeJpg(finalImage, quality: minQuality);
  }

  /// Saves compressed image bytes to a temporary file
  static Future<File> _saveCompressedImage(
    Uint8List imageBytes,
    File originalFile,
  ) async {
    try {
      // Get temporary directory
      Directory tempDir = await getTemporaryDirectory();

      // Create unique filename with timestamp
      String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      String originalName = path.basenameWithoutExtension(originalFile.path);
      String compressedPath = path.join(
        tempDir.path,
        '${originalName}_compressed_$timestamp.jpg',
      );

      // Write compressed bytes to file
      File compressedFile = File(compressedPath);
      await compressedFile.writeAsBytes(imageBytes);

      return compressedFile;
    } catch (e) {
      throw Exception('Failed to save compressed image: $e');
    }
  }

  /// Gets image file size in bytes
  static Future<int> getImageSize(File imageFile) async {
    try {
      return await imageFile.length();
    } catch (e) {
      throw Exception('Failed to get image size: $e');
    }
  }

  /// Gets human-readable file size string
  static String getFileSizeString(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  /// Validates if file is a valid image
  static Future<bool> isValidImage(File imageFile) async {
    try {
      Uint8List imageBytes = await imageFile.readAsBytes();
      img.Image? image = img.decodeImage(imageBytes);
      return image != null;
    } catch (e) {
      return false;
    }
  }

  /// Cleans up temporary compressed files
  static Future<void> cleanupTempFiles() async {
    try {
      Directory tempDir = await getTemporaryDirectory();

      // Find and delete compressed image files
      await for (FileSystemEntity entity in tempDir.list()) {
        if (entity is File &&
            entity.path.contains('_compressed_') &&
            entity.path.endsWith('.jpg')) {
          try {
            await entity.delete();
          } catch (e) {
            // Ignore errors for individual file deletions
          }
        }
      }
    } catch (e) {
      // Ignore cleanup errors
    }
  }
}
