class UploadPhotoResponse {
  final String message;
  final String? photoPath;
  final String? error;

  UploadPhotoResponse({required this.message, this.photoPath, this.error});

  factory UploadPhotoResponse.fromJson(Map<String, dynamic> json) {
    return UploadPhotoResponse(
      message: json['message'] as String? ?? '',
      photoPath: json['photo_path'] as String?,
      error: json['error'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {'message': message, 'photo_path': photoPath, 'error': error};
  }

  // Helper methods for easy status checking
  bool get isSuccess => error == null && photoPath != null;
  bool get hasError => error != null;

  // Helper method to get user-friendly message
  String get displayMessage {
    if (error != null) return error!;
    return message;
  }

  // Helper method to check if photo was successfully stored
  bool get photoUploaded => photoPath != null && photoPath!.isNotEmpty;
}
