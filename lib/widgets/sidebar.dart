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
              // Кнопка переключения состояния панели (развернуть)
              icon: const Icon(LucideIcons.panelLeftOpen),
              tooltip: 'Развернуть панель',
              onPressed: widget.onToggleSidebar,
              iconSize: AppThemeVariables.iconLg,
            ),
          ],
        ),
        destinations: const [
          // Кнопки выбора раздела (заметки/задачи)
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
        trailing: Column(
          children: [
            // Кнопки синхронизации и настроек
            IconButton(
              icon: const Icon(LucideIcons.refreshCw),
              tooltip: 'Синхронизация',
              onPressed: () {},
              iconSize: AppThemeVariables.iconLg,
            ),
            IconButton(
              icon: const Icon(LucideIcons.settings),
              tooltip: 'Настройки',
              onPressed: () {},
              iconSize: AppThemeVariables.iconLg,
            ),
            const SizedBox(height: AppThemeVariables.xs),
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
        const Divider(height: 1),
        _buildFooter(context),
      ],
    );
  }

  // Каталог заметок
  Widget _buildNotesSection(BuildContext context, NotesState notesState) {
    // Состояние загрузки
    if (notesState.isLoading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    final notifier = ref.read(notesProvider.notifier);

    // Рабочее состояние
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppThemeVariables.xs,
            horizontal: AppThemeVariables.xl,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Кнопки управления заметками
              IconButton(
                icon: const Icon(LucideIcons.filePlus),
                tooltip: 'Новая заметка',
                onPressed: () => notifier.createNote(),
                visualDensity: VisualDensity.compact,
                iconSize: AppThemeVariables.iconLg,
              ),
              IconButton(
                icon: const Icon(LucideIcons.folderPlus),
                tooltip: 'Новая папка',
                onPressed: () => notifier.createFolder(),
                visualDensity: VisualDensity.compact,
                iconSize: AppThemeVariables.iconLg,
              ),
              IconButton(
                icon: const Icon(LucideIcons.refreshCw),
                tooltip: 'Обновить',
                onPressed: () => notifier.refreshTree(),
                visualDensity: VisualDensity.compact,
                iconSize: AppThemeVariables.iconLg,
              ),
              IconButton(
                icon: const Icon(LucideIcons.listChevronsDownUp),
                tooltip: 'Свернуть/Развернуть всё',
                onPressed: () {},
                visualDensity: VisualDensity.compact,
                iconSize: AppThemeVariables.iconLg,
              ),
              IconButton(
                icon: const Icon(LucideIcons.arrowUpAZ),
                tooltip: 'Сортировка',
                onPressed: () {},
                visualDensity: VisualDensity.compact,
                iconSize: AppThemeVariables.iconLg,
              ),
              IconButton(
                icon: const Icon(LucideIcons.search),
                tooltip: 'Поиск',
                onPressed: () {},
                visualDensity: VisualDensity.compact,
                iconSize: AppThemeVariables.iconLg,
              ),
            ],
          ),
        ),
        // Файловое дерево (file_tree_view.dart)
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
            horizontal: AppThemeVariables.xl,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(LucideIcons.clipboardPlus),
                tooltip: 'Новая доска',
                onPressed: () => notifier.createBoard('Новая доска'),
                visualDensity: VisualDensity.compact,
                iconSize: AppThemeVariables.iconLg,
              ),
              IconButton(
                icon: const Icon(LucideIcons.refreshCw),
                tooltip: 'Обновить',
                onPressed: () => notifier.initTasks(),
                visualDensity: VisualDensity.compact,
                iconSize: AppThemeVariables.iconLg,
              ),
            ],
          ),
        ),
        // Каталог
        const Expanded(child: BoardsListView()),
      ],
    );
  }

  // Выбор раздела (заметки/задачи)
  Widget _buildTabSelector(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: EdgeInsets.all(AppThemeVariables.xs),
            child: SegmentedButton<int>(
              showSelectedIcon: false,
              style: ButtonStyle(
                shape: WidgetStatePropertyAll(
                  RoundedRectangleBorder(
                    borderRadius: AppThemeVariables.borderRadiusXs,
                  ),
                ),
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              segments: [
                ButtonSegment<int>(
                  // Кнопка раздела заметок
                  value: 0,
                  icon: Icon(
                    LucideIcons.fileText,
                    size: AppThemeVariables.iconLg,
                    color: context.colors.primary,
                  ),
                  label: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppThemeVariables.xs,
                    ),
                    child: Text('Заметки', style: context.h3),
                  ),
                ),
                ButtonSegment<int>(
                  // Кнопка раздела задач
                  value: 1,
                  icon: Icon(
                    LucideIcons.squareKanban,
                    size: AppThemeVariables.iconLg,
                    color: context.colors.primary,
                  ),
                  label: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppThemeVariables.xs,
                    ),
                    child: Text('Задачи', style: context.h3),
                  ),
                ),
              ],
              selected: {widget.selectedTab},
              onSelectionChanged: (Set<int> newSelection) {
                widget.onTabChanged(newSelection.first);
              },
            ),
          ),
        ),
        IconButton(
          // Кнопка переключения состояния панели (свернуть)
          icon: const Icon(LucideIcons.panelLeftClose),
          tooltip: 'Свернуть панель',
          onPressed: widget.onToggleSidebar,
          visualDensity: VisualDensity.compact,
          iconSize: AppThemeVariables.iconLg,
        ),
        SizedBox(width: AppThemeVariables.xs),
      ],
    );
  }

  // Футер
  Widget _buildFooter(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: AppThemeVariables.xs,
        horizontal: AppThemeVariables.xxs,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        spacing: AppThemeVariables.xxs,
        children: [
          Expanded(
            child: TextButton.icon(
              // Кнопка синхронизации
              label: Text('Синхронизация', style: context.bodySecondary),
              icon: const Icon(
                LucideIcons.refreshCw,
                size: AppThemeVariables.iconSm,
              ),
              onPressed: () {},
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
            ),
          ),
          Expanded(
            child: TextButton.icon(
              // Кнопка настроек
              label: Text('Настройки', style: context.bodySecondary),
              icon: const Icon(
                LucideIcons.settings,
                size: AppThemeVariables.iconSm,
              ),
              onPressed: () {},
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
            ),
          ),
        ],
      ),
    );
  }
}
