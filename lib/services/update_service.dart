import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

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

class UpdateService {
  static const String _owner = 'linghualive';
  static const String _repo = 'linghuadays';

  /// GitHub API URLs with fallback mirrors for Chinese users.
  static const List<String> _apiUrls = [
    'https://api.github.com/repos/$_owner/$_repo/releases/latest',
    'https://ghfast.top/https://api.github.com/repos/$_owner/$_repo/releases/latest',
  ];

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
      } catch (_) {
        // Try next URL
        continue;
      }
    }

    return null;
  }

  AppUpdateInfo _parseRelease(String body, String currentVersion) {
    final json = jsonDecode(body) as Map<String, dynamic>;

    final tagName = json['tag_name'] as String? ?? '';
    final latestVersion = tagName.startsWith('v') ? tagName.substring(1) : tagName;
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
  String getMirrorDownloadUrl(String originalUrl) {
    return 'https://ghfast.top/$originalUrl';
  }
}
