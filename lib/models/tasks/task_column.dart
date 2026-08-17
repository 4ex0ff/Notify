import 'package:flutter/foundation.dart';
import 'task.dart';

@immutable
class TaskColumn {
  final String id;
  final String title;
  final List<Task> tasks;
  final int order;

  const TaskColumn({
    required this.id,
    required this.title,
    this.tasks = const [],
    this.order = 0,
  });

  TaskColumn copyWith({
    String? id,
    String? title,
    List<Task>? tasks,
    int? order,
  }) {
    return TaskColumn(
      id: id ?? this.id,
      title: title ?? this.title,
      tasks: tasks ?? this.tasks,
      order: order ?? this.order,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'tasks': tasks.map((t) => t.toJson()).toList(),
      'order': order,
    };
  }

  factory TaskColumn.fromJson(Map<String, dynamic> json) {
    return TaskColumn(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      tasks:
          (json['tasks'] as List<dynamic>?)
              ?.map((e) => Task.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      order: json['order'] as int? ?? 0,
    );
  }
}
