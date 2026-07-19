import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'widget_timer_animation.dart';
import 'provider_timer.dart';
import 'provider_quotes.dart';
import 'provider_wallpaper.dart';

/// 计时器主页面：包含番茄钟倒计时 / 正向计时器
/// 集成海浪起伏+太阳东升西落动画、名言警句
class TimerScreen extends ConsumerStatefulWidget {
  const TimerScreen({super.key});

  @override
  ConsumerState<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends ConsumerState<TimerScreen> with TickerProviderStateMixin {
  late AnimationController _timePulseController;
  late Animation<double> _timePulseAnim;

  @override
  void initState() {
    super.initState();
    _timePulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _timePulseAnim = Tween<double>(begin: 0.98, end: 1.02).animate(
      CurvedAnimation(parent: _timePulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _timePulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timerState = ref.watch(timerProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final quote = ref.watch(quoteProvider);

    return Scaffold(
      body: Stack(
        children: [
          Container(color: colorScheme.surface),
          _buildWallpaperBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(colorScheme, ref, timerState, quote),
                Expanded(child: _buildTimerCenter(colorScheme, ref, timerState)),
                _buildBottomControls(colorScheme, ref, timerState),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWallpaperBackground() {
    final wallpaper = ref.watch(wallpaperProvider);
    if (!wallpaper.hasWallpaper) return const SizedBox.shrink();
    return Positioned.fill(
      child: Opacity(
        opacity: 0.08,
        child: Image.memory(wallpaper.imageBytes!, fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildTopBar(ColorScheme cs, WidgetRef ref, TimerState timerState, QuoteState quote) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => ref.read(quoteProvider.notifier).nextQuote(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLow.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(quote.text, style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.75), height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
                    if (quote.author.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text('\u2014\u2014 ${quote.author}', style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant.withValues(alpha: 0.5), fontStyle: FontStyle.italic)),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SegmentedButton<TimerMode>(
            segments: const [
              ButtonSegment(value: TimerMode.pomodoro, label: Text('番茄', style: TextStyle(fontSize: 11)), icon: Icon(Icons.timer, size: 16)),
              ButtonSegment(value: TimerMode.stopwatch, label: Text('正向', style: TextStyle(fontSize: 11)), icon: Icon(Icons.trending_up, size: 16)),
            ],
            selected: {timerState.mode},
            onSelectionChanged: (Set<TimerMode> newSelection) {
              ref.read(timerProvider.notifier).switchMode(newSelection.first);
            },
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerCenter(ColorScheme cs, WidgetRef ref, TimerState timerState) {
    return AnimatedBuilder(
      animation: _timePulseAnim,
      builder: (context, child) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 1),
            Stack(
              alignment: Alignment.center,
              children: [
                TimerBackgroundAnimation(progress: timerState.progress, isRunning: timerState.isRunning, size: 300),
                Transform.scale(
                  scale: timerState.isRunning ? _timePulseAnim.value : 1.0,
                  child: Text(
                    timerState.formattedTime,
                    style: TextStyle(fontSize: 56, fontWeight: FontWeight.w200, letterSpacing: 6, color: cs.onSurface, shadows: [Shadow(color: cs.primary.withValues(alpha: 0.3), blurRadius: 20)]),
                  ),
                ),
              ],
            ),
            const Spacer(flex: 1),
          ],
        );
      },
    );
  }

  Widget _buildBottomControls(ColorScheme cs, WidgetRef ref, TimerState timerState) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 72, height: 72,
                child: FloatingActionButton(
                  heroTag: 'timer_main',
                  onPressed: () {
                    if (timerState.isRunning) { ref.read(timerProvider.notifier).pause(); }
                    else { ref.read(timerProvider.notifier).start(); }
                  },
                  backgroundColor: cs.primary,
                  child: Icon(timerState.isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 36, color: cs.onPrimary),
                ),
              ),
              const SizedBox(width: 32),
              SizedBox(
                width: 56, height: 56,
                child: FloatingActionButton(
                  heroTag: 'timer_reset',
                  onPressed: () => ref.read(timerProvider.notifier).reset(),
                  backgroundColor: cs.surfaceContainerHighest,
                  child: Icon(Icons.restart_alt_rounded, color: cs.onSurfaceVariant),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (timerState.mode == TimerMode.pomodoro)
            _PomodoroChips(currentMinutes: timerState.totalSeconds ~/ 60, onChanged: (m) => ref.read(timerProvider.notifier).setPomodoroMinutes(m)),
        ],
      ),
    );
  }
}

class _PomodoroChips extends StatelessWidget {
  final int currentMinutes;
  final ValueChanged<int> onChanged;
  const _PomodoroChips({required this.currentMinutes, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const durations = [5, 15, 25, 45, 60];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: durations.map((m) {
        final active = m == currentMinutes;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: ActionChip(
            label: Text('${m}min', style: TextStyle(fontSize: 11, fontWeight: active ? FontWeight.w600 : FontWeight.normal)),
            onPressed: () => onChanged(m),
            backgroundColor: active ? cs.primaryContainer : cs.surfaceContainerLow,
            side: BorderSide.none,
            visualDensity: VisualDensity.compact,
          ),
        );
      }).toList(),
    );
  }
}
