import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'widget_timer_animation.dart';
import 'provider_timer.dart';
import 'model_task_record.dart';
import 'provider_quotes.dart';
import 'provider_wallpaper.dart';

enum _OrientationMode { auto, portrait, landscape }

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
  _OrientationMode _orientationMode = _OrientationMode.auto;

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
    } else {
      await _restoreSystemUi();
    }
  }

  Future<void> _restoreSystemUi() async {
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
    );
    await SystemChrome.setPreferredOrientations(DeviceOrientation.values);
  }

  Future<void> _setOrientation(_OrientationMode mode) async {
    setState(() => _orientationMode = mode);
    switch (mode) {
      case _OrientationMode.auto:
        await SystemChrome.setPreferredOrientations(DeviceOrientation.values);
        return;
      case _OrientationMode.portrait:
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
        return;
      case _OrientationMode.landscape:
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final timerState = ref.watch(timerProvider);
    ref.listen<TimerState>(timerProvider, (previous, next) {
      final focusJustFinished = previous != null &&
          !previous.isBreak &&
          next.isBreak &&
          _immersiveFocus;
      if (focusJustFinished) {
        _setImmersive(false);
      }
    });
    final colorScheme = Theme.of(context).colorScheme;
    final quote = ref.watch(quoteProvider);

    // 动效控制：仅在运行时播放时间脉冲动画
    if (timerState.isRunning) {
      if (!_timePulseController.isAnimating) {
        _timePulseController.repeat(reverse: true);
      }
    } else if (_timePulseController.isAnimating) {
      _timePulseController.stop();
    }

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 420),
        reverseDuration: const Duration(milliseconds: 320),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.985, end: 1).animate(animation),
            child: child,
          ),
        ),
        child: _immersiveFocus
            ? _buildImmersiveView(colorScheme, timerState)
            : Stack(
                key: const ValueKey('normal_timer'),
                children: [
                  Container(color: colorScheme.surface),
                  _buildWallpaperBackground(),
                  SafeArea(
                    child: Column(
                      children: [
                        _buildTopBar(colorScheme, ref, timerState, quote),
                        Expanded(
                          child: _buildTimerCenter(
                            colorScheme,
                            ref,
                            timerState,
                          ),
                        ),
                        _buildBottomControls(colorScheme, ref, timerState),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildImmersiveView(ColorScheme cs, TimerState timerState) {
    return LayoutBuilder(
      key: const ValueKey('immersive_timer'),
      builder: (context, constraints) {
        final landscape = constraints.maxWidth > constraints.maxHeight;
        final artSize = (landscape
                ? constraints.maxHeight.clamp(260.0, 560.0)
                : constraints.maxWidth.clamp(280.0, 520.0))
            .toDouble();
        final visual = TweenAnimationBuilder<double>(
          tween: Tween<double>(
            end: timerState.progress.clamp(0.0, 1.0).toDouble(),
          ),
          duration:
              timerState.isRunning ? const Duration(seconds: 1) : Duration.zero,
          curve: Curves.linear,
          builder: (context, progress, child) => Stack(
            alignment: Alignment.center,
            children: [
              TimerBackgroundAnimation(
                progress: progress,
                isRunning: timerState.isRunning,
                size: artSize,
              ),
              ScaleTransition(
                scale: timerState.isRunning
                    ? _timePulseAnim
                    : const AlwaysStoppedAnimation<double>(1),
                child: Text(
                  timerState.formattedTime,
                  style: TextStyle(
                    fontSize: landscape ? 64 : 58,
                    fontWeight: FontWeight.w200,
                    letterSpacing: 7,
                    color: cs.onSurface,
                    shadows: [
                      Shadow(
                        color: cs.primary.withOpacity(0.45),
                        blurRadius: 28,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );

        final controls = _buildImmersiveControls(cs, timerState);
        return Stack(
          children: [
            Container(color: cs.surface),
            _buildWallpaperBackground(),
            SafeArea(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 420),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.03, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: landscape
                    ? Row(
                        key: const ValueKey('immersive_landscape'),
                        children: [
                          Expanded(flex: 3, child: Center(child: visual)),
                          Expanded(flex: 2, child: Center(child: controls)),
                        ],
                      )
                    : Column(
                        key: const ValueKey('immersive_portrait'),
                        children: [
                          Expanded(child: Center(child: visual)),
                          controls,
                          const SizedBox(height: 24),
                        ],
                      ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildImmersiveControls(ColorScheme cs, TimerState timerState) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: Text(
              timerState.isBreak
                  ? '休息'
                  : timerState.isRunning
                      ? '专注进行中'
                      : '专注已暂停',
              key: ValueKey('${timerState.isBreak}_${timerState.isRunning}'),
              style: TextStyle(
                color: cs.onSurfaceVariant,
                fontSize: 14,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton.large(
                heroTag: 'immersive_pause',
                onPressed: () {
                  final notifier = ref.read(timerProvider.notifier);
                  timerState.isRunning ? notifier.pause() : notifier.start();
                },
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: Icon(
                    timerState.isRunning
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    key: ValueKey(timerState.isRunning),
                    size: 36,
                  ),
                ),
              ),
              const SizedBox(width: 24),
              FloatingActionButton(
                heroTag: 'immersive_skip',
                onPressed: () {
                  if (!timerState.isBreak) {
                    ref.read(timerProvider.notifier).forceFinishFocus();
                  } else {
                    ref.read(timerProvider.notifier).reset();
                  }
                  _setImmersive(false);
                },
                child: const Icon(Icons.skip_next_rounded),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SegmentedButton<_OrientationMode>(
            segments: const [
              ButtonSegment(
                  value: _OrientationMode.auto,
                  icon: Icon(Icons.screen_rotation_rounded),
                  label: Text('自动')),
              ButtonSegment(
                  value: _OrientationMode.portrait,
                  icon: Icon(Icons.stay_current_portrait_rounded),
                  label: Text('竖屏')),
              ButtonSegment(
                  value: _OrientationMode.landscape,
                  icon: Icon(Icons.stay_current_landscape_rounded),
                  label: Text('横屏')),
            ],
            selected: {_orientationMode},
            onSelectionChanged: (value) => _setOrientation(value.first),
            showSelectedIcon: false,
          ),
          TextButton.icon(
            onPressed: () => _setImmersive(false),
            icon: const Icon(Icons.fullscreen_exit_rounded),
            label: const Text('退出沉浸'),
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

  Widget _buildTopBar(
      ColorScheme cs, WidgetRef ref, TimerState timerState, QuoteState quote) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => ref.read(quoteProvider.notifier).nextQuote(),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLow.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(quote.text,
                        style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurface.withOpacity(0.75),
                            height: 1.4),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    if (quote.author.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text('\u2014\u2014 ${quote.author}',
                          style: TextStyle(
                              fontSize: 10,
                              color: cs.onSurfaceVariant.withOpacity(0.5),
                              fontStyle: FontStyle.italic)),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SegmentedButton<TimerMode>(
            segments: const [
              ButtonSegment(
                  value: TimerMode.pomodoro,
                  label: Text('番茄', style: TextStyle(fontSize: 11)),
                  icon: Icon(Icons.timer, size: 16)),
              ButtonSegment(
                  value: TimerMode.stopwatch,
                  label: Text('正向', style: TextStyle(fontSize: 11)),
                  icon: Icon(Icons.trending_up, size: 16)),
            ],
            selected: {timerState.mode},
            onSelectionChanged: (Set<TimerMode> newSelection) {
              ref.read(timerProvider.notifier).switchMode(newSelection.first);
            },
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: WidgetStatePropertyAll(RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerCenter(
      ColorScheme cs, WidgetRef ref, TimerState timerState) {
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
                color: timerState.isBreak
                    ? cs.tertiaryContainer
                    : cs.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                timerState.isBreak ? '休息中' : '专注中',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: timerState.isBreak
                      ? cs.onTertiaryContainer
                      : cs.onPrimaryContainer,
                ),
              ),
            ),
          ),
        TweenAnimationBuilder<double>(
          tween: Tween<double>(
            end: timerState.progress.clamp(0.0, 1.0).toDouble(),
          ),
          duration:
              timerState.isRunning ? const Duration(seconds: 1) : Duration.zero,
          curve: Curves.linear,
          builder: (context, smoothProgress, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                TimerBackgroundAnimation(
                  progress: smoothProgress,
                  isRunning: timerState.isRunning,
                  size: 300,
                ),
                ScaleTransition(
                  scale: timerState.isRunning
                      ? _timePulseAnim
                      : const AlwaysStoppedAnimation<double>(1.0),
                  child: Text(
                    timerState.formattedTime,
                    style: TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.w200,
                      letterSpacing: 6,
                      color: cs.onSurface,
                      shadows: [
                        Shadow(
                          color: cs.primary.withOpacity(0.3),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        const Spacer(flex: 1),
      ],
    );
  }

  Widget _buildBottomControls(
      ColorScheme cs, WidgetRef ref, TimerState timerState) {
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
                    hintText: timerState.mode == TimerMode.pomodoro
                        ? '本次专注任务名...'
                        : '本次计时任务名...',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: cs.surfaceContainerLow.withOpacity(0.6),
                  ),
                  style: TextStyle(fontSize: 13, color: cs.onSurface),
                  onChanged: (v) => ref
                      .read(timerProvider.notifier)
                      .setCurrentTaskName(v.trim()),
                ),
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 72,
                height: 72,
                child: FloatingActionButton(
                  heroTag: 'timer_main',
                  onPressed: () {
                    final notifier = ref.read(timerProvider.notifier);
                    if (timerState.isRunning) {
                      notifier.pause();
                      return;
                    }
                    notifier.start();
                    if (timerState.mode == TimerMode.pomodoro &&
                        !timerState.isBreak) {
                      _setImmersive(true);
                    }
                  },
                  backgroundColor:
                      timerState.isRunning ? cs.secondary : cs.primary,
                  child: Icon(
                      timerState.isRunning
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      size: 36,
                      color: cs.onPrimary),
                ),
              ),
              const SizedBox(width: 32),
              // 正向计时：停止按钮（记录任务）
              if (timerState.mode == TimerMode.stopwatch &&
                  timerState.remainingSeconds > 0)
                SizedBox(
                  width: 56,
                  height: 56,
                  child: FloatingActionButton(
                    heroTag: 'timer_stop',
                    onPressed: () =>
                        ref.read(timerProvider.notifier).stopStopwatch(),
                    backgroundColor: cs.errorContainer,
                    child: Icon(Icons.stop_rounded, color: cs.onErrorContainer),
                  ),
                )
              else if (timerState.mode == TimerMode.pomodoro &&
                  timerState.isRunning &&
                  !timerState.isBreak)
                // 强制结束专注 → 进入休息
                SizedBox(
                  width: 56,
                  height: 56,
                  child: FloatingActionButton(
                    heroTag: 'timer_force',
                    onPressed: () =>
                        ref.read(timerProvider.notifier).forceFinishFocus(),
                    backgroundColor: cs.tertiaryContainer,
                    child: Icon(Icons.fast_forward_rounded,
                        color: cs.onTertiaryContainer),
                  ),
                )
              else
                SizedBox(
                  width: 56,
                  height: 56,
                  child: FloatingActionButton(
                    heroTag: 'timer_reset',
                    onPressed: () => ref.read(timerProvider.notifier).reset(),
                    backgroundColor: cs.surfaceContainerHighest,
                    child: Icon(Icons.restart_alt_rounded,
                        color: cs.onSurfaceVariant),
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
              onChanged: (m) =>
                  ref.read(timerProvider.notifier).setWorkMinutes(m),
            ),
            const SizedBox(height: 6),
            _DurationRow(
              label: '休息',
              currentMinutes: timerState.breakSeconds ~/ 60,
              durations: const [1, 3, 5, 10, 15],
              onChanged: (m) =>
                  ref.read(timerProvider.notifier).setBreakMinutes(m),
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
  const _DurationRow(
      {required this.label,
      required this.currentMinutes,
      required this.durations,
      required this.onChanged});

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
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(widget.label,
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: cs.onSurfaceVariant)),
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
                  label: Text('${m}min',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight:
                              active ? FontWeight.w600 : FontWeight.normal)),
                  onPressed: () {
                    _isCustom = false;
                    widget.onChanged(m);
                  },
                  backgroundColor:
                      active ? cs.primaryContainer : cs.surfaceContainerLow,
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
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                  hintText: '自定义',
                  hintStyle: TextStyle(
                      fontSize: 10,
                      color: cs.onSurfaceVariant.withOpacity(0.4)),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
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
            Text('min',
                style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
          ],
        ),
      ),
    ]);
  }
}
