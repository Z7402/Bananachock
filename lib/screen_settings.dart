import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'provider_theme.dart';
import 'widget_theme_picker.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('设置'), centerTitle: true),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        _SettingsGroup(title: '个性化', items: [
          _SettingsItem(icon: Icons.color_lens, title: '主题模式', subtitle: _getThemeName(themeMode),
            onTap: () => _showThemePicker(context, ref)),
          _SettingsItem(icon: Icons.wallpaper, title: '更换背景壁纸', subtitle: '使用本地图片或纯色',
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('壁纸功能即将开放')))),
        ]),
        const SizedBox(height: 20),
        _SettingsGroup(title: '专注辅助', items: [
          _SettingsItem(icon: Icons.nightlight_round, title: '白噪音 / 提示音效', subtitle: '自定义专注背景音',
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('白噪音功能即将开放')))),
          _SettingsItem(icon: Icons.screen_lock_portrait, title: '息屏运行策略', subtitle: '后台持续计时，降低功耗',
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('息屏策略即将开放')))),
          _SwitchSettingsItem(icon: Icons.brightness_high, title: '保持屏幕常亮', subtitle: '计时期间防止熄屏',
            onToggle: (v) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('屏幕常亮已${v ? "开启" : "关闭"}')))),
        ]),
        const SizedBox(height: 20),
        _SettingsGroup(title: '数据', items: [
          _SettingsItem(icon: Icons.backup, title: '数据备份 / 导出', subtitle: '备份数据库或导出 CSV',
            onTap: () async {
              final prefs = await SharedPreferences.getInstance();
              final tasksJson = prefs.getString('bananachock_tasks') ?? '[]';
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('数据已准备导出（共 ${tasksJson.length} 字节）')));
            }),
          _SettingsItem(icon: Icons.restore, title: '从备份恢复', subtitle: '',
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('恢复功能即将开放')))),
        ]),
        const SizedBox(height: 20),
        _SettingsGroup(title: '关于', items: [
          _SettingsItem(icon: Icons.info_outline, title: 'Bananachock', subtitle: 'v1.0.0 | 极简时间管理', onTap: () {}),
        ]),
      ]),
    );
  }

  String _getThemeName(AppThemeMode mode) => switch (mode) { AppThemeMode.light => '浅色', AppThemeMode.dark => '深色', AppThemeMode.system => '跟随系统' };

  void _showThemePicker(BuildContext context, WidgetRef ref) {
    showDialog(context: context, builder: (_) => ThemePickerDialog(
      currentMode: ref.read(themeProvider),
      onSelected: (mode) => ref.read(themeProvider.notifier).setThemeMode(mode),
    ));
  }
}

class _SettingsGroup extends StatelessWidget {
  final String title;
  final List<Widget> items;
  const _SettingsGroup({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.only(left: 8, bottom: 8),
        child: Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.primary))),
      Card(elevation: 0, color: Theme.of(context).colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), child: Column(children: items)),
    ]);
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;
  const _SettingsItem({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title), subtitle: subtitle.isNotEmpty ? Text(subtitle) : null,
      trailing: const Icon(Icons.chevron_right_rounded), onTap: onTap,
    );
  }
}

class _SwitchSettingsItem extends StatefulWidget {
  final IconData icon;
  final String title, subtitle;
  final ValueChanged<bool> onToggle;
  const _SwitchSettingsItem({required this.icon, required this.title, required this.subtitle, required this.onToggle});
  @override
  State<_SwitchSettingsItem> createState() => _SwitchSettingsItemState();
}

class _SwitchSettingsItemState extends State<_SwitchSettingsItem> {
  bool _value = false;
  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      secondary: Icon(widget.icon, color: Theme.of(context).colorScheme.primary),
      title: Text(widget.title), subtitle: widget.subtitle.isNotEmpty ? Text(widget.subtitle) : null,
      value: _value, onChanged: (v) { setState(() => _value = v); widget.onToggle(v); },
    );
  }
}
