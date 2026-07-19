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
        RadioGroup<AppThemeMode>(groupValue: currentMode, onChanged: (mode) {
          if (mode == null) return;
          onSelected(mode); Navigator.pop(context);
        }, child: const Column(mainAxisSize: MainAxisSize.min, children: [
          RadioListTile<AppThemeMode>(title: Text('浅色'), subtitle: Text('始终使用浅色主题'), value: AppThemeMode.light),
          RadioListTile<AppThemeMode>(title: Text('深色'), subtitle: Text('始终使用深色主题'), value: AppThemeMode.dark),
          RadioListTile<AppThemeMode>(title: Text('跟随系统'), subtitle: Text('根据系统设置自动切换'), value: AppThemeMode.system),
        ])),
      ],
    );
  }
}
