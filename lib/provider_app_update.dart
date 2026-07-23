import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AppUpdateState {
  final bool isChecking;
  final String currentVersion;
  final String? latestVersion;
  final String? downloadUrl;
  final String? releaseUrl;
  final String? releaseNotes;
  final DateTime? publishedAt;
  final bool updateAvailable;
  final String? error;

  const AppUpdateState({
    this.isChecking = false,
    this.currentVersion = '1.1.7a',
    this.latestVersion,
    this.downloadUrl,
    this.releaseUrl,
    this.releaseNotes,
    this.publishedAt,
    this.updateAvailable = false,
    this.error,
  });
}

class AppUpdateNotifier extends StateNotifier<AppUpdateState> {
  AppUpdateNotifier() : super(const AppUpdateState());

  static const _latestReleaseApi =
      'https://api.github.com/repos/Z7402/Bananachock/releases/latest';

  Future<AppUpdateState> checkForUpdate() async {
    state = AppUpdateState(
      isChecking: true,
      currentVersion: state.currentVersion,
    );
    try {
      final package = await PackageInfo.fromPlatform();
      final current = package.version;
      final response = await http
          .get(
            Uri.parse(_latestReleaseApi),
            headers: const {
              'Accept': 'application/vnd.github+json',
              'X-GitHub-Api-Version': '2022-11-28',
            },
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        throw Exception(_httpMessage(response.statusCode));
      }

      final data =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final rawTag = data['tag_name'] as String? ?? '';
      final latest = _semanticVersion(rawTag);
      if (latest == null) {
        throw const FormatException('最新 Release 标签不是语义化版本（应为 v1.2.3）');
      }

      String? apkUrl;
      for (final item in (data['assets'] as List<dynamic>? ?? const [])) {
        final asset = item as Map<String, dynamic>;
        final name = (asset['name'] as String? ?? '').toLowerCase();
        if (name.endsWith('.apk') && name.contains('arm64')) {
          apkUrl = asset['browser_download_url'] as String?;
          break;
        }
      }
      apkUrl ??= (data['assets'] as List<dynamic>? ?? const [])
          .cast<Map<String, dynamic>>()
          .where(
            (asset) =>
                (asset['name'] as String? ?? '').toLowerCase().endsWith('.apk'),
          )
          .map((asset) => asset['browser_download_url'] as String?)
          .whereType<String>()
          .firstOrNull;

      state = AppUpdateState(
        currentVersion: current,
        latestVersion: latest,
        downloadUrl: apkUrl,
        releaseUrl: data['html_url'] as String?,
        releaseNotes: data['body'] as String?,
        publishedAt: DateTime.tryParse(data['published_at'] as String? ?? ''),
        updateAvailable: _isNewer(latest, current),
      );
    } catch (error) {
      state = AppUpdateState(
        currentVersion: state.currentVersion,
        error: error.toString().replaceFirst('Exception: ', ''),
      );
    }
    return state;
  }

  Future<bool> openDownload() => _open(state.downloadUrl ?? state.releaseUrl);
  Future<bool> openReleasePage() => _open(state.releaseUrl);

  Future<bool> _open(String? value) async {
    final uri = value == null ? null : Uri.tryParse(value);
    if (uri == null) return false;
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  String? _semanticVersion(String input) {
    final m = RegExp(r'^v?(\d+\.\d+\.\d+)').firstMatch(input.trim());
    return m?.group(1);
  }

  bool _isNewer(String latest, String current) {
    final a = latest.split('.').map(int.parse).toList();
    final normalizedCurrent =
        _semanticVersion(current) ?? current.split('+').first;
    final b = normalizedCurrent
        .split('.')
        .map((e) => int.tryParse(e) ?? 0)
        .toList();
    for (var i = 0; i < 3; i++) {
      if (a[i] != b[i]) return a[i] > b[i];
    }
    return false;
  }

  String _httpMessage(int code) => switch (code) {
    403 => 'GitHub API 请求受限，请稍后重试',
    404 => '未找到正式 Release',
    _ => '检查更新失败（HTTP $code）',
  };
}

final appUpdateProvider =
    StateNotifierProvider<AppUpdateNotifier, AppUpdateState>((ref) {
      return AppUpdateNotifier();
    });
