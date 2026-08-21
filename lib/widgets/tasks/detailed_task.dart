import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../models/tasks/task.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_theme_variables.dart';
import '../common/app_quill_toolbar.dart';
import '../common/app_context_menu.dart';

class DetailedTaskDialog extends StatefulWidget {
  final Task task;
  final Function(
    String newTitle,
    String newDescription,
    TaskPriority newPriority,
    DateTime? newDueDate,
  )
  onSave;

  const DetailedTaskDialog({
    super.key,
    required this.task,
    required this.onSave,
  });

  static Future<void> show(
    BuildContext context, {
    required Task task,
    required Function(
      String newTitle,
      String newDescription,
      TaskPriority newPriority,
      DateTime? newDueDate,
    )
    onSave,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => DetailedTaskDialog(task: task, onSave: onSave),
    );
  }

  @override
  State<DetailedTaskDialog> createState() => _DetailedTaskDialogState();
}

class _DetailedTaskDialogState extends State<DetailedTaskDialog> {
  late TextEditingController _titleController;
  late QuillController _quillController;
  late TaskPriority _selectedPriority;
  DateTime? _selectedDueDate;
  bool _isDescriptionEditing = false;
  final GlobalKey _priorityKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    _titleController = TextEditingController(text: widget.task.title);
    _selectedPriority = widget.task.priority;
    _selectedDueDate = widget.task.dueDate;

    _titleController.addListener(_onTitleChanged);
    _quillController = _initQuillController(widget.task.description);
    _quillController.readOnly = true;
  }

  void _onTitleChanged() {
    setState(() {});
  }

  QuillController _initQuillController(String description) {
    if (description.isNotEmpty) {
      try {
        final jsonList = jsonDecode(description) as List<dynamic>;
        final doc = Document.fromJson(jsonList);
        return QuillController(
          document: doc,
          selection: const TextSelection.collapsed(offset: 0),
        );
      } catch (_) {
        final doc = Document()..insert(0, description);
        return QuillController(
          document: doc,
          selection: const TextSelection.collapsed(offset: 0),
        );
      }
    }
    return QuillController.basic();
  }

  @override
  void dispose() {
    _titleController.removeListener(_onTitleChanged);
    _titleController.dispose();
    _quillController.dispose();
    super.dispose();
  }

  String _getDescriptionContent() {
    return jsonEncode(_quillController.document.toDelta().toJson());
  }

  void _save() {
    final title = _titleController.text.trim();
    widget.onSave(
      title.isEmpty ? 'Без названия' : title,
      _getDescriptionContent(),
      _selectedPriority,
      _selectedDueDate,
    );
    Navigator.of(context).pop();
  }

  Future<void> _selectDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() => _selectedDueDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: context.colors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: context.colors.outlineVariant),
        borderRadius: BorderRadius.circular(AppThemeVariables.md),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 750, maxHeight: 800),
        child: Padding(
          padding: const EdgeInsets.all(AppThemeVariables.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(LucideIcons.x),
                    iconSize: AppThemeVariables.iconMd,
                    tooltip: 'Закрыть',
                  ),
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _titleController,
                      style: context.h2,
                      decoration: const InputDecoration(
                        hintText: 'Название задачи',
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppThemeVariables.sm),
                  _buildPrioritySelector(),
                  const SizedBox(width: AppThemeVariables.xs),
                  _buildDatePickerButton(),
                ],
              ),
              const SizedBox(height: AppThemeVariables.md),

              Expanded(
                child: Column(
                  children: [
                    _buildDescriptionModeBar(context),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: context.colors.surface,
                          borderRadius: BorderRadius.circular(
                            AppThemeVariables.xs,
                          ),
                        ),
                        padding: const EdgeInsets.all(AppThemeVariables.md),
                        child: QuillEditor.basic(controller: _quillController),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppThemeVariables.md),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Material(
                    color: context.colors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(AppThemeVariables.xs),
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      mouseCursor: SystemMouseCursors.click,
                      borderRadius: BorderRadius.circular(AppThemeVariables.xs),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppThemeVariables.xxs + 2,
                          horizontal: AppThemeVariables.lg,
                        ),
                        child: Text('Назад', style: context.body),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppThemeVariables.xs),
                  Material(
                    color: context.colors.primary,
                    borderRadius: BorderRadius.circular(AppThemeVariables.xs),
                    child: InkWell(
                      onTap: _save,
                      mouseCursor: SystemMouseCursors.click,
                      hoverColor: context.colors.secondary.withAlpha(150),
                      borderRadius: BorderRadius.circular(AppThemeVariables.xs),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppThemeVariables.xxs + 2,
                          horizontal: AppThemeVariables.lg,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              LucideIcons.check,
                              size: AppThemeVariables.iconMd,
                              color: context.colors.onPrimary,
                            ),
                            SizedBox(width: AppThemeVariables.xxs),
                            Text(
                              'Сохранить',
                              style: context.body!.copyWith(
                                color: context.colors.onPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDescriptionModeBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppThemeVariables.md),
      child: Row(
        children: [
          Material(
            color: !_isDescriptionEditing
                ? context.colors.surface
                : context.colors.surfaceContainerHigh,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppThemeVariables.xs),
            ),
            child: InkWell(
              onTap: () => setState(() {
                _isDescriptionEditing = false;
                _quillController.readOnly = true;
              }),
              mouseCursor: SystemMouseCursors.click,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppThemeVariables.xs),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppThemeVariables.xs,
                  vertical: AppThemeVariables.xs - 1,
                ),
                child: Text('Просмотр', style: context.bodySecondary),
              ),
            ),
          ),
          const SizedBox(width: AppThemeVariables.xs),
          Material(
            color: _isDescriptionEditing
                ? context.colors.surface
                : context.colors.surfaceContainerHigh,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(AppThemeVariables.xs),
              topRight: _isDescriptionEditing
                  ? Radius.circular(0)
                  : Radius.circular(AppThemeVariables.xs),
            ),
            child: InkWell(
              mouseCursor: SystemMouseCursors.click,
              onTap: () => setState(() {
                _isDescriptionEditing = true;
                _quillController.readOnly = false;
              }),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppThemeVariables.xs),
                topRight: _isDescriptionEditing
                    ? Radius.circular(0)
                    : Radius.circular(AppThemeVariables.xs),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppThemeVariables.xs,
                  vertical: AppThemeVariables.xs - 1,
                ),
                child: Text('Редактор', style: context.bodySecondary),
              ),
            ),
          ),
          if (_isDescriptionEditing) ...[
            Expanded(
              child: AppQuillToolbar(
                controller: _quillController,
                isCompact: true,
                backgroundColor: context.colors.surface,
                border: Border(),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(AppThemeVariables.xs),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPrioritySelector() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Material(
        key: _priorityKey,
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppThemeVariables.xs),
        child: Ink(
          decoration: BoxDecoration(
            color: switch (_selectedPriority) {
              TaskPriority.high => const Color.fromARGB(255, 79, 31, 29),
              TaskPriority.medium => const Color.fromARGB(255, 75, 50, 19),
              TaskPriority.low => const Color.fromARGB(255, 38, 56, 44),
            },
            borderRadius: BorderRadius.circular(AppThemeVariables.xs),
          ),
          child: InkWell(
            mouseCursor: SystemMouseCursors.click,
            hoverColor: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppThemeVariables.xs),
            onTap: () {
              final renderObject = _priorityKey.currentContext
                  ?.findRenderObject();
              if (renderObject is! RenderBox) return;

              final position = renderObject.localToGlobal(
                Offset(0, renderObject.size.height),
              );

              showAppContextMenu<TaskPriority>(
                context: context,
                position: position,
                items: const [
                  ContextMenuItem(
                    value: TaskPriority.low,
                    title: 'Низкий',
                    icon: LucideIcons.flag,
                  ),
                  ContextMenuItem(
                    value: TaskPriority.medium,
                    title: 'Средний',
                    icon: LucideIcons.flag,
                  ),
                  ContextMenuItem(
                    value: TaskPriority.high,
                    title: 'Высокий',
                    icon: LucideIcons.flag,
                  ),
                ],
              ).then((priority) {
                if (priority != null && mounted) {
                  setState(() => _selectedPriority = priority);
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppThemeVariables.sm,
                vertical: AppThemeVariables.xs,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.flag,
                    size: AppThemeVariables.iconSm,
                    color: switch (_selectedPriority) {
                      TaskPriority.high => const Color.fromARGB(
                        255,
                        249,
                        198,
                        194,
                      ),
                      TaskPriority.medium => const Color.fromARGB(
                        255,
                        253,
                        221,
                        183,
                      ),
                      TaskPriority.low => const Color.fromARGB(
                        255,
                        218,
                        241,
                        225,
                      ),
                    },
                  ),
                  const SizedBox(width: AppThemeVariables.xxs),
                  Text(
                    switch (_selectedPriority) {
                      TaskPriority.high => 'Высокий',
                      TaskPriority.medium => 'Средний',
                      TaskPriority.low => 'Низкий',
                    },
                    style: context.bodySmall?.copyWith(
                      color: switch (_selectedPriority) {
                        TaskPriority.high => const Color.fromARGB(
                          255,
                          249,
                          198,
                          194,
                        ),
                        TaskPriority.medium => const Color.fromARGB(
                          255,
                          253,
                          221,
                          183,
                        ),
                        TaskPriority.low => const Color.fromARGB(
                          255,
                          218,
                          241,
                          225,
                        ),
                      },
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDatePickerButton() {
    final dateText = _selectedDueDate != null
        ? '${_selectedDueDate!.day.toString().padLeft(2, '0')}.${_selectedDueDate!.month.toString().padLeft(2, '0')}.${_selectedDueDate!.year}'
        : 'Дата';

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppThemeVariables.xs),
      child: Ink(
        decoration: BoxDecoration(
          color: context.colors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(AppThemeVariables.xs),
        ),
        child: InkWell(
          mouseCursor: SystemMouseCursors.click,
          hoverColor: context.colors.surfaceContainerHighest,
          onTap: _selectDueDate,
          borderRadius: BorderRadius.circular(AppThemeVariables.xs),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppThemeVariables.sm,
              vertical: AppThemeVariables.xs,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons.calendar,
                  size: AppThemeVariables.iconSm,
                  color: context.colors.onSurface,
                ),
                const SizedBox(width: AppThemeVariables.xxs),
                Text(
                  dateText,
                  style: context.bodySmall!.copyWith(
                    color: context.colors.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (_selectedDueDate != null) ...[
                  const SizedBox(width: AppThemeVariables.xxs),
                  GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () => setState(() => _selectedDueDate = null),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Icon(
                        LucideIcons.x,
                        size: 14,
                        color: context.colors.error,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
