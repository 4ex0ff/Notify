import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/tasks/board.dart';
import '../models/tasks/task.dart';
import '../models/tasks/task_column.dart';

@immutable
class TasksState {
  final List<Board> boards;
  final String? selectedBoardId;
  final bool isLoading;

  const TasksState({
    required this.boards,
    this.selectedBoardId,
    this.isLoading = false,
  });

  TasksState copyWith({
    List<Board>? boards,
    String? selectedBoardId,
    bool? isLoading,
    bool clearSelectedBoard = false,
  }) {
    return TasksState(
      boards: boards ?? this.boards,
      selectedBoardId: clearSelectedBoard
          ? null
          : (selectedBoardId ?? this.selectedBoardId),
      isLoading: isLoading ?? this.isLoading,
    );
  }

  // Текущая выбранная доска в разделе задач
  Board? get selectedBoard {
    if (selectedBoardId == null) return null;
    try {
      return boards.firstWhere((b) => b.id == selectedBoardId);
    } catch (_) {
      return null;
    }
  }
}

class TasksNotifier extends Notifier<TasksState> {
  String _tasksDirectoryPath = '';
  Future<void> _mutationQueue = Future<void>.value();

  Future<void> _enqueueMutation(Future<void> Function() mutation) {
    final next = _mutationQueue.then((_) => mutation());
    _mutationQueue = next.catchError((_) {});
    return next;
  }

  @override
  TasksState build() {
    return const TasksState(boards: [], isLoading: true);
  }

  // Инициализация раздела задач
  Future<void> initTasks() async {
    state = state.copyWith(isLoading: true);

    final docsDir = await getApplicationDocumentsDirectory();
    final targetDir = Directory(p.join(docsDir.path, 'NotifyStorage', 'tasks'));

    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    _tasksDirectoryPath = targetDir.path;
    await _loadTasks();
  }

  // Загрузка данных раздела задач
  Future<void> _loadTasks() async {
    if (_tasksDirectoryPath.isEmpty) return;

    final dir = Directory(_tasksDirectoryPath);
    final entities = dir.listSync();
    final List<Board> loadedBoards = [];

    // Чтение JSON-файлов из папки задач
    for (final entity in entities) {
      if (entity is File && entity.path.endsWith('.json')) {
        try {
          final content = await entity.readAsString();
          final json = jsonDecode(content) as Map<String, dynamic>;
          loadedBoards.add(Board.fromJson(json));
        } catch (error, stackTrace) {
          FlutterError.reportError(
            FlutterErrorDetails(
              exception: error,
              stack: stackTrace,
              library: 'tasks_provider',
              context: ErrorDescription('loading ${entity.path}'),
            ),
          );
        }
      }
    }

    // Сортировка досок по дате создания
    loadedBoards.sort((a, b) => a.createdAt.compareTo(b.createdAt));

    String? newSelectedId = state.selectedBoardId;
    if (loadedBoards.isNotEmpty) {
      if (newSelectedId == null ||
          !loadedBoards.any((b) => b.id == newSelectedId)) {
        newSelectedId = loadedBoards.first.id;
      }
    } else {
      newSelectedId = null;
    }

    state = state.copyWith(
      boards: loadedBoards,
      selectedBoardId: newSelectedId,
      isLoading: false,
    );
  }

  // Сохранение изменений доски
  Future<void> _saveBoard(Board board) async {
    if (_tasksDirectoryPath.isEmpty) return;
    final file = File(p.join(_tasksDirectoryPath, '${board.id}.json'));
    final jsonString = jsonEncode(board.toJson());
    await file.writeAsString(jsonString);
  }

  // Обновление текущей доски
  Future<void> _applyBoard(Board updatedBoard) async {
    await _saveBoard(updatedBoard);

    final updatedBoards = state.boards.map((b) {
      return b.id == updatedBoard.id ? updatedBoard : b;
    }).toList();

    state = state.copyWith(boards: updatedBoards);
  }

  // --- Управление канбан-досками ---
  // Выбор доски
  void selectBoard(String boardId) {
    state = state.copyWith(selectedBoardId: boardId);
  }

  // Создание доски
  Future<void> createBoard(String title) async {
    await _enqueueMutation(() async {
      final id = DateTime.now().microsecondsSinceEpoch.toString();
      final newBoard = Board(
        id: id,
        title: title.trim().isEmpty ? 'Новая доска' : title.trim(),
        columns: [
          TaskColumn(id: '${id}_col_1', title: 'Запланировано', order: 0),
          TaskColumn(id: '${id}_col_2', title: 'В работе', order: 1),
          TaskColumn(id: '${id}_col_3', title: 'Отложено', order: 2),
          TaskColumn(id: '${id}_col_4', title: 'Выполнено', order: 3),
        ],
        createdAt: DateTime.now(),
      );

      await _saveBoard(newBoard);
      final updatedBoards = List<Board>.from(state.boards)..add(newBoard);
      state = state.copyWith(
        boards: updatedBoards,
        selectedBoardId: newBoard.id,
      );
    });
  }

  // Переименование доски
  Future<void> renameBoard(String boardId, String newTitle) async {
    await _enqueueMutation(() async {
      final boardIndex = state.boards.indexWhere((b) => b.id == boardId);
      if (boardIndex == -1) return;

      final updatedBoard = state.boards[boardIndex].copyWith(title: newTitle);
      await _saveBoard(updatedBoard);
      final updatedBoards = List<Board>.from(state.boards);
      updatedBoards[boardIndex] = updatedBoard;
      state = state.copyWith(boards: updatedBoards);
    });
  }

  // Удаление доски
  Future<void> deleteBoard(String boardId) async {
    await _enqueueMutation(() async {
      final file = File(p.join(_tasksDirectoryPath, '$boardId.json'));
      if (await file.exists()) {
        await file.delete();
      }

      final updatedBoards = state.boards.where((b) => b.id != boardId).toList();
      String? nextSelected = state.selectedBoardId;
      if (state.selectedBoardId == boardId) {
        nextSelected = updatedBoards.isNotEmpty ? updatedBoards.first.id : null;
      }

      state = state.copyWith(
        boards: updatedBoards,
        selectedBoardId: nextSelected,
        clearSelectedBoard: nextSelected == null,
      );
    });
  }

  // --- Управление столбцами ---
  // Создание столбца
  Future<void> createColumn(String title) async {
    await _enqueueMutation(() async {
      final board = state.selectedBoard;
      if (board == null) return;

      final columnId = DateTime.now().microsecondsSinceEpoch.toString();
      final newColumn = TaskColumn(
        id: columnId,
        title: title.trim().isEmpty ? 'Новый столбец' : title.trim(),
        order: board.columns.length,
      );
      final updatedColumns = List<TaskColumn>.from(board.columns)
        ..add(newColumn);
      await _applyBoard(board.copyWith(columns: updatedColumns));
    });
  }

  // Переименование столбца
  Future<void> renameColumn(String columnId, String newTitle) async {
    await _enqueueMutation(() async {
      final board = state.selectedBoard;
      if (board == null) return;

      final updatedColumns = board.columns.map((col) {
        return col.id == columnId ? col.copyWith(title: newTitle) : col;
      }).toList();
      await _applyBoard(board.copyWith(columns: updatedColumns));
    });
  }

  // Удаление столбца
  Future<void> deleteColumn(String columnId) async {
    await _enqueueMutation(() async {
      final board = state.selectedBoard;
      if (board == null) return;

      final updatedColumns = board.columns
          .where((col) => col.id != columnId)
          .toList();
      await _applyBoard(board.copyWith(columns: updatedColumns));
    });
  }

  Future<void> moveColumn({
    required int fromIndex,
    required int toIndex,
  }) async {
    await _enqueueMutation(() async {
      final currentBoard = state.selectedBoard;
      if (currentBoard == null) return;

      final updatedColumns = List<TaskColumn>.from(currentBoard.columns);
      final movedColumn = updatedColumns.removeAt(fromIndex);
      updatedColumns.insert(toIndex, movedColumn);
      await _applyBoard(currentBoard.copyWith(columns: updatedColumns));
    });
  }

  // --- Управление задачами ---
  // Создание задачи
  Future<void> createTask(String columnId, String title) async {
    await _enqueueMutation(() async {
      final board = state.selectedBoard;
      if (board == null) return;

      final taskId = DateTime.now().microsecondsSinceEpoch.toString();
      final updatedColumns = board.columns.map((col) {
        if (col.id != columnId) return col;
        final newTask = Task(
          id: taskId,
          title: title.trim(),
          order: col.tasks.length,
        );
        return col.copyWith(tasks: [...col.tasks, newTask]);
      }).toList();
      await _applyBoard(board.copyWith(columns: updatedColumns));
    });
  }

  // Обновление задачи
  Future<void> updateTask(String columnId, Task updatedTask) async {
    await _enqueueMutation(() async {
      final board = state.selectedBoard;
      if (board == null) return;

      final updatedColumns = board.columns.map((col) {
        if (col.id != columnId) return col;
        final updatedTasks = col.tasks.map((task) {
          return task.id == updatedTask.id ? updatedTask : task;
        }).toList();
        return col.copyWith(tasks: updatedTasks);
      }).toList();
      await _applyBoard(board.copyWith(columns: updatedColumns));
    });
  }

  // Удаление задачи
  Future<void> deleteTask(String columnId, String taskId) async {
    await _enqueueMutation(() async {
      final board = state.selectedBoard;
      if (board == null) return;

      final updatedColumns = board.columns.map((col) {
        if (col.id != columnId) return col;
        final updatedTasks = col.tasks
            .where((task) => task.id != taskId)
            .toList();
        return col.copyWith(tasks: updatedTasks);
      }).toList();
      await _applyBoard(board.copyWith(columns: updatedColumns));
    });
  }

  // Перемещение задачи (drag-and-drop)
  Future<void> moveTask({
    required String fromColumnId,
    required String toColumnId,
    required int fromIndex,
    required int toIndex,
  }) async {
    await _enqueueMutation(() async {
      final board = state.selectedBoard;
      if (board == null) return;

      final fromColumn = board.columns.firstWhere(
        (col) => col.id == fromColumnId,
      );
      final taskToMove = fromColumn.tasks[fromIndex];

      final updatedColumns = board.columns.map((col) {
        if (col.id == fromColumnId && fromColumnId != toColumnId) {
          final tasks = List<Task>.from(col.tasks)..removeAt(fromIndex);
          return col.copyWith(tasks: tasks);
        }

        if (col.id == toColumnId) {
          final tasks = List<Task>.from(col.tasks);
          if (fromColumnId == toColumnId) {
            tasks.removeAt(fromIndex);
          }
          tasks.insert(toIndex, taskToMove);
          return col.copyWith(tasks: tasks);
        }

        return col;
      }).toList();
      await _applyBoard(board.copyWith(columns: updatedColumns));
    });
  }
}

// Создание провайдера
final tasksProvider = NotifierProvider<TasksNotifier, TasksState>(
  TasksNotifier.new,
);
