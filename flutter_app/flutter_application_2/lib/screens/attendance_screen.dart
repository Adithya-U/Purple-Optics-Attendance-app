import 'package:flutter/material.dart';
import '../models/employee_status.dart';
import '../services/api_service.dart';
import '../widgets/employee_id_input.dart';
import '../widgets/status_display.dart';
import '../widgets/action_buttons.dart';
import '../widgets/upload_reference_photo.dart';
import '../widgets/loading_indicator.dart';
import '../utils/constants.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({Key? key}) : super(key: key);

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  String? _employeeId;
  EmployeeStatus? _employeeStatus;
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _fetchStatus(String employeeId) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final status = await ApiService.getEmployeeStatus(employeeId);
      setState(() {
        _employeeId = employeeId;
        _employeeStatus = status;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _handleSuccess() {
    if (_employeeId != null) {
      _fetchStatus(_employeeId!);
    }
  }

  void _handleError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Attendance"),
        actions: [
          if (_employeeId != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _fetchStatus(_employeeId!),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: EmployeeIdInput(
                onEmployeeIdChanged: (id) {
                  setState(() {
                    _employeeId = id;
                  });
                },
                onCheckStatus: () {
                  if (_employeeId != null && _employeeId!.isNotEmpty) {
                    _fetchStatus(_employeeId!);
                  }
                },
                isLoading: _isLoading,
                enabled: !_isLoading,
              ),
            ),
            if (_isLoading)
              const Expanded(
                child: Center(child: LoadingIndicator(message: "Loading...")),
              )
            else if (_errorMessage != null)
              Expanded(
                child: Center(
                  child: Text(
                    _errorMessage!,
                    style: AppConstants.bodyTextStyle.copyWith(
                      color: AppConstants.errorColor,
                    ),
                  ),
                ),
              )
            else if (_employeeStatus != null)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: ListView(
                    children: [
                      StatusDisplay(
                        status: _employeeStatus!,
                        onRefresh: () {
                          if (_employeeId != null) _fetchStatus(_employeeId!);
                        },
                      ),
                      const SizedBox(height: 16),
                      ActionButtons(
                        employeeStatus: _employeeStatus!,
                        employeeId: _employeeId!,
                        onSuccess: _handleSuccess,
                        onError: _handleError,
                      ),
                    ],
                  ),
                ),
              )
            else
              const Expanded(
                child: Center(child: Text("Enter employee ID to view status")),
              ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: UploadReferencePhoto(employeeId: _employeeId ?? ""),
            ),
          ],
        ),
      ),
    );
  }
}
