import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'model_task_record.dart';
import 'provider_task.dart';

/// 计时器状态 Notifier
class TimerNotifier extends StateNotifier<TimerState> {
  TimerNotifier()
      : super(
          const TimerState(
            mode: TimerMode.pomodoro,
            remainingSeconds: 25 * 60,
          ),
        );

  Timer? _timer;

  void start() {
    if (state.isRunning) return;
    _timer?.cancel();

    // 完成后的番茄钟再次开始时，从当前设定时长创建新一轮。
    final remaining = state.mode == TimerMode.pomodoro &&
            state.remainingSeconds <= 0
        ? state.totalSeconds
        : state.remainingSeconds;
    final isNewSession = state.startSeconds == 0;
    final startSec = isNewSession ? remaining : state.startSeconds;
    state = state.copyWith(
      isRunning: true,
      remainingSeconds: remaining,
      startSeconds: startSec,
    );
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.mode == TimerMode.pomodoro) {
        if (state.remainingSeconds <= 1) {
          state = state.copyWith(remainingSeconds: 0);
          _onComplete();
          return;
        }
        state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
      } else {
        state = state.copyWith(remainingSeconds: state.remainingSeconds + 1);
      }
    });
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
        ? (state.startSeconds > 0 ? state.startSeconds : state.totalSeconds) -
            state.remainingSeconds
        : state.remainingSeconds;
    if (elapsed > 0) {
      final task = TaskRecord(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: state.mode == TimerMode.pomodoro ? '番茄钟专注' : '正向计时',
        category: '学习',
        date: DateTime.now(),
        duration: Duration(seconds: elapsed),
        focusMinutes: state.mode == TimerMode.pomodoro
            ? (state.startSeconds > 0
                ? state.startSeconds
                : state.totalSeconds) ~/
                60
            : 0,
      );
      _onTaskComplete?.call(task);
    }
    state = state.copyWith(
      isRunning: false,
      remainingSeconds: 0,
      completedPomodoros: state.completedPomodoros + 1,
      startSeconds: 0,
    );
  }

  void Function(TaskRecord)? _onTaskComplete;

  void setOnTaskComplete(void Function(TaskRecord) callback) {
    _onTaskComplete = callback;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final timerProvider = StateNotifierProvider<TimerNotifier, TimerState>((ref) {
  final notifier = TimerNotifier();
  notifier.setOnTaskComplete((task) {
    ref.read(taskProvider.notifier).addTask(task);
  });
  return notifier;
});
