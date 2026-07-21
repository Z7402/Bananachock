import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:url_launcher/url_launcher.dart";
import "provider_theme.dart";
import "provider_wallpaper.dart";
import "provider_app_update.dart";
import "screen_webdav.dart";
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
              onTap: () => _pickWallpaper(context, ref),
            ),
            if (wallpaper.hasWallpaper) ...[
              _WallpaperOpacitySlider(
                value: wallpaper.opacity,
                onChanged: (value) =>
                    ref.read(wallpaperProvider.notifier).setOpacity(value),
              ),
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
            ],
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
              onToggle: (v) =>
                  _showComingSoon(context, "屏幕常亮已${v ? "开启" : "关闭"}"),
            ),
          ]),
          const SizedBox(height: 20),
          _Section(title: "数据与云同步", items: [
            _Item(
              icon: Icons.cloud_upload_outlined,
              title: "WebDAV 云备份",
              subtitle: "将任务数据与壁纸配置同步到云存储",
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const WebDavScreen()),
              ),
            ),
          ]),
          const SizedBox(height: 20),
          _Section(title: "更新", items: [
            _Item(
              icon: Icons.system_update_rounded,
              title: "检查更新",
              subtitle: "当前版本 v1.1.1 · 手动检查 GitHub Release",
              onTap: () => _checkUpdate(context, ref),
            ),
          ]),
          const SizedBox(height: 20),
          _Section(title: "关于", items: [
            _Item(
              icon: Icons.info_outline,
              title: "关于 Bananachock",
              subtitle: "v1.1.1 | 作者、项目与技术支持",
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const _AboutScreen()),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Future<void> _checkUpdate(BuildContext context, WidgetRef ref) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    final result = await ref.read(appUpdateProvider.notifier).checkForUpdate();
    if (!context.mounted) return;
    Navigator.of(context).pop();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(result.error != null
            ? "检查更新失败"
            : result.updateAvailable
                ? "发现 v${result.latestVersion}"
                : "已是最新版本"),
        content: SingleChildScrollView(
          child: Text(result.error ??
              "当前版本：v${result.currentVersion}\n最新版本：v${result.latestVersion}\n发布时间：${result.publishedAt?.toLocal().toString().substring(0, 16) ?? "未知"}\n\n${result.releaseNotes?.trim().isNotEmpty == true ? result.releaseNotes : "暂无更新说明"}${result.updateAvailable && result.downloadUrl == null ? "\n\n该 Release 未提供 APK，请前往发布页查看。" : ""}"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("稍后"),
          ),
          if (result.releaseUrl != null)
            TextButton(
              onPressed: () =>
                  ref.read(appUpdateProvider.notifier).openReleasePage(),
              child: const Text("发布页"),
            ),
          if (result.updateAvailable)
            FilledButton(
              onPressed: () =>
                  ref.read(appUpdateProvider.notifier).openDownload(),
              child: Text(result.downloadUrl == null ? "查看版本" : "下载 APK"),
            ),
        ],
      ),
    );
  }

  Future<void> _pickWallpaper(BuildContext context, WidgetRef ref) async {
    try {
      final selected =
          await ref.read(wallpaperProvider.notifier).pickWallpaper();
      if (!context.mounted || !selected) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("壁纸已更新")),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("无法读取所选图片，请重试")),
      );
    }
  }

  String _themeName(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return "浅色";
      case AppThemeMode.dark:
        return "深色";
      case AppThemeMode.system:
        return "跟随系统";
    }
  }

  void _showThemePicker(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => ThemePickerDialog(
        currentMode: ref.read(themeProvider),
        onSelected: (mode) =>
            ref.read(themeProvider.notifier).setThemeMode(mode),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}

class _AboutScreen extends StatelessWidget {
  const _AboutScreen();

  static final Uri _authorUrl = Uri.parse("https://github.com/Z7402");
  static final Uri _repositoryUrl =
      Uri.parse("https://github.com/Z7402/Bananachock");
  static final Uri _supportUrl =
      Uri.parse("https://github.com/Z7402/Bananachock/issues");

  Future<void> _openLink(BuildContext context, Uri uri) async {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("无法打开链接，请检查浏览器设置")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text("关于"), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          Center(
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Icon(Icons.timer_rounded,
                  size: 48, color: cs.onPrimaryContainer),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "Bananachock",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            "v1.1.1",
            textAlign: TextAlign.center,
            style: TextStyle(color: cs.primary, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Text(
            "专注计时、长期时间记录与统计复盘工具。通过沉浸式光影动画，让每一次专注都更自然、更有节奏。",
            textAlign: TextAlign.center,
            style: TextStyle(
              height: 1.55,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 28),
          _AboutCard(
            title: "作者",
            children: [
              const ListTile(
                leading: Icon(Icons.person_outline_rounded),
                title: Text("Z7402"),
                subtitle: Text("Bananachock 设计与开发"),
              ),
              ListTile(
                leading: const Icon(Icons.open_in_new_rounded),
                title: const Text("GitHub 个人主页"),
                subtitle: const Text("github.com/Z7402"),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _openLink(context, _authorUrl),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _AboutCard(
            title: "开源项目",
            children: [
              ListTile(
                leading: const Icon(Icons.code_rounded),
                title: const Text("Bananachock GitHub 仓库"),
                subtitle: const Text("查看源代码、版本发布与开发动态"),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _openLink(context, _repositoryUrl),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _AboutCard(
            title: "技术支持",
            children: [
              ListTile(
                leading: const Icon(Icons.support_agent_rounded),
                title: const Text("问题反馈与功能建议"),
                subtitle: const Text("通过 GitHub Issues 提交问题"),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _openLink(context, _supportUrl),
              ),
              const ListTile(
                leading: Icon(Icons.developer_board_rounded),
                title: Text("主要技术"),
                subtitle: Text(
                  "Flutter · Dart · Riverpod · Material 3\nAndroid ARM64 · GitHub Actions",
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            "Made with focus by Z7402",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _AboutCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _AboutCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              color: cs.primary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
        ),
        Card(
          margin: EdgeInsets.zero,
          elevation: 0,
          color: cs.surfaceContainerLow,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          clipBehavior: Clip.antiAlias,
          child: Column(children: children),
        ),
      ],
    );
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
          child: Text(title,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: cs.primary,
                  letterSpacing: 1)),
        ),
        Card(
          elevation: 0,
          color: cs.surfaceContainerLow,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
  const _Item(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon, color: cs.primary),
      title: Text(title),
      subtitle: subtitle.isNotEmpty
          ? Text(subtitle,
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant))
          : null,
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }
}

class _WallpaperOpacitySlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;

  const _WallpaperOpacitySlider({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final percent = (value * 100).round();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Icon(Icons.opacity_rounded, color: cs.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("壁纸透明度  $percent%"),
                Slider(
                  value: value,
                  min: 0,
                  max: 1,
                  divisions: 20,
                  label: "$percent%",
                  onChanged: onChanged,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SwitchItem extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final ValueChanged<bool> onToggle;
  const _SwitchItem(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.onToggle});

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
      subtitle: widget.subtitle.isNotEmpty
          ? Text(widget.subtitle,
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant))
          : null,
      value: _value,
      onChanged: (v) {
        setState(() => _value = v);
        widget.onToggle(v);
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }
}
