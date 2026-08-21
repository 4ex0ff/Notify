import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../providers/tasks_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_theme_variables.dart';
import '../common/app_context_menu.dart';
import '../common/confirm_dialog.dart';
import '../common/inline_edit_text.dart';

class BoardsListView extends ConsumerStatefulWidget {
  const BoardsListView({super.key});

  @override
  ConsumerState<BoardsListView> createState() => _BoardsListViewState();
}

class _BoardsListViewState extends ConsumerState<BoardsListView> {
  final Map<String, GlobalKey<InlineEditTextState>> _editKeys = {};

  GlobalKey<InlineEditTextState> _getKeyForBoard(String boardId) {
    return _editKeys.putIfAbsent(
      boardId,
      () => GlobalKey<InlineEditTextState>(),
    );
  }

  // Контекстное меню при клике на доску
  void _openMenu(
    BuildContext context,
    WidgetRef ref,
    Offset position,
    String boardId,
    String boardTitle,
  ) async {
    showAppContextMenu<String>(
      context: context,
      position: position,
      items: const [
        ContextMenuItem(
          value: 'create',
          title: 'Новая доска',
          icon: LucideIcons.clipboardPlus,
        ),
        ContextMenuItem(
          value: 'rename',
          title: 'Переименовать',
          icon: LucideIcons.pencil,
        ),
        ContextMenuItem(
          value: 'refresh',
          title: 'Обновить',
          icon: LucideIcons.refreshCw,
        ),
        ContextMenuDivider(),
        ContextMenuItem(
          value: 'delete',
          title: 'Удалить',
          icon: LucideIcons.trash2,
          isDestructive: true,
        ),
      ],
    ).then((action) {
      if (action == 'create') {
        ref.read(tasksProvider.notifier).createBoard('Новая доска');
      } else if (action == 'rename') {
        _getKeyForBoard(boardId).currentState?.startEditing();
      } else if (action == 'refresh') {
        ref.read(tasksProvider.notifier).initTasks();
      } else if (action == 'delete' && context.mounted) {
        showConfirmDialog(
          context,
          title: 'Удалить доску "$boardTitle"?',
          message: 'Данные этой доски будут удалены безвозвратно.',
          confirmText: 'Удалить',
          cancelText: 'Отмена',
        ).then((confirmed) {
          if (confirmed) {
            _editKeys.remove(boardId);
            ref.read(tasksProvider.notifier).deleteBoard(boardId);
          }
        });
      }
    });
  }

  // Контекстное меню при клике по пустому месту
  void _openBackgroundMenu(
    BuildContext context,
    WidgetRef ref,
    Offset position,
  ) async {
    final action = await showAppContextMenu<String>(
      context: context,
      position: position,
      items: const [
        ContextMenuItem(
          value: 'create',
          title: 'Новая доска',
          icon: LucideIcons.clipboardPlus,
        ),
        ContextMenuItem(
          value: 'refresh',
          title: 'Обновить',
          icon: LucideIcons.refreshCw,
        ),
      ],
    );

    if (action == 'create') {
      ref.read(tasksProvider.notifier).createBoard('Новая доска');
    } else if (action == 'refresh') {
      ref.read(tasksProvider.notifier).initTasks();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tasksState = ref.watch(tasksProvider);
    final notifier = ref.read(tasksProvider.notifier);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onSecondaryTapUp: (details) =>
          _openBackgroundMenu(context, ref, details.globalPosition),
      child: tasksState.boards.isEmpty
          ? Center(child: Text('Нет созданных досок', style: context.bodySmall))
          : ListView.builder(
              itemCount: tasksState.boards.length,
              itemBuilder: (context, index) {
                final board = tasksState.boards[index];
                final isSelected = board.id == tasksState.selectedBoardId;

                return GestureDetector(
                  onSecondaryTapUp: (details) => _openMenu(
                    context,
                    ref,
                    details.globalPosition,
                    board.id,
                    board.title,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppThemeVariables.xxs,
                      horizontal: AppThemeVariables.xs,
                    ),
                    child: Material(
                      color: isSelected
                          ? context.colors.surfaceContainerHighest
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppThemeVariables.xs),
                      child: InkWell(
                        mouseCursor: SystemMouseCursors.click,
                        hoverColor: context.colors.surfaceContainerHigh,
                        splashColor: context.colors.primary.withValues(
                          alpha: 0.16,
                        ),
                        borderRadius: BorderRadius.circular(
                          AppThemeVariables.xs,
                        ),
                        onTap: () => notifier.selectBoard(board.id),
                        child: Padding(
                          padding: const EdgeInsets.all(AppThemeVariables.xs),
                          child: Row(
                            children: [
                              Icon(
                                LucideIcons.clipboardList,
                                size: AppThemeVariables.iconMd,
                                color: isSelected
                                    ? context.colors.primary
                                    : context.colors.onSurfaceVariant,
                              ),
                              const SizedBox(width: AppThemeVariables.xs),
                              Expanded(
                                child: InlineEditText(
                                  key: _getKeyForBoard(board.id),
                                  text: board.title,
                                  style: context.body,
                                  trigger: InlineEditTrigger.doubleTap,
                                  onSubmitted: (newTitle) {
                                    notifier.renameBoard(board.id, newTitle);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
