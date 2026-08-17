import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:watcher/watcher.dart';
import '../models/notes/note_node.dart';

class NotesState {
  final String notesPath;
  final List<NoteNode> nodes;
  final Set<String> expandedPaths;
  final String? selectedFilePath;
  final String? editingPath;
  final bool isLoading;

  const NotesState({
    required this.notesPath,
    required this.nodes,
    required this.expandedPaths,
    this.selectedFilePath,
    this.editingPath,
    this.isLoading = false,
  });

  NotesState copyWith({
    String? notesPath,
    List<NoteNode>? nodes,
    Set<String>? expandedPaths,
    String? selectedFilePath,
    String? editingPath,
    bool? isLoading,
    bool clearEditingPath = false,
    bool clearSelectedFile = false,
  }) {
    return NotesState(
      notesPath: notesPath ?? this.notesPath,
      nodes: nodes ?? this.nodes,
      expandedPaths: expandedPaths ?? this.expandedPaths,
      selectedFilePath: selectedFilePath ?? this.selectedFilePath,
      editingPath: clearEditingPath ? null : (editingPath ?? this.editingPath),
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class NotesNotifier extends Notifier<NotesState> {
  StreamSubscription<WatchEvent>? _watcherSubscription;

  @override
  NotesState build() {
    ref.onDispose(() => _watcherSubscription?.cancel());
    return const NotesState(
      notesPath: '',
      nodes: [],
      expandedPaths: {},
      isLoading: true,
    );
  }

  Future<void> initNotes() async {
    state = state.copyWith(isLoading: true);

    final docsDir = await getApplicationDocumentsDirectory();
    final targetDir = Directory(p.join(docsDir.path, 'NotifyStorage', 'notes'));

    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    final path = targetDir.path;
    final tree = _scanDirectory(Directory(path));

    state = state.copyWith(notesPath: path, nodes: tree, isLoading: false);

    _watchFileSystem(path);
  }

  List<NoteNode> _scanDirectory(Directory dir) {
    if (!dir.existsSync()) return [];

    final List<NoteNode> nodes = [];
    final List<FileSystemEntity> entities = dir.listSync();

    entities.sort((a, b) {
      if (a is Directory && b is! Directory) return -1;
      if (a is! Directory && b is Directory) return 1;
      return p
          .basename(a.path)
          .toLowerCase()
          .compareTo(p.basename(b.path).toLowerCase());
    });

    for (final entity in entities) {
      final name = p.basename(entity.path);

      if (entity is Directory) {
        nodes.add(
          NoteNode(
            title: name,
            path: entity.path,
            isDirectory: true,
            children: _scanDirectory(entity),
          ),
        );
      } else if (entity is File && name.endsWith('.json')) {
        nodes.add(
          NoteNode(
            title: p.basenameWithoutExtension(name),
            path: entity.path,
            isDirectory: false,
          ),
        );
      }
    }

    return nodes;
  }

  void _watchFileSystem(String path) {
    _watcherSubscription?.cancel();
    final watcher = DirectoryWatcher(path);
    _watcherSubscription = watcher.events.listen((_) => refreshTree());
  }

  void refreshTree() {
    if (state.notesPath.isEmpty) return;
    final tree = _scanDirectory(Directory(state.notesPath));
    state = state.copyWith(nodes: tree);
  }

  void togglePathExpanded(String path) {
    final updated = Set<String>.from(state.expandedPaths);
    if (updated.contains(path)) {
      updated.remove(path);
    } else {
      updated.add(path);
    }
    state = state.copyWith(expandedPaths: updated);
  }

  void _ensureParentsExpanded(String filePath) {
    final updated = Set<String>.from(state.expandedPaths);
    String parent = p.dirname(filePath);
    while (parent.isNotEmpty && parent != state.notesPath) {
      updated.add(parent);
      parent = p.dirname(parent);
    }
    state = state.copyWith(expandedPaths: updated);
  }

  void selectFile(String path) {
    state = state.copyWith(selectedFilePath: path);
  }

  Future<void> createNote([NoteNode? targetNode]) async {
    final parentDir = _resolveParentDirectory(targetNode);
    final fullPath = await _getUniquePath(
      parentDir,
      'Новая заметка',
      isDirectory: false,
    );

    final file = File(fullPath);
    await file.create(recursive: true);
    await file.writeAsString('[]');

    _ensureParentsExpanded(fullPath);
    refreshTree();

    state = state.copyWith(editingPath: fullPath);
  }

  Future<void> createFolder([NoteNode? targetNode]) async {
    final parentDir = _resolveParentDirectory(targetNode);
    final fullPath = await _getUniquePath(
      parentDir,
      'Новая папка',
      isDirectory: true,
    );

    final dir = Directory(fullPath);
    await dir.create(recursive: true);

    _ensureParentsExpanded(fullPath);
    refreshTree();

    state = state.copyWith(editingPath: fullPath);
  }

  Future<void> renameNode(NoteNode node, String newTitle) async {
    final entity = node.isDirectory ? Directory(node.path) : File(node.path);
    final parentDir = entity.parent.path;

    final newFileName = node.isDirectory
        ? newTitle
        : (newTitle.endsWith('.json') ? newTitle : '$newTitle.json');

    final newPath = p.join(parentDir, newFileName);

    if (newPath != node.path) {
      await entity.rename(newPath);

      // Обновляем selectedFilePath, если переименован выбранный файл или его родитель
      String? updatedSelected = state.selectedFilePath;
      if (state.selectedFilePath != null) {
        if (state.selectedFilePath == node.path) {
          updatedSelected = newPath;
        } else if (p.isWithin(node.path, state.selectedFilePath!)) {
          final relative = p.relative(state.selectedFilePath!, from: node.path);
          updatedSelected = p.join(newPath, relative);
        }
      }

      refreshTree();

      state = state.copyWith(
        selectedFilePath: updatedSelected,
        clearEditingPath: true,
      );
    } else {
      state = state.copyWith(clearEditingPath: true);
    }
  }

  Future<void> deleteNode(NoteNode node) async {
    final entity = node.isDirectory ? Directory(node.path) : File(node.path);
    if (await entity.exists()) {
      await entity.delete(recursive: true);

      final isSelectedDeleted =
          state.selectedFilePath != null &&
          (state.selectedFilePath == node.path ||
              p.isWithin(node.path, state.selectedFilePath!));
      final isEditingDeleted =
          state.editingPath != null &&
          (state.editingPath == node.path ||
              p.isWithin(node.path, state.editingPath!));

      refreshTree();

      if (isSelectedDeleted || isEditingDeleted) {
        state = state.copyWith(
          clearSelectedFile: isSelectedDeleted,
          clearEditingPath: isEditingDeleted,
        );
      }
    }
  }

  void startEditing(String path) {
    state = state.copyWith(editingPath: path);
  }

  void cancelEditing() {
    state = state.copyWith(clearEditingPath: true);
  }

  String _resolveParentDirectory(NoteNode? targetNode) {
    if (targetNode == null) return state.notesPath;
    if (targetNode.isDirectory) return targetNode.path;
    return p.dirname(targetNode.path);
  }

  Future<String> _getUniquePath(
    String parentDir,
    String baseName, {
    required bool isDirectory,
  }) async {
    final ext = isDirectory ? '' : '.json';
    String title = baseName;
    String fullPath = p.join(parentDir, '$title$ext');
    int counter = 1;

    while (await (isDirectory
        ? Directory(fullPath).exists()
        : File(fullPath).exists())) {
      title = '$baseName ($counter)';
      fullPath = p.join(parentDir, '$title$ext');
      counter++;
    }

    return fullPath;
  }
}

final notesProvider = NotifierProvider<NotesNotifier, NotesState>(
  NotesNotifier.new,
);
