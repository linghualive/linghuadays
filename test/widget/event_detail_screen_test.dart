import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daysmater/models/event.dart';
import 'package:daysmater/screens/event_detail_screen.dart';

void main() {
  final now = DateTime.now();

  Event createEvent({
    String name = '测试事件',
    DateTime? targetDate,
    String calendarType = 'solar',
  }) {
    return Event(
      id: 1,
      name: name,
      targetDate: targetDate ?? now.add(const Duration(days: 30)),
      calendarType: calendarType,
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
    testWidgets('AppBar 显示玲华倒数', (tester) async {
      final event = createEvent(name: '妈妈生日');
      await tester.pumpWidget(wrapWithMaterial(
        EventDetailScreen(event: event),
      ));
      expect(find.text('玲华倒数'), findsOneWidget);
    });

    testWidgets('卡片标题栏显示事件名称和还有', (tester) async {
      final event = createEvent(name: '妈妈生日');
      await tester.pumpWidget(wrapWithMaterial(
        EventDetailScreen(event: event),
      ));
      expect(find.text('妈妈生日还有'), findsOneWidget);
    });

    testWidgets('过去事件显示已过', (tester) async {
      final event = createEvent(
        name: '过去事件',
        targetDate: now.subtract(const Duration(days: 10)),
      );
      await tester.pumpWidget(wrapWithMaterial(
        EventDetailScreen(event: event),
      ));
      expect(find.text('过去事件已过'), findsOneWidget);
    });

    testWidgets('显示天数数字', (tester) async {
      final event = createEvent(
        targetDate: now.add(const Duration(days: 30)),
      );
      await tester.pumpWidget(wrapWithMaterial(
        EventDetailScreen(event: event),
      ));
      expect(find.text('30'), findsOneWidget);
    });

    testWidgets('显示目标日期', (tester) async {
      final target = DateTime(2026, 12, 25);
      final event = createEvent(targetDate: target);
      await tester.pumpWidget(wrapWithMaterial(
        EventDetailScreen(event: event),
      ));
      expect(find.textContaining('目标日:'), findsOneWidget);
      expect(find.textContaining('2026-12-25'), findsOneWidget);
    });

    testWidgets('AppBar 有编辑按钮', (tester) async {
      final event = createEvent();
      await tester.pumpWidget(wrapWithMaterial(
        EventDetailScreen(event: event),
      ));
      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
    });

    testWidgets('显示样式按钮', (tester) async {
      final event = createEvent();
      await tester.pumpWidget(wrapWithMaterial(
        EventDetailScreen(event: event),
      ));
      expect(find.text('样式'), findsOneWidget);
    });

    testWidgets('显示字体按钮', (tester) async {
      final event = createEvent();
      await tester.pumpWidget(wrapWithMaterial(
        EventDetailScreen(event: event),
      ));
      expect(find.text('字体'), findsOneWidget);
    });

    testWidgets('显示存图按钮', (tester) async {
      final event = createEvent();
      await tester.pumpWidget(wrapWithMaterial(
        EventDetailScreen(event: event),
      ));
      expect(find.text('存图'), findsOneWidget);
    });

    testWidgets('未来事件显示倒计时按钮', (tester) async {
      final event = createEvent(
        targetDate: now.add(const Duration(days: 10)),
      );
      await tester.pumpWidget(wrapWithMaterial(
        EventDetailScreen(event: event),
      ));
      expect(find.text('倒计时'), findsOneWidget);
    });

    testWidgets('过去事件不显示倒计时按钮', (tester) async {
      final event = createEvent(
        targetDate: now.subtract(const Duration(days: 10)),
      );
      await tester.pumpWidget(wrapWithMaterial(
        EventDetailScreen(event: event),
      ));
      expect(find.text('倒计时'), findsNothing);
    });

    testWidgets('点击样式按钮弹出样式选择面板', (tester) async {
      final event = createEvent();
      await tester.pumpWidget(wrapWithMaterial(
        EventDetailScreen(event: event),
      ));
      await tester.tap(find.text('样式'));
      await tester.pumpAndSettle();
      expect(find.text('选择样式'), findsOneWidget);
    });

    testWidgets('点击字体按钮弹出字体选择面板', (tester) async {
      final event = createEvent();
      await tester.pumpWidget(wrapWithMaterial(
        EventDetailScreen(event: event),
      ));
      await tester.tap(find.text('字体'));
      await tester.pumpAndSettle();
      expect(find.text('选择字体'), findsOneWidget);
    });
  });
}
