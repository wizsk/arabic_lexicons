import 'package:flutter/material.dart';

enum IconButtonSizedColor { normal, err, primary }

Widget iconButtonSized(
  BuildContext context, {
  required IconData icon,
  String? tooltip,
  required VoidCallback? onPressed,
  VoidCallback? onLongPress,
  final IconButtonSizedColor scheme = IconButtonSizedColor.normal,
  final double size = 40.00,
  final double iconSize = 20.00,
}) {
  final theme = Theme.of(context);
  final cs = theme.colorScheme;

  final (color, fg) = switch (scheme) {
    IconButtonSizedColor.normal => (null, cs.onSurfaceVariant),
    IconButtonSizedColor.primary => (cs.onPrimary, cs.primary),
    IconButtonSizedColor.err => (cs.onError, cs.error),
  };

  return IconButton(
    onPressed: onPressed,
    onLongPress: onLongPress,
    tooltip: tooltip,
    icon: Icon(icon, size: iconSize),
    color: color,
    style: IconButton.styleFrom(
      foregroundColor: fg,
      minimumSize: Size(size, size),
      maximumSize: Size(size, size),
      padding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    visualDensity: VisualDensity.compact,
  );
}
