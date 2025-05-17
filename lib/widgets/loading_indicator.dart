import 'package:flutter/material.dart';

import '../core/config/app_theme.dart';

class LoadingIndicator extends StatelessWidget {
  final String message;
  final Color color;

  const LoadingIndicator({
    super.key,
    this.message = 'Loading...',
    this.color = AppTheme.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(color),
              strokeWidth: 3,
            ),
          ),
          if (message.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                message,
                style: AppTheme.bodyStyle,
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}

/// Loading overlay that dims the background
class LoadingOverlay extends StatelessWidget {
  final Widget child;
  final bool isLoading;
  final String message;

  const LoadingOverlay({
    super.key,
    required this.child,
    required this.isLoading,
    this.message = 'Loading...',
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black.withValues(alpha: 0.5),
            child: LoadingIndicator(message: message, color: Colors.white),
          ),
      ],
    );
  }
}
