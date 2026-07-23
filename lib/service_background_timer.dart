import 'package:flutter/services.dart';

import 'model_task_record.dart';

class BackgroundTimerSnapshot {
  final bool running;
  final TimerMode mode;
  final int value;
  final int workSeconds;
  final int breakSeconds;
  final bool isBreak;
  final String taskName;
  final int pendingFocusSessions;

  const BackgroundTimerSnapshot({
    required this.running,
    required this.mode,
    required this.value,
    required this.workSeconds,
    required this.breakSeconds,
    required this.isBreak,
    required this.taskName,
    required this.pendingFocusSessions,
  });

  factory BackgroundTimerSnapshot.fromMap(Map<Object?, Object?> map) {
    return BackgroundTimerSnapshot(
      running: map['running'] == true,
      mode: map['mode'] == 'stopwatch'
          ? TimerMode.stopwatch
          : TimerMode.pomodoro,
      value: (map['value'] as num?)?.toInt() ?? 0,
      workSeconds: (map['work'] as num?)?.toInt() ?? 1500,
      breakSeconds: (map['break'] as num?)?.toInt() ?? 300,
      isBreak: map['isBreak'] == true,
      taskName: map['task'] as String? ?? '',
      pendingFocusSessions: (map['pending'] as num?)?.toInt() ?? 0,
    );
  }
}

class BackgroundTimerService {
  static const _channel = MethodChannel('com.example.bananachock/timer');

  static Future<void> start(TimerState state) async {
    try {
      await _channel.invokeMethod<void>('startTimer', {
        'mode': state.mode.name,
        'value': state.remainingSeconds,
        'work': state.workSeconds,
        'break': state.breakSeconds,
        'isBreak': state.isBreak,
        'task': state.currentTaskName,
      });
    } on PlatformException {
      // 平台服务不可用时仍允许应用内计时。
    } on MissingPluginException {
      // 单元测试及非 Android 平台没有原生实现。
    }
  }

  static Future<void> pause() => _invoke('pauseTimer');
  static Future<void> stop() => _invoke('stopTimer');

  static Future<BackgroundTimerSnapshot?> snapshot({
    bool consume = true,
  }) async {
    try {
      final value = await _channel.invokeMethod<Map<Object?, Object?>>(
        'getTimerState',
        {'consume': consume},
      );
      if (value == null || value['active'] != true) return null;
      return BackgroundTimerSnapshot.fromMap(value);
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  static Future<void> setImmersive(bool enabled) async {
    try {
      await _channel.invokeMethod<void>('setImmersive', {'enabled': enabled});
    } on PlatformException {
      // Flutter SystemChrome 仍作为回退实现。
    } on MissingPluginException {
      // 非 Android 平台无需原生窗口控制。
    }
  }

  static Future<void> _invoke(String method) async {
    try {
      await _channel.invokeMethod<void>(method);
    } on PlatformException {
      // 前台服务失败不应中断应用内计时。
    } on MissingPluginException {
      // 单元测试及非 Android 平台忽略。
    }
  }
}
