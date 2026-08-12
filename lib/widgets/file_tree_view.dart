import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_fancy_tree_view/flutter_fancy_tree_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:path/path.dart' as p;
import 'package:notify/theme/app_theme_variables.dart';
import '../models/note_node.dart';
import '../providers/notes_provider.dart';
import '../theme/app_theme.dart';

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

  void _showContextMenu(BuildContext context, Offset position, NoteNode node) {
    final notifier = ref.read(notesProvider.notifier);

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx,
        position.dy,
      ),
      items: [
        PopupMenuItem(
          value: 'create_file',
          height: AppThemeVariables.xl,
          child: Row(
            children: [
              const Icon(LucideIcons.filePlus, size: AppThemeVariables.iconSm),
              const SizedBox(width: AppThemeVariables.xs),
              Text('Новая заметка', style: context.bodySecondary),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'create_folder',
          height: AppThemeVariables.xl,
          child: Row(
            children: [
              const Icon(
                LucideIcons.folderPlus,
                size: AppThemeVariables.iconSm,
              ),
              const SizedBox(width: AppThemeVariables.xs),
              Text('Новая папка', style: context.bodySecondary),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'rename',
          height: AppThemeVariables.xl,
          child: Row(
            children: [
              const Icon(LucideIcons.pencil, size: AppThemeVariables.iconSm),
              const SizedBox(width: AppThemeVariables.xs),
              Text('Переименовать', style: context.bodySecondary),
            ],
          ),
        ),
        PopupMenuDivider(),
        PopupMenuItem(
          value: 'delete',
          height: AppThemeVariables.xl,
          child: Row(
            children: [
              Icon(
                LucideIcons.trash2,
                size: AppThemeVariables.iconSm,
                color: context.colors.error,
              ),
              const SizedBox(width: AppThemeVariables.xs),
              Text(
                'Удалить',
                style: context.bodySecondary?.copyWith(
                  color: context.colors.error,
                ),
              ),
            ],
          ),
        ),
      ],
    ).then((action) {
      if (action == 'create_file') {
        notifier.createNote(node);
      } else if (action == 'create_folder') {
        notifier.createFolder(node);
      } else if (action == 'rename') {
        notifier.startEditing(node.path);
      } else if (action == 'delete') {
        notifier.deleteNode(node);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.nodes.isEmpty) {
      return Center(child: Text('Нет заметок', style: context.bodySmall));
    }

    ref.listen(notesProvider.select((s) => s.editingPath), (previous, next) {
      if (next != null) {
        _setupRenameField(next);
      } else {
        _renameController.clear();
      }
    });

    final notesState = ref.watch(notesProvider);
    final notifier = ref.read(notesProvider.notifier);

    return TreeView<NoteNode>(
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
              _showContextMenu(context, details.globalPosition, node);
            },
            child: InkWell(
              borderRadius: AppThemeVariables.borderRadiusXs,
              onTap: () {
                if (isEditing) return;

                if (node.isDirectory) {
                  _treeController.toggleExpansion(node);
                  notifier.togglePathExpanded(node.path);
                } else {
                  notifier.selectFile(node.path);
                }
              },
              child: Container(
                color: isSelected
                    ? context.colors.surfaceContainerHigh
                    : Colors.transparent,
                padding: const EdgeInsets.symmetric(
                  vertical: AppThemeVariables.xxs,
                  horizontal: AppThemeVariables.xs,
                ),
                child: Row(
                  children: [
                    if (node.isDirectory)
                      Icon(
                        entry.isExpanded
                            ? LucideIcons.chevronDown
                            : LucideIcons.chevronRight,
                        size: AppThemeVariables.iconSm,
                      )
                    else
                      const SizedBox(width: AppThemeVariables.md),

                    const SizedBox(width: AppThemeVariables.xxs),

                    Icon(
                      node.isDirectory
                          ? (entry.isExpanded
                                ? LucideIcons.folderOpen
                                : LucideIcons.folder)
                          : LucideIcons.fileText,
                      size: AppThemeVariables.iconSm,
                      color: node.isDirectory
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
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
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: AppThemeVariables.xxs,
                                    vertical: 2.0,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius:
                                        AppThemeVariables.borderRadiusXs,
                                    borderSide: BorderSide(
                                      color: context.colors.primary,
                                    ),
                                  ),
                                ),
                                onSubmitted: (_) => _submitRename(node),
                                onTapOutside: (_) => _submitRename(node),
                              ),
                            )
                          : Text(
                              node.title,
                              style: context.bodySecondary,
                              overflow: TextOverflow.ellipsis,
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
