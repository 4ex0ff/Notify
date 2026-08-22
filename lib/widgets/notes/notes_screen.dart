import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:path/path.dart' as p;

import '../../providers/notes_provider.dart';
import '../../models/notes/note_node.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_theme_variables.dart';
import '../common/app_quill_toolbar.dart';

class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  static const _contentWidthFactor = 0.75;

  QuillController? _quillController;
  late final TextEditingController _titleController;
  late final FocusNode _titleFocusNode;
  String? _currentLoadedPath;
  Timer? _autoSaveTimer;
  StreamSubscription? _documentSubscription;
  int _editorGeneration = 0;
  bool _isRenamingTitle = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _titleFocusNode = FocusNode()..addListener(_handleTitleFocusChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final initialPath = ref.read(notesProvider).selectedFilePath;
      if (initialPath != null) {
        _loadNote(initialPath);
      }
    });
  }

  @override
  void dispose() {
    _titleFocusNode
      ..removeListener(_handleTitleFocusChange)
      ..dispose();
    _titleController.dispose();
    _resetEditor();
    super.dispose();
  }

  void _handleTitleFocusChange() {
    if (!_titleFocusNode.hasFocus) {
      unawaited(_commitTitle());
    }
  }

  void _resetEditor() {
    _editorGeneration++;
    _autoSaveTimer?.cancel();
    _autoSaveTimer = null;
    _documentSubscription?.cancel();
    _documentSubscription = null;
    _quillController?.dispose();
    _quillController = null;
    _currentLoadedPath = null;
  }

  Future<void> _loadNote(String path) async {
    if (_currentLoadedPath == path) return;

    final generation = ++_editorGeneration;
    _autoSaveTimer?.cancel();

    final file = File(path);
    if (!await file.exists()) {
      if (mounted && generation == _editorGeneration) {
        setState(() => _resetEditor());
      }
      return;
    }

    final content = await file.readAsString();
    if (!mounted || generation != _editorGeneration) return;
    Document doc;

    try {
      if (content.trim().isEmpty || content == '[]') {
        doc = Document()..insert(0, '');
      } else {
        final json = jsonDecode(content);
        doc = Document.fromJson(json);
      }
    } catch (_) {
      doc = Document()..insert(0, '');
    }

    if (!mounted || generation != _editorGeneration) return;

    _documentSubscription?.cancel();
    _quillController?.dispose();

    final controller = QuillController(
      document: doc,
      selection: const TextSelection.collapsed(offset: 0),
    );

    _documentSubscription = controller.document.changes.listen((_) {
      _scheduleAutoSave(path);
    });

    setState(() {
      _quillController = controller;
      _currentLoadedPath = path;
      _titleController.text = p.basenameWithoutExtension(path);
    });
  }

  Future<void> _commitTitle() async {
    if (_isRenamingTitle) return;

    final path = _currentLoadedPath;
    final title = _titleController.text.trim();
    if (path == null || title.isEmpty) return;

    final currentTitle = p.basenameWithoutExtension(path);
    if (title == currentTitle) return;

    _isRenamingTitle = true;
    try {
      await ref
          .read(notesProvider.notifier)
          .renameNode(
            NoteNode(title: currentTitle, path: path, isDirectory: false),
            title,
          );
    } finally {
      _isRenamingTitle = false;
    }
  }

  void _scheduleAutoSave(String path) {
    _autoSaveTimer?.cancel();
    final generation = _editorGeneration;
    final controller = _quillController;
    if (controller == null) return;

    _autoSaveTimer = Timer(const Duration(milliseconds: 500), () async {
      if (!mounted ||
          generation != _editorGeneration ||
          _currentLoadedPath != path ||
          _quillController != controller) {
        return;
      }

      final deltaJson = jsonEncode(controller.document.toDelta().toJson());
      final file = File(path);

      if (!await file.exists()) return;
      if (!mounted ||
          generation != _editorGeneration ||
          _currentLoadedPath != path ||
          _quillController != controller) {
        return;
      }

      await file.writeAsString(deltaJson);
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(notesProvider.select((s) => s.selectedFilePath), (
      previous,
      next,
    ) {
      if (next != null) {
        if (next != _currentLoadedPath) {
          _loadNote(next);
        }
      } else {
        setState(() {
          _resetEditor();
        });
      }
    });

    final selectedFilePath = ref.watch(
      notesProvider.select((s) => s.selectedFilePath),
    );

    if (selectedFilePath == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.fileText,
              size: AppThemeVariables.xxxl,
              color: context.colors.onSurfaceVariant.withAlpha(100),
            ),
            const SizedBox(height: AppThemeVariables.md),
            Text(
              'Выберите заметку или создайте новую',
              style: context.bodySecondary,
            ),
          ],
        ),
      );
    }

    if (_quillController == null || _currentLoadedPath != selectedFilePath) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    return Scaffold(
      backgroundColor: context.colors.surface,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(
              top: AppThemeVariables.xl,
              bottom: AppThemeVariables.sm,
            ),
            child: Center(
              child: FractionallySizedBox(
                widthFactor: _contentWidthFactor,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppThemeVariables.xl,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: AppQuillToolbar(controller: _quillController!),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: FractionallySizedBox(
                widthFactor: _contentWidthFactor,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppThemeVariables.xl,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppThemeVariables.md),
                      TextField(
                        controller: _titleController,
                        focusNode: _titleFocusNode,
                        style: context.h1,
                        maxLines: 1,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) {
                          unawaited(_commitTitle());
                          _titleFocusNode.unfocus();
                        },
                        decoration: const InputDecoration(
                          hintText: 'Название заметки',
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const SizedBox(height: AppThemeVariables.md),
                      Expanded(
                        child: QuillEditor.basic(
                          controller: _quillController!,
                          config: QuillEditorConfig(
                            placeholder: 'Начните писать здесь...',
                            padding: EdgeInsets.zero,
                            customStyles: DefaultStyles(
                              code: DefaultTextBlockStyle(
                                TextStyle(
                                  color: context.colors.onSurface,
                                  fontSize: 13,
                                  fontFamily: 'monospace',
                                ),
                                HorizontalSpacing.zero,
                                const VerticalSpacing(8, 8),
                                const VerticalSpacing(0, 0),
                                BoxDecoration(
                                  color: context.colors.surfaceContainerHigh,
                                  borderRadius: BorderRadius.circular(
                                    AppThemeVariables.xs,
                                  ),
                                  border: Border.all(
                                    color: context.colors.outlineVariant,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
