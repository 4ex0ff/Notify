import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:path/path.dart' as p;

import '../../providers/notes_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_theme_variables.dart';

class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  QuillController? _quillController;
  String? _currentLoadedPath;
  Timer? _autoSaveTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final initialPath = ref.read(notesProvider).selectedFilePath;
      if (initialPath != null) {
        _loadNote(initialPath);
      }
    });
  }

  @override
  void dispose() {
    _resetEditor();
    super.dispose();
  }

  void _resetEditor() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = null;
    _quillController?.dispose();
    _quillController = null;
    _currentLoadedPath = null;
  }

  Future<void> _loadNote(String path) async {
    if (_currentLoadedPath == path) return;

    _autoSaveTimer?.cancel();

    final file = File(path);
    if (!await file.exists()) {
      if (mounted) {
        setState(() => _resetEditor());
      }
      return;
    }

    final content = await file.readAsString();
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

    _quillController?.dispose();

    if (!mounted) return;

    final controller = QuillController(
      document: doc,
      selection: const TextSelection.collapsed(offset: 0),
    );

    controller.document.changes.listen((_) {
      _scheduleAutoSave(path);
    });

    setState(() {
      _quillController = controller;
      _currentLoadedPath = path;
    });
  }

  void _scheduleAutoSave(String path) {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(milliseconds: 500), () async {
      if (_quillController == null || _currentLoadedPath != path) return;

      final deltaJson = jsonEncode(
        _quillController!.document.toDelta().toJson(),
      );
      final file = File(path);

      if (await file.exists()) {
        await file.writeAsString(deltaJson);
      }
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

    final fileName = p.basenameWithoutExtension(selectedFilePath);

    return Column(
      children: [
        Container(
          color: context.colors.surfaceContainerLowest,
          padding: const EdgeInsets.symmetric(
            horizontal: AppThemeVariables.md,
            vertical: AppThemeVariables.xs,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppThemeVariables.xs,
                  vertical: AppThemeVariables.xxs,
                ),
                child: Text(
                  fileName,
                  style: context.h2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Divider(height: AppThemeVariables.md),
              QuillSimpleToolbar(
                controller: _quillController!,
                config: const QuillSimpleToolbarConfig(
                  showFontFamily: false,
                  showFontSize: false,
                  showSearchButton: false,
                  showInlineCode: true,
                  showCodeBlock: true,
                  showSubscript: false,
                  showSuperscript: false,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: Container(
            color: context.colors.surface,
            padding: const EdgeInsets.all(AppThemeVariables.xl),
            child: QuillEditor.basic(
              controller: _quillController!,
              config: const QuillEditorConfig(
                placeholder: 'Начните писать здесь...',
                padding: EdgeInsets.zero,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
