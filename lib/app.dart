import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/theme_provider.dart';
import 'router.dart';
import 'themes/app_theme.dart';

class DaysMaterApp extends ConsumerWidget {
  const DaysMaterApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(themeProvider);
    final themeNotifier = ref.read(themeProvider.notifier);
    final seedColor = ref.watch(seedColorProvider);
    final useDynamic = ref.watch(useDynamicColorProvider);

    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        ThemeData lightTheme;
        ThemeData darkTheme;

        if (useDynamic && lightDynamic != null && darkDynamic != null) {
          // Use Monet dynamic colors from wallpaper
          lightTheme = AppTheme.fromColorScheme(lightDynamic);
          darkTheme = AppTheme.fromColorScheme(darkDynamic);
        } else {
          // Use seed color (custom or default)
          lightTheme = AppTheme.lightTheme(seedColor: seedColor);
          darkTheme = AppTheme.darkTheme(seedColor: seedColor);
        }

        return MaterialApp.router(
          title: '玲华倒数',
          debugShowCheckedModeBanner: false,
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: themeNotifier.themeMode,
          routerConfig: router,
          locale: const Locale('zh', 'CN'),
        );
      },
    );
  }
}
