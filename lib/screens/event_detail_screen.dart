import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/event.dart';
import '../providers/category_provider.dart';
import '../providers/event_provider.dart';
import '../providers/style_provider.dart';
import '../widgets/event_card.dart';

class EventDetailScreen extends ConsumerWidget {
  final Event event;

  const EventDetailScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final categories = ref.watch(categoriesProvider).valueOrNull ?? [];
    final styles = ref.watch(stylesProvider).valueOrNull ?? [];

    final category = event.categoryId != null
        ? categories
            .where((c) => c.id == event.categoryId)
            .firstOrNull
        : null;

    final style = event.styleId != null
        ? styles.where((s) => s.id == event.styleId).firstOrNull
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(event.name),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 焦点卡片
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: EventCard(
                event: event,
                style: style,
                category: category,
                isFocusCard: true,
              ),
            ),
            // 详细信息
            _buildInfoSection(theme),
            const SizedBox(height: 24),
            // 操作按钮
            _buildActions(context, ref, theme),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow(
                theme,
                icon: Icons.calendar_today,
                label: '日历类型',
                value: event.calendarType == 'lunar' ? '农历' : '公历',
              ),
              const Divider(height: 24),
              _buildInfoRow(
                theme,
                icon: Icons.repeat,
                label: '重复',
                value: event.isRepeating ? '每年重复' : '不重复',
              ),
              const Divider(height: 24),
              _buildInfoRow(
                theme,
                icon: Icons.notifications_outlined,
                label: '提醒',
                value: _formatReminder(),
              ),
              const Divider(height: 24),
              _buildInfoRow(
                theme,
                icon: Icons.notes,
                label: '备注',
                value: event.note?.isNotEmpty == true
                    ? event.note!
                    : '暂无备注',
              ),
              const Divider(height: 24),
              _buildInfoRow(
                theme,
                icon: Icons.access_time,
                label: '创建时间',
                value: _formatDateTime(event.createdAt),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context, WidgetRef ref, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.icon(
            onPressed: () {
              context.pushNamed('countdown', extra: event);
            },
            icon: const Icon(Icons.timer),
            label: const Text('进入倒计时'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              context.pushNamed('editEvent', extra: event);
            },
            icon: const Icon(Icons.edit_outlined),
            label: const Text('编辑'),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => _confirmDelete(context, ref),
            icon: Icon(
              Icons.delete_outline,
              color: theme.colorScheme.error,
            ),
            label: Text(
              '删除',
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除「${event.name}」吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              ref.read(eventsProvider.notifier).deleteEvent(event.id!);
              context.pop();
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  String _formatReminder() {
    if (event.reminderDaysBefore == null) return '未设置';
    final hour =
        (event.reminderHour ?? 9).toString().padLeft(2, '0');
    final minute =
        (event.reminderMinute ?? 0).toString().padLeft(2, '0');
    if (event.reminderDaysBefore == 0) {
      return '当天 $hour:$minute';
    }
    return '提前 ${event.reminderDaysBefore} 天 $hour:$minute';
  }

  String _formatDateTime(DateTime dt) {
    final y = dt.year;
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $h:$min';
  }
}
