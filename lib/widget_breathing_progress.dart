import 'dart:math';
import 'package:flutter/material.dart';

/// 呼吸阴影动画 + 波浪进度圆弧组件
class BreathingProgress extends StatefulWidget {
  const BreathingProgress({super.key, this.size = 200.0, this.progress = 0.0});
  final double size;
  final double progress;

  @override
  State<BreathingProgress> createState() => _BreathingProgressState();
}

class _BreathingProgressState extends State<BreathingProgress> with TickerProviderStateMixin {
  late AnimationController _breathController;
  late Animation<double> _shadowAnimation;

  @override
  void initState() {
    super.initState();
    _breathController = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
    _shadowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(CurvedAnimation(parent: _breathController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _breathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _shadowAnimation,
      builder: (context, child) {
        final shadowOpacity = _shadowAnimation.value;
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withOpacity(0.2 * shadowOpacity),
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
          primaryColor: Theme.of(context).colorScheme.primary,
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
  _WaveProgressPainter({required this.progress, required this.primaryColor, required this.surfaceColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final bgPaint = Paint()..color = surfaceColor..style = PaintingStyle.stroke..strokeWidth = 12;
    canvas.drawCircle(center, radius, bgPaint);

    final sweepAngle = 2 * pi * progress;
    if (sweepAngle > 0.01) {
      final wavePaint = Paint()
        ..shader = SweepGradient(colors: [primaryColor.withOpacity(0.6), primaryColor], startAngle: 0, endAngle: sweepAngle).createShader(rect)
        ..style = PaintingStyle.stroke..strokeWidth = 12..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, -pi / 2, sweepAngle, false, wavePaint);
    }

    final innerPaint = Paint()..color = primaryColor.withOpacity(0.1)..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius - 18, innerPaint);
  }

  @override
  bool shouldRepaint(covariant _WaveProgressPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.primaryColor != primaryColor || oldDelegate.surfaceColor != surfaceColor;
}