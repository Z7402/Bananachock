import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class WebDavConfig {
  final String serverUrl;
  final String username;
  final String password;
  final String remotePath;

  const WebDavConfig({
    this.serverUrl = '',
    this.username = '',
    this.password = '',
    this.remotePath = 'Bananachock/bananachock_backup.json',
  });

  bool get isValid =>
      Uri.tryParse(serverUrl)?.hasScheme == true &&
      remotePath.trim().isNotEmpty;
}

class WebDavState {
  final WebDavConfig config;
  final bool loading;
  final bool configLoaded;
  final String? message;
  final bool isError;
  final DateTime? lastBackupAt;
  final DateTime? lastRestoreAt;

  const WebDavState({
    this.config = const WebDavConfig(),
    this.loading = false,
    this.configLoaded = false,
    this.message,
    this.isError = false,
    this.lastBackupAt,
    this.lastRestoreAt,
  });

  WebDavState copyWith({
    WebDavConfig? config,
    bool? loading,
    bool? configLoaded,
    String? message,
    bool clearMessage = false,
    bool? isError,
    DateTime? lastBackupAt,
    DateTime? lastRestoreAt,
  }) =>
      WebDavState(
        config: config ?? this.config,
        loading: loading ?? this.loading,
        configLoaded: configLoaded ?? this.configLoaded,
        message: clearMessage ? null : message ?? this.message,
        isError: isError ?? this.isError,
        lastBackupAt: lastBackupAt ?? this.lastBackupAt,
        lastRestoreAt: lastRestoreAt ?? this.lastRestoreAt,
      );
}

class WebDavNotifier extends StateNotifier<WebDavState> {
  WebDavNotifier() : super(const WebDavState()) {
    _loadConfig();
  }

  static const _secure = FlutterSecureStorage();
  static const _urlKey = 'webdav_url';
  static const _userKey = 'webdav_username';
  static const _passwordKey = 'webdav_password';
  static const _pathKey = 'webdav_remote_path';
  static const _lastBackupKey = 'webdav_last_backup';
  static const _lastRestoreKey = 'webdav_last_restore';

  Future<void> _loadConfig() async {
    final values = await _secure.readAll();
    final prefs = await SharedPreferences.getInstance();
    state = state.copyWith(
      configLoaded: true,
      config: WebDavConfig(
        serverUrl: values[_urlKey] ?? '',
        username: values[_userKey] ?? '',
        password: values[_passwordKey] ?? '',
        remotePath: values[_pathKey] ?? 'Bananachock/bananachock_backup.json',
      ),
      lastBackupAt: DateTime.tryParse(prefs.getString(_lastBackupKey) ?? ''),
      lastRestoreAt: DateTime.tryParse(prefs.getString(_lastRestoreKey) ?? ''),
    );
  }

  Future<void> saveConfig(WebDavConfig config) async {
    await Future.wait([
      _secure.write(key: _urlKey, value: config.serverUrl.trim()),
      _secure.write(key: _userKey, value: config.username.trim()),
      _secure.write(key: _passwordKey, value: config.password),
      _secure.write(key: _pathKey, value: config.remotePath.trim()),
    ]);
    state = state.copyWith(
      config: config,
      configLoaded: true,
      message: '配置已安全保存',
      isError: false,
    );
  }

  Future<bool> testConnection(WebDavConfig config) async {
    if (!config.isValid) return _fail('请填写有效的 HTTPS/HTTP 地址和远程路径');
    state = state.copyWith(loading: true, clearMessage: true);
    try {
      final response = http.Request('PROPFIND', _directoryUri(config));
      response.headers.addAll(_headers(config, json: false));
      response.headers['Depth'] = '0';
      final result = await response.send().timeout(const Duration(seconds: 15));
      if ({200, 207, 301, 302, 404}.contains(result.statusCode)) {
        state = state.copyWith(
          loading: false,
          message:
              result.statusCode == 404 ? '服务器连接成功；备份目录将在首次备份时创建' : '连接测试成功',
          isError: false,
        );
        return true;
      }
      return _fail(_statusMessage(result.statusCode));
    } catch (error) {
      return _fail('连接失败：${_shortError(error)}');
    }
  }

  Future<bool> backupToCloud() async {
    final config = state.config;
    if (!config.isValid) return _fail('请先保存有效的 WebDAV 配置');
    state =
        state.copyWith(loading: true, message: '正在整理并上传数据…', isError: false);
    try {
      await _ensureDirectories(config);
      final prefs = await SharedPreferences.getInstance();
      final values = <String, Object?>{};
      for (final key in prefs.getKeys()) {
        if (!key.startsWith('webdav_')) values[key] = prefs.get(key);
      }
      final payload = utf8.encode(jsonEncode({
        'format': 'bananachock-backup',
        'schemaVersion': 1,
        'appVersion': '1.1.1',
        'createdAt': DateTime.now().toUtc().toIso8601String(),
        'preferences': values,
      }));
      final response = await http
          .put(
            _fileUri(config),
            headers: _headers(config),
            body: payload,
          )
          .timeout(const Duration(seconds: 30));
      if (![200, 201, 204].contains(response.statusCode)) {
        return _fail(_statusMessage(response.statusCode));
      }
      final now = DateTime.now();
      await prefs.setString(_lastBackupKey, now.toIso8601String());
      state = state.copyWith(
        loading: false,
        message: '云端备份成功',
        isError: false,
        lastBackupAt: now,
      );
      return true;
    } catch (error) {
      return _fail('备份失败：${_shortError(error)}');
    }
  }

  Future<bool> restoreFromCloud() async {
    final config = state.config;
    if (!config.isValid) return _fail('请先保存有效的 WebDAV 配置');
    state =
        state.copyWith(loading: true, message: '正在下载并校验备份…', isError: false);
    try {
      final response = await http
          .get(
            _fileUri(config),
            headers: _headers(config, json: false),
          )
          .timeout(const Duration(seconds: 30));
      if (response.statusCode == 404) return _fail('云端备份文件不存在');
      if (response.statusCode != 200)
        return _fail(_statusMessage(response.statusCode));
      final root = jsonDecode(utf8.decode(response.bodyBytes));
      if (root is! Map<String, dynamic> ||
          root['format'] != 'bananachock-backup' ||
          root['preferences'] is! Map<String, dynamic>) {
        return _fail('备份文件格式无效或已损坏');
      }
      final prefs = await SharedPreferences.getInstance();
      final values = root['preferences'] as Map<String, dynamic>;
      for (final entry in values.entries) {
        await _writePreference(prefs, entry.key, entry.value);
      }
      final now = DateTime.now();
      await prefs.setString(_lastRestoreKey, now.toIso8601String());
      state = state.copyWith(
        loading: false,
        message: '恢复成功，应用数据已重新载入',
        isError: false,
        lastRestoreAt: now,
      );
      return true;
    } on FormatException {
      return _fail('备份文件不是有效 JSON，可能已损坏');
    } catch (error) {
      return _fail('恢复失败：${_shortError(error)}');
    }
  }

  Future<void> _ensureDirectories(WebDavConfig config) async {
    final segments =
        config.remotePath.split('/').where((e) => e.isNotEmpty).toList();
    if (segments.length < 2) return;
    var uri = _baseUri(config);
    for (final segment in segments.take(segments.length - 1)) {
      uri = uri.replace(pathSegments: [
        ...uri.pathSegments.where((e) => e.isNotEmpty),
        segment
      ]);
      final request = http.Request('MKCOL', uri)
        ..headers.addAll(_headers(config, json: false));
      final response =
          await request.send().timeout(const Duration(seconds: 15));
      if (![201, 405].contains(response.statusCode)) {
        throw Exception(_statusMessage(response.statusCode));
      }
    }
  }

  Uri _baseUri(WebDavConfig config) {
    final raw = config.serverUrl.trim();
    return Uri.parse(raw.endsWith('/') ? raw : '$raw/');
  }

  Uri _fileUri(WebDavConfig config) => _baseUri(config).replace(
        pathSegments: [
          ..._baseUri(config).pathSegments.where((e) => e.isNotEmpty),
          ...config.remotePath.split('/').where((e) => e.isNotEmpty),
        ],
      );

  Uri _directoryUri(WebDavConfig config) {
    final parts =
        config.remotePath.split('/').where((e) => e.isNotEmpty).toList();
    if (parts.length <= 1) return _baseUri(config);
    return _baseUri(config).replace(pathSegments: [
      ..._baseUri(config).pathSegments.where((e) => e.isNotEmpty),
      ...parts.take(parts.length - 1),
    ]);
  }

  Map<String, String> _headers(WebDavConfig config, {bool json = true}) => {
        if (config.username.isNotEmpty || config.password.isNotEmpty)
          'Authorization':
              'Basic ${base64Encode(utf8.encode('${config.username}:${config.password}'))}',
        if (json) 'Content-Type': 'application/json; charset=utf-8',
      };

  Future<void> _writePreference(
      SharedPreferences prefs, String key, dynamic value) async {
    if (value == null) return;
    if (value is bool) await prefs.setBool(key, value);
    if (value is int) await prefs.setInt(key, value);
    if (value is double) await prefs.setDouble(key, value);
    if (value is String) await prefs.setString(key, value);
    if (value is List && value.every((e) => e is String)) {
      await prefs.setStringList(key, value.cast<String>());
    }
  }

  bool _fail(String message) {
    state = state.copyWith(loading: false, message: message, isError: true);
    return false;
  }

  String _statusMessage(int code) => switch (code) {
        401 || 403 => '认证失败，请检查用户名和密码',
        404 => '服务器地址或远程路径不存在',
        405 => '服务器不允许此 WebDAV 操作',
        507 => '云端存储空间不足',
        _ => 'WebDAV 请求失败（HTTP $code）',
      };

  String _shortError(Object error) {
    final text = error.toString().replaceFirst('Exception: ', '');
    return text.length > 120 ? '${text.substring(0, 120)}…' : text;
  }
}

final webDavProvider =
    StateNotifierProvider<WebDavNotifier, WebDavState>((ref) {
  return WebDavNotifier();
});
