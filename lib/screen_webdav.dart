import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'provider_task.dart';
import 'provider_theme.dart';
import 'provider_wallpaper.dart';
import 'provider_webdav.dart';

class WebDavScreen extends ConsumerStatefulWidget {
  const WebDavScreen({super.key});

  @override
  ConsumerState<WebDavScreen> createState() => _WebDavScreenState();
}

class _WebDavScreenState extends ConsumerState<WebDavScreen> {
  final _url = TextEditingController();
  final _user = TextEditingController();
  final _password = TextEditingController();
  final _path = TextEditingController();
  bool _filled = false;
  bool _showPassword = false;

  @override
  void dispose() {
    _url.dispose();
    _user.dispose();
    _password.dispose();
    _path.dispose();
    super.dispose();
  }

  WebDavConfig get _draft => WebDavConfig(
        serverUrl: _url.text.trim(),
        username: _user.text.trim(),
        password: _password.text,
        remotePath: _path.text.trim(),
      );

  void _fill(WebDavState state) {
    if (_filled || !state.configLoaded) return;
    _filled = true;
    _url.text = state.config.serverUrl;
    _user.text = state.config.username;
    _password.text = state.config.password;
    _path.text = state.config.remotePath;
  }

  Future<void> _save() => ref.read(webDavProvider.notifier).saveConfig(_draft);

  Future<void> _test() async {
    await _save();
    await ref.read(webDavProvider.notifier).testConnection(_draft);
  }

  Future<void> _restore() async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('从云端恢复？'),
            content: const Text('云端备份将覆盖本机现有配置与记录。建议先备份当前数据。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('确认恢复'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;
    final ok = await ref.read(webDavProvider.notifier).restoreFromCloud();
    if (ok) {
      ref.invalidate(taskProvider);
      ref.invalidate(themeProvider);
      ref.invalidate(wallpaperProvider);
    }
  }

  String _time(DateTime? value) {
    if (value == null) return '暂无';
    final local = value.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} '
        '${two(local.hour)}:${two(local.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(webDavProvider);
    _fill(state);
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('WebDAV 云备份')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _url,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(
                      labelText: '服务器地址',
                      hintText:
                          'https://dav.example.com/remote.php/dav/files/user/',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _user,
                    decoration: const InputDecoration(labelText: '用户名（可选）'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _password,
                    obscureText: !_showPassword,
                    decoration: InputDecoration(
                      labelText: '密码 / 应用密码（可选）',
                      suffixIcon: IconButton(
                        onPressed: () =>
                            setState(() => _showPassword = !_showPassword),
                        icon: Icon(_showPassword
                            ? Icons.visibility_off
                            : Icons.visibility),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _path,
                    decoration: const InputDecoration(
                      labelText: '远程备份路径',
                      hintText: 'Bananachock/bananachock_backup.json',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: state.loading ? null : _test,
                          icon: const Icon(Icons.wifi_tethering),
                          label: const Text('保存并测试'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: state.loading ? null : _save,
                          icon: const Icon(Icons.save_outlined),
                          label: const Text('保存配置'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (state.message != null) ...[
            const SizedBox(height: 12),
            Material(
              color: state.isError ? cs.errorContainer : cs.primaryContainer,
              borderRadius: BorderRadius.circular(14),
              child: ListTile(
                leading: state.loading
                    ? const CircularProgressIndicator()
                    : Icon(state.isError
                        ? Icons.error_outline
                        : Icons.check_circle_outline),
                title: Text(state.message!),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('数据同步', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text('上次备份：${_time(state.lastBackupAt)}\n'
                      '上次恢复：${_time(state.lastRestoreAt)}'),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: state.loading || !state.config.isValid
                              ? null
                              : () => ref
                                  .read(webDavProvider.notifier)
                                  .backupToCloud(),
                          icon: const Icon(Icons.cloud_upload),
                          label: const Text('备份到云端'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: state.loading || !state.config.isValid
                              ? null
                              : _restore,
                          icon: const Icon(Icons.cloud_download),
                          label: const Text('从云端恢复'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '备份覆盖任务记录、主题、壁纸及应用使用的其他本地配置；WebDAV 凭据存储于系统加密存储中，不写入备份文件。',
            style: TextStyle(color: cs.onSurfaceVariant, height: 1.5),
          ),
        ],
      ),
    );
  }
}
