import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 液态玻璃效果开关：低性能设备可关闭背景模糊，退化为半透明纯色。
class GlassEffectsNotifier extends StateNotifier<bool> {
  GlassEffectsNotifier() : super(true) {
    _loadFromStorage();
  }

  static const _storageKey = 'bananachock_glass_effects';

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_storageKey, enabled);
  }

  Future<void> _loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getBool(_storageKey);
    if (saved != null) state = saved;
  }
}

final glassEffectsProvider =
    StateNotifierProvider<GlassEffectsNotifier, bool>((ref) {
  return GlassEffectsNotifier();
});
