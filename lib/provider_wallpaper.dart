import "dart:convert";
import "dart:typed_data";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:image_picker/image_picker.dart";
import "package:palette_generator/palette_generator.dart";
import "dart:io";

class WallpaperNotifier extends StateNotifier<WallpaperState> {
  WallpaperNotifier() : super(const WallpaperState()) {
    _loadFromStorage();
  }

  static const _wallpaperImageKey = "bananachock_wallpaper_image";

  Future<void> pickWallpaper(BuildContext context) async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(source: ImageSource.gallery, maxWidth: 2048);
    if (xFile == null) return;

    final file = File(xFile.path);
    final bytes = await file.readAsBytes();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_wallpaperImageKey, base64.encode(bytes));

    final imageProvider = MemoryImage(bytes);
    final palette = await PaletteGenerator.fromImageProvider(imageProvider);
    final dominant = palette.dominantColor?.color ?? Colors.amber;
    final vibrant = palette.vibrantColor?.color;
    final muted = palette.mutedColor?.color;
    final lightMuted = palette.lightMutedColor?.color;

    state = WallpaperState(
      imagePath: xFile.path,
      imageBytes: bytes,
      dominantColor: dominant,
      vibrantColor: vibrant,
      mutedColor: muted,
      lightMutedColor: lightMuted,
    );
  }

  void removeWallpaper() async {
    state = const WallpaperState();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_wallpaperImageKey);
  }

  Future<void> _loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final base64Str = prefs.getString(_wallpaperImageKey);
    if (base64Str != null) {
      try {
        final bytes = base64.decode(base64Str);
        final imageProvider = MemoryImage(bytes);
        final palette = await PaletteGenerator.fromImageProvider(imageProvider);
        state = WallpaperState(
          imageBytes: bytes,
          dominantColor: palette.dominantColor?.color ?? Colors.amber,
          vibrantColor: palette.vibrantColor?.color,
          mutedColor: palette.mutedColor?.color,
          lightMutedColor: palette.lightMutedColor?.color,
        );
      } catch (_) {
        state = const WallpaperState();
      }
    }
  }
}

class WallpaperState {
  final String? imagePath;
  final Uint8List? imageBytes;
  final Color dominantColor;
  final Color? vibrantColor;
  final Color? mutedColor;
  final Color? lightMutedColor;

  const WallpaperState({
    this.imagePath,
    this.imageBytes,
    this.dominantColor = Colors.amber,
    this.vibrantColor,
    this.mutedColor,
    this.lightMutedColor,
  });

  bool get hasWallpaper => imageBytes != null;
  Color get primaryAccent => vibrantColor ?? dominantColor;
  Color get mutedAccent => mutedColor ?? primaryAccent.withOpacity(0.6);
}

final wallpaperProvider = StateNotifierProvider<WallpaperNotifier, WallpaperState>((ref) {
  return WallpaperNotifier();
});
