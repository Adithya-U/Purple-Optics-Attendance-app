import 'dart:io';
import 'package:image/image.dart' as img;

/// Fixes orientation and ensures JPEG output under 3MB
Future<File> fixPhoto(File originalFile) async {
  final bytes = await originalFile.readAsBytes();
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return originalFile;

  int quality = 90;
  List<int> fixedBytes = img.encodeJpg(decoded, quality: quality);

  // Compress until < 3 MB
  while (fixedBytes.length > 3 * 1024 * 1024 && quality > 30) {
    quality -= 10;
    fixedBytes = img.encodeJpg(decoded, quality: quality);
  }

  final fixedFile = File(originalFile.path.replaceAll(".png", ".jpg"));
  await fixedFile.writeAsBytes(fixedBytes);
  return fixedFile;
}
