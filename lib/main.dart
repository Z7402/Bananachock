import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'screen_splash.dart';
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
class BananachockApp extends ConsumerWidget {
  const BananachockApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appThemeMode = ref.watch(themeProvider);

    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        ThemeMode themeMode;
        switch (appThemeMode) {
          case AppThemeMode.light:
            themeMode = ThemeMode.light;
            break;
          case AppThemeMode.dark:
            themeMode = ThemeMode.dark;
            break;
          case AppThemeMode.system:
            themeMode = ThemeMode.system;
            break;
        }

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
          themeMode: themeMode,
          home: const SplashScreen(),
        );
      },
    );
  }
}
