import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/category_provider.dart';
import '../providers/event_provider.dart';
import '../providers/theme_provider.dart';
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
            title: const Text('DaysMater'),
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

    final messenger = ScaffoldMessenger.of(context);

    try {
      final updateService = UpdateService();
      final info = await updateService.checkForUpdate();

      if (!mounted) return;

      if (info == null) {
        messenger.showSnackBar(
          const SnackBar(content: Text('检查更新失败，请检查网络连接')),
        );
        return;
      }

      if (info.hasUpdate) {
        _showUpdateDialog(context, info, updateService);
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text('已是最新版本 (${info.currentVersion})')),
        );
      }
    } catch (_) {
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('检查更新失败，请稍后重试')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _checkingUpdate = false);
      }
    }
  }

  void _showUpdateDialog(
    BuildContext context,
    AppUpdateInfo info,
    UpdateService updateService,
  ) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('发现新版本'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '${info.currentVersion} ',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
                Icon(
                  Icons.arrow_forward,
                  size: 16,
                  color: theme.colorScheme.outline,
                ),
                Text(
                  ' ${info.latestVersion}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (info.releaseNotes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                '更新内容',
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(height: 4),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200),
                child: SingleChildScrollView(
                  child: Text(
                    info.releaseNotes,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('稍后再说'),
          ),
          if (info.htmlUrl.isNotEmpty)
            FilledButton.tonal(
              onPressed: () {
                Navigator.pop(context);
                _openUrl(updateService.getMirrorDownloadUrl(info.htmlUrl));
              },
              child: const Text('镜像下载'),
            ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _openUrl(info.htmlUrl);
            },
            child: const Text('前往下载'),
          ),
        ],
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('无法打开链接')),
      );
    }
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
      final file = File('${dir.path}/daysmater_export.json');
      await file.writeAsString(jsonStr);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '已导出 ${events.length} 个倒数日到 ${file.path}',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出失败: $e')),
        );
      }
    }
  }

  Future<void> _importData(BuildContext context) async {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('导入功能即将上线')),
      );
    }
  }
}
