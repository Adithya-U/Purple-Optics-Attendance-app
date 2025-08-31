import 'package:flutter/material.dart';
import '../utils/constants.dart';

class LoadingIndicator extends StatelessWidget {
  final String? message;
  final double size;
  final Color? color;
  final bool showMessage;

  const LoadingIndicator({
    super.key,
    this.message,
    this.size = 24.0,
    this.color,
    this.showMessage = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            strokeWidth: 2.0,
            valueColor: AlwaysStoppedAnimation<Color>(
              color ?? AppConstants.primaryColor,
            ),
          ),
        ),
        if (showMessage && message != null) ...[
          SizedBox(height: AppConstants.smallPadding),
          Text(
            message!,
            style: AppConstants.captionTextStyle,
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

/// Overlay loading indicator that covers the entire screen
class OverlayLoadingIndicator extends StatelessWidget {
  final String message;
  final bool isLoading;

  const OverlayLoadingIndicator({
    super.key,
    required this.message,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    if (!isLoading) return const SizedBox.shrink();

    return Container(
      color: Colors.black54,
      child: Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.largePadding),
            child: LoadingIndicator(message: message, size: 32.0),
          ),
        ),
      ),
    );
  }
}

/// Button with integrated loading state
class LoadingButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final String? loadingText;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double height;

  const LoadingButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.loadingText,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height = AppConstants.buttonHeight,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? AppConstants.primaryColor,
          foregroundColor: textColor ?? Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          ),
          elevation: isLoading ? 0 : 2,
        ),
        child: isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        textColor ?? Colors.white,
                      ),
                    ),
                  ),
                  if (loadingText != null) ...[
                    SizedBox(width: AppConstants.smallPadding),
                    Text(
                      loadingText!,
                      style: AppConstants.buttonTextStyle.copyWith(
                        color: textColor ?? Colors.white,
                      ),
                    ),
                  ],
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon),
                    SizedBox(width: AppConstants.smallPadding),
                  ],
                  Text(
                    text,
                    style: AppConstants.buttonTextStyle.copyWith(
                      color: textColor ?? Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Linear progress indicator for file uploads
class UploadProgressIndicator extends StatelessWidget {
  final double? progress; // 0.0 to 1.0, null for indeterminate
  final String? message;
  final Color? color;

  const UploadProgressIndicator({
    super.key,
    this.progress,
    this.message,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (message != null) ...[
          Text(
            message!,
            style: AppConstants.captionTextStyle,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppConstants.smallPadding),
        ],
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(
            color ?? AppConstants.primaryColor,
          ),
        ),
        if (progress != null) ...[
          SizedBox(height: AppConstants.smallPadding / 2),
          Text(
            '${(progress! * 100).toInt()}%',
            style: AppConstants.captionTextStyle.copyWith(fontSize: 12),
          ),
        ],
      ],
    );
  }
}

/// Shimmer loading effect for list items
class ShimmerLoadingItem extends StatefulWidget {
  final double height;
  final double? width;
  final BorderRadius? borderRadius;

  const ShimmerLoadingItem({
    super.key,
    required this.height,
    this.width,
    this.borderRadius,
  });

  @override
  State<ShimmerLoadingItem> createState() => _ShimmerLoadingItemState();
}

class _ShimmerLoadingItemState extends State<ShimmerLoadingItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius:
                widget.borderRadius ??
                BorderRadius.circular(AppConstants.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(-1.0, -0.3),
              end: Alignment(1.0, 0.3),
              colors: [Colors.grey[300]!, Colors.grey[100]!, Colors.grey[300]!],
              stops: [0.0, 0.5, 1.0],
              transform: GradientRotation(_animation.value),
            ),
          ),
        );
      },
    );
  }
}

/// GPS/Location loading indicator
class LocationLoadingIndicator extends StatelessWidget {
  final String message;
  final VoidCallback? onCancel;

  const LocationLoadingIndicator({
    super.key,
    required this.message,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_searching,
              size: 48,
              color: AppConstants.primaryColor,
            ),
            SizedBox(height: AppConstants.smallPadding),
            Text(
              message,
              style: AppConstants.bodyTextStyle,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppConstants.defaultPadding),
            LoadingIndicator(message: null, showMessage: false, size: 20),
            if (onCancel != null) ...[
              SizedBox(height: AppConstants.defaultPadding),
              TextButton(
                onPressed: onCancel,
                child: Text(
                  AppConstants.btnCancel,
                  style: TextStyle(color: AppConstants.primaryColor),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Face verification loading indicator
class FaceVerificationLoadingIndicator extends StatelessWidget {
  final String message;

  const FaceVerificationLoadingIndicator({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.face_retouching_natural,
              size: 48,
              color: AppConstants.primaryColor,
            ),
            SizedBox(height: AppConstants.smallPadding),
            Text(
              message,
              style: AppConstants.bodyTextStyle,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppConstants.defaultPadding),
            LoadingIndicator(message: null, showMessage: false, size: 20),
          ],
        ),
      ),
    );
  }
}
