import 'package:flutter/material.dart';
import 'provider_theme.dart';

class ThemePickerDialog extends StatelessWidget {
  final AppThemeMode currentMode;
  final ValueChanged<AppThemeMode> onSelected;
  const ThemePickerDialog({super.key, required this.currentMode, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: const Text('选择主题模式'),
      children: [
        RadioListTile<AppThemeMode>(title: const Text('浅色'), subtitle: const Text('始终使用浅色主题'),
          value: AppThemeMode.light, groupValue: currentMode, onChanged: (v) { onSelected(v!); Navigator.pop(context); }),
        RadioListTile<AppThemeMode>(title: const Text('深色'), subtitle: const Text('始终使用深色主题'),
          value: AppThemeMode.dark, groupValue: currentMode, onChanged: (v) { onSelected(v!); Navigator.pop(context); }),
        RadioListTile<AppThemeMode>(title: const Text('跟随系统'), subtitle: const Text('根据系统设置自动切换'),
          value: AppThemeMode.system, groupValue: currentMode, onChanged: (v) { onSelected(v!); Navigator.pop(context); }),
      ],
    );
  }
}