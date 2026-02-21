import 'package:flutter_test/flutter_test.dart';
import 'package:daysmater/models/event.dart';
import 'package:daysmater/services/widget_service.dart';

void main() {
  group('WidgetService', () {
    late WidgetService service;

    setUp(() {
      service = WidgetService();
    });

    test('实例化成功', () {
      expect(service, isNotNull);
    });

    test('updateWidget 非 Android 平台不抛异常', () async {
      final event = Event(
        id: 1,
        name: '测试事件',
        targetDate: DateTime.now().add(const Duration(days: 10)),
        calendarType: 'solar',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      // 非 Android 平台应静默返回
      await expectLater(service.updateWidget(event), completes);
    });

    test('saveAllEvents 非 Android 平台不抛异常', () async {
      final events = [
        Event(
          id: 1,
          name: '事件1',
          targetDate: DateTime.now().add(const Duration(days: 5)),
          calendarType: 'solar',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Event(
          id: 2,
          name: '事件2',
          targetDate: DateTime.now().add(const Duration(days: 15)),
          calendarType: 'solar',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];
      await expectLater(service.saveAllEvents(events), completes);
    });

    test('refreshWidget 非 Android 平台不抛异常', () async {
      await expectLater(service.refreshWidget(), completes);
    });
  });
}
