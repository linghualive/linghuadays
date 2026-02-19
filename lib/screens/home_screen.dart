import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/card_style.dart';
import '../models/category.dart';
import '../models/event.dart';
import '../providers/category_provider.dart';
import '../providers/event_provider.dart';
import '../providers/style_provider.dart';
import '../repositories/event_repository.dart';
import '../services/update_service.dart';
import '../widgets/event_card.dart';
import '../widgets/skeleton_loader.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isMultiSelectMode = false;
  final Set<int> _selectedIds = {};
  Timer? _updateCheckTimer;

  @override
  void initState() {
    super.initState();
    _updateCheckTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        UpdateService().checkAndNotify(context);
      }
    });
  }

  @override
  void dispose() {
    _updateCheckTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final eventsAsync = ref.watch(eventsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final stylesAsync = ref.watch(stylesProvider);
    final focusEventAsync = ref.watch(focusEventProvider);
    final sortType = ref.watch(eventSortProvider);

    return Scaffold(
      appBar: _isMultiSelectMode
          ? _buildMultiSelectAppBar(theme)
          : _buildNormalAppBar(theme, sortType),
      body: eventsAsync.when(
        data: (events) {
          final categories =
              categoriesAsync.valueOrNull ?? <EventCategory>[];
          final styles = stylesAsync.valueOrNull ?? <CardStyle>[];
          final focusEvent = focusEventAsync.valueOrNull;

          if (events.isEmpty) {
            return _buildEmptyState(theme);
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(eventsProvider);
            },
            child: _buildEventList(
              events,
              categories,
              styles,
              focusEvent,
              theme,
            ),
          );
        },
        loading: () => const SkeletonLoader(),
        error: (e, _) => Center(child: Text('加载失败: $e')),
      ),
      floatingActionButton: _isMultiSelectMode
          ? null
          : FloatingActionButton(
              onPressed: _onCreateEvent,
              child: const Icon(Icons.add),
            ),
    );
  }

  AppBar _buildNormalAppBar(ThemeData theme, EventSortType sortType) {
    return AppBar(
      title: const Text('DaysMater'),
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: _showSearch,
        ),
        PopupMenuButton<EventSortType>(
          icon: const Icon(Icons.sort),
          onSelected: (type) {
            ref.read(eventSortProvider.notifier).state = type;
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: EventSortType.byDaysRemaining,
              child: Row(
                children: [
                  if (sortType == EventSortType.byDaysRemaining)
                    Icon(
                      Icons.check,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                  if (sortType == EventSortType.byDaysRemaining)
                    const SizedBox(width: 8),
                  const Text('按剩余天数'),
                ],
              ),
            ),
            PopupMenuItem(
              value: EventSortType.byCreatedAt,
              child: Row(
                children: [
                  if (sortType == EventSortType.byCreatedAt)
                    Icon(
                      Icons.check,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                  if (sortType == EventSortType.byCreatedAt)
                    const SizedBox(width: 8),
                  const Text('按创建时间'),
                ],
              ),
            ),
            PopupMenuItem(
              value: EventSortType.byName,
              child: Row(
                children: [
                  if (sortType == EventSortType.byName)
                    Icon(
                      Icons.check,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                  if (sortType == EventSortType.byName)
                    const SizedBox(width: 8),
                  const Text('按名称'),
                ],
              ),
            ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          onPressed: () => context.pushNamed('settings'),
        ),
      ],
    );
  }

  AppBar _buildMultiSelectAppBar(ThemeData theme) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: _exitMultiSelect,
      ),
      title: Text('已选择 ${_selectedIds.length} 项'),
      actions: [
        IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: _selectedIds.isEmpty ? null : _deleteSelected,
        ),
      ],
    );
  }

  Widget _buildEventList(
    List<Event> events,
    List<EventCategory> categories,
    List<CardStyle> styles,
    Event? focusEvent,
    ThemeData theme,
  ) {
    // Group events by category
    final grouped = <int?, List<Event>>{};
    for (final event in events) {
      grouped.putIfAbsent(event.categoryId, () => []).add(event);
    }

    // Sort groups: categorized first (by category name), uncategorized last
    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) {
        if (a == null && b == null) return 0;
        if (a == null) return 1;
        if (b == null) return -1;
        final catA = _findCategory(a, categories);
        final catB = _findCategory(b, categories);
        return (catA?.name ?? '').compareTo(catB?.name ?? '');
      });

    return CustomScrollView(
      slivers: [
        // 焦点事件
        if (focusEvent != null && !_isMultiSelectMode)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: EventCard(
                event: focusEvent,
                style: _findStyle(focusEvent.styleId, styles),
                category:
                    _findCategory(focusEvent.categoryId, categories),
                isFocusCard: true,
                onTap: () => _onEventTap(focusEvent),
                onLongPress: () => _showEventMenu(focusEvent),
              ),
            ),
          ),
        // 按分类分组的事件列表
        for (final categoryId in sortedKeys) ...[
          SliverToBoxAdapter(
            child: _buildGroupHeader(categoryId, categories, theme),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList.separated(
              itemCount: grouped[categoryId]!.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final event = grouped[categoryId]![index];
                return EventCard(
                  event: event,
                  style: _findStyle(event.styleId, styles),
                  category: _findCategory(event.categoryId, categories),
                  isSelected: _selectedIds.contains(event.id),
                  onTap: () {
                    if (_isMultiSelectMode) {
                      _toggleSelection(event.id!);
                    } else {
                      _onEventTap(event);
                    }
                  },
                  onLongPress: () {
                    if (_isMultiSelectMode) {
                      _toggleSelection(event.id!);
                    } else {
                      _showEventMenu(event);
                    }
                  },
                );
              },
            ),
          ),
        ],
        const SliverToBoxAdapter(
          child: SizedBox(height: 88),
        ),
      ],
    );
  }

  Widget _buildGroupHeader(
    int? categoryId,
    List<EventCategory> categories,
    ThemeData theme,
  ) {
    final category = _findCategory(categoryId, categories);
    final name = category?.name ?? '未分类';
    final color = category?.color;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          if (color != null)
            Container(
              width: 12,
              height: 12,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
          Text(
            name,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_available,
            size: 64,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            '还没有倒数日',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(height: 8),
          FilledButton.tonal(
            onPressed: _onCreateEvent,
            child: const Text('创建第一个倒数日'),
          ),
        ],
      ),
    );
  }

  CardStyle? _findStyle(int? styleId, List<CardStyle> styles) {
    if (styleId == null) return null;
    try {
      return styles.firstWhere((s) => s.id == styleId);
    } catch (_) {
      return null;
    }
  }

  EventCategory? _findCategory(int? categoryId, List<EventCategory> cats) {
    if (categoryId == null) return null;
    try {
      return cats.firstWhere((c) => c.id == categoryId);
    } catch (_) {
      return null;
    }
  }

  void _onEventTap(Event event) {
    context.pushNamed('eventDetail', extra: event);
  }

  void _onCreateEvent() {
    context.pushNamed('createEvent');
  }

  void _showSearch() {
    showSearch(
      context: context,
      delegate: _EventSearchDelegate(ref),
    );
  }

  void _showEventMenu(Event event) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('编辑'),
              onTap: () {
                Navigator.pop(context);
                context.pushNamed('editEvent', extra: event);
              },
            ),
            ListTile(
              leading: Icon(
                event.isPinned
                    ? Icons.push_pin
                    : Icons.push_pin_outlined,
              ),
              title: Text(event.isPinned ? '取消置顶' : '置顶'),
              onTap: () {
                Navigator.pop(context);
                ref.read(eventsProvider.notifier).togglePin(event.id!);
              },
            ),
            ListTile(
              leading: const Icon(Icons.star_outline),
              title: const Text('设为焦点'),
              onTap: () {
                Navigator.pop(context);
                ref.read(eventsProvider.notifier).setFocus(event.id!);
              },
            ),
            ListTile(
              leading: const Icon(Icons.checklist),
              title: const Text('多选'),
              onTap: () {
                Navigator.pop(context);
                _enterMultiSelect(event.id!);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.delete_outline,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                '删除',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(event);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _enterMultiSelect(int initialId) {
    setState(() {
      _isMultiSelectMode = true;
      _selectedIds.add(initialId);
    });
  }

  void _exitMultiSelect() {
    setState(() {
      _isMultiSelectMode = false;
      _selectedIds.clear();
    });
  }

  void _toggleSelection(int id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) {
          _isMultiSelectMode = false;
        }
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _deleteSelected() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除选中的 ${_selectedIds.length} 个倒数日吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ref
                  .read(eventsProvider.notifier)
                  .deleteMultiple(_selectedIds.toList());
              _exitMultiSelect();
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(Event event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除「${event.name}」吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(eventsProvider.notifier).deleteEvent(event.id!);
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}

class _EventSearchDelegate extends SearchDelegate<String> {
  final WidgetRef ref;

  _EventSearchDelegate(this.ref);

  @override
  String get searchFieldLabel => '搜索倒数日';

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        ref.read(eventSearchQueryProvider.notifier).state = null;
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    ref.read(eventSearchQueryProvider.notifier).state = query;
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return const Center(
        child: Text('输入关键字搜索倒数日'),
      );
    }
    ref.read(eventSearchQueryProvider.notifier).state = query;
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    return Consumer(
      builder: (context, ref, _) {
        final eventsAsync = ref.watch(eventsProvider);
        return eventsAsync.when(
          data: (events) {
            if (events.isEmpty) {
              return const Center(
                child: Text('没有找到匹配的倒数日'),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: events.length,
              itemBuilder: (context, index) {
                final event = events[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: EventCard(
                    event: event,
                    onTap: () {
                      ref.read(eventSearchQueryProvider.notifier).state =
                          null;
                      close(context, '');
                    },
                  ),
                );
              },
            );
          },
          loading: () =>
              const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('搜索失败: $e')),
        );
      },
    );
  }
}
