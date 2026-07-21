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
  static const _wallpaperOpacityKey = "bananachock_wallpaper_opacity";

  Future<bool> pickWallpaper() async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 2048,
      imageQuality: 85,
    );
    if (xFile == null) return false;

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
      opacity: state.opacity,
    );
    return true;
  }

  Future<void> removeWallpaper() async {
    state = WallpaperState(opacity: state.opacity);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_wallpaperImageKey);
  }

  Future<void> setOpacity(double value) async {
    final opacity = value.clamp(0.0, 1.0).toDouble();
    state = state.copyWith(opacity: opacity);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_wallpaperOpacityKey, opacity);
  }

  Future<void> _loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final opacity = (prefs.getDouble(_wallpaperOpacityKey) ?? 0.08)
        .clamp(0.0, 1.0)
        .toDouble();
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
          opacity: opacity,
        );
      } catch (_) {
        state = WallpaperState(opacity: opacity);
      }
    } else {
      state = WallpaperState(opacity: opacity);
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
  final double opacity;

  const WallpaperState({
    this.imagePath,
    this.imageBytes,
    this.dominantColor = Colors.amber,
    this.vibrantColor,
    this.mutedColor,
    this.lightMutedColor,
    this.opacity = 0.08,
  });

  WallpaperState copyWith({double? opacity}) => WallpaperState(
        imagePath: imagePath,
        imageBytes: imageBytes,
        dominantColor: dominantColor,
        vibrantColor: vibrantColor,
        mutedColor: mutedColor,
        lightMutedColor: lightMutedColor,
        opacity: opacity ?? this.opacity,
      );

  bool get hasWallpaper => imageBytes != null;
  Color get primaryAccent => vibrantColor ?? dominantColor;
  Color get mutedAccent => mutedColor ?? primaryAccent.withValues(alpha: 0.6);
}

final wallpaperProvider =
    StateNotifierProvider<WallpaperNotifier, WallpaperState>((ref) {
  return WallpaperNotifier();
});
