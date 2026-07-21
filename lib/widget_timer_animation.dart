import "dart:math";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "provider_wallpaper.dart";

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
    with TickerProviderStateMixin {
  late AnimationController _waveController;
  late Animation<double> _waveAnim;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    // 线性相位保证循环首尾速度一致，避免 easeInOut 周期减速造成顿挫。
    _waveAnim = Tween<double>(begin: 0, end: 2 * pi).animate(_waveController);
    if (widget.isRunning) {
      _waveController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant TimerBackgroundAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRunning == oldWidget.isRunning) return;
    if (widget.isRunning) {
      _waveController.repeat();
    } else {
      _waveController.stop(canceled: false);
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final wallpaper = ref.watch(wallpaperProvider);
    final skyTop =
        wallpaper.hasWallpaper ? wallpaper.mutedAccent : cs.primaryContainer;
    final skyBottom = wallpaper.hasWallpaper
        ? (wallpaper.lightMutedColor ?? wallpaper.mutedAccent.withAlpha(100))
        : cs.surface;
    final sunColor =
        wallpaper.hasWallpaper ? wallpaper.primaryAccent : cs.primary;

    return AnimatedBuilder(
      animation: _waveAnim,
      builder: (context, child) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            painter: _SunWavePainter(
              progress: widget.progress,
              waveOffset: _waveAnim.value,
              skyTop: skyTop,
              skyBottom: skyBottom,
              sunColor: sunColor,
            ),
          ),
        );
      },
    );
  }
}

class _SunWavePainter extends CustomPainter {
  final double progress, waveOffset;
  final Color skyTop, skyBottom, sunColor;

  _SunWavePainter({
    required this.progress,
    required this.waveOffset,
    required this.skyTop,
    required this.skyBottom,
    required this.sunColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height, cx = w / 2, cy = h / 2;

    // 天空渐变背景
    final skyRect = Rect.fromLTWH(0, 0, w, h);
    final skyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [skyTop, skyBottom],
      ).createShader(skyRect);
    final skyRrect =
        RRect.fromRectAndRadius(skyRect, const Radius.circular(24));
    final skyPath = Path()..addRRect(skyRrect);
    canvas.drawPath(skyPath, skyPaint);

    final seaLevel = h * 0.62;
    final phase = waveOffset;

    // ─── 远景海浪：先绘制在太阳背后，建立第一层景深 ───
    final distantSea = Path()..moveTo(0, seaLevel - h * 0.025);
    for (double x = 0; x <= w; x += 2) {
      final nx = x / w;
      distantSea.lineTo(
        x,
        seaLevel -
            h * 0.025 +
            sin(nx * 4 * pi + phase) * h * 0.012 +
            sin(nx * 8 * pi + phase * 2) * h * 0.005,
      );
    }
    distantSea
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.save();
    canvas.clipPath(skyPath);
    canvas.drawPath(
      distantSea,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            sunColor.withOpacity(0.16),
            skyBottom.withOpacity(0.32),
          ],
        ).createShader(Rect.fromLTWH(0, seaLevel - 20, w, h - seaLevel + 20)),
    );

    // ─── 太阳：按画布比例沿弧线移动 ───
    final safeProgress = progress.clamp(0.0, 1.0).toDouble();
    final sizeFactor = sin(pi * safeProgress);
    final sunX = w * (0.12 + 0.76 * safeProgress);
    final sunY = seaLevel + h * 0.06 - h * 0.48 * sizeFactor;
    final sunRadius = w * (0.065 + 0.035 * sizeFactor);
    final sunCenter = Offset(sunX, sunY);

    // 宽幅环境光束，越接近天空中央越明显。
    final beamPath = Path()
      ..moveTo(sunX - sunRadius * 0.5, sunY)
      ..lineTo(sunX - w * 0.28, seaLevel)
      ..lineTo(sunX + w * 0.28, seaLevel)
      ..lineTo(sunX + sunRadius * 0.5, sunY)
      ..close();
    canvas.drawPath(
      beamPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            sunColor.withOpacity(0.02),
            sunColor.withOpacity(0.12 + 0.08 * sizeFactor),
            sunColor.withOpacity(0),
          ],
        ).createShader(Rect.fromLTRB(0, sunY, w, seaLevel)),
    );

    // 三层柔光：环境晕、暖色晕、太阳边缘高光。
    for (final layer in const [3.8, 2.5, 1.55]) {
      final radius = sunRadius * layer;
      final alpha = layer == 3.8
          ? 0.10
          : layer == 2.5
              ? 0.18
              : 0.28;
      canvas.drawCircle(
        sunCenter,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [
              sunColor.withOpacity(alpha * (0.7 + sizeFactor * 0.3)),
              sunColor.withOpacity(0),
            ],
          ).createShader(Rect.fromCircle(center: sunCenter, radius: radius)),
      );
    }

    final sunBodyPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.28, -0.32),
        colors: [
          Colors.white.withOpacity(0.92),
          sunColor,
          sunColor.withOpacity(0.64),
        ],
        stops: const [0, 0.38, 1],
      ).createShader(Rect.fromCircle(center: sunCenter, radius: sunRadius));
    canvas.drawCircle(sunCenter, sunRadius, sunBodyPaint);

    // 海面碎金反射，会被后续中/前景海浪自然切割遮挡。
    final reflectionTop = max(sunY + sunRadius * 0.7, seaLevel - 8);
    final reflectionPath = Path()..moveTo(sunX, reflectionTop);
    const reflectionSegments = 14;
    for (var i = 0; i <= reflectionSegments; i++) {
      final t = i / reflectionSegments;
      final y = reflectionTop + (h - reflectionTop) * t;
      final halfWidth = w *
          (0.018 + t * 0.13) *
          (0.72 + 0.28 * sin(phase * 2 + i * 1.7).abs());
      reflectionPath.lineTo(sunX + halfWidth, y);
    }
    for (var i = reflectionSegments; i >= 0; i--) {
      final t = i / reflectionSegments;
      final y = reflectionTop + (h - reflectionTop) * t;
      final halfWidth = w *
          (0.018 + t * 0.13) *
          (0.72 + 0.28 * sin(phase * 2 + i * 1.7).abs());
      reflectionPath.lineTo(sunX - halfWidth, y);
    }
    reflectionPath.close();
    canvas.drawPath(
      reflectionPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            sunColor.withOpacity(0.30),
            sunColor.withOpacity(0.02),
          ],
        ).createShader(Rect.fromLTRB(0, reflectionTop, w, h)),
    );
    canvas.restore();

    // ─── 中景与前景波浪：绘制在太阳前方，实现出海/入海遮挡 ───
    final amplitude = h * (0.035 + 0.012 * safeProgress);

    // 主波浪
    final seaPath = Path()..moveTo(0, seaLevel);
    for (double x = 0; x <= w; x += 2) {
      final nx = x / w;
      final y = seaLevel +
          sin(nx * 1.8 * 2 * pi + waveOffset) * amplitude +
          sin(nx * 2.7 * pi * 1.8 + waveOffset * 2) * amplitude * 0.5 +
          sin(nx * 1.3 * pi * 1.8 + waveOffset * 3) * amplitude * 0.25;
      seaPath.lineTo(x, y);
    }
    seaPath
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();

    canvas.save();
    canvas.clipPath(skyPath);

    final seaPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          sunColor.withOpacity(0.45),
          sunColor.withOpacity(0.08),
        ],
      ).createShader(Rect.fromLTWH(
        0,
        seaLevel - amplitude * 2,
        w,
        h - seaLevel + amplitude * 2,
      ));
    canvas.drawPath(seaPath, seaPaint);

    // 次波浪
    final seaPath2 = Path()..moveTo(0, seaLevel + 4);
    for (double x = 0; x <= w; x += 2) {
      final y = seaLevel +
          4 +
          sin(x / w * 2.5 * 2 * pi + waveOffset) * amplitude * 0.4 +
          sin(x / w * 2 * 2 * pi + waveOffset * 2) * amplitude * 0.3;
      seaPath2.lineTo(x, y);
    }
    seaPath2
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(
        seaPath2,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              sunColor.withOpacity(0.3),
              sunColor.withOpacity(0.02),
            ],
          ).createShader(Rect.fromLTWH(
            0,
            seaLevel + 4,
            w,
            h - seaLevel,
          )));
    canvas.restore();

    // ─── 外圈进度环 ───
    canvas.drawCircle(
      Offset(cx, cy - 10),
      w * 0.42,
      Paint()
        ..color = Colors.white.withOpacity(0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    if (progress > 0.01) {
      final r = Rect.fromCircle(center: Offset(cx, cy - 10), radius: w * 0.42);
      canvas.drawArc(
        r,
        -pi / 2,
        2 * pi * progress,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..color = sunColor.withOpacity(0.8),
      );
    }

    // 边框
    canvas.drawPath(
      skyPath,
      Paint()
        ..color = Colors.white.withOpacity(0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant _SunWavePainter o) =>
      progress != o.progress ||
      waveOffset != o.waveOffset ||
      skyTop != o.skyTop ||
      skyBottom != o.skyBottom ||
      sunColor != o.sunColor;
}
