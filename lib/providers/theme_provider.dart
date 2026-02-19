import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../themes/app_theme.dart';

const _themeKey = 'theme_mode';
const _seedColorKey = 'seed_color';
const _useDynamicColorKey = 'use_dynamic_color';

final themeProvider =
    StateNotifierProvider<ThemeNotifier, ThemeModeSetting>((ref) {
  return ThemeNotifier();
});

final seedColorProvider =
    StateNotifierProvider<SeedColorNotifier, Color?>((ref) {
  return SeedColorNotifier();
});

final useDynamicColorProvider =
    StateNotifierProvider<UseDynamicColorNotifier, bool>((ref) {
  return UseDynamicColorNotifier();
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

class SeedColorNotifier extends StateNotifier<Color?> {
  SeedColorNotifier() : super(null) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getInt(_seedColorKey);
    if (value != null) {
      state = Color(value);
    }
  }

  Future<void> setSeedColor(Color? color) async {
    state = color;
    final prefs = await SharedPreferences.getInstance();
    if (color != null) {
      await prefs.setInt(_seedColorKey, color.toARGB32());
    } else {
      await prefs.remove(_seedColorKey);
    }
  }
}

class UseDynamicColorNotifier extends StateNotifier<bool> {
  UseDynamicColorNotifier() : super(true) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getBool(_useDynamicColorKey);
    if (value != null) {
      state = value;
    }
  }

  Future<void> setUseDynamicColor(bool value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_useDynamicColorKey, value);
  }
}
