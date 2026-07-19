/// 单个任务活动记录（用于统计复盘）
class TaskRecord {
  final String id;
  final String title;
  final String category;
  final DateTime date;
  final Duration duration;
  /// 番茄钟专注分钟数（用于区分是自定义时间）
  final int focusMinutes;

  TaskRecord({
    required this.id,
    required this.title,
    required this.category,
    required this.date,
    required this.duration,
    this.focusMinutes = 0,
  });

  factory TaskRecord.fromJson(Map<String, dynamic> json) {
    return TaskRecord(
      id: json['id'] as String,
      title: json['title'] as String,
      category: json['category'] as String,
      date: DateTime.parse(json['date'] as String),
      duration: Duration(seconds: json['durationSeconds'] as int),
      focusMinutes: (json['focusMinutes'] as int?) ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'date': date.toIso8601String(),
      'durationSeconds': duration.inSeconds,
      'focusMinutes': focusMinutes,
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
  final int totalSeconds;
  final int completedPomodoros;
  /// 番茄钟开始时的秒数，用于任务记录
  final int startSeconds;

  const TimerState({
    required this.mode,
    this.isRunning = false,
    this.remainingSeconds = 0,
    this.totalSeconds = 25 * 60,
    this.completedPomodoros = 0,
    this.startSeconds = 0,
  });

  TimerState copyWith({
    TimerMode? mode,
    bool? isRunning,
    int? remainingSeconds,
    int? totalSeconds,
    int? completedPomodoros,
    int? startSeconds,
  }) {
    return TimerState(
      mode: mode ?? this.mode,
      isRunning: isRunning ?? this.isRunning,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      completedPomodoros: completedPomodoros ?? this.completedPomodoros,
      startSeconds: startSeconds ?? this.startSeconds,
    );
  }

  String get formattedTime {
    final minutes =
        (remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds =
        (remainingSeconds % 60).toString().padLeft(2, '0');
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
