import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'model_task_record.dart';
import 'provider_task.dart';

/// 计时器状态 Notifier
class TimerNotifier extends StateNotifier<TimerState> {
  TimerNotifier(this._ref) : super(const TimerState(mode: TimerMode.pomodoro));

  final Ref _ref;
  Timer? _timer;

  void start() {
    if (state.isRunning) return;
    _timer?.cancel();
    final startSec = state.remainingSeconds;
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
    state = state.copyWith(isRunning: true, startSeconds: startSec);
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
      startSeconds: 0,
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
    final elapsed = state.mode == TimerMode.pomodoro
        ? state.totalSeconds - state.remainingSeconds
        : state.remainingSeconds;
    if (elapsed > 0) {
      final task = TaskRecord(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: state.mode == TimerMode.pomodoro ? '番茄钟专注' : '正向计时',
        category: '学习',
        date: DateTime.now(),
        duration: Duration(seconds: elapsed),
        focusMinutes: state.mode == TimerMode.pomodoro ? state.totalSeconds ~/ 60 : 0,
      );
      _ref.read(taskProvider.notifier).addTask(task);
    }
    state = state.copyWith(
      isRunning: false,
      remainingSeconds: 0,
      completedPomodoros: state.completedPomodoros + 1,
      startSeconds: 0,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final timerProvider = StateNotifierProvider<TimerNotifier, TimerState>((ref) {
  return TimerNotifier(ref);
});
