import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:notify/providers/tasks_provider.dart';
import 'package:notify/theme/app_theme_variables.dart';
import '../providers/notes_provider.dart';
import '../theme/app_theme.dart';
import 'notes/file_tree_view.dart';
import 'tasks/boards_list_view.dart';

class Sidebar extends ConsumerStatefulWidget {
  final bool isOpen;
  final int selectedTab;
  final VoidCallback onToggleSidebar;
  final ValueChanged<int> onTabChanged;

  const Sidebar({
    super.key,
    required this.isOpen,
    required this.selectedTab,
    required this.onToggleSidebar,
    required this.onTabChanged,
  });

  @override
  ConsumerState<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends ConsumerState<Sidebar> {
  // Инициализация состояния боковой панели
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(notesProvider.notifier).initNotes();
      ref.read(tasksProvider.notifier).initTasks();
    });
  }

  // Отрисовка боковой панели
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: widget.isOpen ? 320.0 : 56.0,
      color: context.colors.surfaceContainerLowest,
      child: widget.isOpen
          ? _buildExpandedContent(context)
          : _buildCollapsedContent(context),
    );
  }

  // Боковая панель в свёрнутом состоянии
  Widget _buildCollapsedContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppThemeVariables.xxs),
      child: NavigationRail(
        selectedIndex: widget.selectedTab,
        onDestinationSelected: widget.onTabChanged,
        labelType: NavigationRailLabelType.none,
        trailingAtBottom: true,
        backgroundColor: Colors.transparent,
        leading: Column(
          children: [
            IconButton(
              mouseCursor: SystemMouseCursors.click,
              icon: const Icon(LucideIcons.panelLeftOpen),
              tooltip: 'Развернуть панель',
              onPressed: widget.onToggleSidebar,
              iconSize: AppThemeVariables.iconLg,
            ),
          ],
        ),
        destinations: const [
          NavigationRailDestination(
            icon: Icon(LucideIcons.fileText, size: AppThemeVariables.iconLg),
            label: Text(''),
          ),
          NavigationRailDestination(
            icon: Icon(
              LucideIcons.squareKanban,
              size: AppThemeVariables.iconLg,
            ),
            label: Text(''),
          ),
        ],
        trailing: const Column(
          children: [
            IconButton(
              mouseCursor: SystemMouseCursors.forbidden,
              icon: Icon(LucideIcons.refreshCw),
              tooltip: 'Синхронизация',
              onPressed: null, // Заблокировано
              iconSize: AppThemeVariables.iconLg,
            ),
            IconButton(
              mouseCursor: SystemMouseCursors.forbidden,
              icon: Icon(LucideIcons.settings),
              tooltip: 'Настройки',
              onPressed: null, // Заблокировано
              iconSize: AppThemeVariables.iconLg,
            ),
            SizedBox(height: AppThemeVariables.xs),
          ],
        ),
      ),
    );
  }

  // Боковая панель в раскрытом состоянии
  Widget _buildExpandedContent(BuildContext context) {
    final notesState = ref.watch(notesProvider);
    final tasksState = ref.watch(tasksProvider);

    return Column(
      children: [
        _buildTabSelector(context),
        Expanded(
          child: widget.selectedTab == 0
              ? _buildNotesSection(context, notesState)
              : _buildTasksSection(context, tasksState),
        ),
        _buildFooter(context),
      ],
    );
  }

  // Каталог заметок
  Widget _buildNotesSection(BuildContext context, NotesState notesState) {
    if (notesState.isLoading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    final notifier = ref.read(notesProvider.notifier);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppThemeVariables.xs,
            horizontal: AppThemeVariables.md,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: AppThemeVariables.xs,
            children: [
              IconButton(
                mouseCursor: SystemMouseCursors.click,
                icon: const Icon(LucideIcons.filePlus),
                tooltip: 'Новая заметка',
                onPressed: () => notifier.createNote(),
                visualDensity: VisualDensity.compact,
                iconSize: AppThemeVariables.iconMd,
              ),
              IconButton(
                mouseCursor: SystemMouseCursors.click,
                icon: const Icon(LucideIcons.folderPlus),
                tooltip: 'Новая папка',
                onPressed: () => notifier.createFolder(),
                visualDensity: VisualDensity.compact,
                iconSize: AppThemeVariables.iconMd,
              ),
              const IconButton(
                mouseCursor: SystemMouseCursors.forbidden,
                icon: Icon(LucideIcons.listChevronsDownUp),
                tooltip: 'Свернуть/Развернуть всё',
                onPressed: null, // Выключено
                visualDensity: VisualDensity.compact,
                iconSize: AppThemeVariables.iconMd,
              ),
              const IconButton(
                mouseCursor: SystemMouseCursors.forbidden,
                icon: Icon(LucideIcons.arrowUpAZ),
                tooltip: 'Сортировка',
                onPressed: null, // Выключено
                visualDensity: VisualDensity.compact,
                iconSize: AppThemeVariables.iconMd,
              ),
              const IconButton(
                mouseCursor: SystemMouseCursors.forbidden,
                icon: Icon(LucideIcons.search),
                tooltip: 'Поиск',
                onPressed: null, // Выключено
                visualDensity: VisualDensity.compact,
                iconSize: AppThemeVariables.iconMd,
              ),
            ],
          ),
        ),
        Expanded(child: FileTreeView(nodes: notesState.nodes)),
      ],
    );
  }

  // Каталог канбан-досок
  Widget _buildTasksSection(BuildContext context, TasksState tasksState) {
    if (tasksState.isLoading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    final notifier = ref.read(tasksProvider.notifier);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppThemeVariables.xs,
            horizontal: AppThemeVariables.md,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: AppThemeVariables.xs,
            children: [
              IconButton(
                mouseCursor: SystemMouseCursors.click,
                icon: const Icon(LucideIcons.clipboardPlus),
                tooltip: 'Новая доска',
                onPressed: () => notifier.createBoard('Новая доска'),
                visualDensity: VisualDensity.compact,
                iconSize: AppThemeVariables.iconMd,
              ),
              const IconButton(
                mouseCursor: SystemMouseCursors.forbidden,
                icon: Icon(LucideIcons.arrowUpAZ),
                tooltip: 'Сортировка',
                onPressed: null, // Выключено
                visualDensity: VisualDensity.compact,
                iconSize: AppThemeVariables.iconMd,
              ),
              const IconButton(
                mouseCursor: SystemMouseCursors.forbidden,
                icon: Icon(LucideIcons.search),
                tooltip: 'Поиск',
                onPressed: null, // Выключено
                visualDensity: VisualDensity.compact,
                iconSize: AppThemeVariables.iconMd,
              ),
            ],
          ),
        ),
        const Expanded(child: BoardsListView()),
      ],
    );
  }

  // Выбор раздела (заметки/задачи)
  Widget _buildTabSelector(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: AppThemeVariables.xs,
        bottom: AppThemeVariables.xs,
        left: AppThemeVariables.xs,
        right: AppThemeVariables.xxs,
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              label: Text('Заметки', style: context.h3),
              icon: Icon(
                LucideIcons.fileText,
                size: AppThemeVariables.iconLg,
                color: widget.selectedTab == 0
                    ? context.colors.primary
                    : context.colors.onSurfaceVariant,
              ),
              onPressed: () => widget.onTabChanged(0),
              style: OutlinedButton.styleFrom(
                enabledMouseCursor: SystemMouseCursors.click,
                backgroundColor: widget.selectedTab == 0
                    ? context.colors.surfaceContainerHigh
                    : Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppThemeVariables.xs),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: AppThemeVariables.sm,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppThemeVariables.xs),
          Expanded(
            child: OutlinedButton.icon(
              label: Text('Задачи', style: context.h3),
              icon: Icon(
                LucideIcons.clipboardList,
                size: AppThemeVariables.iconLg,
                color: widget.selectedTab == 1
                    ? context.colors.primary
                    : context.colors.onSurfaceVariant,
              ),
              onPressed: () => widget.onTabChanged(1),
              style: OutlinedButton.styleFrom(
                enabledMouseCursor: SystemMouseCursors.click,
                backgroundColor: widget.selectedTab == 1
                    ? context.colors.surfaceContainerHigh
                    : Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppThemeVariables.xs),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: AppThemeVariables.sm,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppThemeVariables.xxs),
          IconButton(
            mouseCursor: SystemMouseCursors.click,
            icon: const Icon(LucideIcons.panelLeftClose),
            tooltip: 'Свернуть панель',
            onPressed: widget.onToggleSidebar,
            visualDensity: VisualDensity.compact,
            iconSize: AppThemeVariables.iconLg,
          ),
        ],
      ),
    );
  }

  // Футер
  Widget _buildFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppThemeVariables.xs),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: null, // Выключено
              label: const Text('Синхронизация'),
              icon: const Icon(
                LucideIcons.refreshCw,
                size: AppThemeVariables.iconSm,
              ),
              style: OutlinedButton.styleFrom(
                enabledMouseCursor: SystemMouseCursors.click,
                padding: const EdgeInsets.symmetric(
                  vertical: AppThemeVariables.xs,
                  horizontal: AppThemeVariables.xxs,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppThemeVariables.xs),
                ),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
          const SizedBox(width: AppThemeVariables.xs),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: null, // Выключено
              label: const Text('Настройки'),
              icon: const Icon(
                LucideIcons.settings,
                size: AppThemeVariables.iconSm,
              ),
              style: OutlinedButton.styleFrom(
                enabledMouseCursor: SystemMouseCursors.click,
                padding: const EdgeInsets.symmetric(
                  vertical: AppThemeVariables.xs,
                  horizontal: AppThemeVariables.xxs,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppThemeVariables.xs),
                ),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
