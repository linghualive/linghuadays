import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/event.dart';
import '../repositories/event_repository.dart';
import '../services/notification_service.dart';
import 'database_provider.dart';

// 排序方式状态
final eventSortProvider =
    StateProvider<EventSortType>((ref) => EventSortType.byDaysRemaining);

// 分类筛选状态
final eventCategoryFilterProvider = StateProvider<int?>((ref) => null);

// 搜索关键字状态
final eventSearchQueryProvider = StateProvider<String?>((ref) => null);

// 事件列表（响应排序/筛选/搜索变化）
final eventsProvider =
    AsyncNotifierProvider<EventsNotifier, List<Event>>(EventsNotifier.new);

class EventsNotifier extends AsyncNotifier<List<Event>> {
  @override
  Future<List<Event>> build() async {
    final repo = ref.watch(eventRepositoryProvider);
    final sortType = ref.watch(eventSortProvider);
    final categoryId = ref.watch(eventCategoryFilterProvider);
    final searchQuery = ref.watch(eventSearchQueryProvider);

    return repo.getAll(
      sortType: sortType,
      categoryId: categoryId,
      searchQuery: searchQuery,
    );
  }

  Future<void> addEvent(Event event) async {
    final repo = ref.read(eventRepositoryProvider);
    final id = await repo.insert(event);
    // Schedule notification for the newly created event
    if (event.reminderDaysBefore != null) {
      final saved = event.copyWith(id: id);
      await NotificationService().scheduleForEvent(saved);
    }
    ref.invalidateSelf();
  }

  Future<void> updateEvent(Event event) async {
    final repo = ref.read(eventRepositoryProvider);
    await repo.update(event);
    // Re-schedule or cancel notification
    if (event.id != null) {
      await NotificationService().cancelForEvent(event.id!);
      if (event.reminderDaysBefore != null) {
        await NotificationService().scheduleForEvent(event);
      }
    }
    ref.invalidateSelf();
  }

  Future<void> deleteEvent(int id) async {
    final repo = ref.read(eventRepositoryProvider);
    await repo.delete(id);
    await NotificationService().cancelForEvent(id);
    ref.invalidateSelf();
  }

  Future<void> deleteMultiple(List<int> ids) async {
    final repo = ref.read(eventRepositoryProvider);
    await repo.deleteMultiple(ids);
    for (final id in ids) {
      await NotificationService().cancelForEvent(id);
    }
    ref.invalidateSelf();
  }

  Future<void> togglePin(int eventId) async {
    final repo = ref.read(eventRepositoryProvider);
    await repo.togglePin(eventId);
    ref.invalidateSelf();
  }

  Future<void> setFocus(int eventId) async {
    final repo = ref.read(eventRepositoryProvider);
    await repo.setFocus(eventId);
    ref.invalidateSelf();
  }
}

// 焦点事件
final focusEventProvider = FutureProvider<Event?>((ref) async {
  // 依赖 eventsProvider 确保数据刷新时同步更新
  ref.watch(eventsProvider);
  final repo = ref.watch(eventRepositoryProvider);
  return repo.getFocusEvent();
});
