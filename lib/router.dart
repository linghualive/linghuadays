import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'models/event.dart';
import 'screens/category_management_screen.dart';
import 'screens/countdown_screen.dart';
import 'screens/event_detail_screen.dart';
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
      pageBuilder: (context, state) => _buildSlideUpPage(
        key: state.pageKey,
        child: const EventFormScreen(),
      ),
    ),
    GoRoute(
      path: '/event/detail',
      name: 'eventDetail',
      pageBuilder: (context, state) {
        final event = state.extra as Event;
        return _buildSlidePage(
          key: state.pageKey,
          child: EventDetailScreen(event: event),
        );
      },
    ),
    GoRoute(
      path: '/event/edit',
      name: 'editEvent',
      pageBuilder: (context, state) {
        final event = state.extra as Event;
        return _buildSlideUpPage(
          key: state.pageKey,
          child: EventFormScreen(event: event),
        );
      },
    ),
    GoRoute(
      path: '/countdown',
      name: 'countdown',
      pageBuilder: (context, state) {
        final event = state.extra as Event;
        return _buildFadePage(
          key: state.pageKey,
          child: CountdownScreen(event: event),
        );
      },
    ),
    GoRoute(
      path: '/settings',
      name: 'settings',
      pageBuilder: (context, state) => _buildSlidePage(
        key: state.pageKey,
        child: const SettingsScreen(),
      ),
    ),
    GoRoute(
      path: '/settings/categories',
      name: 'categoryManagement',
      pageBuilder: (context, state) => _buildSlidePage(
        key: state.pageKey,
        child: const CategoryManagementScreen(),
      ),
    ),
  ],
);

/// M3 forward/backward shared axis (horizontal slide).
CustomTransitionPage<void> _buildSlidePage({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage(
    key: key,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 250),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final offsetAnimation = Tween<Offset>(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ));

      final fadeAnimation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: const Interval(0.0, 0.6),
      ));

      return SlideTransition(
        position: offsetAnimation,
        child: FadeTransition(
          opacity: fadeAnimation,
          child: child,
        ),
      );
    },
  );
}

/// Bottom sheet style slide-up for create/edit forms.
CustomTransitionPage<void> _buildSlideUpPage({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage(
    key: key,
    child: child,
    transitionDuration: const Duration(milliseconds: 350),
    reverseTransitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final offsetAnimation = Tween<Offset>(
        begin: const Offset(0.0, 0.3),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ));

      final fadeAnimation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: const Interval(0.0, 0.5),
      ));

      return SlideTransition(
        position: offsetAnimation,
        child: FadeTransition(
          opacity: fadeAnimation,
          child: child,
        ),
      );
    },
  );
}

/// Fade through for immersive screens (countdown).
CustomTransitionPage<void> _buildFadePage({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage(
    key: key,
    child: child,
    transitionDuration: const Duration(milliseconds: 400),
    reverseTransitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final scaleAnimation = Tween<double>(
        begin: 0.92,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      ));

      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: scaleAnimation,
          child: child,
        ),
      );
    },
  );
}
