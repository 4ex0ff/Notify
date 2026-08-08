import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class KanbanScreen extends StatelessWidget {
  const KanbanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Раздел задач (Скоро здесь будут канбан-доски)',
        style: context.h2,
      ),
    );
  }
}
