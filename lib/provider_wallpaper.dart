import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WallpaperNotifier extends StateNotifier<WallpaperState> {
  WallpaperNotifier() : super(const WallpaperState()) {
    _loadFromStorage();
  }

  static const _wallpaperImageKey = 'bananachock_wallpaper_image';

  Future<void> pickWallpaper() async {
    final xFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 2048,
    );
    if (xFile == null) return;

    final bytes = await xFile.readAsBytes();
    final palette = await PaletteGenerator.fromImageProvider(
      MemoryImage(bytes),
    );
    state = WallpaperState(
      imageBytes: bytes,
      dominantColor: palette.dominantColor?.color ?? Colors.amber,
      vibrantColor: palette.vibrantColor?.color,
      mutedColor: palette.mutedColor?.color,
      lightMutedColor: palette.lightMutedColor?.color,
    );
    await _saveToStorage();
  }

  Future<void> removeWallpaper() async {
    state = const WallpaperState();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_wallpaperImageKey);
  }

  Future<void> _loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString(_wallpaperImageKey);
    if (encoded == null) return;

    try {
      final bytes = base64Decode(encoded);
      final palette = await PaletteGenerator.fromImageProvider(
        MemoryImage(bytes),
      );
      state = WallpaperState(
        imageBytes: bytes,
        dominantColor: palette.dominantColor?.color ?? Colors.amber,
        vibrantColor: palette.vibrantColor?.color,
        mutedColor: palette.mutedColor?.color,
        lightMutedColor: palette.lightMutedColor?.color,
      );
    } on FormatException {
      await prefs.remove(_wallpaperImageKey);
      state = const WallpaperState();
    }
  }

  Future<void> _saveToStorage() async {
    final bytes = state.imageBytes;
    if (bytes == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_wallpaperImageKey, base64Encode(bytes));
  }
}

class WallpaperState {
  const WallpaperState({
    this.imageBytes,
    this.dominantColor = Colors.amber,
    this.vibrantColor,
    this.mutedColor,
    this.lightMutedColor,
  });

  final Uint8List? imageBytes;
  final Color dominantColor;
  final Color? vibrantColor;
  final Color? mutedColor;
  final Color? lightMutedColor;

  bool get hasWallpaper => imageBytes != null;
  Color get primaryAccent => vibrantColor ?? dominantColor;
  Color get mutedAccent =>
      mutedColor ?? primaryAccent.withValues(alpha: 0.6);
}

final wallpaperProvider =
    StateNotifierProvider<WallpaperNotifier, WallpaperState>((ref) {
  return WallpaperNotifier();
});
