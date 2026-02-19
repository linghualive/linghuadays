import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/event.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Initialize the notification plugin with platform-specific settings.
  Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Shanghai'));

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _plugin.initialize(settings);
    _initialized = true;
  }

  /// Request notification permission on iOS/Android 13+.
  /// Returns true if permission was granted.
  Future<bool> requestPermission() async {
    // Try iOS permission first
    final iOS = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (iOS != null) {
      final granted = await iOS.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    // Try Android permission (Android 13+)
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }

    return true;
  }

  /// Schedule a notification for an event based on its reminder settings.
  /// Does nothing if the event has no reminder configured.
  Future<void> scheduleForEvent(Event event) async {
    if (event.id == null || event.reminderDaysBefore == null) return;

    final notificationTime = calculateNotificationTime(
      event.targetDate,
      event.reminderDaysBefore!,
      event.reminderHour ?? 9,
      event.reminderMinute ?? 0,
    );

    // Don't schedule if the notification time has already passed
    if (notificationTime.isBefore(tz.TZDateTime.now(tz.local))) return;

    final body = _buildNotificationBody(event);

    await _plugin.zonedSchedule(
      event.id!,
      event.name,
      body,
      notificationTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daysmater_reminders',
          '倒数日提醒',
          channelDescription: '倒数日事件到期提醒',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: event.isRepeating
          ? DateTimeComponents.dateAndTime
          : null,
    );
  }

  /// Cancel any scheduled notification for an event.
  Future<void> cancelForEvent(int eventId) async {
    await _plugin.cancel(eventId);
  }

  /// Cancel all scheduled notifications.
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  /// Calculate the exact notification trigger time.
  tz.TZDateTime calculateNotificationTime(
    DateTime targetDate,
    int daysBefore,
    int hour,
    int minute,
  ) {
    final reminderDate = targetDate.subtract(Duration(days: daysBefore));
    return tz.TZDateTime(
      tz.local,
      reminderDate.year,
      reminderDate.month,
      reminderDate.day,
      hour,
      minute,
    );
  }

  String _buildNotificationBody(Event event) {
    final daysBefore = event.reminderDaysBefore!;
    if (daysBefore == 0) {
      return '今天就是「${event.name}」的日子！';
    }
    return '距离「${event.name}」还有 $daysBefore 天';
  }
}
