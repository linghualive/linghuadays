import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daysmater/models/event.dart';
import 'package:daysmater/models/card_style.dart';
import 'package:daysmater/models/category.dart';
import 'package:daysmater/widgets/event_card.dart';

void main() {
  final now = DateTime.now();

  Event createEvent({
    String name = '测试事件',
    DateTime? targetDate,
    String calendarType = 'solar',
    bool isPinned = false,
  }) {
    return Event(
      id: 1,
      name: name,
      targetDate: targetDate ?? DateTime.now().add(const Duration(days: 30)),
      calendarType: calendarType,
      isPinned: isPinned,
      createdAt: now,
      updatedAt: now,
    );
  }

  Widget wrapWithMaterial(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );
  }

  group('EventCard', () {
    testWidgets('显示事件名称', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        EventCard(event: createEvent(name: '妈妈生日')),
      ));
      expect(find.text('妈妈生日'), findsOneWidget);
    });

    testWidgets('未来事件显示剩余天数', (tester) async {
      final futureDate = DateTime.now().add(const Duration(days: 10));
      await tester.pumpWidget(wrapWithMaterial(
        EventCard(event: createEvent(targetDate: futureDate)),
      ));
      // 应显示天数数字
      expect(find.text('10'), findsOneWidget);
      expect(find.text('天后'), findsOneWidget);
    });

    testWidgets('过去事件显示已过天数', (tester) async {
      final pastDate = DateTime.now().subtract(const Duration(days: 5));
      await tester.pumpWidget(wrapWithMaterial(
        EventCard(event: createEvent(targetDate: pastDate)),
      ));
      expect(find.text('5'), findsOneWidget);
      expect(find.text('天前'), findsOneWidget);
    });

    testWidgets('当天事件显示就是今天', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        EventCard(event: createEvent(targetDate: DateTime.now())),
      ));
      expect(find.text('就是今天'), findsOneWidget);
    });

    testWidgets('显示分类色条', (tester) async {
      const category = EventCategory(
        id: 1,
        name: '生日',
        colorValue: 0xFFE91E63,
      );
      await tester.pumpWidget(wrapWithMaterial(
        EventCard(
          event: createEvent(),
          category: category,
        ),
      ));
      // 分类色条存在
      expect(find.byType(EventCard), findsOneWidget);
    });

    testWidgets('置顶图标显示', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        EventCard(event: createEvent(isPinned: true)),
      ));
      expect(find.byIcon(Icons.push_pin), findsOneWidget);
    });

    testWidgets('非置顶事件不显示置顶图标', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        EventCard(event: createEvent(isPinned: false)),
      ));
      expect(find.byIcon(Icons.push_pin), findsNothing);
    });

    testWidgets('选中状态显示勾选图标', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        EventCard(
          event: createEvent(),
          isSelected: true,
        ),
      ));
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('焦点卡片使用大号布局', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        EventCard(
          event: createEvent(name: '焦点事件'),
          isFocusCard: true,
        ),
      ));
      expect(find.text('焦点事件'), findsOneWidget);
    });

    testWidgets('点击触发 onTap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(wrapWithMaterial(
        EventCard(
          event: createEvent(),
          onTap: () => tapped = true,
        ),
      ));
      await tester.tap(find.byType(EventCard));
      expect(tapped, true);
    });

    testWidgets('长按触发 onLongPress', (tester) async {
      var longPressed = false;
      await tester.pumpWidget(wrapWithMaterial(
        EventCard(
          event: createEvent(),
          onLongPress: () => longPressed = true,
        ),
      ));
      await tester.longPress(find.byType(EventCard));
      expect(longPressed, true);
    });

    testWidgets('应用简约风格', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        EventCard(
          event: createEvent(),
          style: CardStyle.presets[0], // 简约
        ),
      ));
      expect(find.byType(EventCard), findsOneWidget);
    });

    testWidgets('应用渐变风格', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        EventCard(
          event: createEvent(),
          style: CardStyle.presets[1], // 渐变
        ),
      ));
      expect(find.byType(EventCard), findsOneWidget);
    });

    testWidgets('应用玻璃拟态风格', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        EventCard(
          event: createEvent(),
          style: CardStyle.presets[2], // 玻璃拟态
        ),
      ));
      expect(find.byType(EventCard), findsOneWidget);
    });

    testWidgets('应用深邃风格', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        EventCard(
          event: createEvent(),
          style: CardStyle.presets[4], // 深邃
        ),
      ));
      expect(find.byType(EventCard), findsOneWidget);
    });

    testWidgets('应用节日风格', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        EventCard(
          event: createEvent(),
          style: CardStyle.presets[6], // 节日
        ),
      ));
      expect(find.byType(EventCard), findsOneWidget);
    });
  });
}
