import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../theme/app_theme.dart';
import '../../theme/app_theme_variables.dart';

class AppQuillToolbar extends StatelessWidget {
  final QuillController controller;
  final bool isCompact;
  final BorderRadius borderRadius;
  final Color? backgroundColor;
  final Border? border;

  const AppQuillToolbar({
    super.key,
    required this.controller,
    this.isCompact = false,
    this.borderRadius = const BorderRadius.all(
      Radius.circular(AppThemeVariables.sm),
    ),
    this.backgroundColor,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    const double iconSize = 12;
    final buttonSize = 32.0;

    final customIconTheme = QuillIconTheme(
      iconButtonSelectedData: IconButtonData(
        constraints: BoxConstraints.tightFor(
          width: buttonSize,
          height: buttonSize,
        ),
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        style: ButtonStyle(
          elevation: const WidgetStatePropertyAll(0),
          mouseCursor: const WidgetStatePropertyAll(SystemMouseCursors.click),
          backgroundColor: WidgetStatePropertyAll(
            context.colors.surfaceContainerHighest,
          ),
          foregroundColor: WidgetStatePropertyAll(context.colors.primary),
          overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
            if (states.contains(WidgetState.hovered)) {
              return context.colors.primary.withValues(alpha: 0.12);
            }
            if (states.contains(WidgetState.pressed)) {
              return context.colors.primary.withValues(alpha: 0.2);
            }
            return null;
          }),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppThemeVariables.xs),
            ),
          ),
        ),
      ),
      iconButtonUnselectedData: IconButtonData(
        constraints: BoxConstraints.tightFor(
          width: buttonSize,
          height: buttonSize,
        ),
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        style: ButtonStyle(
          elevation: const WidgetStatePropertyAll(0),
          mouseCursor: const WidgetStatePropertyAll(SystemMouseCursors.click),
          backgroundColor: const WidgetStatePropertyAll(Colors.transparent),
          foregroundColor: WidgetStatePropertyAll(
            context.colors.onSurfaceVariant,
          ),
          overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
            if (states.contains(WidgetState.hovered)) {
              return context.colors.surfaceContainerHighest;
            }
            if (states.contains(WidgetState.pressed)) {
              return context.colors.primary.withValues(alpha: 0.16);
            }
            return null;
          }),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppThemeVariables.xs),
            ),
          ),
        ),
      ),
    );

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppThemeVariables.xs,
        vertical: AppThemeVariables.xxs,
      ),
      decoration: BoxDecoration(
        color: backgroundColor ?? context.colors.surfaceContainerHigh,
        borderRadius: borderRadius,
        border: border ?? Border.all(color: context.colors.outlineVariant),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                spacing: isCompact
                    ? AppThemeVariables.xxs
                    : AppThemeVariables.sm,
                children: [
                  if (!isCompact) SizedBox(width: AppThemeVariables.xxs),
                  // History (Undo / Redo)
                  QuillToolbarHistoryButton(
                    controller: controller,
                    isUndo: true,
                    options: QuillToolbarHistoryButtonOptions(
                      iconData: LucideIcons.undo,
                      iconSize: iconSize,
                      iconTheme: customIconTheme,
                    ),
                  ),
                  QuillToolbarHistoryButton(
                    controller: controller,
                    isUndo: false,
                    options: QuillToolbarHistoryButtonOptions(
                      iconData: LucideIcons.redo,
                      iconSize: iconSize,
                      iconTheme: customIconTheme,
                    ),
                  ),
                  _buildDivider(context),

                  // Text Styles
                  QuillToolbarToggleStyleButton(
                    controller: controller,
                    attribute: Attribute.bold,
                    options: QuillToolbarToggleStyleButtonOptions(
                      iconData: LucideIcons.bold,
                      iconSize: iconSize,
                      iconTheme: customIconTheme,
                    ),
                  ),
                  QuillToolbarToggleStyleButton(
                    controller: controller,
                    attribute: Attribute.italic,
                    options: QuillToolbarToggleStyleButtonOptions(
                      iconData: LucideIcons.italic,
                      iconSize: iconSize,
                      iconTheme: customIconTheme,
                    ),
                  ),
                  QuillToolbarToggleStyleButton(
                    controller: controller,
                    attribute: Attribute.underline,
                    options: QuillToolbarToggleStyleButtonOptions(
                      iconData: LucideIcons.underline,
                      iconSize: iconSize,
                      iconTheme: customIconTheme,
                    ),
                  ),
                  QuillToolbarToggleStyleButton(
                    controller: controller,
                    attribute: Attribute.strikeThrough,
                    options: QuillToolbarToggleStyleButtonOptions(
                      iconData: LucideIcons.strikethrough,
                      iconSize: iconSize,
                      iconTheme: customIconTheme,
                    ),
                  ),

                  // Headings (H1, H2, H3)
                  _buildDivider(context),
                  _HeaderStyleButton(
                    controller: controller,
                    attribute: Attribute.h1,
                    label: 'H1',
                    iconTheme: customIconTheme,
                  ),
                  _HeaderStyleButton(
                    controller: controller,
                    attribute: Attribute.h2,
                    label: 'H2',
                    iconTheme: customIconTheme,
                  ),
                  _HeaderStyleButton(
                    controller: controller,
                    attribute: Attribute.h3,
                    label: 'H3',
                    iconTheme: customIconTheme,
                  ),

                  _buildDivider(context),

                  // Lists
                  QuillToolbarToggleStyleButton(
                    controller: controller,
                    attribute: Attribute.ul,
                    options: QuillToolbarToggleStyleButtonOptions(
                      iconData: LucideIcons.list,
                      iconSize: iconSize,
                      iconTheme: customIconTheme,
                    ),
                  ),
                  QuillToolbarToggleStyleButton(
                    controller: controller,
                    attribute: Attribute.ol,
                    options: QuillToolbarToggleStyleButtonOptions(
                      iconData: LucideIcons.listOrdered,
                      iconSize: iconSize,
                      iconTheme: customIconTheme,
                    ),
                  ),
                  QuillToolbarToggleStyleButton(
                    controller: controller,
                    attribute: Attribute.unchecked,
                    options: QuillToolbarToggleStyleButtonOptions(
                      iconData: LucideIcons.listTodo,
                      iconSize: iconSize,
                      iconTheme: customIconTheme,
                    ),
                  ),

                  // Code & Quote
                  if (!isCompact) ...[
                    _buildDivider(context),
                    QuillToolbarToggleStyleButton(
                      controller: controller,
                      attribute: Attribute.blockQuote,
                      options: QuillToolbarToggleStyleButtonOptions(
                        iconData: LucideIcons.quote,
                        iconSize: iconSize,
                        iconTheme: customIconTheme,
                      ),
                    ),
                    QuillToolbarToggleStyleButton(
                      controller: controller,
                      attribute: Attribute.codeBlock,
                      options: QuillToolbarToggleStyleButtonOptions(
                        iconData: LucideIcons.code,
                        iconSize: iconSize,
                        iconTheme: customIconTheme,
                      ),
                    ),
                    SizedBox(width: AppThemeVariables.xxs),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Container(
      height: 24,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: AppThemeVariables.xxs),
      color: context.colors.outlineVariant,
    );
  }
}

class _HeaderStyleButton extends StatefulWidget {
  final QuillController controller;
  final Attribute<int?> attribute;
  final String label;
  final QuillIconTheme iconTheme;

  const _HeaderStyleButton({
    required this.controller,
    required this.attribute,
    required this.label,
    required this.iconTheme,
  });

  @override
  State<_HeaderStyleButton> createState() => _HeaderStyleButtonState();
}

class _HeaderStyleButtonState extends State<_HeaderStyleButton> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(covariant _HeaderStyleButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) return;

    oldWidget.controller.removeListener(_refresh);
    widget.controller.addListener(_refresh);
    setState(() {});
  }

  bool get _isSelected {
    final header = widget.controller
        .getSelectionStyle()
        .attributes[Attribute.header.key];
    return header?.value == widget.attribute.value;
  }

  void _toggle() {
    widget.controller.formatSelection(
      _isSelected ? Attribute.header : widget.attribute,
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: widget.label,
      onPressed: _toggle,
      icon: Text(
        widget.label,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: _isSelected
              ? context.colors.primary
              : context.colors.onSurfaceVariant,
        ),
      ),
      style: _isSelected
          ? widget.iconTheme.iconButtonSelectedData?.style
          : widget.iconTheme.iconButtonUnselectedData?.style,
      constraints: const BoxConstraints.tightFor(width: 32, height: 32),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }
}
