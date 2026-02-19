import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daysmater/app.dart';

void main() {
  testWidgets('App 启动显示 DaysMater 标题', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: DaysMaterApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('DaysMater'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
  });
}
