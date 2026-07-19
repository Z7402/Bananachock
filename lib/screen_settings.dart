import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:shared_preferences/shared_preferences.dart";
import "provider_theme.dart";
import "provider_wallpaper.dart";
import "widget_theme_picker.dart";

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final wallpaper = ref.watch(wallpaperProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("设置"), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Section(title: "个性化", items: [
            _Item(
              icon: Icons.color_lens,
              title: "主题模式",
              subtitle: _themeName(themeMode),
              onTap: () => _showThemePicker(context, ref),
            ),
            _Item(
              icon: Icons.wallpaper,
              title: "更换背景壁纸",
              subtitle: wallpaper.hasWallpaper ? "已设置壁纸，点击更换" : "使用本地图片自动适配色调",
              onTap: () => ref.read(wallpaperProvider.notifier).pickWallpaper(context),
            ),
            if (wallpaper.hasWallpaper)
              _Item(
                icon: Icons.delete_outline,
                title: "移除壁纸",
                subtitle: "恢复默认主题色调",
                onTap: () {
                  ref.read(wallpaperProvider.notifier).removeWallpaper();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("壁纸已移除")),
                  );
                },
              ),
          ]),
          const SizedBox(height: 20),
          _Section(title: "专注辅助", items: [
            _Item(
              icon: Icons.nightlight_round,
              title: "白噪音 / 提示音效",
              subtitle: "自定义专注背景音",
              onTap: () => _showComingSoon(context, "白噪音功能即将开放"),
            ),
            _Item(
              icon: Icons.screen_lock_portrait,
              title: "息屏运行策略",
              subtitle: "后台持续计时，降低功耗",
              onTap: () => _showComingSoon(context, "息屏策略即将开放"),
            ),
            _SwitchItem(
              icon: Icons.brightness_high,
              title: "保持屏幕常亮",
              subtitle: "计时期间防止熄屏",
              onToggle: (v) => _showComingSoon(context, "屏幕常亮已" + (v ? "开启" : "关闭")),
            ),
          ]),
          const SizedBox(height: 20),
          _Section(title: "数据", items: [
            _Item(
              icon: Icons.backup,
              title: "数据备份 / 导出",
              subtitle: "备份数据库或导出 CSV",
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                final tasksJson = prefs.getString("bananachock_tasks") ?? "";
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("数据已准备导出（共 " + tasksJson.length.toString() + " 字节）")),
                );
              },
            ),
            _Item(
              icon: Icons.restore,
              title: "从备份恢复",
              subtitle: "",
              onTap: () => _showComingSoon(context, "恢复功能即将开放"),
            ),
          ]),
          const SizedBox(height: 20),
          _Section(title: "关于", items: [
            _Item(
              icon: Icons.info_outline,
              title: "Bananachock",
              subtitle: "v1.0.1 | 极简时间管理",
              onTap: () {},
            ),
          ]),
        ],
      ),
    );
  }

  String _themeName(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light: return "浅色";
      case AppThemeMode.dark: return "深色";
      case AppThemeMode.system: return "跟随系统";
    }
  }

  void _showThemePicker(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => ThemePickerDialog(
        currentMode: ref.read(themeProvider),
        onSelected: (mode) => ref.read(themeProvider.notifier).setThemeMode(mode),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> items;
  const _Section({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.primary, letterSpacing: 1)),
        ),
        Card(
          elevation: 0,
          color: cs.surfaceContainerLow,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(children: items),
        ),
      ],
    );
  }
}

class _Item extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _Item({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon, color: cs.primary),
      title: Text(title),
      subtitle: subtitle.isNotEmpty ? Text(subtitle, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)) : null,
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }
}

class _SwitchItem extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final ValueChanged<bool> onToggle;
  const _SwitchItem({required this.icon, required this.title, required this.subtitle, required this.onToggle});

  @override
  State<_SwitchItem> createState() => _SwitchItemState();
}

class _SwitchItemState extends State<_SwitchItem> {
  bool _value = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SwitchListTile(
      secondary: Icon(widget.icon, color: cs.primary),
      title: Text(widget.title),
      subtitle: widget.subtitle.isNotEmpty ? Text(widget.subtitle, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)) : null,
      value: _value,
      onChanged: (v) {
        setState(() => _value = v);
        widget.onToggle(v);
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }
}
