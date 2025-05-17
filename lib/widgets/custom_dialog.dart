import 'package:flutter/material.dart';

import '../core/config/app_theme.dart';

/// Shows a custom dialog with the provided content
Future<T?> showCustomDialog<T>({
  required BuildContext context,
  required Widget content,
  String? title,
  List<Widget>? actions,
  bool barrierDismissible = true,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (BuildContext context) {
      return CustomDialog(title: title, content: content, actions: actions);
    },
  );
}

/// A custom styled dialog component
class CustomDialog extends StatelessWidget {
  final String? title;
  final Widget content;
  final List<Widget>? actions;

  const CustomDialog({
    super.key,
    this.title,
    required this.content,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null) ...[
              Text(
                title!,
                style: AppTheme.titleStyle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
            ],
            content,
            if (actions != null) ...[
              const SizedBox(height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: actions!),
            ],
          ],
        ),
      ),
    );
  }
}

/// A custom alert dialog for simple confirmations
class CustomAlertDialog extends StatelessWidget {
  final String title;
  final String message;
  final String? confirmText;
  final String? cancelText;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final Color confirmColor;

  const CustomAlertDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText = 'OK',
    this.cancelText,
    this.onConfirm,
    this.onCancel,
    this.confirmColor = AppTheme.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return CustomDialog(
      title: title,
      content: Text(message, style: AppTheme.bodyStyle),
      actions: [
        if (cancelText != null)
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false);
              if (onCancel != null) {
                onCancel!();
              }
            },
            child: Text(
              cancelText!,
              style: TextStyle(
                color: AppTheme.mediumColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(true);
            if (onConfirm != null) {
              onConfirm!();
            }
          },
          child: Text(
            confirmText!,
            style: TextStyle(color: confirmColor, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

/// Shows a simple alert dialog with the provided title and message
Future<bool?> showAlertDialog({
  required BuildContext context,
  required String title,
  required String message,
  String? confirmText,
  String? cancelText,
  VoidCallback? onConfirm,
  VoidCallback? onCancel,
  Color confirmColor = AppTheme.primaryColor,
}) {
  return showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return CustomAlertDialog(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        onConfirm: onConfirm,
        onCancel: onCancel,
        confirmColor: confirmColor,
      );
    },
  );
}
