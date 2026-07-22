import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'widget_timer_animation.dart';
import 'provider_timer.dart';
import 'model_task_record.dart';
import 'provider_quotes.dart';
import 'provider_wallpaper.dart';

/// 计时器主页面：包含番茄钟倒计时 / 正向计时器
/// 集成海浪起伏+太阳东升西落动画、名言警句
class TimerScreen extends ConsumerStatefulWidget {
  final ValueChanged<bool>? onImmersiveChanged;

  const TimerScreen({super.key, this.onImmersiveChanged});

  @override
  ConsumerState<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends ConsumerState<TimerScreen>
    with TickerProviderStateMixin {
  late AnimationController _timePulseController;
  late Animation<double> _timePulseAnim;
  final _taskNameController = TextEditingController();
  bool _immersiveFocus = false;

  @override
  void initState() {
    super.initState();
    _timePulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _timePulseAnim = Tween<double>(begin: 0.98, end: 1.02).animate(
      CurvedAnimation(parent: _timePulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _restoreSystemUi();
    _timePulseController.dispose();
    _taskNameController.dispose();
    super.dispose();
  }

  Future<void> _setImmersive(bool value) async {
    if (_immersiveFocus == value) return;
    setState(() => _immersiveFocus = value);
    widget.onImmersiveChanged?.call(value);
    if (value) {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarIconBrightness: Brightness.light,
          systemStatusBarContrastEnforced: false,
          systemNavigationBarContrastEnforced: false,
        ),
      );
    } else {
      await _restoreSystemUi();
    }
  }

  Future<void> _restoreSystemUi() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    await SystemChrome.setPreferredOrientations(DeviceOrientation.values);
  }

  @override
  Widget build(BuildContext context) {
    final timerState = ref.watch(timerProvider);
    final cs = Theme.of(context).colorScheme;
    final quote = ref.watch(quoteProvider);

    // 监听休息状态切换，自动退出沉浸
    ref.listen<TimerState>(timerProvider, (previous, next) {
      if (previous != null &&
          !previous.isBreak &&
          next.isBreak &&
          _immersiveFocus) {
        _setImmersive(false);
      }
    });

    if (timerState.isRunning && !_timePulseController.isAnimating) {
      _timePulseController.repeat(reverse: true);
    } else if (!timerState.isRunning && _timePulseController.isAnimating) {
      _timePulseController.stop();
    }

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final landscape = constraints.maxWidth > constraints.maxHeight;
          final visualAlignment = _immersiveFocus
              ? (landscape
                    ? const Alignment(-0.48, -0.05)
                    : const Alignment(0, -0.30))
              : const Alignment(0, -0.16);
          final buttonAlignment = _immersiveFocus
              ? (landscape
                    ? const Alignment(0.56, 0.08)
                    : const Alignment(0, 0.50))
              : const Alignment(0, 0.28);
          return Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(color: cs.surface),
              _buildWallpaperBackground(),
              SafeArea(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 360),
                  opacity: _immersiveFocus ? 0 : 1,
                  child: IgnorePointer(
                    ignoring: _immersiveFocus,
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: _buildTopBar(cs, ref, timerState),
                    ),
                  ),
                ),
              ),
              AnimatedAlign(
                duration: const Duration(milliseconds: 620),
                curve: Curves.easeInOutCubicEmphasized,
                alignment: visualAlignment,
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 620),
                  curve: Curves.easeInOutCubicEmphasized,
                  scale: _immersiveFocus ? (landscape ? 0.72 : 0.82) : 1,
                  child: _buildSharedTimerVisual(cs, timerState),
                ),
              ),
              AnimatedAlign(
                duration: const Duration(milliseconds: 620),
                curve: Curves.easeInOutCubicEmphasized,
                alignment: buttonAlignment,
                child: _buildSharedPrimaryButton(cs, timerState),
              ),
              SafeArea(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: _immersiveFocus ? 0 : 1,
                  child: IgnorePointer(
                    ignoring: _immersiveFocus,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: _buildNormalOptions(cs, timerState),
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 420),
                  opacity: _immersiveFocus ? 1 : 0,
                  child: IgnorePointer(
                    ignoring: !_immersiveFocus,
                    child: Align(
                      alignment: landscape
                          ? const Alignment(0.58, 0.72)
                          : Alignment.bottomCenter,
                      child: _buildImmersiveSecondaryControls(cs, timerState),
                    ),
                  ),
                ),
              ),
              _buildFloatingQuote(cs, ref, timerState, quote, landscape),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSharedTimerVisual(ColorScheme cs, TimerState timerState) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(
        begin: 0,
        end: timerState.progress.clamp(0.0, 1.0).toDouble(),
      ),
      duration: timerState.isRunning
          ? const Duration(seconds: 1)
          : Duration.zero,
      curve: Curves.linear,
      builder: (context, progress, _) => SizedBox.square(
        dimension: 300,
        child: Stack(
          alignment: Alignment.center,
          children: [
            TimerBackgroundAnimation(
              progress: progress,
              isRunning: timerState.isRunning,
              size: 300,
            ),
            ScaleTransition(
              scale: timerState.isRunning
                  ? _timePulseAnim
                  : const AlwaysStoppedAnimation(1),
              child: Text(
                timerState.formattedTime,
                style: TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.w200,
                  letterSpacing: 6,
                  color: cs.onSurface,
                  shadows: [
                    Shadow(color: cs.primary.withOpacity(0.24), blurRadius: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSharedPrimaryButton(ColorScheme cs, TimerState timerState) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 620),
      width: _immersiveFocus ? 66 : 72,
      height: _immersiveFocus ? 66 : 72,
      child: FloatingActionButton(
        heroTag: 'shared_timer_primary',
        onPressed: () {
          final notifier = ref.read(timerProvider.notifier);
          if (timerState.isRunning) {
            notifier.pause();
          } else {
            notifier.start();
            if (timerState.mode == TimerMode.pomodoro && !timerState.isBreak) {
              _setImmersive(true);
            }
          }
        },
        backgroundColor: timerState.isRunning ? cs.secondary : cs.primary,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Icon(
            timerState.isRunning
                ? Icons.pause_rounded
                : Icons.play_arrow_rounded,
            key: ValueKey(timerState.isRunning),
            size: 34,
            color: cs.onPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildNormalOptions(ColorScheme cs, TimerState timerState) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!timerState.isRunning)
            SizedBox(
              width: 240,
              child: TextField(
                controller: _taskNameController,
                decoration: InputDecoration(
                  hintText:
                      '本次${timerState.mode == TimerMode.pomodoro ? '专注' : '计时'}任务名…',
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: cs.surfaceContainerLow.withOpacity(0.72),
                ),
                onChanged: (value) => ref
                    .read(timerProvider.notifier)
                    .setCurrentTaskName(value.trim()),
              ),
            ),
          const SizedBox(height: 12),
          if (timerState.mode == TimerMode.pomodoro && !timerState.isRunning)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _DurationRow(
                    label: '专注时长',
                    currentMinutes: timerState.workSeconds ~/ 60,
                    durations: const [15, 20, 25, 30, 45, 60],
                    onChanged: (m) =>
                        ref.read(timerProvider.notifier).setWorkMinutes(m),
                  ),
                  const SizedBox(height: 8),
                  _DurationRow(
                    label: '休息时长',
                    currentMinutes: timerState.breakSeconds ~/ 60,
                    durations: const [3, 5, 8, 10, 15, 20],
                    onChanged: (m) =>
                        ref.read(timerProvider.notifier).setBreakMinutes(m),
                  ),
                ],
              ),
            ),
          // 休息中 → 显示跳过按钮
          if (timerState.isRunning && timerState.isBreak) ...[
            const SizedBox(height: 4),
            OutlinedButton.icon(
              onPressed: () => ref.read(timerProvider.notifier).skipBreak(),
              icon: const Icon(Icons.skip_next_rounded),
              label: const Text('跳过休息'),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildImmersiveSecondaryControls(
    ColorScheme cs,
    TimerState timerState,
  ) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            timerState.isRunning
                ? (timerState.isBreak ? '休息中' : '专注进行中')
                : (timerState.isBreak ? '休息已暂停' : '专注已暂停'),
            style: TextStyle(color: cs.onSurfaceVariant, letterSpacing: 2),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (timerState.isBreak)
                IconButton.filledTonal(
                  tooltip: '跳过休息',
                  onPressed: () {
                    ref.read(timerProvider.notifier).skipBreak();
                    _setImmersive(false);
                  },
                  icon: const Icon(Icons.skip_next_rounded),
                )
              else
                IconButton.filledTonal(
                  tooltip: '结束本轮',
                  onPressed: () {
                    ref.read(timerProvider.notifier).forceFinishFocus();
                    _setImmersive(false);
                  },
                  icon: const Icon(Icons.skip_next_rounded),
                ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                tooltip: '退出沉浸',
                onPressed: () => _setImmersive(false),
                icon: const Icon(Icons.fullscreen_exit_rounded),
              ),
            ],
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
        opacity: wallpaper.opacity,
        child: Image.memory(wallpaper.imageBytes!, fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildFloatingQuote(
    ColorScheme cs,
    WidgetRef ref,
    TimerState timerState,
    QuoteState quote,
    bool landscape,
  ) {
    // 沉浸模式下 Quote 出现在底部控制区上方；普通模式在顶部。
    // 横屏沉浸: 引用在左侧区域上方; 竖屏: 在底部避开跳过/退出按钮(约80px)
    final immersiveBottomOffset = landscape ? 16.0 : 100.0;
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeInOutCubic,
      left: 16,
      right: 16,
      top: _immersiveFocus ? null : MediaQuery.paddingOf(context).top + 58,
      bottom: _immersiveFocus
          ? MediaQuery.paddingOf(context).bottom + immersiveBottomOffset
          : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 320),
        opacity: _immersiveFocus ? 0.82 : (quote.text.isNotEmpty ? 1.0 : 0.0),
        child: _buildQuoteChip(
          cs,
          quote,
          () => ref.read(quoteProvider.notifier).nextQuote(),
          immersive: _immersiveFocus,
        ),
      ),
    );
  }

  Widget _buildQuoteChip(
    ColorScheme cs,
    QuoteState quote,
    VoidCallback onTap, {
    bool immersive = false,
  }) {
    final bgOpacity = immersive ? 0.08 : 0.6;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow.withOpacity(bgOpacity),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              quote.text,
              style: TextStyle(
                fontSize: 12,
                color: cs.onSurface.withOpacity(0.75),
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (quote.author.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                '\u2014\u2014 ${quote.author}',
                style: TextStyle(
                  fontSize: 10,
                  color: cs.onSurfaceVariant.withOpacity(0.5),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(ColorScheme cs, WidgetRef ref, TimerState timerState) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          // 模式切换直接靠左，Quote 由浮动层独立控制
          SegmentedButton<TimerMode>(
            segments: const [
              ButtonSegment(
                value: TimerMode.pomodoro,
                label: Text('番茄', style: TextStyle(fontSize: 11)),
                icon: Icon(Icons.timer, size: 16),
              ),
              ButtonSegment(
                value: TimerMode.stopwatch,
                label: Text('正向', style: TextStyle(fontSize: 11)),
                icon: Icon(Icons.trending_up, size: 16),
              ),
            ],
            selected: {timerState.mode},
            onSelectionChanged: (Set<TimerMode> newSelection) {
              ref.read(timerProvider.notifier).switchMode(newSelection.first);
            },
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: WidgetStatePropertyAll(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
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
  const _DurationRow({
    required this.label,
    required this.currentMinutes,
    required this.durations,
    required this.onChanged,
  });

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
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: cs.onSurfaceVariant,
          ),
        ),
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
                    label: Text(
                      '${m}min',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: active
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                    onPressed: () {
                      _isCustom = false;
                      widget.onChanged(m);
                    },
                    backgroundColor: active
                        ? cs.primaryContainer
                        : cs.surfaceContainerLow,
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
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 6,
                    ),
                    hintText: '自定义',
                    hintStyle: TextStyle(
                      fontSize: 10,
                      color: cs.onSurfaceVariant.withOpacity(0.4),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: _isCustom
                        ? cs.primaryContainer.withOpacity(0.3)
                        : cs.surfaceContainerLow,
                  ),
                  style: TextStyle(fontSize: 12, color: cs.onSurface),
                  textAlign: TextAlign.center,
                  onSubmitted: (_) => _submitCustom(),
                  onEditingComplete: _submitCustom,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'min',
                style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
