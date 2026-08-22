import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_fancy_tree_view/flutter_fancy_tree_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:notify/widgets/common/app_context_menu.dart';
import 'package:notify/widgets/common/confirm_dialog.dart';
import 'package:path/path.dart' as p;
import 'package:notify/theme/app_theme_variables.dart';
import '../../models/notes/note_node.dart';
import '../../providers/notes_provider.dart';
import '../../theme/app_theme.dart';
import '../common/inline_edit_text.dart';

class FileTreeView extends ConsumerStatefulWidget {
  final List<NoteNode> nodes;

  const FileTreeView({super.key, required this.nodes});

  @override
  ConsumerState<FileTreeView> createState() => _FileTreeViewState();
}

class _FileTreeViewState extends ConsumerState<FileTreeView> {
  late final TreeController<NoteNode> _treeController;
  late final TextEditingController _renameController;
  late final FocusNode _renameFocusNode;

  @override
  void initState() {
    super.initState();
    _renameController = TextEditingController();
    _renameFocusNode = FocusNode();

    _treeController = TreeController<NoteNode>(
      roots: widget.nodes,
      childrenProvider: (node) => node.children,
    );
  }

  @override
  void didUpdateWidget(covariant FileTreeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.nodes != widget.nodes) {
      _treeController.roots = widget.nodes;
      _restoreExpansionState(widget.nodes);
    }
  }

  void _restoreExpansionState(Iterable<NoteNode> nodes) {
    final expandedPaths = ref.read(notesProvider).expandedPaths;
    for (final node in nodes) {
      if (node.isDirectory) {
        if (expandedPaths.contains(node.path)) {
          _treeController.expand(node);
        } else {
          _treeController.collapse(node);
        }
        if (node.children.isNotEmpty) {
          _restoreExpansionState(node.children);
        }
      }
    }
  }

  @override
  void dispose() {
    _renameController.dispose();
    _renameFocusNode.dispose();
    _treeController.dispose();
    super.dispose();
  }

  void _setupRenameField(String path) {
    _renameController.text = p.basenameWithoutExtension(path);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _renameFocusNode.requestFocus();
      _renameController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _renameController.text.length,
      );
    });
  }

  void _submitRename(NoteNode node) {
    final newTitle = _renameController.text.trim();
    if (newTitle.isNotEmpty && newTitle != node.title) {
      ref.read(notesProvider.notifier).renameNode(node, newTitle);
    } else {
      ref.read(notesProvider.notifier).cancelEditing();
    }
  }

  void _showItemMenu(BuildContext context, Offset position, NoteNode node) {
    final notifier = ref.read(notesProvider.notifier);

    showAppContextMenu<String>(
      context: context,
      position: position,
      items: const [
        ContextMenuItem(
          value: 'create_file',
          title: 'Новая заметка',
          icon: LucideIcons.filePlus,
        ),
        ContextMenuItem(
          value: 'create_folder',
          title: 'Новая папка',
          icon: LucideIcons.folderPlus,
        ),
        ContextMenuItem(
          value: 'rename',
          title: 'Переименовать',
          icon: LucideIcons.pencil,
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
      if (action == 'create_file') {
        notifier.createNote(node);
      } else if (action == 'create_folder') {
        notifier.createFolder(node);
      } else if (action == 'rename') {
        notifier.startEditing(node.path);
      } else if (action == 'delete' && context.mounted) {
        showConfirmDialog(
          context,
          title: node.isDirectory ? 'Удалить папку?' : 'Удалить заметку?',
          message: 'Данные будут удалены безвозвратно.',
          confirmText: 'Удалить',
        ).then((confirmed) {
          if (confirmed) {
            notifier.deleteNode(node);
          }
        });
      }
    });
  }

  void _showBackgroundMenu(BuildContext context, Offset position) {
    final notifier = ref.read(notesProvider.notifier);

    showAppContextMenu<String>(
      context: context,
      position: position,
      items: const [
        ContextMenuItem(
          value: 'create_file',
          title: 'Новая заметка',
          icon: LucideIcons.filePlus,
        ),
        ContextMenuItem(
          value: 'create_folder',
          title: 'Новая папка',
          icon: LucideIcons.folderPlus,
        ),
      ],
    ).then((action) {
      if (action == 'create_file') {
        notifier.createNote();
      } else if (action == 'create_folder') {
        notifier.createFolder();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(notesProvider.select((s) => s.editingPath), (previous, next) {
      if (next != null) {
        _setupRenameField(next);
      } else {
        _renameController.clear();
      }
    });

    final notesState = ref.watch(notesProvider);
    final notifier = ref.read(notesProvider.notifier);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onSecondaryTapUp: (details) =>
          _showBackgroundMenu(context, details.globalPosition),
      child: widget.nodes.isEmpty
          ? Center(child: Text('Нет заметок', style: context.bodySmall))
          : TreeView<NoteNode>(
              treeController: _treeController,
              nodeBuilder: (BuildContext context, TreeEntry<NoteNode> entry) {
                final node = entry.node;
                final isSelected = notesState.selectedFilePath == node.path;
                final isEditing = notesState.editingPath == node.path;

                return TreeIndentation(
                  entry: entry,
                  guide: const IndentGuide(indent: AppThemeVariables.md),
                  child: GestureDetector(
                    onSecondaryTapDown: (details) {
                      _showItemMenu(context, details.globalPosition, node);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppThemeVariables.xxs,
                        horizontal: AppThemeVariables.xs,
                      ),
                      child: Material(
                        color: isSelected
                            ? context.colors.surfaceContainerHighest
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(
                          AppThemeVariables.xs,
                        ),
                        child: InkWell(
                          mouseCursor: SystemMouseCursors.click,
                          hoverColor: context.colors.surfaceContainerHigh,
                          splashColor: context.colors.primary.withValues(
                            alpha: 0.16,
                          ),
                          borderRadius: BorderRadius.circular(
                            AppThemeVariables.xs,
                          ),
                          onTap: () {
                            if (isEditing) return;

                            if (node.isDirectory) {
                              _treeController.toggleExpansion(node);
                              notifier.togglePathExpanded(node.path);
                            } else {
                              notifier.selectFile(node.path);
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(
                              AppThemeVariables.xxs,
                            ),
                            child: Row(
                              children: [
                                if (node.isDirectory) ...[
                                  Icon(
                                    entry.isExpanded
                                        ? LucideIcons.chevronDown
                                        : LucideIcons.chevronRight,
                                    size: AppThemeVariables.iconMd,
                                  ),
                                  SizedBox(width: AppThemeVariables.xxs),
                                ] else
                                  const SizedBox(width: AppThemeVariables.md),

                                const SizedBox(width: AppThemeVariables.xxs),

                                Icon(
                                  node.isDirectory
                                      ? (entry.isExpanded
                                            ? LucideIcons.folderOpen
                                            : LucideIcons.folder)
                                      : LucideIcons.fileText,
                                  size: AppThemeVariables.iconMd,
                                  color: isSelected || entry.isExpanded
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                ),

                                const SizedBox(width: AppThemeVariables.xs),

                                Expanded(
                                  child: isEditing
                                      ? CallbackShortcuts(
                                          bindings: {
                                            const SingleActivator(
                                              LogicalKeyboardKey.escape,
                                            ): () {
                                              notifier.cancelEditing();
                                            },
                                          },
                                          child: TextField(
                                            controller: _renameController,
                                            focusNode: _renameFocusNode,
                                            style: context.bodySecondary,
                                            cursorHeight: 14,
                                            decoration: InputDecoration(
                                              isDense: true,
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal:
                                                        AppThemeVariables.xxs,
                                                    vertical: 2.0,
                                                  ),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                      AppThemeVariables.xxs,
                                                    ),
                                                borderSide: BorderSide(
                                                  color: context.colors.primary,
                                                ),
                                              ),
                                            ),
                                            onSubmitted: (_) =>
                                                _submitRename(node),
                                            onTapOutside: (_) =>
                                                _submitRename(node),
                                          ),
                                        )
                                      : InlineEditText(
                                          text: node.title,
                                          style: context.body,
                                          trigger: InlineEditTrigger.doubleTap,
                                          onSubmitted: (newTitle) {
                                            notifier.renameNode(node, newTitle);
                                          },
                                        ),
                                ),
                              ],
                            ),
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
