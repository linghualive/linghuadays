import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum ThemeModeSetting {
  light,
  dark,
  system,
}

class AppTheme {
  static const Color _seedColor = Color(0xFFD4869C);

  static ThemeData lightTheme({Color? seedColor}) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor ?? _seedColor,
      brightness: Brightness.light,
    );
    return _buildTheme(colorScheme);
  }

  static ThemeData darkTheme({Color? seedColor}) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor ?? _seedColor,
      brightness: Brightness.dark,
    );
    return _buildTheme(colorScheme);
  }

  /// Build theme from a pre-built ColorScheme (e.g. Monet dynamic colors).
  static ThemeData fromColorScheme(ColorScheme colorScheme) {
    return _buildTheme(colorScheme);
  }

  static ThemeData _buildTheme(ColorScheme colorScheme) {
    final textTheme = _buildTextTheme(colorScheme);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: colorScheme.surfaceContainerLow,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withAlpha(80),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        showDragHandle: true,
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      searchBarTheme: SearchBarThemeData(
        elevation: const WidgetStatePropertyAll(1),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
      ),
    );
  }

  static TextTheme _buildTextTheme(ColorScheme colorScheme) {
    // 用于倒数数字的大号显示字体
    final displayStyle = GoogleFonts.robotoMonoTextTheme();

    return TextTheme(
      // 倒计时全屏页面大数字
      displayLarge: displayStyle.displayLarge?.copyWith(
        fontSize: 72,
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
      ),
      // 焦点事件卡片中的天数
      displayMedium: displayStyle.displayMedium?.copyWith(
        fontSize: 48,
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
      ),
      // 列表卡片中的天数
      displaySmall: displayStyle.displaySmall?.copyWith(
        fontSize: 36,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
      // 页面标题
      headlineMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
      // 事件名称
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w500,
        color: colorScheme.onSurface,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: colorScheme.onSurface,
      ),
      // 日期文本
      bodyLarge: TextStyle(
        fontSize: 16,
        color: colorScheme.onSurfaceVariant,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: colorScheme.onSurfaceVariant,
      ),
      // 分类标签
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: colorScheme.primary,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }

  /// 内置字体名称列表（显示名 -> fontFamily 值）
  static const Map<String, String> availableFonts = {
    '系统默认': 'default',
    '手写': 'Caveat',
    '花体': 'DancingScript',
    '圆趣': 'ZCOOLQingKeHuangYou',
    '快乐': 'ZCOOLKuaiLe',
    '书法': 'MaShanZheng',
    '行草': 'LiuJianMaoCao',
    '龙藏': 'LongCang',
    '复古': 'PlayfairDisplay',
    '像素': 'PressStart2P',
  };
}
