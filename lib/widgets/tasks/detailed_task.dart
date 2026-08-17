import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../models/tasks/task.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_theme_variables.dart';

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

  @override
  void initState() {
    super.initState();

    _titleController = TextEditingController(text: widget.task.title);
    _selectedPriority = widget.task.priority;
    _selectedDueDate = widget.task.dueDate;

    _titleController.addListener(_onTitleChanged);
    _quillController = _initQuillController(widget.task.description);
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
      backgroundColor: context.colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppThemeVariables.lg),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 750, maxHeight: 800),
        child: Padding(
          padding: const EdgeInsets.all(AppThemeVariables.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. ВЕРХНЯЯ СТРОКА: Динамический заголовок и Закрытие
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _titleController.text.trim().isEmpty
                          ? 'Новая задача'
                          : _titleController.text,
                      style: context.bodySecondary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(LucideIcons.x),
                    iconSize: AppThemeVariables.iconSm,
                    tooltip: 'Закрыть',
                  ),
                ],
              ),
              const Divider(height: AppThemeVariables.md),

              // 2. ТУЛБАР РЕДАКТОРА (QuillSimpleToolbar)
              Container(
                decoration: BoxDecoration(
                  color: context.colors.surfaceContainerLow,
                  borderRadius: AppThemeVariables.borderRadiusSm,
                ),
                child: QuillSimpleToolbar(
                  controller: _quillController,
                  config: const QuillSimpleToolbarConfig(
                    showFontFamily: false,
                    showFontSize: false,
                    showSearchButton: false,
                    showInlineCode: false,
                    showSubscript: false,
                    showSuperscript: false,
                    showColorButton: false,
                    showBackgroundColorButton: false,
                    showAlignmentButtons: false,
                    showDirection: false,
                    showLink: false,
                    showCodeBlock: false,
                    showQuote: false,
                  ),
                ),
              ),
              const SizedBox(height: AppThemeVariables.md),

              // 3. ПОЛЕ НАЗВАНИЯ + ПРИОРИТЕТ + ДАТА
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

              // 4. ОСНОВНОЙ РЕДАКТОР (QuillEditor)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(AppThemeVariables.xs),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: context.colors.outlineVariant.withAlpha(100),
                    ),
                    borderRadius: AppThemeVariables.borderRadiusSm,
                  ),
                  child: QuillEditor.basic(controller: _quillController),
                ),
              ),
              const SizedBox(height: AppThemeVariables.md),

              // 5. КНОПКИ УПРАВЛЕНИЯ
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Назад'),
                  ),
                  const SizedBox(width: AppThemeVariables.xs),
                  ElevatedButton.icon(
                    onPressed: _save,
                    icon: const Icon(
                      LucideIcons.check,
                      size: AppThemeVariables.iconSm,
                    ),
                    label: const Text('Сохранить'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrioritySelector() {
    return PopupMenuButton<TaskPriority>(
      initialValue: _selectedPriority,
      onSelected: (priority) => setState(() => _selectedPriority = priority),
      itemBuilder: (context) => const [
        PopupMenuItem(value: TaskPriority.low, child: Text('Низкий')),
        PopupMenuItem(value: TaskPriority.medium, child: Text('Средний')),
        PopupMenuItem(value: TaskPriority.high, child: Text('Высокий')),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppThemeVariables.sm,
          vertical: AppThemeVariables.xs,
        ),
        decoration: BoxDecoration(
          color: context.colors.surfaceContainerHigh,
          borderRadius: AppThemeVariables.borderRadiusSm,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.flag,
              size: AppThemeVariables.iconSm,
              color: context.colors.primary,
            ),
            const SizedBox(width: AppThemeVariables.xxs),
            Text(
              _getPriorityLabel(_selectedPriority),
              style: context.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePickerButton() {
    final dateText = _selectedDueDate != null
        ? '${_selectedDueDate!.day.toString().padLeft(2, '0')}.${_selectedDueDate!.month.toString().padLeft(2, '0')}.${_selectedDueDate!.year}'
        : 'Дата';

    return InkWell(
      onTap: _selectDueDate,
      borderRadius: AppThemeVariables.borderRadiusSm,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppThemeVariables.sm,
          vertical: AppThemeVariables.xs,
        ),
        decoration: BoxDecoration(
          color: context.colors.surfaceContainerHigh,
          borderRadius: AppThemeVariables.borderRadiusSm,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.calendar,
              size: AppThemeVariables.iconSm,
              color: context.colors.onSurfaceVariant,
            ),
            const SizedBox(width: AppThemeVariables.xxs),
            Text(dateText, style: context.bodySmall),
            if (_selectedDueDate != null) ...[
              const SizedBox(width: AppThemeVariables.xxs),
              GestureDetector(
                onTap: () => setState(() => _selectedDueDate = null),
                child: Icon(
                  LucideIcons.x,
                  size: 14,
                  color: context.colors.error,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getPriorityLabel(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return 'Высокий';
      case TaskPriority.medium:
        return 'Средний';
      case TaskPriority.low:
        return 'Низкий';
    }
  }
}
