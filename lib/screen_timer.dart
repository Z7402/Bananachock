import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'widget_breathing_progress.dart';
import 'provider_timer.dart';
import 'model_task_record.dart';

/// 计时器主页面
class TimerScreen extends ConsumerStatefulWidget {
  const TimerScreen({super.key});

  @override
  ConsumerState<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends ConsumerState<TimerScreen>
    with TickerProviderStateMixin {
  late AnimationController _timePulseController;
  late Animation<double> _timePulseAnim;
  bool _pulseRunning = false;

  @override
  void initState() {
    super.initState();
    _timePulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _timePulseAnim = Tween<double>(begin: 0.98, end: 1.02).animate(
      CurvedAnimation(
        parent: _timePulseController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _timePulseController.dispose();
    super.dispose();
  }

  /// 仅在计时运行且进度>0时播放脉动动画
  void _syncPulse(bool shouldRun) {
    if (shouldRun && !_pulseRunning) {
      _pulseRunning = true;
      // 从当前位置开始 repeat
      _timePulseController.repeat(reverse: true);
    } else if (!shouldRun && _pulseRunning) {
      _pulseRunning = false;
      _timePulseController.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final timerState = ref.watch(timerProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final shouldRun =
        timerState.isRunning && timerState.remainingSeconds > 0;
    _syncPulse(shouldRun);

    return Scaffold(
      appBar: AppBar(
        title: const Text('计时'),
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: SegmentedButton<TimerMode>(
              segments: const [
                ButtonSegment(
                  value: TimerMode.pomodoro,
                  label: Text('番茄'),
                  icon: Icon(Icons.timer, size: 18),
                ),
                ButtonSegment(
                  value: TimerMode.stopwatch,
                  label: Text('正向'),
                  icon: Icon(Icons.trending_up, size: 18),
                ),
              ],
              selected: {timerState.mode},
              onSelectionChanged: (Set<TimerMode> newSelection) {
                ref
                    .read(timerProvider.notifier)
                    .switchMode(newSelection.first);
              },
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                shape: WidgetStatePropertyAll(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        color: colorScheme.surface,
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 2),
            _TimeDisplay(timeString: timerState.formattedTime),
            const SizedBox(height: 16),
            _ProgressBar(progress: timerState.progress),
            const SizedBox(height: 48),
            BreathingProgress(
              progress: timerState.progress,
              isRunning: timerState.isRunning,
            ),
            const Spacer(),
            _ControlButtons(
              isRunning: timerState.isRunning,
              onStartPause: () {
                if (timerState.isRunning) {
                  ref.read(timerProvider.notifier).pause();
                } else {
                  ref.read(timerProvider.notifier).start();
                }
              },
              onReset: () => ref.read(timerProvider.notifier).reset(),
            ),
            const SizedBox(height: 24),
            if (timerState.mode == TimerMode.pomodoro)
              _PomodoroDurationSelector(
                currentMinutes: timerState.totalSeconds ~/ 60,
                onChanged: (minutes) => ref
                    .read(timerProvider.notifier)
                    .setPomodoroMinutes(minutes),
              ),
            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }
}

class _TimeDisplay extends StatelessWidget {
  final String timeString;
  const _TimeDisplay({required this.timeString});

  @override
  Widget build(BuildContext context) {
    return Text(
      timeString,
      style: Theme.of(context).textTheme.displayLarge?.copyWith(
        fontSize: 80,
        fontWeight: FontWeight.w300,
        letterSpacing: 4,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final double progress;
  const _ProgressBar({required this.progress});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: 200,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: progress,
          backgroundColor: cs.surfaceContainerHighest,
          color: cs.primary,
          minHeight: 6,
        ),
      ),
    );
  }
}

class _ControlButtons extends StatelessWidget {
  final bool isRunning;
  final VoidCallback onStartPause;
  final VoidCallback onReset;
  const _ControlButtons({
    required this.isRunning,
    required this.onStartPause,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FilledButton.icon(
          onPressed: onStartPause,
          icon: Icon(
            isRunning
                ? Icons.pause_rounded
                : Icons.play_arrow_rounded,
          ),
          label: Text(isRunning ? '暂停' : '开始'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              horizontal: 32,
              vertical: 16,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ),
        const SizedBox(width: 24),
        OutlinedButton.icon(
          onPressed: onReset,
          icon: const Icon(Icons.restart_alt_rounded),
          label: const Text('重置'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 16,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ),
      ],
    );
  }
}

class _PomodoroDurationSelector extends StatefulWidget {
  final int currentMinutes;
  final ValueChanged<int> onChanged;
  const _PomodoroDurationSelector({
    required this.currentMinutes,
    required this.onChanged,
  });

  @override
  State<_PomodoroDurationSelector> createState() =>
      _PomodoroDurationSelectorState();
}

class _PomodoroDurationSelectorState
    extends State<_PomodoroDurationSelector> {
  final List<int> _presets = [5, 15, 25, 45, 60];
  late int _custom;

  @override
  void initState() {
    super.initState();
    _custom = widget.currentMinutes;
  }

  @override
  void didUpdateWidget(covariant _PomodoroDurationSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentMinutes != widget.currentMinutes) {
      _custom = widget.currentMinutes;
    }
  }

  void _onPreset(int m) {
    _custom = m;
    widget.onChanged(m);
  }

  void _onCustom(String raw) {
    final v = int.tryParse(raw.trim());
    if (v != null && v > 0 && v <= 180) {
      _custom = v;
    }
  }

  void _applyCustom() {
    if (_custom > 0 && _custom <= 180) {
      widget.onChanged(_custom);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _presets.map((minutes) {
              final isSelected = minutes == widget.currentMinutes;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text('\$minutes min'),
                  selected: isSelected,
                  onSelected: (_) => _onPreset(minutes),
                  visualDensity: VisualDensity.compact,
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 60,
              child: TextField(
                controller:
                    TextEditingController(text: '\$_custom'),
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 4,
                  ),
                ),
                onChanged: _onCustom,
                onSubmitted: (_) => _applyCustom(),
              ),
            ),
            const SizedBox(width: 4),
            const Text('分钟', style: TextStyle(fontSize: 12)),
            const SizedBox(width: 8),
            TextButton(
              onPressed: _applyCustom,
              child: const Text('应用'),
            ),
          ],
        ),
      ],
    );
  }
}
