import 'package:flutter/material.dart';
import 'screen_timer.dart';
import 'screen_statistics.dart';
import 'screen_settings.dart';
import 'widget_glass.dart';

/// 主界面：弥散渐变背景 + 悬浮玻璃底部导航管理三个模块（计时、统计、设置）
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  bool _timerImmersive = false;

  @override
  Widget build(BuildContext context) {
    final screens = [
      TimerScreen(
        onImmersiveChanged: (value) {
          if (_timerImmersive != value && mounted) {
            setState(() => _timerImmersive = value);
          }
        },
      ),
      const StatisticsScreen(),
      const SettingsScreen(),
    ];
    final hideNav = _timerImmersive && _selectedIndex == 0;

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const MeshBackground(),
          IndexedStack(index: _selectedIndex, children: screens),
        ],
      ),
      // 沉浸模式下导航栏高度归零，body 底部 inset 随之消失，
      // 保证沉浸布局与全屏对齐（滑出方式会残留布局高度导致控件重叠）。
      bottomNavigationBar: AnimatedSize(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOutCubic,
        child: hideNav
            ? const SizedBox.shrink()
            : GlassNavBar(
                selectedIndex: _selectedIndex,
                onSelected: (index) => setState(() => _selectedIndex = index),
                destinations: const [
                  GlassNavDestination(
                    icon: Icons.timer_outlined,
                    selectedIcon: Icons.timer,
                    label: '计时',
                  ),
                  GlassNavDestination(
                    icon: Icons.assessment_outlined,
                    selectedIcon: Icons.assessment,
                    label: '统计',
                  ),
                  GlassNavDestination(
                    icon: Icons.settings_outlined,
                    selectedIcon: Icons.settings,
                    label: '设置',
                  ),
                ],
              ),
      ),
    );
  }
}
