import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'screen_splash.dart';
import 'provider_theme.dart';
import 'provider_wallpaper.dart';

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
    final wallpaper = ref.watch(wallpaperProvider);

    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        // 壁纸主色优先，否则 fallback 到系统动态色，最后用 amber
        final seedColor = wallpaper.hasWallpaper
            ? wallpaper.primaryAccent
            : (lightDynamic?.primary ?? Colors.amber);

        return MaterialApp(
          title: 'Bananachock',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: lightDynamic != null
                ? lightDynamic.harmonized(seedColor)
                : ColorScheme.fromSeed(
                    seedColor: seedColor,
                    brightness: Brightness.light,
                  ),
            useMaterial3: true,
            cardTheme: CardThemeData(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          darkTheme: ThemeData(
            colorScheme: darkDynamic != null
                ? darkDynamic.harmonized(seedColor)
                : ColorScheme.fromSeed(
                    seedColor: seedColor,
                    brightness: Brightness.dark,
                  ),
            useMaterial3: true,
            cardTheme: CardThemeData(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          themeMode: appThemeMode == AppThemeMode.light
              ? ThemeMode.light
              : appThemeMode == AppThemeMode.dark
                  ? ThemeMode.dark
                  : ThemeMode.system,
          home: const SplashScreen(),
        );
      },
    );
  }
}

extension on ColorScheme {
  /// 将当前色彩方案的主色替换为 seedColor，其他色取两者调和
  ColorScheme harmonized(Color seedColor) {
    return ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
      surface: surface,
    );
  }
}
