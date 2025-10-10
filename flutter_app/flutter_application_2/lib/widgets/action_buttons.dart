import 'dart:io';
import 'package:flutter/material.dart';
import '../models/employee_status.dart';
import '../models/check_in_response.dart';
import '../models/check_out_response.dart';
import '../models/late_request_response.dart';
import '../services/api_service.dart';
import '../services/camera_service.dart';
import '../services/location_service.dart';
import '../services/image_service.dart';
import '../utils/constants.dart';
import 'loading_indicator.dart';
import '../utils/image_helper.dart'; // ✅ import added

class ActionButtons extends StatefulWidget {
  final EmployeeStatus employeeStatus;
  final String employeeId;
  final VoidCallback onSuccess;
  final Function(String) onError;

  const ActionButtons({
    Key? key,
    required this.employeeStatus,
    required this.employeeId,
    required this.onSuccess,
    required this.onError,
  }) : super(key: key);

  @override
  State<ActionButtons> createState() => _ActionButtonsState();
}

class _ActionButtonsState extends State<ActionButtons> {
  bool _isProcessing = false;
  LocationResult? _currentLocation;
  bool _isGettingLocation = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildActionButton(),
        const SizedBox(height: 16),
        if (_isGettingLocation) _buildLocationLoadingIndicator(),
        if (_currentLocation?.isDefault == true) _buildLocationWarning(),
      ],
    );
  }

  Widget _buildActionButton() {
    if (widget.employeeStatus.canCheckIn) {
      return _buildCheckInButton();
    } else if (widget.employeeStatus.canCheckOut) {
      return _buildCheckOutButton();
    } else if (widget.employeeStatus.needsLateRequest) {
      return _buildLateRequestButton();
    } else if (widget.employeeStatus.isWaitingForApproval) {
      return _buildWaitingForApprovalButton();
    } else if (widget.employeeStatus.isRequestRejected) {
      return _buildRejectedRequestButton();
    } else if (widget.employeeStatus.hasCompletedDay) {
      return _buildCompletedDayMessage();
    } else {
      return Container();
    }
  }

  Widget _buildCheckInButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: _isProcessing ? null : () => _handleCheckIn(),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        icon: _isProcessing
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Icon(widget.employeeStatus.actionIcon),
        label: Text(
          _isProcessing
              ? "Processing..."
              : widget.employeeStatus.actionDisplayText,
          style: AppConstants.buttonTextStyle,
        ),
      ),
    );
  }

  Widget _buildCheckOutButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: _isProcessing ? null : () => _handleCheckOut(),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.warningColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        icon: _isProcessing
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Icon(widget.employeeStatus.actionIcon),
        label: Text(
          _isProcessing
              ? "Processing..."
              : widget.employeeStatus.actionDisplayText,
          style: AppConstants.buttonTextStyle,
        ),
      ),
    );
  }

  Widget _buildLateRequestButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: _isProcessing ? null : () => _handleLateRequest(),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.errorColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        icon: _isProcessing
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Icon(widget.employeeStatus.actionIcon),
        label: Text(
          _isProcessing
              ? "Submitting..."
              : widget.employeeStatus.actionDisplayText,
          style: AppConstants.buttonTextStyle,
        ),
      ),
    );
  }

  Widget _buildWaitingForApprovalButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.warningColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppConstants.warningColor),
      ),
      child: Row(
        children: [
          Icon(Icons.hourglass_empty, color: AppConstants.warningColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.employeeStatus.message,
              style: AppConstants.bodyTextStyle.copyWith(
                color: AppConstants.warningColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRejectedRequestButton() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppConstants.errorColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppConstants.errorColor),
          ),
          child: Row(
            children: [
              Icon(Icons.cancel, color: AppConstants.errorColor),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.employeeStatus.message,
                  style: AppConstants.bodyTextStyle.copyWith(
                    color: AppConstants.errorColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _isProcessing ? null : () => _handleLateRequest(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.errorColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: _isProcessing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.refresh),
            label: Text(
              _isProcessing ? "Submitting..." : "Submit New Request",
              style: AppConstants.buttonTextStyle,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompletedDayMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.successColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppConstants.successColor),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: AppConstants.successColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.employeeStatus.message ?? "Day completed successfully!",
              style: AppConstants.bodyTextStyle.copyWith(
                color: AppConstants.successColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationLoadingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: LocationLoadingIndicator(
        message: "Getting your location...",
        onCancel: () => _useDefaultLocation(),
      ),
    );
  }

  Widget _buildLocationWarning() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppConstants.warningColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppConstants.warningColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber, color: AppConstants.warningColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "Using approximate location",
              style: AppConstants.captionTextStyle.copyWith(
                color: AppConstants.warningColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleCheckIn() async {
    final confirmed = await _showConfirmationDialog(
      title: "Check In",
      message: "Are you sure you want to check in now?",
    );

    if (!confirmed) return;

    setState(() => _isProcessing = true);

    try {
      await _getCurrentLocation();

      if (_currentLocation == null) {
        widget.onError("Failed to get location. Please try again.");
        return;
      }

      final CameraResult cameraResult = await CameraService.selectPhoto(
        PhotoSource.camera,
      );

      if (!cameraResult.isSuccess) {
        widget.onError("Failed to capture photo. Please try again.");
        return;
      }

      // ✅ Fix orientation/compression
      File processedPhoto = await fixPhoto(cameraResult.imageFile!);

      final CheckInResponse response = await ApiService.checkIn(
        employeeId: widget.employeeId,
        photo: processedPhoto,
        latitude: _currentLocation!.latitude!,
        longitude: _currentLocation!.longitude!,
      );

      if (response.attendanceRecorded == true) {
        widget.onSuccess();
      } else {
        widget.onError(response.message ?? "Check-in failed");
      }
    } catch (e) {
      widget.onError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleCheckOut() async {
    final confirmed = await _showConfirmationDialog(
      title: "Check Out",
      message: "Are you sure you want to check out now?",
    );

    if (!confirmed) return;

    setState(() => _isProcessing = true);

    try {
      final CameraResult cameraResult = await CameraService.selectPhoto(
        PhotoSource.camera,
      );

      if (!cameraResult.isSuccess) {
        widget.onError("Failed to capture photo. Please try again.");
        return;
      }

      // ✅ Fix orientation/compression
      File processedPhoto = await fixPhoto(cameraResult.imageFile!);

      final CheckOutResponse response = await ApiService.checkOut(
        employeeId: widget.employeeId,
        photo: processedPhoto,
      );

      if (response.checkOutRecorded == true) {
        widget.onSuccess();
      } else {
        widget.onError(response.message ?? "Check-out failed");
      }
    } catch (e) {
      widget.onError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleLateRequest() async {
    final confirmed = await _showConfirmationDialog(
      title: "Submit Late Request",
      message: "Submit a late arrival request for current time?",
    );

    if (!confirmed) return;

    setState(() => _isProcessing = true);

    try {
      // Get current location
      await _getCurrentLocation();

      if (_currentLocation == null) {
        widget.onError("Failed to get location. Please try again.");
        return;
      }

      // Capture photo
      final CameraResult cameraResult = await CameraService.selectPhoto(
        PhotoSource.camera,
      );

      if (!cameraResult.isSuccess) {
        widget.onError("Failed to capture photo. Please try again.");
        return;
      }

      // Fix photo orientation/compression
      File processedPhoto = await fixPhoto(cameraResult.imageFile!);

      // Get current time
      final now = DateTime.now();
      final currentTime =
          "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

      // Submit late request with photo and location
      final LateRequestResponse response = await ApiService.submitLateRequest(
        employeeId: widget.employeeId,
        time: currentTime,
        photo: processedPhoto,
        latitude: _currentLocation!.latitude!,
        longitude: _currentLocation!.longitude!,
      );

      if (response.success == true && response.requestSubmitted == true) {
        widget.onSuccess();
      } else {
        widget.onError(response.displayMessage);
      }
    } catch (e) {
      widget.onError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isGettingLocation = true);
    try {
      _currentLocation = await LocationService.getCurrentLocation();
    } catch (e) {
      _useDefaultLocation();
    } finally {
      if (mounted) setState(() => _isGettingLocation = false);
    }
  }

  void _useDefaultLocation() {
    _currentLocation = LocationResult(
      status: LocationStatus.success,
      latitude: 0.0,
      longitude: 0.0,
      isDefault: true,
    );
    setState(() => _isGettingLocation = false);
  }

  Future<bool> _showConfirmationDialog({
    required String title,
    required String message,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(title, style: AppConstants.headingTextStyle),
              content: Text(message, style: AppConstants.bodyTextStyle),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    "Cancel",
                    style: AppConstants.bodyTextStyle.copyWith(
                      color: AppConstants.primaryColor,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: Text("Confirm", style: AppConstants.buttonTextStyle),
                ),
              ],
            );
          },
        ) ??
        false;
  }
}
