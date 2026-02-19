import 'package:go_router/go_router.dart';

import 'models/event.dart';
import 'screens/category_management_screen.dart';
import 'screens/countdown_screen.dart';
import 'screens/event_form_screen.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/event/create',
      name: 'createEvent',
      builder: (context, state) => const EventFormScreen(),
    ),
    GoRoute(
      path: '/event/edit',
      name: 'editEvent',
      builder: (context, state) {
        final event = state.extra as Event;
        return EventFormScreen(event: event);
      },
    ),
    GoRoute(
      path: '/countdown',
      name: 'countdown',
      builder: (context, state) {
        final event = state.extra as Event;
        return CountdownScreen(event: event);
      },
    ),
    GoRoute(
      path: '/settings',
      name: 'settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/settings/categories',
      name: 'categoryManagement',
      builder: (context, state) => const CategoryManagementScreen(),
    ),
  ],
);
