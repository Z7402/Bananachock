import 'dart:math';
import 'package:flutter/material.dart';

/// 呼吸阴影动画 + 波浪进度圆弧组件
/// 仅在 isRunning=true 且 progress>0 时运行动画
class BreathingProgress extends StatefulWidget {
  const BreathingProgress({
    super.key,
    this.size = 200.0,
    this.progress = 0.0,
    this.isRunning = false,
  });
  final double size;
  final double progress;
  final bool isRunning;

  @override
  State<BreathingProgress> createState() => _BreathingProgressState();
}

class _BreathingProgressState extends State<BreathingProgress>
    with TickerProviderStateMixin {
  AnimationController? _breathController;
  Animation<double>? _shadowAnimation;
  bool get _shouldAnimate => widget.isRunning && widget.progress > 0;

  @override
  void initState() {
    super.initState();
    if (_shouldAnimate) {
      _ensureController();
    }
  }

  @override
  void didUpdateWidget(covariant BreathingProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    final wasRunning = oldWidget.isRunning && oldWidget.progress > 0;
    if (_shouldAnimate && !wasRunning) {
      _ensureController();
    } else if (!_shouldAnimate && wasRunning) {
      _disposeController();
    }
  }

  void _ensureController() {
    if (_breathController != null) return;
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _shadowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _breathController!, curve: Curves.easeInOut),
    );
  }

  void _disposeController() {
    _breathController?.dispose();
    _breathController = null;
    _shadowAnimation = null;
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final running = _shouldAnimate;
    final colorScheme = Theme.of(context).colorScheme;

    if (!running) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _WaveProgressPainter(
            progress: widget.progress,
            primaryColor: colorScheme.primary,
            surfaceColor: colorScheme.surfaceContainerHighest,
          ),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _shadowAnimation!,
      builder: (context, child) {
        final shadowOpacity = _shadowAnimation!.value;
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withValues(
                  alpha: 0.2 * shadowOpacity,
                ),
                blurRadius: 24 * shadowOpacity + 8,
                spreadRadius: 8 * shadowOpacity,
              ),
            ],
          ),
          child: child,
        );
      },
      child: CustomPaint(
        size: Size(widget.size, widget.size),
        painter: _WaveProgressPainter(
          progress: widget.progress,
          primaryColor: colorScheme.primary,
          surfaceColor: colorScheme.surfaceContainerHighest,
        ),
      ),
    );
  }
}

class _WaveProgressPainter extends CustomPainter {
  final double progress;
  final Color primaryColor;
  final Color surfaceColor;
  _WaveProgressPainter({
    required this.progress,
    required this.primaryColor,
    required this.surfaceColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final bgPaint = Paint()
      ..color = surfaceColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;
    canvas.drawCircle(center, radius, bgPaint);

    final sweepAngle = 2 * pi * progress;
    if (sweepAngle > 0.01) {
      final wavePaint = Paint()
        ..shader = SweepGradient(
          colors: [
            primaryColor.withValues(alpha: 0.6),
            primaryColor,
          ],
          startAngle: 0,
          endAngle: sweepAngle,
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, -pi / 2, sweepAngle, false, wavePaint);
    }

    final innerPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius - 18, innerPaint);
  }

  @override
  bool shouldRepaint(covariant _WaveProgressPainter oldDelegate) =>
      oldDelegate.progress != progress
      || oldDelegate.primaryColor != primaryColor
      || oldDelegate.surfaceColor != surfaceColor;
}
