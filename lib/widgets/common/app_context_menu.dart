import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_theme_variables.dart';

class ContextMenuItem<T> {
  final T value;
  final String title;
  final IconData icon;
  final bool isDestructive;

  const ContextMenuItem({
    required this.value,
    required this.title,
    required this.icon,
    this.isDestructive = false,
  });
}

/// Вызов всплывающего меню по правому клику или кнопке
Future<T?> showAppContextMenu<T>({
  required BuildContext context,
  required Offset position,
  required List<ContextMenuItem<T>> items,
}) {
  return showMenu<T>(
    context: context,
    position: RelativeRect.fromLTRB(
      position.dx,
      position.dy,
      position.dx,
      position.dy,
    ),
    items: items.map((item) {
      final color = item.isDestructive
          ? context.colors.error
          : context.colors.onSurface;

      return PopupMenuItem<T>(
        value: item.value,
        height: AppThemeVariables.xl,
        child: Row(
          children: [
            Icon(item.icon, size: AppThemeVariables.iconSm, color: color),
            const SizedBox(width: AppThemeVariables.xs),
            Text(
              item.title,
              style: context.bodySecondary?.copyWith(color: color),
            ),
          ],
        ),
      );
    }).toList(),
  );
}
