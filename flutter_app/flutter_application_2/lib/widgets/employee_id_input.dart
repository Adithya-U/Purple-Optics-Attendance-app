import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';
import 'loading_indicator.dart';

class EmployeeIdInput extends StatefulWidget {
  final String? initialValue;
  final Function(String) onEmployeeIdChanged;
  final VoidCallback onCheckStatus;
  final bool isLoading;
  final bool enabled;

  const EmployeeIdInput({
    super.key,
    this.initialValue,
    required this.onEmployeeIdChanged,
    required this.onCheckStatus,
    this.isLoading = false,
    this.enabled = true,
  });

  @override
  State<EmployeeIdInput> createState() => _EmployeeIdInputState();
}

class _EmployeeIdInputState extends State<EmployeeIdInput> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  String? _errorText;
  bool _hasInteracted = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);

    // Listen to text changes
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final text = _controller.text;

    // Notify parent of changes
    widget.onEmployeeIdChanged(text);

    // Validate on change if user has interacted
    if (_hasInteracted) {
      setState(() {
        _errorText = Validators.validateEmployeeId(text);
      });
    }
  }

  void _onSubmitted() {
    _hasInteracted = true;
    final validation = Validators.validateEmployeeId(_controller.text);

    setState(() {
      _errorText = validation;
    });

    if (validation == null) {
      // Valid employee ID, proceed with status check
      _focusNode.unfocus(); // Hide keyboard
      widget.onCheckStatus();
    }
  }

  void _onFieldTapped() {
    if (!_hasInteracted) {
      setState(() {
        _hasInteracted = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title
            Row(
              children: [
                Icon(Icons.badge, color: AppConstants.primaryColor, size: 24),
                SizedBox(width: AppConstants.smallPadding),
                Text(
                  AppConstants.labelEmployeeId,
                  style: AppConstants.headingTextStyle,
                ),
              ],
            ),

            SizedBox(height: AppConstants.defaultPadding),

            // Input Row
            Row(
              children: [
                // Employee ID Input Field
                Expanded(
                  child: TextFormField(
                    controller: _controller,
                    focusNode: _focusNode,
                    enabled: widget.enabled && !widget.isLoading,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter
                          .digitsOnly, // Only allow digits
                      LengthLimitingTextInputFormatter(10), // Max 10 digits
                    ],
                    textInputAction: TextInputAction.done,
                    onTap: _onFieldTapped,
                    onFieldSubmitted: (_) => _onSubmitted(),
                    decoration: InputDecoration(
                      hintText: AppConstants.hintEmployeeId,
                      errorText: _errorText,
                      prefixIcon: Icon(
                        Icons.person,
                        color: _errorText != null
                            ? AppConstants.errorColor
                            : AppConstants.primaryColor,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppConstants.borderRadius,
                        ),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppConstants.borderRadius,
                        ),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppConstants.borderRadius,
                        ),
                        borderSide: BorderSide(
                          color: _errorText != null
                              ? AppConstants.errorColor
                              : AppConstants.primaryColor,
                          width: 2,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppConstants.borderRadius,
                        ),
                        borderSide: BorderSide(color: AppConstants.errorColor),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppConstants.borderRadius,
                        ),
                        borderSide: BorderSide(
                          color: AppConstants.errorColor,
                          width: 2,
                        ),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: AppConstants.defaultPadding,
                        vertical: AppConstants.smallPadding,
                      ),
                    ),
                    style: AppConstants.bodyTextStyle,
                  ),
                ),

                SizedBox(width: AppConstants.smallPadding),

                // Check Status Button
                LoadingButton(
                  text: AppConstants.btnCheckStatus,
                  isLoading: widget.isLoading,
                  loadingText: AppConstants.msgLoading,
                  icon: Icons.search,
                  onPressed: _controller.text.trim().isEmpty
                      ? null
                      : _onSubmitted,
                  width: 172,
                ),
              ],
            ),

            // Helper text
            if (!_hasInteracted && _controller.text.isEmpty) ...[
              SizedBox(height: AppConstants.smallPadding),
              Text(
                'Enter your numeric Employee ID to check your status',
                style: AppConstants.captionTextStyle.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],

            // Current ID display (when valid)
            if (_controller.text.isNotEmpty && _errorText == null) ...[
              SizedBox(height: AppConstants.smallPadding),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppConstants.smallPadding,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppConstants.primaryLightColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(
                    AppConstants.borderRadius / 2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 16,
                      color: AppConstants.successColor,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Employee ID: E${_controller.text}',
                      style: AppConstants.captionTextStyle.copyWith(
                        color: AppConstants.successColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Compact version for scenarios where space is limited
class CompactEmployeeIdInput extends StatefulWidget {
  final String? initialValue;
  final Function(String) onEmployeeIdChanged;
  final VoidCallback? onSubmitted;
  final bool enabled;
  final String? errorText;

  const CompactEmployeeIdInput({
    super.key,
    this.initialValue,
    required this.onEmployeeIdChanged,
    this.onSubmitted,
    this.enabled = true,
    this.errorText,
  });

  @override
  State<CompactEmployeeIdInput> createState() => _CompactEmployeeIdInputState();
}

class _CompactEmployeeIdInputState extends State<CompactEmployeeIdInput> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _controller.addListener(() {
      widget.onEmployeeIdChanged(_controller.text);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      enabled: widget.enabled,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(10),
      ],
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => widget.onSubmitted?.call(),
      decoration: InputDecoration(
        labelText: AppConstants.labelEmployeeId,
        hintText: 'e.g., 123',
        errorText: widget.errorText,
        prefixIcon: Icon(Icons.person),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppConstants.defaultPadding,
          vertical: AppConstants.smallPadding,
        ),
        isDense: true,
      ),
      style: AppConstants.bodyTextStyle,
    );
  }
}

/// Employee ID display widget (read-only)
class EmployeeIdDisplay extends StatelessWidget {
  final String employeeId;
  final String? employeeName;
  final VoidCallback? onEdit;

  const EmployeeIdDisplay({
    super.key,
    required this.employeeId,
    this.employeeName,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppConstants.primaryLightColor,
              child: Text(
                'E',
                style: TextStyle(
                  color: AppConstants.primaryDarkColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(width: AppConstants.defaultPadding),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Employee ID: E$employeeId',
                    style: AppConstants.bodyTextStyle.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (employeeName != null) ...[
                    SizedBox(height: 2),
                    Text(employeeName!, style: AppConstants.captionTextStyle),
                  ],
                ],
              ),
            ),
            if (onEdit != null)
              IconButton(
                onPressed: onEdit,
                icon: Icon(Icons.edit, color: AppConstants.primaryColor),
                tooltip: 'Change Employee ID',
              ),
          ],
        ),
      ),
    );
  }
}
