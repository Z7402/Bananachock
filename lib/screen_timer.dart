import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'widget_breathing_progress.dart';
import 'provider_timer.dart';
import 'model_task_record.dart';

/// 计时器主页面：包含番茄钟倒计时 / 正向计时器
class TimerScreen extends ConsumerWidget {
  const TimerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerState = ref.watch(timerProvider);
    final colorScheme = Theme.of(context).colorScheme;

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
                ButtonSegment(value: TimerMode.pomodoro, label: Text('番茄'), icon: Icon(Icons.timer, size: 18)),
                ButtonSegment(value: TimerMode.stopwatch, label: Text('正向'), icon: Icon(Icons.trending_up, size: 18)),
              ],
              selected: {timerState.mode},
              onSelectionChanged: (Set<TimerMode> newSelection) {
                ref.read(timerProvider.notifier).switchMode(newSelection.first);
              },
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                shape: MaterialStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
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
            BreathingProgress(progress: timerState.progress),
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
                onChanged: (minutes) => ref.read(timerProvider.notifier).setPomodoroMinutes(minutes),
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
  const _ControlButtons({required this.isRunning, required this.onStartPause, required this.onReset});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FilledButton.icon(
          onPressed: onStartPause,
          icon: Icon(isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded),
          label: Text(isRunning ? '暂停' : '开始'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          ),
        ),
        const SizedBox(width: 24),
        OutlinedButton.icon(
          onPressed: onReset,
          icon: const Icon(Icons.restart_alt_rounded),
          label: const Text('重置'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          ),
        ),
      ],
    );
  }
}

class _PomodoroDurationSelector extends StatelessWidget {
  final int currentMinutes;
  final ValueChanged<int> onChanged;
  const _PomodoroDurationSelector({required this.currentMinutes, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final List<int> durations = [5, 15, 25, 45, 60];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: durations.map((minutes) {
          final isSelected = minutes == currentMinutes;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text('$minutes min'),
              selected: isSelected,
              onSelected: (_) => onChanged(minutes),
              visualDensity: VisualDensity.compact,
            ),
          );
        }).toList(),
      ),
    );
  }
}