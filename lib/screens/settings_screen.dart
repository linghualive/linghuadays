import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../providers/category_provider.dart';
import '../providers/event_provider.dart';
import '../providers/theme_provider.dart';
import '../services/import_service.dart';
import '../services/update_service.dart';
import '../themes/app_theme.dart';
import 'category_management_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _appVersion = '';
  bool _checkingUpdate = false;

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() => _appVersion = info.version);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeSetting = ref.watch(themeProvider);
    final useDynamic = ref.watch(useDynamicColorProvider);
    final seedColor = ref.watch(seedColorProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          // 主题设置
          _buildSectionHeader('外观', theme),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('主题模式'),
            subtitle: Text(_themeLabel(themeSetting)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showThemeDialog(context, themeSetting),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.wallpaper_outlined),
            title: const Text('壁纸取色'),
            subtitle: const Text('使用系统壁纸颜色（需 Android 12+）'),
            value: useDynamic,
            onChanged: (value) {
              ref.read(useDynamicColorProvider.notifier).setUseDynamicColor(value);
            },
          ),
          ListTile(
            leading: const Icon(Icons.color_lens_outlined),
            title: const Text('主题色'),
            subtitle: Text(useDynamic ? '壁纸取色已开启' : '自定义主题色'),
            enabled: !useDynamic,
            trailing: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: useDynamic
                    ? theme.colorScheme.primary
                    : (seedColor ?? const Color(0xFF6750A4)),
                shape: BoxShape.circle,
              ),
            ),
            onTap: useDynamic ? null : () => _showColorPicker(context, seedColor),
          ),
          const Divider(),

          // 数据管理
          _buildSectionHeader('数据管理', theme),
          ListTile(
            leading: const Icon(Icons.category_outlined),
            title: const Text('分类管理'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const CategoryManagementScreen(),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.upload_outlined),
            title: const Text('导出数据'),
            subtitle: const Text('导出所有倒数日为 JSON 文件'),
            onTap: () => _exportData(context),
          ),
          ListTile(
            leading: const Icon(Icons.download_outlined),
            title: const Text('导入数据'),
            subtitle: const Text('从 JSON 文件导入倒数日'),
            onTap: () => _importData(context),
          ),
          const Divider(),

          // 关于
          _buildSectionHeader('关于', theme),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('玲华倒数'),
            subtitle: Text('版本 $_appVersion'),
          ),
          ListTile(
            leading: _checkingUpdate
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.system_update_outlined),
            title: const Text('检查更新'),
            subtitle: const Text('从 GitHub 获取最新版本'),
            onTap: _checkingUpdate ? null : _checkForUpdate,
          ),
          ListTile(
            leading: const Icon(Icons.share_outlined),
            title: const Text('推荐给朋友'),
            subtitle: const Text('分享玲华倒数给好友'),
            onTap: () {
              Share.share(
                '推荐一个好用的倒数日 App「玲华倒数」，快来试试吧！\nhttps://github.com/linghualive/linghuadays/releases',
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: theme.textTheme.labelLarge,
      ),
    );
  }

  String _themeLabel(ThemeModeSetting setting) {
    switch (setting) {
      case ThemeModeSetting.light:
        return '浅色';
      case ThemeModeSetting.dark:
        return '深色';
      case ThemeModeSetting.system:
        return '跟随系统';
    }
  }

  void _showThemeDialog(BuildContext context, ThemeModeSetting current) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('主题模式'),
        children: ThemeModeSetting.values.map((mode) {
          return SimpleDialogOption(
            onPressed: () {
              ref.read(themeProvider.notifier).setThemeMode(mode);
              Navigator.pop(context);
            },
            child: Row(
              children: [
                Icon(
                  mode == current
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: mode == current
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                const SizedBox(width: 12),
                Text(_themeLabel(mode)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _checkForUpdate() async {
    setState(() => _checkingUpdate = true);

    try {
      await UpdateService().manualCheck(context);
    } finally {
      if (mounted) {
        setState(() => _checkingUpdate = false);
      }
    }
  }

  void _showColorPicker(BuildContext context, Color? currentColor) {
    final presetColors = <Color>[
      const Color(0xFFD4869C), // 浅粉
      const Color(0xFF9B8EC4), // 淡紫
      const Color(0xFF7B9CB8), // 雾蓝
      const Color(0xFF6B8F7B), // 墨绿
      const Color(0xFFB8849A), // 烟粉
      const Color(0xFF8FA67A), // 抹茶
      const Color(0xFFC09080), // 玫瑰金
      const Color(0xFFC4A882), // 奶油
      const Color(0xFFD4937A), // 蜜桃
      const Color(0xFF9A9A8C), // 莫兰迪
      const Color(0xFF8B79AD), // 薰衣草
      const Color(0xFF7B6E92), // 暮色
    ];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('选择主题色'),
          content: SizedBox(
            width: 280,
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: presetColors.map((color) {
                final isSelected = currentColor == color ||
                    (currentColor == null && color == const Color(0xFFD4869C));
                return GestureDetector(
                  onTap: () {
                    ref.read(seedColorProvider.notifier).setSeedColor(color);
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(
                              color: Theme.of(context).colorScheme.outline,
                              width: 3,
                            )
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 20)
                        : null,
                  ),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                ref.read(seedColorProvider.notifier).setSeedColor(null);
                Navigator.pop(context);
              },
              child: const Text('恢复默认'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _exportData(BuildContext context) async {
    try {
      final events = await ref.read(eventsProvider.future);
      final categories = await ref.read(categoriesProvider.future);

      final data = {
        'version': 1,
        'exportDate': DateTime.now().toIso8601String(),
        'events': events.map((e) => e.toJson()).toList(),
        'categories': categories
            .where((c) => !c.isPreset)
            .map((c) => c.toJson())
            .toList(),
      };

      final jsonStr = const JsonEncoder.withIndent('  ').convert(data);
      final dir = await getTemporaryDirectory();
      final fileName =
          'daysmater_export_${DateTime.now().millisecondsSinceEpoch}.json';
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(jsonStr);

      if (!context.mounted) return;

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: '玲华倒数 数据导出',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出失败: $e')),
        );
      }
    }
  }

  Future<void> _importData(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.single.path == null) return;

      final file = File(result.files.single.path!);
      final jsonStr = await file.readAsString();

      final existingEvents = await ref.read(eventsProvider.future);
      final importService = ImportService();
      final importData =
          importService.parseAndValidate(jsonStr, existingEvents);

      if (!mounted) return;

      // Import non-duplicate categories
      final existingCats = await ref.read(categoriesProvider.future);
      final existingCatNames = existingCats.map((c) => c.name).toSet();
      var importedCats = 0;
      for (final cat in importData.categories) {
        if (!existingCatNames.contains(cat.name)) {
          await ref.read(categoriesProvider.notifier).addCategory(cat);
          importedCats++;
        }
      }

      // Import non-duplicate events
      for (final event in importData.events) {
        await ref.read(eventsProvider.notifier).addEvent(event);
      }

      // Handle duplicates: ask user
      var overwritten = 0;
      if (importData.duplicates.isNotEmpty && mounted) {
        overwritten = await _showDuplicateDialog(
              importData.duplicates,
            ) ??
            0;
      }

      if (!mounted) return;

      final total = importData.events.length + overwritten;
      final skipped = importData.duplicates.length - overwritten;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            '导入完成：$total 个事件导入'
            '${skipped > 0 ? '，$skipped 个跳过' : ''}'
            '${importedCats > 0 ? '，$importedCats 个分类' : ''}',
          ),
        ),
      );
    } on FormatException catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('导入失败：${e.message}')),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('导入失败：$e')),
        );
      }
    }
  }

  Future<int?> _showDuplicateDialog(
    List<DuplicateEvent> duplicates,
  ) async {
    return showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('发现重复事件'),
        content: Text('检测到 ${duplicates.length} 个重复事件（名称和日期相同），如何处理？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 0),
            child: const Text('全部跳过'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context, duplicates.length);
              for (final dup in duplicates) {
                final updated = dup.existing.copyWith(
                  note: () => dup.incoming.note,
                  isRepeating: dup.incoming.isRepeating,
                  updatedAt: DateTime.now(),
                );
                await ref.read(eventsProvider.notifier).updateEvent(updated);
              }
            },
            child: const Text('全部覆盖'),
          ),
        ],
      ),
    );
  }
}
