/// 单个任务活动记录（用于统计复盘）
class TaskRecord {
  final String id;
  final String title;
  final String category;
  final DateTime date;
  final Duration duration;

  TaskRecord({
    required this.id,
    required this.title,
    required this.category,
    required this.date,
    required this.duration,
  });

  factory TaskRecord.fromJson(Map<String, dynamic> json) {
    return TaskRecord(
      id: json['id'] as String,
      title: json['title'] as String,
      category: json['category'] as String,
      date: DateTime.parse(json['date'] as String),
      duration: Duration(seconds: json['durationSeconds'] as int),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'date': date.toIso8601String(),
      'durationSeconds': duration.inSeconds,
    };
  }
}

/// 计时器模式枚举
enum TimerMode { pomodoro, stopwatch }

/// 计时器状态
class TimerState {
  final TimerMode mode;
  final bool isRunning;
  final int remainingSeconds;
  final int workSeconds;
  final int breakSeconds;
  final int completedPomodoros;
  final bool isBreak;
  final String currentTaskName;

  const TimerState({
    required this.mode,
    this.isRunning = false,
    this.remainingSeconds = 0,
    this.workSeconds = 25 * 60,
    this.breakSeconds = 5 * 60,
    this.completedPomodoros = 0,
    this.isBreak = false,
    this.currentTaskName = '',
  });

  /// 当前阶段总时长（休息时用 breakSeconds，否则用 workSeconds）
  int get totalSeconds => isBreak ? breakSeconds : workSeconds;

  TimerState copyWith({
    TimerMode? mode,
    bool? isRunning,
    int? remainingSeconds,
    int? workSeconds,
    int? breakSeconds,
    int? completedPomodoros,
    bool? isBreak,
    String? currentTaskName,
  }) {
    return TimerState(
      mode: mode ?? this.mode,
      isRunning: isRunning ?? this.isRunning,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      workSeconds: workSeconds ?? this.workSeconds,
      breakSeconds: breakSeconds ?? this.breakSeconds,
      completedPomodoros: completedPomodoros ?? this.completedPomodoros,
      isBreak: isBreak ?? this.isBreak,
      currentTaskName: currentTaskName ?? this.currentTaskName,
    );
  }

  String get formattedTime {
    final minutes = (remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (remainingSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  double get progress {
    if (totalSeconds == 0) return 0;
    if (mode == TimerMode.pomodoro) {
      return 1.0 - (remainingSeconds / totalSeconds);
    }
    return (remainingSeconds % 3600) / 3600;
  }
}