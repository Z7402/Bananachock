import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'model_task_record.dart';

/// 计时器状态 Notifier
class TimerNotifier extends StateNotifier<TimerState> {
  TimerNotifier() : super(const TimerState(mode: TimerMode.pomodoro));

  Timer? _timer;

  void start() {
    if (state.isRunning) return;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.mode == TimerMode.pomodoro) {
        if (state.remainingSeconds <= 0) {
          _onComplete();
          return;
        }
        state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
      } else {
        state = state.copyWith(remainingSeconds: state.remainingSeconds + 1);
      }
    });
    state = state.copyWith(isRunning: true);
  }

  void pause() {
    _timer?.cancel();
    state = state.copyWith(isRunning: false);
  }

  void reset() {
    _timer?.cancel();
    state = state.copyWith(
      isRunning: false,
      remainingSeconds: state.mode == TimerMode.pomodoro ? state.totalSeconds : 0,
    );
  }

  void switchMode(TimerMode mode) {
    _timer?.cancel();
    state = TimerState(
      mode: mode,
      remainingSeconds: mode == TimerMode.pomodoro ? state.totalSeconds : 0,
      totalSeconds: state.totalSeconds,
      completedPomodoros: state.completedPomodoros,
    );
  }

  void setPomodoroMinutes(int minutes) {
    final total = minutes * 60;
    state = state.copyWith(
      totalSeconds: total,
      remainingSeconds: state.mode == TimerMode.pomodoro ? total : state.remainingSeconds,
    );
  }

  void _onComplete() {
    _timer?.cancel();
    state = state.copyWith(
      isRunning: false,
      remainingSeconds: 0,
      completedPomodoros: state.completedPomodoros + 1,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final timerProvider = StateNotifierProvider<TimerNotifier, TimerState>((ref) {
  return TimerNotifier();
});