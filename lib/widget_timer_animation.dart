import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'provider_wallpaper.dart';

class TimerBackgroundAnimation extends ConsumerStatefulWidget {
  final double progress;
  final bool isRunning;
  final double size;

  const TimerBackgroundAnimation({
    super.key,
    required this.progress,
    this.isRunning = false,
    this.size = 320,
  });

  @override
  ConsumerState<TimerBackgroundAnimation> createState() =>
      _TimerBackgroundAnimationState();
}

class _TimerBackgroundAnimationState
    extends ConsumerState<TimerBackgroundAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );
    if (widget.isRunning) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant TimerBackgroundAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRunning == oldWidget.isRunning) return;
    widget.isRunning ? _controller.repeat() : _controller.stop(canceled: false);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final wallpaper = ref.watch(wallpaperProvider);
    final accent = wallpaper.hasWallpaper
        ? wallpaper.primaryAccent
        : cs.primary;
    final top = wallpaper.hasWallpaper
        ? Color.lerp(wallpaper.mutedAccent, const Color(0xFF10162D), 0.52)!
        : Color.lerp(cs.primaryContainer, const Color(0xFF10162D), 0.64)!;
    final bottom = wallpaper.hasWallpaper
        ? Color.lerp(
            wallpaper.lightMutedColor ?? wallpaper.mutedAccent,
            const Color(0xFF29405F),
            0.44,
          )!
        : Color.lerp(
            cs.surfaceContainerHighest,
            const Color(0xFF29405F),
            0.56,
          )!;
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) => SizedBox.square(
        dimension: widget.size,
        child: CustomPaint(
          painter: _MoonlitWavePainter(
            progress: widget.progress,
            phase: _controller.value * 2 * pi,
            skyTop: top,
            skyBottom: bottom,
            accent: accent,
          ),
        ),
      ),
    );
  }
}

class _MoonlitWavePainter extends CustomPainter {
  final double progress, phase;
  final Color skyTop, skyBottom, accent;

  const _MoonlitWavePainter({
    required this.progress,
    required this.phase,
    required this.skyTop,
    required this.skyBottom,
    required this.accent,
  });

  Path _wave(
    Size size,
    double level,
    double amplitude,
    double frequency,
    double offset,
  ) {
    final path = Path()..moveTo(0, level);
    for (double x = 0; x <= size.width + 2; x += 2) {
      final t = x / size.width;
      final y =
          level +
          sin(t * frequency * 2 * pi + phase + offset) * amplitude +
          sin(t * (frequency + 1.35) * 2 * pi - phase * 0.55) *
              amplitude *
              0.22;
      path.lineTo(x, y);
    }
    return path
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final rect = Offset.zero & size;
    final scene = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(w * 0.08)));
    final value = progress.clamp(0.0, 1.0).toDouble();
    final breath = 0.5 + 0.5 * sin(phase - pi / 3);
    final moon = Color.lerp(const Color(0xFFFFF4CE), accent, 0.12)!;
    final deep = Color.lerp(skyTop, const Color(0xFF061426), 0.66)!;
    final blue = Color.lerp(accent, const Color(0xFF7CB6D5), 0.48)!;

    canvas.save();
    canvas.clipPath(scene);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [skyTop, skyBottom, Color.lerp(skyBottom, deep, 0.28)!],
          stops: const [0, 0.68, 1],
        ).createShader(rect),
    );

    const stars = [
      Offset(.57, .16),
      Offset(.72, .24),
      Offset(.84, .13),
      Offset(.48, .32),
      Offset(.90, .37),
      Offset(.66, .40),
    ];
    for (var i = 0; i < stars.length; i++) {
      final alpha = .17 + .17 * (.5 + .5 * sin(phase * .7 + i * 1.9));
      canvas.drawCircle(
        Offset(stars[i].dx * w, stars[i].dy * h),
        w * (i.isEven ? .0042 : .003),
        Paint()..color = moon.withValues(alpha: alpha),
      );
    }

    final moonCenter = Offset(w * .245, h * .255);
    final moonRadius = w * .086;
    for (final scale in const [3.8, 2.7, 1.85]) {
      final radius = moonRadius * scale;
      final alpha = (.018 + (4.1 - scale) * .018) * (.82 + breath * .18);
      canvas.drawCircle(
        moonCenter,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [
              moon.withValues(alpha: alpha),
              moon.withValues(alpha: alpha * .4),
              moon.withValues(alpha: 0),
            ],
            stops: const [0, .52, 1],
          ).createShader(Rect.fromCircle(center: moonCenter, radius: radius)),
      );
    }
    canvas.drawCircle(
      moonCenter,
      moonRadius,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-.28, -.34),
          colors: [
            Colors.white.withValues(alpha: .98),
            moon.withValues(alpha: .96),
            Color.lerp(moon, accent, .22)!.withValues(alpha: .88),
          ],
          stops: const [0, .62, 1],
        ).createShader(Rect.fromCircle(center: moonCenter, radius: moonRadius)),
    );
    for (final crater in const [
      (Offset(-.28, -.10), .13),
      (Offset(.22, .24), .10),
      (Offset(.16, -.32), .07),
    ]) {
      canvas.drawCircle(
        moonCenter +
            Offset(crater.$1.dx * moonRadius, crater.$1.dy * moonRadius),
        moonRadius * crater.$2,
        Paint()..color = skyBottom.withValues(alpha: .10),
      );
    }

    final seaLevel = h * .64;
    final light = Path()
      ..moveTo(moonCenter.dx - moonRadius * .45, moonCenter.dy + moonRadius)
      ..lineTo(w * .10, h)
      ..lineTo(w * .58, h)
      ..lineTo(moonCenter.dx + moonRadius * .45, moonCenter.dy + moonRadius)
      ..close();
    canvas.drawPath(
      light,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            moon.withValues(alpha: .055),
            moon.withValues(alpha: .025 + breath * .018),
            moon.withValues(alpha: 0),
          ],
          stops: const [0, .58, 1],
        ).createShader(Rect.fromLTRB(0, moonCenter.dy, w, h)),
    );

    canvas.drawPath(
      _wave(size, seaLevel - h * .018, h * .010, 1.45, pi * .72),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [blue.withValues(alpha: .25), deep.withValues(alpha: .84)],
        ).createShader(Rect.fromLTRB(0, seaLevel - h * .05, w, h)),
    );

    for (var i = 0; i < 12; i++) {
      final t = i / 11;
      final y = seaLevel + h * (.018 + t * .31);
      final center =
          moonCenter.dx + sin(phase * .75 + i * 1.37) * w * .018 + t * w * .045;
      final half = w * (.025 + t * .105) * (.72 + .28 * sin(i * 2.2).abs());
      canvas.drawLine(
        Offset(center - half, y),
        Offset(center + half, y),
        Paint()
          ..shader = LinearGradient(
            colors: [
              moon.withValues(alpha: 0),
              moon.withValues(alpha: (.30 - t * .18) * (.86 + breath * .14)),
              moon.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromLTRB(center - half, y, center + half, y + 1))
          ..strokeWidth = max(1, w * (.006 - t * .002))
          ..strokeCap = StrokeCap.round,
      );
    }

    canvas.drawPath(
      _wave(size, seaLevel + h * .018, h * .020, 1.18, 0),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [blue.withValues(alpha: .34), deep.withValues(alpha: .94)],
          stops: const [0, .72],
        ).createShader(Rect.fromLTRB(0, seaLevel, w, h)),
    );
    final near = _wave(
      size,
      seaLevel + h * .09,
      h * (.025 + value * .004),
      .92,
      pi * 1.16,
    );
    canvas.drawPath(
      near,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [accent.withValues(alpha: .20), deep],
          stops: const [0, .76],
        ).createShader(Rect.fromLTRB(0, seaLevel, w, h)),
    );
    canvas.drawPath(
      near,
      Paint()
        ..color = moon.withValues(alpha: .12 + breath * .035)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1,
    );
    canvas.restore();

    final center = Offset(w / 2, h / 2 - h * .03), radius = w * .42;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = moon.withValues(alpha: .075)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2,
    );
    if (value > .002) {
      final arc = Rect.fromCircle(center: center, radius: radius);
      canvas.drawArc(
        arc,
        -pi / 2,
        2 * pi * value,
        false,
        Paint()
          ..color = moon.withValues(alpha: .16)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 7
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      canvas.drawArc(
        arc,
        -pi / 2,
        2 * pi * value,
        false,
        Paint()
          ..shader = SweepGradient(
            startAngle: -pi / 2,
            endAngle: 3 * pi / 2,
            colors: [
              moon.withValues(alpha: .42),
              moon.withValues(alpha: .88),
              accent.withValues(alpha: .66),
            ],
          ).createShader(arc)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.6
          ..strokeCap = StrokeCap.round,
      );
    }
    canvas.drawPath(
      scene,
      Paint()
        ..color = moon.withValues(alpha: .10)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  @override
  bool shouldRepaint(covariant _MoonlitWavePainter old) =>
      progress != old.progress ||
      phase != old.phase ||
      skyTop != old.skyTop ||
      skyBottom != old.skyBottom ||
      accent != old.accent;
}
