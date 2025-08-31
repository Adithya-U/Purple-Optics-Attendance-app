// import 'dart:io';
// import 'package:flutter/material.dart';
// import '../services/camera_service.dart';
// import '../services/api_service.dart';

// class UploadReferencePhoto extends StatefulWidget {
//   final String? employeeId;

//   const UploadReferencePhoto({super.key, required this.employeeId});

//   @override
//   State<UploadReferencePhoto> createState() => _UploadReferencePhotoState();
// }

// class _UploadReferencePhotoState extends State<UploadReferencePhoto> {
//   File? _selectedImage;
//   bool _isUploading = false;

//   Future<void> _selectPhoto(PhotoSource source) async {
//     try {
//       final result = await CameraService.selectPhoto(source);

//       if (result.isSuccess && result.imageFile != null) {
//         setState(() {
//           _selectedImage = result.imageFile;
//         });
//       } else if (result.hasError || result.isPermissionDenied) {
//         _showSnackBar(
//           message: result.errorMessage ?? 'Failed to select photo',
//           isError: true,
//         );
//       }
//       // Don't show error for cancelled selections
//     } catch (e) {
//       _showSnackBar(
//         message: 'Failed to select photo: ${e.toString()}',
//         isError: true,
//       );
//     }
//   }

//   Future<void> _uploadPhoto() async {
//     if (_selectedImage == null || widget.employeeId == null) return;

//     setState(() {
//       _isUploading = true;
//     });

//     try {
//       final response = await ApiService.uploadReferencePhoto(
//         employeeId: widget.employeeId!,
//         photo: _selectedImage!,
//       );

//       if (response.isSuccess) {
//         setState(() {
//           _selectedImage = null; // Clear preview after successful upload
//         });
//         _showSnackBar(message: response.displayMessage, isError: false);
//       } else {
//         _showSnackBar(message: response.displayMessage, isError: true);
//       }
//     } catch (e) {
//       _showSnackBar(message: 'Upload failed: ${e.toString()}', isError: true);
//     } finally {
//       setState(() {
//         _isUploading = false;
//       });
//     }
//   }

//   void _showPhotoSourceDialog() {
//     showModalBottomSheet(
//       context: context,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder: (BuildContext context) {
//         return Container(
//           padding: const EdgeInsets.all(20),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               const Text(
//                 'Select Photo Source',
//                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//               ),
//               const SizedBox(height: 20),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                 children: [
//                   _buildSourceOption(
//                     icon: Icons.camera_alt,
//                     label: 'Camera',
//                     onTap: () {
//                       Navigator.pop(context);
//                       _selectPhoto(PhotoSource.camera);
//                     },
//                   ),
//                   _buildSourceOption(
//                     icon: Icons.photo_library,
//                     label: 'Gallery',
//                     onTap: () {
//                       Navigator.pop(context);
//                       _selectPhoto(PhotoSource.gallery);
//                     },
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 20),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildSourceOption({
//     required IconData icon,
//     required String label,
//     required VoidCallback onTap,
//   }) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
//         decoration: BoxDecoration(
//           color: Colors.grey[100],
//           borderRadius: BorderRadius.circular(12),
//           border: Border.all(color: Colors.grey[300]!),
//         ),
//         child: Column(
//           children: [
//             Icon(icon, size: 40, color: Colors.deepPurple[400]),
//             const SizedBox(height: 8),
//             Text(
//               label,
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.w500,
//                 color: Colors.deepPurple[700],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _showSnackBar({required String message, required bool isError}) {
//     if (!mounted) return;

//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: isError ? Colors.red[600] : Colors.green[600],
//         duration: const Duration(seconds: 3),
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//         action: SnackBarAction(
//           label: 'Dismiss',
//           textColor: Colors.white,
//           onPressed: () {
//             ScaffoldMessenger.of(context).hideCurrentSnackBar();
//           },
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final bool isEnabled =
//         widget.employeeId != null && widget.employeeId!.isNotEmpty;

//     return Card(
//       margin: const EdgeInsets.all(16),
//       elevation: 4,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       child: Container(
//         padding: const EdgeInsets.all(20),
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(16),
//           gradient: LinearGradient(
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//             colors: [Colors.deepPurple[50]!, Colors.indigo[50]!],
//           ),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Container(
//                   padding: const EdgeInsets.all(8),
//                   decoration: BoxDecoration(
//                     color: Colors.deepPurple[100],
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: Icon(
//                     Icons.person_add_alt_1,
//                     color: Colors.deepPurple[700],
//                     size: 20,
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 const Text(
//                   'Upload Reference Photo',
//                   style: TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.black87,
//                   ),
//                 ),
//               ],
//             ),

//             if (!isEnabled) ...[
//               const SizedBox(height: 12),
//               Container(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 12,
//                   vertical: 8,
//                 ),
//                 decoration: BoxDecoration(
//                   color: Colors.orange[100],
//                   borderRadius: BorderRadius.circular(8),
//                   border: Border.all(color: Colors.orange[300]!),
//                 ),
//                 child: Row(
//                   children: [
//                     Icon(
//                       Icons.info_outline,
//                       color: Colors.orange[700],
//                       size: 16,
//                     ),
//                     const SizedBox(width: 8),
//                     const Expanded(
//                       child: Text(
//                         'Please enter Employee ID first',
//                         style: TextStyle(fontSize: 12, color: Colors.black87),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],

//             const SizedBox(height: 16),

//             // Image Preview
//             if (_selectedImage != null) ...[
//               Container(
//                 width: double.infinity,
//                 height: 120,
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(12),
//                   border: Border.all(color: Colors.grey[300]!),
//                 ),
//                 child: ClipRRect(
//                   borderRadius: BorderRadius.circular(12),
//                   child: Image.file(_selectedImage!, fit: BoxFit.cover),
//                 ),
//               ),
//               const SizedBox(height: 12),
//               Row(
//                 children: [
//                   Expanded(
//                     child: OutlinedButton.icon(
//                       onPressed: isEnabled && !_isUploading
//                           ? _showPhotoSourceDialog
//                           : null,
//                       icon: const Icon(Icons.refresh),
//                       label: const Text('Change Photo'),
//                       style: OutlinedButton.styleFrom(
//                         foregroundColor: Colors.deepPurple[600],
//                         side: BorderSide(color: Colors.deepPurple[300]!),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 8),
//                   Expanded(
//                     child: ElevatedButton.icon(
//                       onPressed: isEnabled && !_isUploading
//                           ? _uploadPhoto
//                           : null,
//                       icon: _isUploading
//                           ? const SizedBox(
//                               width: 16,
//                               height: 16,
//                               child: CircularProgressIndicator(
//                                 strokeWidth: 2,
//                                 valueColor: AlwaysStoppedAnimation<Color>(
//                                   Colors.white,
//                                 ),
//                               ),
//                             )
//                           : const Icon(Icons.cloud_upload),
//                       label: Text(_isUploading ? 'Uploading...' : 'Upload'),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.deepPurple[600],
//                         foregroundColor: Colors.white,
//                         elevation: 2,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ] else ...[
//               // Select Photo Button
//               SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton.icon(
//                   onPressed: isEnabled ? _showPhotoSourceDialog : null,
//                   icon: const Icon(Icons.add_a_photo),
//                   label: const Text('Select Photo'),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: isEnabled
//                         ? Colors.deepPurple[600]
//                         : Colors.grey[400],
//                     foregroundColor: Colors.white,
//                     padding: const EdgeInsets.symmetric(vertical: 16),
//                     elevation: isEnabled ? 2 : 0,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     // Clean up selected image file if needed
//     super.dispose();
//   }
// }
import 'dart:io';
import 'package:flutter/material.dart';
import '../services/camera_service.dart';
import '../services/api_service.dart';
import '../utils/image_helper.dart'; // ✅ import fixPhoto

class UploadReferencePhoto extends StatefulWidget {
  final String? employeeId;

  const UploadReferencePhoto({super.key, required this.employeeId});

  @override
  State<UploadReferencePhoto> createState() => _UploadReferencePhotoState();
}

class _UploadReferencePhotoState extends State<UploadReferencePhoto> {
  File? _selectedImage;
  bool _isUploading = false;

  Future<void> _selectPhoto(PhotoSource source) async {
    try {
      final result = await CameraService.selectPhoto(source);

      if (result.isSuccess && result.imageFile != null) {
        setState(() {
          _selectedImage = result.imageFile;
        });
      } else if (result.hasError || result.isPermissionDenied) {
        _showSnackBar(
          message: result.errorMessage ?? 'Failed to select photo',
          isError: true,
        );
      }
      // Don't show error for cancelled selections
    } catch (e) {
      _showSnackBar(
        message: 'Failed to select photo: ${e.toString()}',
        isError: true,
      );
    }
  }

  Future<void> _uploadPhoto() async {
    if (_selectedImage == null || widget.employeeId == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      // ✅ Fix orientation + compress before upload
      final fixedPhoto = await fixPhoto(_selectedImage!);

      final response = await ApiService.uploadReferencePhoto(
        employeeId: widget.employeeId!,
        photo: fixedPhoto,
      );

      if (response.isSuccess) {
        setState(() {
          _selectedImage = null; // Clear preview after successful upload
        });
        _showSnackBar(message: response.displayMessage, isError: false);
      } else {
        _showSnackBar(message: response.displayMessage, isError: true);
      }
    } catch (e) {
      _showSnackBar(message: 'Upload failed: ${e.toString()}', isError: true);
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  void _showPhotoSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select Photo Source',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSourceOption(
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    onTap: () {
                      Navigator.pop(context);
                      _selectPhoto(PhotoSource.camera);
                    },
                  ),
                  _buildSourceOption(
                    icon: Icons.photo_library,
                    label: 'Gallery',
                    onTap: () {
                      Navigator.pop(context);
                      _selectPhoto(PhotoSource.gallery);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: Colors.deepPurple[400]),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.deepPurple[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackBar({required String message, required bool isError}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red[600] : Colors.green[600],
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isEnabled =
        widget.employeeId != null && widget.employeeId!.isNotEmpty;

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.deepPurple[50]!, Colors.indigo[50]!],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.person_add_alt_1,
                    color: Colors.deepPurple[700],
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Upload Reference Photo',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),

            if (!isEnabled) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[300]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange[700],
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Please enter Employee ID first',
                        style: TextStyle(fontSize: 12, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Image Preview
            if (_selectedImage != null) ...[
              Container(
                width: double.infinity,
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(_selectedImage!, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: isEnabled && !_isUploading
                          ? _showPhotoSourceDialog
                          : null,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Change Photo'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.deepPurple[600],
                        side: BorderSide(color: Colors.deepPurple[300]!),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isEnabled && !_isUploading
                          ? _uploadPhoto
                          : null,
                      icon: _isUploading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Icon(Icons.cloud_upload),
                      label: Text(_isUploading ? 'Uploading...' : 'Upload'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple[600],
                        foregroundColor: Colors.white,
                        elevation: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              // Select Photo Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isEnabled ? _showPhotoSourceDialog : null,
                  icon: const Icon(Icons.add_a_photo),
                  label: const Text('Select Photo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isEnabled
                        ? Colors.deepPurple[600]
                        : Colors.grey[400],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: isEnabled ? 2 : 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Clean up selected image file if needed
    super.dispose();
  }
}
