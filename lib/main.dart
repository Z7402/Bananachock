import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'screen_main.dart';
import 'provider_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: BananachockApp(),
    ),
  );
}

/// 应用根 Widget
/// 集成 dynamic_color 实现壁纸色彩自动提取与 Material 3 动态主题适配
class BananachockApp extends ConsumerWidget {
  const BananachockApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appThemeMode = ref.watch(themeProvider);

    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        return MaterialApp(
          title: 'Bananachock',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme:
                lightDynamic ?? ColorScheme.fromSeed(seedColor: Colors.amber),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: darkDynamic ??
                ColorScheme.fromSeed(
                  seedColor: Colors.amber,
                  brightness: Brightness.dark,
                ),
            useMaterial3: true,
          ),
          themeMode: appThemeMode.flutterThemeMode,
          home: const MainScreen(),
        );
      },
    );
  }
}