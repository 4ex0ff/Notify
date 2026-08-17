import 'package:flutter/foundation.dart';
import 'task_column.dart';

@immutable
class Board {
  final String id;
  final String title;
  final List<TaskColumn> columns;
  final DateTime createdAt;

  const Board({
    required this.id,
    required this.title,
    this.columns = const [],
    required this.createdAt,
  });

  Board copyWith({
    String? id,
    String? title,
    List<TaskColumn>? columns,
    DateTime? createdAt,
  }) {
    return Board(
      id: id ?? this.id,
      title: title ?? this.title,
      columns: columns ?? this.columns,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'columns': columns.map((c) => c.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Board.fromJson(Map<String, dynamic> json) {
    return Board(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      columns:
          (json['columns'] as List<dynamic>?)
              ?.map((e) => TaskColumn.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
