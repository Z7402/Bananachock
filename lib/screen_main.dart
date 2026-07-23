import 'package:flutter/material.dart';
import 'screen_timer.dart';
import 'screen_statistics.dart';
import 'screen_settings.dart';

/// 主界面：使用 Material 3 NavigationBar 管理三个模块（计时、统计、设置）
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
    final colorScheme = Theme.of(context).colorScheme;
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

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: IndexedStack(index: _selectedIndex, children: screens),
      bottomNavigationBar: AnimatedSize(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOutCubic,
        child: _timerImmersive && _selectedIndex == 0
            ? const SizedBox.shrink()
            : NavigationBar(
                selectedIndex: _selectedIndex,
                onDestinationSelected: (int index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
                backgroundColor: colorScheme.surface,
                indicatorColor: colorScheme.secondaryContainer,
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.timer_outlined),
                    selectedIcon: Icon(Icons.timer),
                    label: '计时',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.assessment_outlined),
                    selectedIcon: Icon(Icons.assessment),
                    label: '统计',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.settings_outlined),
                    selectedIcon: Icon(Icons.settings),
                    label: '设置',
                  ),
                ],
              ),
      ),
    );
  }
}
