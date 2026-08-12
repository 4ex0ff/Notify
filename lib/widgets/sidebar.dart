import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:notify/theme/app_theme_variables.dart';
import '../providers/notes_provider.dart';
import '../theme/app_theme.dart';
import 'file_tree_view.dart';

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
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(notesProvider.notifier).initNotes();
    });
  }

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

  Widget _buildExpandedContent(BuildContext context) {
    final notesState = ref.watch(notesProvider);

    return Column(
      children: [
        _buildTabSelector(context),
        Expanded(
          child: widget.selectedTab == 0
              ? _buildNotesSection(context, notesState)
              : _buildTasksSection(context),
        ),
        const Divider(height: 1),
        _buildFooter(context),
      ],
    );
  }

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
            horizontal: AppThemeVariables.xl,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
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
        Expanded(child: FileTreeView(nodes: notesState.nodes)),
      ],
    );
  }

  Widget _buildTasksSection(BuildContext context) {
    return Center(child: Text('Раздел задач', style: context.bodySmall));
  }

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
        trailing: Column(
          children: [
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
}
