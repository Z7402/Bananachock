import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import 'model_task_record.dart';
import 'provider_task.dart';
import 'service_background_timer.dart';

/// 计时器状态 Notifier
class TimerNotifier extends StateNotifier<TimerState> {
  final Ref _ref;
  Timer? _timer;
  final AudioPlayer _completionPlayer = AudioPlayer();
  DateTime? _sessionStart;

  TimerNotifier(this._ref)
    : super(
        const TimerState(mode: TimerMode.pomodoro, remainingSeconds: 25 * 60),
      );

  void start() {
    if (state.isRunning) return;
    _timer?.cancel();

    // 记录会话开始时间（用于任务绑定）
    if (_sessionStart == null) {
      _sessionStart = DateTime.now();
    }

    state = state.copyWith(isRunning: true);
    BackgroundTimerService.start(state);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void pause() {
    _timer?.cancel();
    BackgroundTimerService.pause();
    state = state.copyWith(isRunning: false);
  }

  void reset() {
    _timer?.cancel();
    BackgroundTimerService.stop();
    _sessionStart = null;
    state = state.copyWith(
      isRunning: false,
      remainingSeconds: state.mode == TimerMode.pomodoro
          ? state.workSeconds
          : 0,
      isBreak: false,
    );
  }

  void switchMode(TimerMode mode) {
    _timer?.cancel();
    BackgroundTimerService.stop();
    _sessionStart = null;
    if (mode == TimerMode.pomodoro) {
      state = TimerState(
        mode: mode,
        remainingSeconds: state.workSeconds,
        workSeconds: state.workSeconds,
        breakSeconds: state.breakSeconds,
        completedPomodoros: state.completedPomodoros,
        isBreak: false,
        currentTaskName: state.currentTaskName,
      );
    } else {
      state = TimerState(
        mode: mode,
        remainingSeconds: 0,
        workSeconds: state.workSeconds,
        breakSeconds: state.breakSeconds,
        completedPomodoros: state.completedPomodoros,
        isBreak: false,
        currentTaskName: state.currentTaskName,
      );
    }
  }

  void setWorkMinutes(int minutes) {
    final total = minutes * 60;
    state = state.copyWith(
      workSeconds: total,
      remainingSeconds: (!state.isBreak && state.mode == TimerMode.pomodoro)
          ? total
          : state.remainingSeconds,
    );
  }

  void setBreakMinutes(int minutes) {
    final total = minutes * 60;
    state = state.copyWith(
      breakSeconds: total,
      remainingSeconds: state.isBreak ? total : state.remainingSeconds,
    );
  }

  void setCurrentTaskName(String name) {
    state = state.copyWith(currentTaskName: name);
    if (state.isRunning) BackgroundTimerService.start(state);
  }

  Future<void> syncFromBackground() async {
    final snapshot = await BackgroundTimerService.snapshot();
    if (snapshot == null) return;
    _applySnapshot(snapshot);
    if (snapshot.running) {
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    }
  }

  Future<void> _tick() async {
    final snapshot = await BackgroundTimerService.snapshot();
    if (snapshot != null) {
      _applySnapshot(snapshot);
      return;
    }
    if (state.mode == TimerMode.pomodoro) {
      if (state.remainingSeconds <= 0) {
        _onComplete();
      } else {
        state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
      }
    } else {
      state = state.copyWith(remainingSeconds: state.remainingSeconds + 1);
    }
  }

  void _applySnapshot(BackgroundTimerSnapshot snapshot) {
    for (var i = 0; i < snapshot.pendingFocusSessions; i++) {
      _recordTask(snapshot.workSeconds, titleOverride: snapshot.taskName);
    }
    if (snapshot.pendingFocusSessions > 0) _playCompletionSound();
    state = TimerState(
      mode: snapshot.mode,
      isRunning: snapshot.running,
      remainingSeconds: snapshot.value,
      workSeconds: snapshot.workSeconds,
      breakSeconds: snapshot.breakSeconds,
      completedPomodoros:
          state.completedPomodoros + snapshot.pendingFocusSessions,
      isBreak: snapshot.isBreak,
      currentTaskName: snapshot.taskName,
    );
    if (!snapshot.running) _timer?.cancel();
  }

  /// 强行结束当前专注阶段，直接进入休息
  void forceFinishFocus() {
    if (state.mode != TimerMode.pomodoro || state.isBreak || !state.isRunning)
      return;
    _timer?.cancel();
    BackgroundTimerService.stop();
    // 计算已专注时长
    final focusedSeconds = state.workSeconds - state.remainingSeconds;
    if (focusedSeconds > 0) {
      _recordTask(focusedSeconds);
    }
    // 切换到休息并交给前台服务继续计时。
    state = state.copyWith(
      isRunning: true,
      remainingSeconds: state.breakSeconds,
      isBreak: true,
      completedPomodoros: state.completedPomodoros + 1,
    );
    BackgroundTimerService.start(state);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    _sessionStart = null;
  }

  /// 结束正向计时并记录任务（用于停止按钮）
  void stopStopwatch() {
    if (state.mode != TimerMode.stopwatch) return;
    _timer?.cancel();
    BackgroundTimerService.stop();
    final elapsed = state.remainingSeconds;
    if (elapsed > 0) {
      _recordTask(elapsed);
    }
    _sessionStart = null;
    state = state.copyWith(isRunning: false, remainingSeconds: 0);
  }

  /// 启动休息计时器（独立于 start()，仅用于倒计时）
  void _startBreakTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.remainingSeconds <= 0) {
        _onComplete();
        return;
      }
      state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
    });
  }

  /// 跳过当前休息，直接切回专注模式
  void skipBreak() {
    if (!state.isBreak) return;
    _timer?.cancel();
    BackgroundTimerService.stop();
    state = state.copyWith(
      isRunning: false,
      remainingSeconds: state.workSeconds,
      isBreak: false,
    );
    _sessionStart = null;
  }

  void _onComplete() {
    _timer?.cancel();
    _playCompletionSound();
    final wasBreak = state.isBreak;

    if (!wasBreak) {
      // 专注完成 -> 记录任务
      _recordTask(state.workSeconds);
      // 自动进入休息并开始计时
      _startBreakTimer();
      state = state.copyWith(
        isRunning: true,
        remainingSeconds: state.breakSeconds,
        completedPomodoros: state.completedPomodoros + 1,
        isBreak: true,
      );
    } else {
      // 休息完成 -> 切回专注
      state = state.copyWith(
        isRunning: false,
        remainingSeconds: state.workSeconds,
        isBreak: false,
      );
    }
    _sessionStart = null;
  }

  Future<void> _playCompletionSound() async {
    try {
      await _completionPlayer.stop();
      await _completionPlayer.play(
        AssetSource('sounds/InCallNotification.ogg'),
      );
    } catch (_) {
      // 音频播放失败不应中断计时状态切换。
    }
  }

  void _recordTask(int durationSeconds, {String? titleOverride}) {
    final title = titleOverride?.isNotEmpty == true
        ? (titleOverride ?? '番茄专注')
        : state.currentTaskName.isNotEmpty
        ? state.currentTaskName
        : (state.mode == TimerMode.pomodoro ? '番茄专注' : '正向计时');
    final now = DateTime.now();
    // 使用精确的实际开始时间，不受暂停影响
    final startTime = now.subtract(Duration(seconds: durationSeconds));
    _sessionStart = null;

    final task = TaskRecord(
      id: '${now.millisecondsSinceEpoch}_${now.microsecond}',
      title: title,
      category: '专注',
      date: startTime,
      duration: Duration(seconds: durationSeconds),
    );
    _ref.read(taskProvider.notifier).addTask(task);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _completionPlayer.dispose();
    super.dispose();
  }
}

final timerProvider = StateNotifierProvider<TimerNotifier, TimerState>((ref) {
  return TimerNotifier(ref);
});
