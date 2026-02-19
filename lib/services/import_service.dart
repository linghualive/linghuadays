import 'dart:convert';

import '../models/category.dart';
import '../models/event.dart';

class ImportResult {
  final int importedEvents;
  final int skippedEvents;
  final int importedCategories;
  final List<String> errors;

  const ImportResult({
    required this.importedEvents,
    required this.skippedEvents,
    required this.importedCategories,
    required this.errors,
  });
}

class DuplicateEvent {
  final Event incoming;
  final Event existing;

  const DuplicateEvent({required this.incoming, required this.existing});
}

class ImportData {
  final List<Event> events;
  final List<EventCategory> categories;
  final List<DuplicateEvent> duplicates;

  const ImportData({
    required this.events,
    required this.categories,
    required this.duplicates,
  });
}

class ImportService {
  /// Parse and validate a JSON string for import.
  /// Returns parsed data or throws [FormatException] on invalid input.
  ImportData parseAndValidate(
    String jsonStr,
    List<Event> existingEvents,
  ) {
    final dynamic decoded;
    try {
      decoded = jsonDecode(jsonStr);
    } catch (e) {
      throw const FormatException('JSON 格式无效');
    }

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('JSON 根元素必须是对象');
    }

    if (!decoded.containsKey('events')) {
      throw const FormatException('缺少 events 字段');
    }

    final eventsJson = decoded['events'];
    if (eventsJson is! List) {
      throw const FormatException('events 必须是数组');
    }

    final now = DateTime.now();
    final events = <Event>[];
    final errors = <String>[];

    for (var i = 0; i < eventsJson.length; i++) {
      try {
        final map = eventsJson[i] as Map<String, dynamic>;
        // Validate required fields
        if (map['name'] == null || (map['name'] as String).isEmpty) {
          errors.add('事件 #${i + 1}: 缺少名称');
          continue;
        }
        if (map['target_date'] == null) {
          errors.add('事件 #${i + 1}: 缺少目标日期');
          continue;
        }
        // Parse with defaults for missing timestamps
        final event = Event(
          name: map['name'] as String,
          targetDate: DateTime.parse(map['target_date'] as String),
          calendarType: (map['calendar_type'] as String?) ?? 'solar',
          lunarYear: map['lunar_year'] as int?,
          lunarMonth: map['lunar_month'] as int?,
          lunarDay: map['lunar_day'] as int?,
          isLeapMonth: (map['is_leap_month'] as int?) == 1,
          note: map['note'] as String?,
          isRepeating: (map['is_repeating'] as int?) == 1,
          createdAt: map['created_at'] != null
              ? DateTime.parse(map['created_at'] as String)
              : now,
          updatedAt: map['updated_at'] != null
              ? DateTime.parse(map['updated_at'] as String)
              : now,
          reminderDaysBefore: map['reminder_days_before'] as int?,
          reminderHour: map['reminder_hour'] as int?,
          reminderMinute: map['reminder_minute'] as int?,
        );
        events.add(event);
      } catch (e) {
        errors.add('事件 #${i + 1}: 解析失败 ($e)');
      }
    }

    // Parse categories
    final categories = <EventCategory>[];
    final catsJson = decoded['categories'];
    if (catsJson is List) {
      for (var i = 0; i < catsJson.length; i++) {
        try {
          final map = catsJson[i] as Map<String, dynamic>;
          if (map['name'] != null && map['color_value'] != null) {
            categories.add(EventCategory(
              name: map['name'] as String,
              colorValue: map['color_value'] as int,
            ));
          }
        } catch (_) {
          // Skip invalid categories silently
        }
      }
    }

    // Detect duplicates by name + targetDate
    final duplicates = <DuplicateEvent>[];
    final newEvents = <Event>[];

    for (final event in events) {
      final match = _findDuplicate(event, existingEvents);
      if (match != null) {
        duplicates.add(DuplicateEvent(incoming: event, existing: match));
      } else {
        newEvents.add(event);
      }
    }

    return ImportData(
      events: newEvents,
      categories: categories,
      duplicates: duplicates,
    );
  }

  Event? _findDuplicate(Event incoming, List<Event> existing) {
    for (final e in existing) {
      if (e.name == incoming.name &&
          e.targetDate.year == incoming.targetDate.year &&
          e.targetDate.month == incoming.targetDate.month &&
          e.targetDate.day == incoming.targetDate.day) {
        return e;
      }
    }
    return null;
  }
}
