import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_theme_variables.dart';

abstract class ContextMenuEntry<T> {
  const ContextMenuEntry();
}

class ContextMenuItem<T> extends ContextMenuEntry<T> {
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

class ContextMenuDivider<T> extends ContextMenuEntry<T> {
  const ContextMenuDivider();
}

class _RoundedPopupMenuItem<T> extends PopupMenuEntry<T> {
  final T value;
  final Widget child;
  final double itemHeight;
  final BorderRadius borderRadius;

  const _RoundedPopupMenuItem({
    required this.value,
    required this.child,
    required this.itemHeight,
    required this.borderRadius,
  });

  @override
  double get height => itemHeight;

  @override
  bool represents(T? value) => value == this.value;

  @override
  State<PopupMenuEntry<T>> createState() => _RoundedPopupMenuItemState<T>();
}

class _RoundedPopupMenuItemState<T> extends State<_RoundedPopupMenuItem<T>> {
  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: Material(
        color: Colors.transparent,
        borderRadius: widget.borderRadius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          mouseCursor: SystemMouseCursors.click,
          borderRadius: widget.borderRadius,
          hoverColor: context.colors.surfaceContainerHighest,
          onTap: () => Navigator.pop<T>(context, widget.value),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: widget.itemHeight),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppThemeVariables.xs,
              ),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<T?> showAppContextMenu<T>({
  required BuildContext context,
  required Offset position,
  required List<ContextMenuEntry<T>> items,
}) {
  return showMenu<T>(
    context: context,
    color: context.colors.surfaceContainerHigh,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppThemeVariables.xxs),
    ),
    clipBehavior: Clip.antiAlias,
    menuPadding: EdgeInsets.symmetric(
      vertical: AppThemeVariables.xxs,
      horizontal: AppThemeVariables.xxs,
    ),
    position: RelativeRect.fromLTRB(
      position.dx,
      position.dy,
      position.dx,
      position.dy,
    ),
    items: items.expand<PopupMenuEntry<T>>((item) {
      if (item is ContextMenuDivider<T>) {
        return [const PopupMenuDivider()];
      }

      final menuItem = item as ContextMenuItem<T>;
      final color = menuItem.isDestructive
          ? context.colors.error
          : context.colors.onSurface;

      return [
        _RoundedPopupMenuItem<T>(
          value: menuItem.value,
          itemHeight: AppThemeVariables.xl,
          borderRadius: BorderRadius.circular(AppThemeVariables.xxs),
          child: Row(
            children: [
              Icon(menuItem.icon, size: AppThemeVariables.iconSm, color: color),
              const SizedBox(width: AppThemeVariables.xs),
              Text(
                menuItem.title,
                style: context.bodySecondary?.copyWith(color: color),
              ),
            ],
          ),
        ),
      ];
    }).toList(),
  );
}
