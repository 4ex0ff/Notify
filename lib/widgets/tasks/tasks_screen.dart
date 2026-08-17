import 'dart:convert';
import 'package:boardview/board_item.dart';
import 'package:boardview/board_list.dart';
import 'package:boardview/boardview.dart';
import 'package:boardview/boardview_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../../models/tasks/task.dart';
import '../../providers/tasks_provider.dart';
import '../tasks/detailed_task.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_theme_variables.dart';
import '../common/app_context_menu.dart';
import '../common/confirm_dialog.dart';
import '../common/inline_edit_text.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  // ignore: deprecated_member_use
  final BoardViewController _boardController = BoardViewController();

  @override
  Widget build(BuildContext context) {
    final tasksState = ref.watch(tasksProvider);
    final selectedBoard = tasksState.selectedBoard;

    if (selectedBoard == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.squareKanban,
              size: 48,
              color: context.colors.onSurfaceVariant.withAlpha(125),
            ),
            const SizedBox(height: AppThemeVariables.md),
            Text(
              'Выберите доску или создайте новую',
              style: context.bodySecondary,
            ),
          ],
        ),
      );
    }

    // Подготовка данных доски для передачи в boardbiew
    final List<BoardList> boardLists = selectedBoard.columns.map((column) {
      final boardItems = column.tasks.map((task) {
        return BoardItem(
          onStartDragItem: (listIndex, itemIndex, state) {},
          onDropItem:
              (listIndex, itemIndex, oldListIndex, oldItemIndex, state) {
                if (listIndex == null ||
                    itemIndex == null ||
                    oldListIndex == null ||
                    oldItemIndex == null) {
                  return;
                }

                final fromColumn = selectedBoard.columns[oldListIndex];
                final toColumn = selectedBoard.columns[listIndex];

                ref
                    .read(tasksProvider.notifier)
                    .moveTask(
                      fromColumnId: fromColumn.id,
                      toColumnId: toColumn.id,
                      fromIndex: oldItemIndex,
                      toIndex: itemIndex,
                    );
              },
          onTapItem: (listIndex, itemIndex, state) {},
          item: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppThemeVariables.xxs,
            ),
            child: Container(
              padding: EdgeInsets.symmetric(
                vertical: AppThemeVariables.xxs,
                horizontal: AppThemeVariables.xs,
              ),
              color: context.colors.surfaceContainerHigh,
              child: _buildTaskCard(context, column.id, task),
            ),
          ),
        );
      }).toList();

      return BoardList(
        onDropList: (listIndex, oldListIndex) {
          if (listIndex == null ||
              oldListIndex == null ||
              listIndex == oldListIndex) {
            return;
          }

          ref
              .read(tasksProvider.notifier)
              .moveColumn(fromIndex: oldListIndex, toIndex: listIndex);
        },
        header: [
          Expanded(child: _buildColumnHeader(context, column.id, column.title)),
        ],
        items: boardItems,
        footer: _buildColumnFooter(context, column.id),
        backgroundColor: Colors.transparent,
      );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Заголовок
        Padding(
          padding: const EdgeInsets.only(
            left: AppThemeVariables.xl,
            right: AppThemeVariables.xl,
            top: AppThemeVariables.lg,
            bottom: AppThemeVariables.md,
          ),
          child: Row(
            children: [
              Expanded(
                child: InlineEditText(
                  text: selectedBoard.title,
                  style: context.h1,
                  trigger: InlineEditTrigger.doubleTap,
                  onSubmitted: (newTitle) {
                    ref
                        .read(tasksProvider.notifier)
                        .renameBoard(selectedBoard.id, newTitle);
                  },
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  ref
                      .read(tasksProvider.notifier)
                      .createColumn('Новый столбец');
                },
                icon: const Icon(
                  LucideIcons.plus,
                  size: AppThemeVariables.iconSm,
                ),
                label: const Text('Добавить столбец'),
              ),
            ],
          ),
        ),

        // Рабочая область
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final columnCount = selectedBoard.columns.length;

              final double minWidth =
                  constraints.maxWidth * 0.25; // Минимум 25%
              final double maxWidth =
                  constraints.maxWidth * 0.50; // Максимум 50%

              final double calculatedWidth = columnCount > 0
                  ? constraints.maxWidth / columnCount
                  : minWidth;

              final double columnWidth = calculatedWidth.clamp(
                minWidth,
                maxWidth,
              );

              return BoardView(
                boardViewController: _boardController,
                lists: boardLists,
                width: columnWidth,
                dragDelay: 50,
                bottomPadding: AppThemeVariables.xs,
                scrollbar: true,
              );
            },
          ),
        ),
      ],
    );
  }

  // Заголовок столбца
  Widget _buildColumnHeader(
    BuildContext context,
    String columnId,
    String title,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppThemeVariables.xxs),
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppThemeVariables.md,
          horizontal: AppThemeVariables.md,
        ),
        decoration: BoxDecoration(
          color: context.colors.surfaceContainerHigh,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppThemeVariables.xs),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: InlineEditText(
                text: title,
                style: context.h3,
                trigger: InlineEditTrigger.doubleTap,
                onSubmitted: (newTitle) {
                  ref
                      .read(tasksProvider.notifier)
                      .renameColumn(columnId, newTitle);
                },
              ),
            ),
            InkWell(
              borderRadius: AppThemeVariables.borderRadiusSm,
              onTap: () {
                ref
                    .read(tasksProvider.notifier)
                    .createTask(columnId, 'Новая задача');
              },
              child: Icon(
                LucideIcons.plus,
                size: AppThemeVariables.iconSm,
                color: context.colors.onSurfaceVariant,
              ),
            ),
            SizedBox(width: AppThemeVariables.xs),
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTapDown: (details) async {
                showAppContextMenu<String>(
                  context: context,
                  position: details.globalPosition,
                  items: const [
                    ContextMenuItem(
                      value: 'delete',
                      title: 'Удалить',
                      icon: LucideIcons.trash2,
                      isDestructive: true,
                    ),
                  ],
                ).then((action) {
                  if (!context.mounted) return;

                  if (action == 'delete') {
                    showConfirmDialog(
                      context,
                      title: 'Удалить столбец "$title"?',
                      message: 'Все задачи в этом столбце будут удалены.',
                      confirmText: 'Удалить',
                    ).then((confirmed) {
                      if (confirmed == true && context.mounted) {
                        ref.read(tasksProvider.notifier).deleteColumn(columnId);
                      }
                    });
                  }
                });
              },
              child: Icon(
                LucideIcons.ellipsisVertical,
                size: AppThemeVariables.iconSm,
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Футер
  Widget _buildColumnFooter(BuildContext context, String columnId) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppThemeVariables.xxs),
      child: Container(
        padding: const EdgeInsets.all(AppThemeVariables.xxs),
        decoration: BoxDecoration(
          color: context.colors.surfaceContainerHigh,
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(AppThemeVariables.xs),
          ),
        ),
      ),
    );
  }

  // Карточка задачи
  Widget _buildTaskCard(BuildContext context, String columnId, Task task) {
    final plainDescription = _getPlainTextFromDescription(task.description);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onSecondaryTapDown: (details) async {
        showAppContextMenu<String>(
          context: context,
          position: details.globalPosition,
          items: const [
            ContextMenuItem(
              value: 'edit',
              title: 'Редактировать',
              icon: LucideIcons.pencil,
            ),
            ContextMenuItem(
              value: 'delete',
              title: 'Удалить',
              icon: LucideIcons.trash2,
              isDestructive: true,
            ),
          ],
        ).then((action) {
          if (!context.mounted) return;

          if (action == 'edit') {
            _openTaskDetails(context, columnId, task);
          } else if (action == 'delete') {
            ref.read(tasksProvider.notifier).deleteTask(columnId, task.id);
          }
        });
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppThemeVariables.md),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: AppThemeVariables.borderRadiusSm,
          border: Border.all(
            color: context.colors.outlineVariant.withAlpha(125),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => _openTaskDetails(context, columnId, task),
              child: Text(
                task.title,
                style: context.body!.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: AppThemeVariables.sm),
            // Описание
            if (plainDescription.isNotEmpty) ...[
              const SizedBox(height: AppThemeVariables.xs),
              Text(
                plainDescription,
                style: context.bodySecondary,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: AppThemeVariables.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Приоритет
                _buildPriorityBadge(context, task.priority),
                // Дата окончания
                if (task.dueDate != null) ...[
                  const SizedBox(height: AppThemeVariables.sm),
                  Row(
                    children: [
                      Icon(
                        LucideIcons.calendar,
                        size: AppThemeVariables.iconSm,
                        color: context.colors.onSurfaceVariant,
                      ),
                      const SizedBox(width: AppThemeVariables.xxs),
                      Text(
                        '${task.dueDate!.day.toString().padLeft(2, '0')}.${task.dueDate!.month.toString().padLeft(2, '0')}.${task.dueDate!.year}',
                        style: context.bodySmall,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openTaskDetails(BuildContext context, String columnId, Task task) {
    DetailedTaskDialog.show(
      context,
      task: task,
      onSave: (newTitle, newDescription, newPriority, newDueDate) {
        ref
            .read(tasksProvider.notifier)
            .updateTask(
              columnId,
              task.copyWith(
                title: newTitle,
                description: newDescription,
                priority: newPriority,
                dueDate: newDueDate,
              ),
            );
      },
    );
  }

  String _getPlainTextFromDescription(String rawDescription) {
    if (rawDescription.trim().isEmpty) return '';

    try {
      final parsed = jsonDecode(rawDescription);
      if (parsed is List) {
        final doc = Document.fromJson(parsed);
        return doc.toPlainText().trim();
      }
    } catch (_) {
      // Если в поле лежит обычный текст (от старых задач)
      return rawDescription.trim();
    }

    return rawDescription.trim();
  }

  // Приоритет задачи
  Widget _buildPriorityBadge(BuildContext context, TaskPriority priority) {
    Color bgColor;
    Color textColor;
    String label;

    switch (priority) {
      case TaskPriority.high:
        bgColor = const Color.fromARGB(255, 79, 31, 29);
        textColor = const Color.fromARGB(255, 249, 198, 194);
        label = 'Высокий';
        break;
      case TaskPriority.medium:
        bgColor = const Color.fromARGB(255, 75, 50, 19);
        textColor = const Color.fromARGB(255, 253, 221, 183);
        label = 'Средний';
        break;
      case TaskPriority.low:
        bgColor = const Color.fromARGB(255, 38, 56, 44);
        textColor = const Color.fromARGB(255, 218, 241, 225);
        label = 'Низкий';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppThemeVariables.xs,
        vertical: AppThemeVariables.xxs,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppThemeVariables.borderRadiusSm,
      ),
      child: Text(
        label,
        style: context.bodySmall?.copyWith(color: textColor, fontSize: 11),
      ),
    );
  }
}
