import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daysmater/models/event.dart';
import 'package:daysmater/screens/event_detail_screen.dart';
import 'package:daysmater/widgets/event_card.dart';

void main() {
  final now = DateTime.now();

  Event createEvent({
    String name = '测试事件',
    DateTime? targetDate,
    String calendarType = 'solar',
    String? note,
    int? categoryId,
    bool isRepeating = false,
    int? reminderDaysBefore,
    int? reminderHour,
    int? reminderMinute,
  }) {
    return Event(
      id: 1,
      name: name,
      targetDate: targetDate ?? now.add(const Duration(days: 30)),
      calendarType: calendarType,
      note: note,
      categoryId: categoryId,
      isRepeating: isRepeating,
      reminderDaysBefore: reminderDaysBefore,
      reminderHour: reminderHour,
      reminderMinute: reminderMinute,
      createdAt: now,
      updatedAt: now,
    );
  }

  Widget wrapWithMaterial(Widget child) {
    return ProviderScope(
      child: MaterialApp(
        home: child,
      ),
    );
  }

  group('EventDetailScreen', () {
    testWidgets('AppBar 显示事件名称', (tester) async {
      final event = createEvent(name: '妈妈生日');
      await tester.pumpWidget(wrapWithMaterial(
        EventDetailScreen(event: event),
      ));
      // AppBar 中应显示事件名称
      expect(find.text('妈妈生日'), findsWidgets);
    });

    testWidgets('显示焦点事件卡片', (tester) async {
      final event = createEvent(name: '新年倒计时');
      await tester.pumpWidget(wrapWithMaterial(
        EventDetailScreen(event: event),
      ));
      // 应包含 EventCard 组件
      expect(find.byType(EventCard), findsOneWidget);
    });

    testWidgets('显示备注信息', (tester) async {
      final event = createEvent(note: '记得买蛋糕');
      await tester.pumpWidget(wrapWithMaterial(
        EventDetailScreen(event: event),
      ));
      expect(find.text('记得买蛋糕'), findsOneWidget);
    });

    testWidgets('无备注时显示占位文本', (tester) async {
      final event = createEvent(note: null);
      await tester.pumpWidget(wrapWithMaterial(
        EventDetailScreen(event: event),
      ));
      expect(find.text('暂无备注'), findsOneWidget);
    });

    testWidgets('显示日历类型', (tester) async {
      final event = createEvent(calendarType: 'solar');
      await tester.pumpWidget(wrapWithMaterial(
        EventDetailScreen(event: event),
      ));
      expect(find.text('公历'), findsOneWidget);
    });

    testWidgets('农历类型显示农历', (tester) async {
      final event = createEvent(calendarType: 'lunar');
      await tester.pumpWidget(wrapWithMaterial(
        EventDetailScreen(event: event),
      ));
      expect(find.text('农历'), findsOneWidget);
    });

    testWidgets('显示重复状态', (tester) async {
      final event = createEvent(isRepeating: true);
      await tester.pumpWidget(wrapWithMaterial(
        EventDetailScreen(event: event),
      ));
      expect(find.text('每年重复'), findsOneWidget);
    });

    testWidgets('非重复显示不重复', (tester) async {
      final event = createEvent(isRepeating: false);
      await tester.pumpWidget(wrapWithMaterial(
        EventDetailScreen(event: event),
      ));
      expect(find.text('不重复'), findsOneWidget);
    });

    testWidgets('显示提醒设置', (tester) async {
      final event = createEvent(
        reminderDaysBefore: 3,
        reminderHour: 9,
        reminderMinute: 0,
      );
      await tester.pumpWidget(wrapWithMaterial(
        EventDetailScreen(event: event),
      ));
      expect(find.text('提前 3 天 09:00'), findsOneWidget);
    });

    testWidgets('无提醒时显示未设置', (tester) async {
      final event = createEvent();
      await tester.pumpWidget(wrapWithMaterial(
        EventDetailScreen(event: event),
      ));
      expect(find.text('未设置'), findsOneWidget);
    });

    testWidgets('显示进入倒计时按钮', (tester) async {
      final event = createEvent();
      await tester.pumpWidget(wrapWithMaterial(
        EventDetailScreen(event: event),
      ));
      await tester.scrollUntilVisible(
        find.text('进入倒计时'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('进入倒计时'), findsOneWidget);
    });

    testWidgets('显示编辑按钮', (tester) async {
      final event = createEvent();
      await tester.pumpWidget(wrapWithMaterial(
        EventDetailScreen(event: event),
      ));
      await tester.scrollUntilVisible(
        find.text('编辑'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('编辑'), findsOneWidget);
    });

    testWidgets('显示删除按钮', (tester) async {
      final event = createEvent();
      await tester.pumpWidget(wrapWithMaterial(
        EventDetailScreen(event: event),
      ));
      await tester.scrollUntilVisible(
        find.text('删除'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('删除'), findsOneWidget);
    });

    testWidgets('点击删除弹出确认对话框', (tester) async {
      final event = createEvent(name: '待删除事件');
      await tester.pumpWidget(wrapWithMaterial(
        EventDetailScreen(event: event),
      ));
      await tester.scrollUntilVisible(
        find.text('删除'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('删除'));
      await tester.pumpAndSettle();
      expect(find.text('确认删除'), findsOneWidget);
      expect(find.text('确定要删除「待删除事件」吗？'), findsOneWidget);
    });

    testWidgets('显示创建时间', (tester) async {
      final createdAt = DateTime(2025, 6, 15, 10, 30);
      final event = Event(
        id: 1,
        name: '测试',
        targetDate: now.add(const Duration(days: 30)),
        calendarType: 'solar',
        createdAt: createdAt,
        updatedAt: createdAt,
      );
      await tester.pumpWidget(wrapWithMaterial(
        EventDetailScreen(event: event),
      ));
      expect(find.text('2025-06-15 10:30'), findsOneWidget);
    });
  });
}
