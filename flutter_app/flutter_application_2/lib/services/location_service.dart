import 'package:geolocator/geolocator.dart';

enum LocationStatus {
  loading,
  success,
  error,
  usingDefault,
  permissionDenied,
  serviceDisabled,
  timeout,
}

class LocationResult {
  final double latitude;
  final double longitude;
  final bool isDefault;
  final double? accuracy;
  final LocationStatus status;
  final String? errorMessage;

  LocationResult({
    required this.latitude,
    required this.longitude,
    required this.isDefault,
    this.accuracy,
    required this.status,
    this.errorMessage,
  });
}

class LocationService {
  // Default location coordinates (fallback)
  static const double _defaultLatitude = 12.97828301152951;
  static const double _defaultLongitude = 80.13844783758844;
  static const int _timeoutSeconds = 20;

  /// Gets current location coordinates with loading state management
  /// Returns LocationResult with coordinates, status, and error info
  static Future<LocationResult> getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return _getDefaultLocationResult(
          status: LocationStatus.serviceDisabled,
          errorMessage: 'Location services are disabled',
        );
      }

      // Check and request location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return _getDefaultLocationResult(
            status: LocationStatus.permissionDenied,
            errorMessage: 'Location permission denied',
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return _getDefaultLocationResult(
          status: LocationStatus.permissionDenied,
          errorMessage: 'Location permission permanently denied',
        );
      }

      // Get current position with timeout
      Position position =
          await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.best,
          ).timeout(
            Duration(seconds: _timeoutSeconds),
            onTimeout: () {
              throw Exception('Location request timed out');
            },
          );

      return LocationResult(
        latitude: position.latitude,
        longitude: position.longitude,
        isDefault: false,
        accuracy: position.accuracy,
        status: LocationStatus.success,
      );
    } catch (e) {
      // Handle timeout specifically
      if (e.toString().contains('timed out')) {
        return _getDefaultLocationResult(
          status: LocationStatus.timeout,
          errorMessage:
              'Location request timed out after $_timeoutSeconds seconds',
        );
      }

      // Return default location for any other error
      return _getDefaultLocationResult(
        status: LocationStatus.error,
        errorMessage: 'Failed to get location: ${e.toString()}',
      );
    }
  }

  /// Returns default location result with specified status
  static LocationResult _getDefaultLocationResult({
    required LocationStatus status,
    String? errorMessage,
  }) {
    return LocationResult(
      latitude: _defaultLatitude,
      longitude: _defaultLongitude,
      isDefault: true,
      accuracy: null,
      status: status,
      errorMessage: errorMessage,
    );
  }

  /// Check if location services are available (for UI feedback)
  static Future<bool> isLocationServiceAvailable() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      LocationPermission permission = await Geolocator.checkPermission();

      return serviceEnabled &&
          permission != LocationPermission.denied &&
          permission != LocationPermission.deniedForever;
    } catch (e) {
      return false;
    }
  }

  /// Get formatted coordinates string for API calls
  static String formatCoordinates(double latitude, double longitude) {
    return '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
  }

  /// Validate if coordinates are within reasonable bounds
  static bool isValidCoordinate(double latitude, double longitude) {
    return latitude >= -90.0 &&
        latitude <= 90.0 &&
        longitude >= -180.0 &&
        longitude <= 180.0;
  }

  /// Get user-friendly status message for UI display
  static String getStatusMessage(LocationStatus status) {
    switch (status) {
      case LocationStatus.loading:
        return 'Getting your location...';
      case LocationStatus.success:
        return 'Location found successfully';
      case LocationStatus.usingDefault:
        return 'Using default location';
      case LocationStatus.permissionDenied:
        return 'Location permission required';
      case LocationStatus.serviceDisabled:
        return 'Please enable location services';
      case LocationStatus.timeout:
        return 'Location request timed out';
      case LocationStatus.error:
        return 'Failed to get location';
    }
  }
}
