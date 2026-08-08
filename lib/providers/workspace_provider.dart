import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:watcher/watcher.dart';
import '../models/file_node.dart';

class WorkspaceState {
  final String workspacePath;
  final List<FileNode> nodes;
  final Set<String> expandedPaths;
  final String? selectedFilePath;
  final String? editingPath;
  final bool isLoading;

  const WorkspaceState({
    required this.workspacePath,
    required this.nodes,
    required this.expandedPaths,
    this.selectedFilePath,
    this.editingPath,
    this.isLoading = false,
  });

  WorkspaceState copyWith({
    String? workspacePath,
    List<FileNode>? nodes,
    Set<String>? expandedPaths,
    String? selectedFilePath,
    String? editingPath,
    bool? isLoading,
    bool clearEditingPath = false,
  }) {
    return WorkspaceState(
      workspacePath: workspacePath ?? this.workspacePath,
      nodes: nodes ?? this.nodes,
      expandedPaths: expandedPaths ?? this.expandedPaths,
      selectedFilePath: selectedFilePath ?? this.selectedFilePath,
      editingPath: clearEditingPath ? null : (editingPath ?? this.editingPath),
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class WorkspaceNotifier extends Notifier<WorkspaceState> {
  StreamSubscription<WatchEvent>? _watcherSubscription;

  @override
  WorkspaceState build() {
    ref.onDispose(() => _watcherSubscription?.cancel());
    return const WorkspaceState(
      workspacePath: '',
      nodes: [],
      expandedPaths: {},
      isLoading: true,
    );
  }

  Future<void> initWorkspace() async {
    state = state.copyWith(isLoading: true);

    final docsDir = await getApplicationDocumentsDirectory();
    final targetDir = Directory(p.join(docsDir.path, 'NotifyNotes'));

    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    final path = targetDir.path;
    final tree = _scanDirectory(Directory(path));

    state = state.copyWith(workspacePath: path, nodes: tree, isLoading: false);

    _watchFileSystem(path);
  }

  List<FileNode> _scanDirectory(Directory dir) {
    if (!dir.existsSync()) return [];

    final List<FileNode> nodes = [];
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
          FileNode(
            title: name,
            path: entity.path,
            isDirectory: true,
            children: _scanDirectory(entity),
          ),
        );
      } else if (entity is File && name.endsWith('.json')) {
        nodes.add(
          FileNode(
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
    if (state.workspacePath.isEmpty) return;
    final tree = _scanDirectory(Directory(state.workspacePath));
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
    while (parent.isNotEmpty && parent != state.workspacePath) {
      updated.add(parent);
      parent = p.dirname(parent);
    }
    state = state.copyWith(expandedPaths: updated);
  }

  void selectFile(String path) {
    state = state.copyWith(selectedFilePath: path);
  }

  Future<void> createNote([FileNode? targetNode]) async {
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

  Future<void> createFolder([FileNode? targetNode]) async {
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

  Future<void> renameNode(FileNode node, String newTitle) async {
    final entity = node.isDirectory ? Directory(node.path) : File(node.path);
    final parentDir = entity.parent.path;

    final newFileName = node.isDirectory
        ? newTitle
        : (newTitle.endsWith('.json') ? newTitle : '$newTitle.json');

    final newPath = p.join(parentDir, newFileName);
    if (newPath != node.path) {
      await entity.rename(newPath);
      refreshTree();
    }
    state = state.copyWith(clearEditingPath: true);
  }

  Future<void> deleteNode(FileNode node) async {
    final entity = node.isDirectory ? Directory(node.path) : File(node.path);
    if (await entity.exists()) {
      await entity.delete(recursive: true);
      refreshTree();
    }
  }

  void startEditing(String path) {
    state = state.copyWith(editingPath: path);
  }

  void cancelEditing() {
    state = state.copyWith(clearEditingPath: true);
  }

  String _resolveParentDirectory(FileNode? targetNode) {
    if (targetNode == null) return state.workspacePath;
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

final workspaceProvider = NotifierProvider<WorkspaceNotifier, WorkspaceState>(
  WorkspaceNotifier.new,
);
