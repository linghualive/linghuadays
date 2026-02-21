import 'dart:convert';
import 'dart:io';

import 'package:home_widget/home_widget.dart';

import '../models/event.dart';
import '../services/date_calculation_service.dart';
import '../services/lunar_service.dart';

/// 管理 Android 桌面小组件的数据同步
class WidgetService {
  static const String _androidWidgetName = 'CountdownWidgetProvider';

  /// 更新小组件展示的单个事件数据
  Future<void> updateWidget(Event event) async {
    if (!Platform.isAndroid) return;

    final calcService = DateCalculationService();
    final effectiveDate = _getEffectiveDate(event, calcService);
    final days = calcService.daysUntil(effectiveDate);

    await HomeWidget.saveWidgetData<String>('event_name', event.name);
    await HomeWidget.saveWidgetData<int>('event_days', days);
    await HomeWidget.saveWidgetData<int>('event_id', event.id ?? 0);
    await HomeWidget.saveWidgetData<String>(
      'event_date',
      _formatDate(event, effectiveDate),
    );
    await HomeWidget.saveWidgetData<String>(
      'event_label',
      days == 0
          ? '就是今天'
          : days > 0
              ? '还有'
              : '已经',
    );

    await HomeWidget.updateWidget(
      androidName: _androidWidgetName,
    );
  }

  /// 保存所有事件列表供配置 Activity 读取
  Future<void> saveAllEvents(List<Event> events) async {
    if (!Platform.isAndroid) return;

    final calcService = DateCalculationService();
    final list = events.map((e) {
      final effectiveDate = _getEffectiveDate(e, calcService);
      final days = calcService.daysUntil(effectiveDate);
      return {
        'id': e.id,
        'name': e.name,
        'days': days,
        'date': _formatDate(e, effectiveDate),
      };
    }).toList();

    await HomeWidget.saveWidgetData<String>(
      'all_events',
      jsonEncode(list),
    );
  }

  /// 触发小组件刷新
  Future<void> refreshWidget() async {
    if (!Platform.isAndroid) return;
    await HomeWidget.updateWidget(
      androidName: _androidWidgetName,
    );
  }

  String _formatDate(Event event, DateTime displayDate) {
    if (event.calendarType == 'lunar' &&
        event.lunarYear != null &&
        event.lunarMonth != null &&
        event.lunarDay != null) {
      return LunarService().getLunarDateString(
        event.lunarYear!,
        event.lunarMonth!,
        event.lunarDay!,
        isLeapMonth: event.isLeapMonth,
      );
    }
    return '${displayDate.year}-${displayDate.month.toString().padLeft(2, '0')}-${displayDate.day.toString().padLeft(2, '0')}';
  }

  static DateTime _getEffectiveDate(
    Event event,
    DateCalculationService calcService,
  ) {
    if (!event.isRepeating) return event.targetDate;
    if (event.calendarType == 'lunar' &&
        event.lunarMonth != null &&
        event.lunarDay != null) {
      return LunarService().nextLunarOccurrence(
        event.lunarMonth!,
        event.lunarDay!,
        isLeapMonth: event.isLeapMonth,
      );
    }
    return calcService.nextOccurrence(event.targetDate);
  }
}
