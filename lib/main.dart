import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'theme/app_theme.dart';
import 'widgets/tasks/tasks_screen.dart';
import 'widgets/notes/notes_screen.dart';
import 'widgets/sidebar.dart';

void main() {
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
  };
  runApp(const ProviderScope(child: NotifyApp()));
}

// --- Главный класс приложения ---
class NotifyApp extends StatelessWidget {
  const NotifyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notify',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        FlutterQuillLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ru', 'RU'), Locale('en', 'US')],
      home: const MainScreen(),
    );
  }
}

// --- Главный экран ---
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

// --- Главный экран ---
class _MainScreenState extends State<MainScreen> {
  int _selectedTab = 0;
  bool _isSidebarOpen = true;

  final List<Widget> _screens = [const NotesScreen(), const TasksScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // --- Боковая панель ---
          Sidebar(
            isOpen: _isSidebarOpen,
            selectedTab: _selectedTab,
            onToggleSidebar: () {
              setState(() {
                _isSidebarOpen = !_isSidebarOpen;
              });
            },
            onTabChanged: (int index) {
              setState(() {
                _selectedTab = index;
              });
            },
          ),
          const VerticalDivider(width: 1),

          // --- Основная рабочая область ---
          Expanded(child: _screens[_selectedTab]),
        ],
      ),
    );
  }
}
