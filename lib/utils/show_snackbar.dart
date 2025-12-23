import 'package:flutter/material.dart';

enum SnackBarType { success, error, info }

void showCustomSnackBar(
  BuildContext context,
  String message, {
  SnackBarType type = SnackBarType.info,
}) {
  if (!context.mounted) return;

  final colorScheme = Theme.of(context).colorScheme;
  final iconData = _getIconForType(type);
  final backgroundColor = _getColorForType(type, colorScheme);

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(iconData, color: colorScheme.onPrimary, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        duration: const Duration(seconds: 3),
      ),
    );
}

IconData _getIconForType(SnackBarType type) {
  switch (type) {
    case SnackBarType.success:
      return Icons.check_circle_outline_rounded;
    case SnackBarType.error:
      return Icons.highlight_off_rounded;
    case SnackBarType.info:
      return Icons.info_outline_rounded;
  }
}

Color _getColorForType(SnackBarType type, ColorScheme colorScheme) {
  switch (type) {
    case SnackBarType.success:
      return Colors.green.shade600;
    case SnackBarType.error:
      return colorScheme.error;
    case SnackBarType.info:
      return Colors.blue.shade600;
  }
}
