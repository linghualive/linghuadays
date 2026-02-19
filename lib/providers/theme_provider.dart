import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../themes/app_theme.dart';

const _themeKey = 'theme_mode';

final themeProvider =
    StateNotifierProvider<ThemeNotifier, ThemeModeSetting>((ref) {
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<ThemeModeSetting> {
  ThemeNotifier() : super(ThemeModeSetting.system) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_themeKey);
    if (value != null) {
      state = ThemeModeSetting.values.byName(value);
    }
  }

  Future<void> setThemeMode(ThemeModeSetting mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, mode.name);
  }

  ThemeMode get themeMode {
    switch (state) {
      case ThemeModeSetting.light:
        return ThemeMode.light;
      case ThemeModeSetting.dark:
        return ThemeMode.dark;
      case ThemeModeSetting.system:
        return ThemeMode.system;
    }
  }
}
