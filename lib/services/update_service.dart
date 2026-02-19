import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class AppUpdateInfo {
  final String latestVersion;
  final String currentVersion;
  final String releaseNotes;
  final String htmlUrl;
  final List<AppAsset> assets;
  final bool hasUpdate;

  const AppUpdateInfo({
    required this.latestVersion,
    required this.currentVersion,
    required this.releaseNotes,
    required this.htmlUrl,
    required this.assets,
    required this.hasUpdate,
  });
}

class AppAsset {
  final String name;
  final String downloadUrl;
  final int size;

  const AppAsset({
    required this.name,
    required this.downloadUrl,
    required this.size,
  });
}

enum _DownloadState { downloading, installing, failed }

class UpdateService {
  static const String _owner = 'linghualive';
  static const String _repo = 'linghuadays';
  static const String _skippedVersionKey = 'skipped_update_version';
  static const _channel = MethodChannel('com.daysmater.daysmater/app_update');

  /// GitHub API URLs with fallback mirrors for Chinese users.
  static const List<String> _apiUrls = [
    'https://gh-proxy.com/https://api.github.com/repos/$_owner/$_repo/releases/latest',
    'https://api.github.com/repos/$_owner/$_repo/releases/latest',
  ];

  // --- Skipped version persistence ---

  Future<String?> getSkippedVersion() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_skippedVersionKey);
  }

  Future<void> setSkippedVersion(String version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_skippedVersionKey, version);
  }

  Future<void> clearSkippedVersion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_skippedVersionKey);
  }

  // --- APK asset helper ---

  AppAsset? getApkAsset(AppUpdateInfo info) {
    for (final asset in info.assets) {
      if (asset.name.toLowerCase().endsWith('.apk')) {
        return asset;
      }
    }
    return null;
  }

  // --- Check for update ---

  /// Check for app updates by querying GitHub Releases.
  /// Tries multiple API endpoints to handle network issues in China.
  Future<AppUpdateInfo?> checkForUpdate() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;

    for (final url in _apiUrls) {
      try {
        final response = await http
            .get(
              Uri.parse(url),
              headers: {'Accept': 'application/vnd.github.v3+json'},
            )
            .timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          return _parseRelease(response.body, currentVersion);
        }
        // 404 means no releases exist — treat as "already latest"
        if (response.statusCode == 404) {
          return AppUpdateInfo(
            latestVersion: currentVersion,
            currentVersion: currentVersion,
            releaseNotes: '',
            htmlUrl: '',
            assets: const [],
            hasUpdate: false,
          );
        }
      } catch (_) {
        continue;
      }
    }

    return null;
  }

  AppUpdateInfo _parseRelease(String body, String currentVersion) {
    final json = jsonDecode(body) as Map<String, dynamic>;

    final tagName = json['tag_name'] as String? ?? '';
    final latestVersion =
        tagName.startsWith('v') ? tagName.substring(1) : tagName;
    final releaseNotes = json['body'] as String? ?? '';
    final htmlUrl = json['html_url'] as String? ?? '';

    final assetsJson = json['assets'] as List<dynamic>? ?? [];
    final assets = assetsJson.map((a) {
      final asset = a as Map<String, dynamic>;
      return AppAsset(
        name: asset['name'] as String? ?? '',
        downloadUrl: asset['browser_download_url'] as String? ?? '',
        size: asset['size'] as int? ?? 0,
      );
    }).toList();

    final hasUpdate = _isNewerVersion(latestVersion, currentVersion);

    return AppUpdateInfo(
      latestVersion: latestVersion,
      currentVersion: currentVersion,
      releaseNotes: releaseNotes,
      htmlUrl: htmlUrl,
      assets: assets,
      hasUpdate: hasUpdate,
    );
  }

  /// Compare semantic versions. Returns true if [latest] > [current].
  bool _isNewerVersion(String latest, String current) {
    final latestParts = _parseVersion(latest);
    final currentParts = _parseVersion(current);

    for (var i = 0; i < 3; i++) {
      if (latestParts[i] > currentParts[i]) return true;
      if (latestParts[i] < currentParts[i]) return false;
    }
    return false;
  }

  List<int> _parseVersion(String version) {
    final cleaned = version.replaceAll(RegExp(r'[^0-9.]'), '');
    final parts = cleaned.split('.');
    return List.generate(3, (i) {
      if (i < parts.length) {
        return int.tryParse(parts[i]) ?? 0;
      }
      return 0;
    });
  }

  /// Get a mirror download URL for Chinese users.
  /// Download mirror prefixes (fast CDN first, slower proxy second).
  static const List<String> _downloadMirrors = [
    'https://ghfast.top/',
    'https://gh-proxy.com/',
  ];

  String getMirrorDownloadUrl(String originalUrl) {
    return '${_downloadMirrors.first}$originalUrl';
  }

  List<String> _getDownloadUrls(String originalUrl) {
    return [
      for (final mirror in _downloadMirrors) '$mirror$originalUrl',
      originalUrl,
    ];
  }

  // --- Auto check (startup) ---

  /// Auto-check: show dialog only if update available and not skipped.
  Future<void> checkAndNotify(BuildContext context) async {
    try {
      final info = await checkForUpdate();
      if (info == null || !info.hasUpdate) return;
      if (!context.mounted) return;

      final skipped = await getSkippedVersion();
      if (skipped == info.latestVersion) return;

      if (!context.mounted) return;
      _showUpdateDialog(context, info);
    } catch (_) {
      // Silent failure for auto-check
    }
  }

  // --- Manual check (settings) ---

  /// Manual check: always show result via SnackBar.
  Future<void> manualCheck(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      final info = await checkForUpdate();

      if (!context.mounted) return;

      if (info == null) {
        messenger.showSnackBar(
          const SnackBar(content: Text('检查更新失败，请检查网络连接')),
        );
        return;
      }

      if (info.hasUpdate) {
        _showUpdateDialog(context, info);
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text('已是最新版本 (${info.currentVersion})')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('检查更新失败，请稍后重试')),
        );
      }
    }
  }

  // --- Update dialog ---

  void _showUpdateDialog(BuildContext context, AppUpdateInfo info) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
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
                constraints: const BoxConstraints(maxHeight: 300),
                child: SingleChildScrollView(
                  child: MarkdownBody(
                    data: info.releaseNotes,
                    shrinkWrap: true,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              setSkippedVersion(info.latestVersion);
            },
            child: const Text('跳过此版本'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('稍后提醒'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _handleUpdate(context, info);
            },
            child: const Text('立即更新'),
          ),
        ],
      ),
    );
  }

  // --- Handle update action ---

  void _handleUpdate(BuildContext context, AppUpdateInfo info) {
    if (Platform.isAndroid) {
      final apk = getApkAsset(info);
      if (apk != null) {
        _downloadAndInstall(context, apk);
        return;
      }
    }
    // Fallback: open browser
    _openUrl(info.htmlUrl);
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // --- APK download & install (Android only) ---

  void _downloadAndInstall(BuildContext context, AppAsset apk) {
    final downloadProgress = ValueNotifier<double>(0.0);
    final downloadState = ValueNotifier<_DownloadState>(_DownloadState.downloading);
    CancelToken? cancelToken = CancelToken();

    final urls = _getDownloadUrls(apk.downloadUrl);

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      builder: (sheetContext) => _DownloadProgressSheet(
        downloadProgress: downloadProgress,
        downloadState: downloadState,
        onCancel: () {
          cancelToken?.cancel();
          Navigator.pop(sheetContext);
        },
        onRetry: () {
          downloadState.value = _DownloadState.downloading;
          downloadProgress.value = 0.0;
          cancelToken = CancelToken();
          _startDownload(
            urls: urls,
            progress: downloadProgress,
            state: downloadState,
            cancelToken: cancelToken!,
          );
        },
      ),
    );

    _startDownload(
      urls: urls,
      progress: downloadProgress,
      state: downloadState,
      cancelToken: cancelToken!,
    );
  }

  Future<void> _startDownload({
    required List<String> urls,
    required ValueNotifier<double> progress,
    required ValueNotifier<_DownloadState> state,
    required CancelToken cancelToken,
  }) async {
    try {
      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/daysmater_update.apk';
      final dio = Dio();

      // Try each mirror URL in order
      for (var i = 0; i < urls.length; i++) {
        try {
          progress.value = 0.0;
          await dio.download(
            urls[i],
            filePath,
            cancelToken: cancelToken,
            onReceiveProgress: (received, total) {
              if (total > 0) {
                progress.value = received / total;
              }
            },
          );
          break; // Download succeeded
        } catch (e) {
          if (cancelToken.isCancelled) return;
          if (i == urls.length - 1) rethrow; // All mirrors failed
        }
      }

      if (cancelToken.isCancelled) return;

      state.value = _DownloadState.installing;
      await _channel.invokeMethod('installApk', {'path': filePath});
    } catch (e) {
      if (!cancelToken.isCancelled) {
        state.value = _DownloadState.failed;
      }
    }
  }
}

// --- Download progress bottom sheet widget ---

class _DownloadProgressSheet extends StatelessWidget {
  final ValueNotifier<double> downloadProgress;
  final ValueNotifier<_DownloadState> downloadState;
  final VoidCallback onCancel;
  final VoidCallback onRetry;

  const _DownloadProgressSheet({
    required this.downloadProgress,
    required this.downloadState,
    required this.onCancel,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ValueListenableBuilder<_DownloadState>(
          valueListenable: downloadState,
          builder: (context, state, _) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _stateTitle(state),
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                if (state == _DownloadState.downloading)
                  ValueListenableBuilder<double>(
                    valueListenable: downloadProgress,
                    builder: (context, progress, _) {
                      return Column(
                        children: [
                          LinearProgressIndicator(value: progress),
                          const SizedBox(height: 8),
                          Text(
                            '${(progress * 100).toInt()}%',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      );
                    },
                  ),
                if (state == _DownloadState.installing)
                  const LinearProgressIndicator(),
                if (state == _DownloadState.failed) ...[
                  Text(
                    '下载失败，请检查网络后重试',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (state == _DownloadState.failed)
                      FilledButton.tonal(
                        onPressed: onRetry,
                        child: const Text('重试'),
                      ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: onCancel,
                      child: Text(
                        state == _DownloadState.failed ? '关闭' : '取消',
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _stateTitle(_DownloadState state) {
    switch (state) {
      case _DownloadState.downloading:
        return '正在下载更新...';
      case _DownloadState.installing:
        return '正在准备安装...';
      case _DownloadState.failed:
        return '下载失败';
    }
  }
}
