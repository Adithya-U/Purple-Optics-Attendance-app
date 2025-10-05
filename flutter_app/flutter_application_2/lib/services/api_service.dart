import 'dart:io';

import 'package:dio/dio.dart';
import '../models/employee_status.dart';
import '../models/check_in_response.dart';
import '../models/check_out_response.dart';
import '../models/late_request_response.dart';
import '../models/upload_photo_response.dart';

class ApiService {
  static const String baseUrl =
      'https://attendancebackend.duckdns.org/'; // Replace with your actual base URL
  static const int timeoutSeconds = 30;

  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: Duration(seconds: timeoutSeconds),
      receiveTimeout: Duration(seconds: timeoutSeconds),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  /// 1. Get Employee Status
  /// POST /api/employee-status
  static Future<EmployeeStatus> getEmployeeStatus(String employeeId) async {
    try {
      final response = await _dio.post(
        '/api/employee-status',
        data: {'employee_id': employeeId},
      );

      if (response.statusCode == 200) {
        return EmployeeStatus.fromJson(response.data);
      } else {
        throw Exception(
          'Failed to get employee status: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Employee not found');
      } else if (e.response?.statusCode == 400) {
        throw Exception('Employee ID is required');
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to get employee status: $e');
    }
  }

  /// 2. Check-In with Photo Verification
  /// POST /check_in (multipart/form-data)
  static Future<CheckInResponse> checkIn({
    required String employeeId,
    required File photo,
    required double latitude,
    required double longitude,
    String? timestamp,
  }) async {
    try {
      // Create form data
      FormData formData = FormData.fromMap({
        'employee_id': employeeId,
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'timestamp': timestamp ?? DateTime.now().toIso8601String(),
        'photo': await MultipartFile.fromFile(
          photo.path,
          filename: 'checkin_photo.jpg',
        ),
      });

      final response = await _dio.post(
        '/check_in',
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );

      if (response.statusCode == 200) {
        return CheckInResponse.fromJson(response.data);
      } else {
        throw Exception('Failed to check in: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        String errorMsg = e.response?.data['error'] ?? 'Invalid request';
        throw Exception(errorMsg);
      } else if (e.response?.statusCode == 404) {
        String errorMsg =
            e.response?.data['error'] ?? 'Employee or photo not found';
        throw Exception(errorMsg);
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to check in: $e');
    }
  }

  /// 3. Check-Out with Photo Verification
  /// POST /api/check-out-verify (multipart/form-data)
  static Future<CheckOutResponse> checkOut({
    required String employeeId,
    required File photo,
    String? timestamp,
  }) async {
    try {
      // Create form data
      FormData formData = FormData.fromMap({
        'employee_id': employeeId,
        'timestamp': timestamp ?? DateTime.now().toIso8601String(),
        'photo': await MultipartFile.fromFile(
          photo.path,
          filename: 'checkout_photo.jpg',
        ),
      });

      final response = await _dio.post(
        '/api/check-out-verify',
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );

      if (response.statusCode == 200) {
        return CheckOutResponse.fromJson(response.data);
      } else {
        throw Exception('Failed to check out: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        // Handle specific 400 errors from your API docs
        Map<String, dynamic> errorData = e.response?.data ?? {};
        String errorMsg =
            errorData['message'] ?? errorData['error'] ?? 'Invalid request';
        throw Exception(errorMsg);
      } else if (e.response?.statusCode == 404) {
        Map<String, dynamic> errorData = e.response?.data ?? {};
        String errorMsg =
            errorData['message'] ?? 'Employee not found or no active check-in';
        throw Exception(errorMsg);
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to check out: $e');
    }
  }

  /// 4. Submit Late Arrival Request
  /// POST /api/submit-late-request
  static Future<LateRequestResponse> submitLateRequest({
    required String employeeId,
    required String time,
  }) async {
    try {
      final response = await _dio.post(
        '/api/submit-late-request',
        data: {'employee_id': employeeId, 'time': time},
      );

      if (response.statusCode == 201) {
        return LateRequestResponse.fromJson(response.data);
      } else {
        throw Exception(
          'Failed to submit late request: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        Map<String, dynamic> errorData = e.response?.data ?? {};
        String errorMsg = errorData['error'] ?? 'Invalid request';
        throw Exception(errorMsg);
      } else if (e.response?.statusCode == 404) {
        throw Exception('Employee not found');
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to submit late request: $e');
    }
  }

  /// 5. Upload Reference Photo
  /// POST /upload_photo (multipart/form-data)
  static Future<UploadPhotoResponse> uploadReferencePhoto({
    required String employeeId,
    required File photo,
  }) async {
    try {
      // Create form data
      FormData formData = FormData.fromMap({
        'employee_id': employeeId,
        'photo': await MultipartFile.fromFile(
          photo.path,
          filename: 'employee_$employeeId.jpg',
        ),
      });

      final response = await _dio.post(
        '/upload_photo',
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );

      if (response.statusCode == 200) {
        return UploadPhotoResponse.fromJson(response.data);
      } else {
        throw Exception('Failed to upload photo: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        String errorMsg =
            e.response?.data['error'] ?? 'Invalid photo or employee ID';
        throw Exception(errorMsg);
      } else if (e.response?.statusCode == 404) {
        throw Exception('Employee ID does not exist');
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to upload photo: $e');
    }
  }

  /// Helper method to test API connectivity
  static Future<bool> testConnection() async {
    try {
      final response = await _dio.get('/health');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Helper method to get formatted error message
  static String getErrorMessage(Exception e) {
    String message = e.toString();
    if (message.startsWith('Exception: ')) {
      return message.substring(11);
    }
    return message;
  }
}
