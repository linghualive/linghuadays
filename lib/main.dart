import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

import 'app.dart';
import 'router.dart';
import 'providers/database_provider.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().initialize();

  if (Platform.isAndroid) {
    HomeWidget.widgetClicked.listen(_handleWidgetClick);
  }

  runApp(
    const ProviderScope(
      child: DaysMaterApp(),
    ),
  );
}

Future<void> _handleWidgetClick(Uri? uri) async {
  if (uri == null) return;
  // URI 格式: daysmater://event/{id}
  if (uri.scheme == 'daysmater' && uri.host == 'event') {
    final idStr = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
    if (idStr != null) {
      final id = int.tryParse(idStr);
      if (id != null && id > 0) {
        // 延迟等待路由系统准备就绪
        await Future.delayed(const Duration(milliseconds: 500));
        final context = router.routerDelegate.navigatorKey.currentContext;
        if (context == null || !context.mounted) return;
        final container = ProviderScope.containerOf(context);
        final repo = container.read(eventRepositoryProvider);
        final event = await repo.getById(id);
        if (event != null) {
          router.pushNamed('eventDetail', extra: event);
        }
      }
    }
  }
}
