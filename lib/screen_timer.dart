import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'widget_timer_animation.dart';
import 'provider_timer.dart';
import 'model_task_record.dart';
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
  final _taskNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _timePulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    ); // 不自动 repeat，由 build 控制
    _timePulseAnim = Tween<double>(begin: 0.98, end: 1.02).animate(
      CurvedAnimation(parent: _timePulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _timePulseController.dispose();
    _taskNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timerState = ref.watch(timerProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final quote = ref.watch(quoteProvider);

    // 动效控制：仅在运行时播放时间脉冲动画
    if (timerState.isRunning) {
      if (!_timePulseController.isAnimating) _timePulseController.repeat(reverse: true);
    } else {
      if (_timePulseController.isAnimating) _timePulseController.stop();
    }

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
            // 阶段标签
            if (timerState.mode == TimerMode.pomodoro)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: timerState.isBreak ? cs.tertiaryContainer : cs.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    timerState.isBreak ? '休息中' : '专注中',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: timerState.isBreak ? cs.onTertiaryContainer : cs.onPrimaryContainer,
                    ),
                  ),
                ),
              ),
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
          // 任务名称输入
          if (!timerState.isRunning)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SizedBox(
                width: 240,
                child: TextField(
                  controller: _taskNameController,
                  decoration: InputDecoration(
                    hintText: timerState.mode == TimerMode.pomodoro ? '本次专注任务名...' : '本次计时任务名...',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: cs.surfaceContainerLow.withValues(alpha: 0.6),
                  ),
                  style: TextStyle(fontSize: 13, color: cs.onSurface),
                  onChanged: (v) => ref.read(timerProvider.notifier).setCurrentTaskName(v.trim()),
                ),
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 72, height: 72,
                child: FloatingActionButton(
                  heroTag: 'timer_main',
                  onPressed: () {
                    if (timerState.isRunning) { ref.read(timerProvider.notifier).pause(); }
                    else if (timerState.mode == TimerMode.stopwatch && timerState.remainingSeconds > 0) {
                      // 正向计时恢复
                      ref.read(timerProvider.notifier).start();
                    } else {
                      ref.read(timerProvider.notifier).start();
                    }
                  },
                  backgroundColor: timerState.isRunning ? cs.secondary : cs.primary,
                  child: Icon(timerState.isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 36, color: cs.onPrimary),
                ),
              ),
              const SizedBox(width: 32),
              // 正向计时：停止按钮（记录任务）
              if (timerState.mode == TimerMode.stopwatch && timerState.remainingSeconds > 0)
                SizedBox(
                  width: 56, height: 56,
                  child: FloatingActionButton(
                    heroTag: 'timer_stop',
                    onPressed: () => ref.read(timerProvider.notifier).stopStopwatch(),
                    backgroundColor: cs.errorContainer,
                    child: Icon(Icons.stop_rounded, color: cs.onErrorContainer),
                  ),
                )
              else
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
          const SizedBox(height: 12),
          if (timerState.mode == TimerMode.pomodoro) ...[
            _DurationRow(
              label: '专注',
              currentMinutes: timerState.workSeconds ~/ 60,
              durations: const [5, 15, 25, 45, 60],
              onChanged: (m) => ref.read(timerProvider.notifier).setWorkMinutes(m),
            ),
            const SizedBox(height: 6),
            _DurationRow(
              label: '休息',
              currentMinutes: timerState.breakSeconds ~/ 60,
              durations: const [1, 3, 5, 10, 15],
              onChanged: (m) => ref.read(timerProvider.notifier).setBreakMinutes(m),
            ),
          ],
        ],
      ),
    );
  }
}

class _DurationRow extends StatefulWidget {
  final String label;
  final int currentMinutes;
  final List<int> durations;
  final ValueChanged<int> onChanged;
  const _DurationRow({required this.label, required this.currentMinutes, required this.durations, required this.onChanged});

  @override
  State<_DurationRow> createState() => _DurationRowState();
}

class _DurationRowState extends State<_DurationRow> {
  final _customController = TextEditingController();
  bool _isCustom = false;

  @override
  void initState() {
    super.initState();
    _isCustom = !widget.durations.contains(widget.currentMinutes);
    if (_isCustom) {
      _customController.text = widget.currentMinutes.toString();
    }
  }

  @override
  void didUpdateWidget(covariant _DurationRow old) {
    super.didUpdateWidget(old);
    if (!_isCustom && !widget.durations.contains(widget.currentMinutes)) {
      _isCustom = true;
      _customController.text = widget.currentMinutes.toString();
    }
    if (_isCustom && widget.durations.contains(widget.currentMinutes)) {
      _isCustom = false;
    }
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  void _submitCustom() {
    final v = int.tryParse(_customController.text);
    if (v != null && v > 0) {
      _isCustom = true;
      widget.onChanged(v);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(widget.label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: cs.onSurfaceVariant)),
      const SizedBox(height: 4),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ...widget.durations.map((m) {
              final active = m == widget.currentMinutes && !_isCustom;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: ActionChip(
                  label: Text('${m}min', style: TextStyle(fontSize: 11, fontWeight: active ? FontWeight.w600 : FontWeight.normal)),
                  onPressed: () {
                    _isCustom = false;
                    widget.onChanged(m);
                  },
                  backgroundColor: active ? cs.primaryContainer : cs.surfaceContainerLow,
                  side: BorderSide.none,
                  visualDensity: VisualDensity.compact,
                ),
              );
            }),
            const SizedBox(width: 8),
            // 自定义输入
            SizedBox(
              width: 60,
              child: TextField(
                controller: _customController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                  hintText: '自定义',
                  hintStyle: TextStyle(fontSize: 10, color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: _isCustom ? cs.primaryContainer.withValues(alpha: 0.3) : cs.surfaceContainerLow,
                ),
                style: TextStyle(fontSize: 12, color: cs.onSurface),
                textAlign: TextAlign.center,
                onSubmitted: (_) => _submitCustom(),
                onEditingComplete: _submitCustom,
              ),
            ),
            const SizedBox(width: 4),
            Text('min', style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
          ],
        ),
      ),
    ]);
  }
}
