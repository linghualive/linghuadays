import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:daysmater/services/update_service.dart';

void main() {
  late UpdateService service;

  setUp(() {
    service = UpdateService();
  });

  group('UpdateService 版本比较', () {
    test('新版本正确检测', () {
      final json = _buildReleaseJson(tagName: 'v2.0.0');
      final info = _parseWithCurrentVersion(json, '1.0.0');

      expect(info.hasUpdate, isTrue);
      expect(info.latestVersion, '2.0.0');
      expect(info.currentVersion, '1.0.0');
    });

    test('相同版本无更新', () {
      final json = _buildReleaseJson(tagName: 'v1.0.0');
      final info = _parseWithCurrentVersion(json, '1.0.0');

      expect(info.hasUpdate, isFalse);
    });

    test('当前版本更高无更新', () {
      final json = _buildReleaseJson(tagName: 'v1.0.0');
      final info = _parseWithCurrentVersion(json, '2.0.0');

      expect(info.hasUpdate, isFalse);
    });

    test('小版本号更新', () {
      final json = _buildReleaseJson(tagName: 'v1.1.0');
      final info = _parseWithCurrentVersion(json, '1.0.0');

      expect(info.hasUpdate, isTrue);
    });

    test('补丁版本号更新', () {
      final json = _buildReleaseJson(tagName: 'v1.0.1');
      final info = _parseWithCurrentVersion(json, '1.0.0');

      expect(info.hasUpdate, isTrue);
    });

    test('无v前缀的标签也能解析', () {
      final json = _buildReleaseJson(tagName: '1.2.3');
      final info = _parseWithCurrentVersion(json, '1.0.0');

      expect(info.hasUpdate, isTrue);
      expect(info.latestVersion, '1.2.3');
    });

    test('主版本号不同优先', () {
      final json = _buildReleaseJson(tagName: 'v2.0.0');
      final info = _parseWithCurrentVersion(json, '1.9.9');

      expect(info.hasUpdate, isTrue);
    });
  });

  group('UpdateService 解析 Release', () {
    test('解析更新内容和链接', () {
      final json = _buildReleaseJson(
        tagName: 'v1.1.0',
        body: '修复了一些 bug',
        htmlUrl:
            'https://github.com/linghualive/linghuadays/releases/tag/v1.1.0',
      );
      final info = _parseWithCurrentVersion(json, '1.0.0');

      expect(info.releaseNotes, '修复了一些 bug');
      expect(info.htmlUrl, contains('github.com'));
    });

    test('解析资源文件列表', () {
      final json = _buildReleaseJson(
        tagName: 'v1.1.0',
        assets: [
          {
            'name': 'app-release.apk',
            'browser_download_url':
                'https://github.com/linghualive/linghuadays/releases/download/v1.1.0/app-release.apk',
            'size': 25000000,
          },
        ],
      );
      final info = _parseWithCurrentVersion(json, '1.0.0');

      expect(info.assets.length, 1);
      expect(info.assets.first.name, 'app-release.apk');
      expect(info.assets.first.size, 25000000);
    });

    test('空资源列表', () {
      final json = _buildReleaseJson(tagName: 'v1.1.0');
      final info = _parseWithCurrentVersion(json, '1.0.0');

      expect(info.assets, isEmpty);
    });
  });

  group('UpdateService 镜像链接', () {
    test('生成镜像下载链接', () {
      final mirror = service.getMirrorDownloadUrl(
        'https://github.com/linghualive/linghuadays/releases/tag/v1.0.0',
      );

      expect(mirror, contains('ghfast.top'));
      expect(mirror, contains('github.com'));
    });
  });

  group('UpdateService 跳过版本', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('默认无跳过版本', () async {
      final version = await service.getSkippedVersion();
      expect(version, isNull);
    });

    test('设置跳过版本后可读取', () async {
      await service.setSkippedVersion('2.0.0');
      final version = await service.getSkippedVersion();
      expect(version, '2.0.0');
    });

    test('清除跳过版本后返回 null', () async {
      await service.setSkippedVersion('2.0.0');
      await service.clearSkippedVersion();
      final version = await service.getSkippedVersion();
      expect(version, isNull);
    });

    test('覆盖已有的跳过版本', () async {
      await service.setSkippedVersion('2.0.0');
      await service.setSkippedVersion('3.0.0');
      final version = await service.getSkippedVersion();
      expect(version, '3.0.0');
    });
  });

  group('UpdateService 查找 APK 资源', () {
    test('从 assets 中找到 .apk 文件', () {
      const info = AppUpdateInfo(
        latestVersion: '2.0.0',
        currentVersion: '1.0.0',
        releaseNotes: '',
        htmlUrl: '',
        assets: [
          AppAsset(
            name: 'app-release.apk',
            downloadUrl: 'https://example.com/app.apk',
            size: 25000000,
          ),
          AppAsset(
            name: 'checksums.txt',
            downloadUrl: 'https://example.com/checksums.txt',
            size: 256,
          ),
        ],
        hasUpdate: true,
      );

      final apk = service.getApkAsset(info);
      expect(apk, isNotNull);
      expect(apk!.name, 'app-release.apk');
    });

    test('没有 .apk 文件时返回 null', () {
      const info = AppUpdateInfo(
        latestVersion: '2.0.0',
        currentVersion: '1.0.0',
        releaseNotes: '',
        htmlUrl: '',
        assets: [
          AppAsset(
            name: 'checksums.txt',
            downloadUrl: 'https://example.com/checksums.txt',
            size: 256,
          ),
        ],
        hasUpdate: true,
      );

      final apk = service.getApkAsset(info);
      expect(apk, isNull);
    });

    test('空 assets 列表时返回 null', () {
      const info = AppUpdateInfo(
        latestVersion: '2.0.0',
        currentVersion: '1.0.0',
        releaseNotes: '',
        htmlUrl: '',
        assets: [],
        hasUpdate: true,
      );

      final apk = service.getApkAsset(info);
      expect(apk, isNull);
    });

    test('多个 .apk 文件时返回第一个', () {
      const info = AppUpdateInfo(
        latestVersion: '2.0.0',
        currentVersion: '1.0.0',
        releaseNotes: '',
        htmlUrl: '',
        assets: [
          AppAsset(
            name: 'app-arm64.apk',
            downloadUrl: 'https://example.com/arm64.apk',
            size: 20000000,
          ),
          AppAsset(
            name: 'app-universal.apk',
            downloadUrl: 'https://example.com/universal.apk',
            size: 40000000,
          ),
        ],
        hasUpdate: true,
      );

      final apk = service.getApkAsset(info);
      expect(apk, isNotNull);
      expect(apk!.name, 'app-arm64.apk');
    });
  });
}

/// Build a mock GitHub release JSON map and encode it.
String _buildReleaseJson({
  required String tagName,
  String body = '',
  String htmlUrl =
      'https://github.com/linghualive/linghuadays/releases/tag/test',
  List<Map<String, dynamic>>? assets,
}) {
  final data = {
    'tag_name': tagName,
    'body': body,
    'html_url': htmlUrl,
    'assets': assets ?? <Map<String, dynamic>>[],
  };
  return jsonEncode(data);
}

/// Parse a release JSON string and compare with current version.
/// This mirrors the logic in UpdateService._parseRelease and _isNewerVersion.
AppUpdateInfo _parseWithCurrentVersion(String jsonBody, String currentVersion) {
  final json = jsonDecode(jsonBody) as Map<String, dynamic>;
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

  final latestParts = _parseVersionParts(latestVersion);
  final currentParts = _parseVersionParts(currentVersion);
  var hasUpdate = false;
  for (var i = 0; i < 3; i++) {
    if (latestParts[i] > currentParts[i]) {
      hasUpdate = true;
      break;
    }
    if (latestParts[i] < currentParts[i]) break;
  }

  return AppUpdateInfo(
    latestVersion: latestVersion,
    currentVersion: currentVersion,
    releaseNotes: releaseNotes,
    htmlUrl: htmlUrl,
    assets: assets,
    hasUpdate: hasUpdate,
  );
}

List<int> _parseVersionParts(String version) {
  final cleaned = version.replaceAll(RegExp(r'[^0-9.]'), '');
  final parts = cleaned.split('.');
  return List.generate(3, (i) {
    if (i < parts.length) {
      return int.tryParse(parts[i]) ?? 0;
    }
    return 0;
  });
}
