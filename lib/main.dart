import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:dynamic_color/dynamic_color.dart";
import "package:intl/intl.dart";
import "screen_splash.dart";
import "provider_theme.dart";
import "provider_wallpaper.dart";

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Intl.defaultLocale = 'zh_CN';
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
  ));
  runApp(const ProviderScope(child: BananachockApp()));
}

class BananachockApp extends ConsumerWidget {
  const BananachockApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appThemeMode = ref.watch(themeProvider);
    final wallpaper = ref.watch(wallpaperProvider);

    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        final seedColor = wallpaper.hasWallpaper
            ? wallpaper.primaryAccent
            : (lightDynamic?.primary ?? Colors.amber);

        return MaterialApp(
          title: "Bananachock",
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: lightDynamic != null
                ? ColorScheme.fromSeed(seedColor: seedColor, brightness: Brightness.light)
                : ColorScheme.fromSeed(seedColor: seedColor, brightness: Brightness.light),
            useMaterial3: true,
            cardTheme: CardThemeData(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          darkTheme: ThemeData(
            colorScheme: darkDynamic != null
                ? ColorScheme.fromSeed(seedColor: seedColor, brightness: Brightness.dark)
                : ColorScheme.fromSeed(seedColor: seedColor, brightness: Brightness.dark),
            useMaterial3: true,
            cardTheme: CardThemeData(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          themeMode: appThemeMode == AppThemeMode.light
              ? ThemeMode.light
              : appThemeMode == AppThemeMode.dark
                  ? ThemeMode.dark
                  : ThemeMode.system,
          builder: (context, child) {
            final brightness = Theme.of(context).brightness;
            final iconBrightness = brightness == Brightness.dark
                ? Brightness.light
                : Brightness.dark;
            return AnnotatedRegion<SystemUiOverlayStyle>(
              value: SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                systemNavigationBarColor: Colors.transparent,
                statusBarIconBrightness: iconBrightness,
                statusBarBrightness: brightness,
                systemNavigationBarIconBrightness: iconBrightness,
                systemNavigationBarContrastEnforced: false,
              ),
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: const SplashScreen(),
        );
      },
    );
  }
}
