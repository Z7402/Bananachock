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
  ConsumerState<TimerBackgroundAnimation> createState() => _TimerBackgroundAnimationState();
}

class _TimerBackgroundAnimationState extends ConsumerState<TimerBackgroundAnimation>
    with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _sunController;
  late Animation<double> _waveAnim;
  late Animation<double> _sunAnim;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
    _sunController = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
    _waveAnim = Tween<double>(begin: 0, end: 2 * pi).animate(CurvedAnimation(parent: _waveController, curve: Curves.easeInOut));
    _sunAnim = Tween<double>(begin: 0, end: 2 * pi).animate(CurvedAnimation(parent: _sunController, curve: Curves.linear));
  }

  @override
  void dispose() {
    _waveController.dispose();
    _sunController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final wallpaper = ref.watch(wallpaperProvider);
    final skyTop = wallpaper.hasWallpaper ? wallpaper.mutedAccent : cs.primaryContainer;
    final skyBottom = wallpaper.hasWallpaper ? (wallpaper.lightMutedColor ?? wallpaper.mutedAccent.withAlpha(100)) : cs.surface;
    final sunColor = wallpaper.hasWallpaper ? wallpaper.primaryAccent : cs.primary;

    return AnimatedBuilder(
      animation: Listenable.merge([_waveAnim, _sunAnim]),
      builder: (context, child) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            painter: _SunWavePainter(
              progress: widget.progress,
              waveOffset: _waveAnim.value,
              sunAngle: _sunAnim.value,
              skyTop: skyTop,
              skyBottom: skyBottom,
              sunColor: sunColor,
              isRunning: widget.isRunning,
            ),
          ),
        );
      },
    );
  }
}

class _SunWavePainter extends CustomPainter {
  final double progress, waveOffset, sunAngle;
  final Color skyTop, skyBottom, sunColor;
  final bool isRunning;

  _SunWavePainter({
    required this.progress, required this.waveOffset, required this.sunAngle,
    required this.skyTop, required this.skyBottom, required this.sunColor,
    this.isRunning = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height, cx = w / 2, cy = h / 2;
    final skyRect = Rect.fromLTWH(0, 0, w, h);
    final skyPaint = Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [skyTop, skyBottom]).createShader(skyRect);
    final skyPath = Path()..addRRect(RRect.fromRectAndRadius(skyRect, const Radius.circular(24)));
    canvas.drawPath(skyPath, skyPaint);

    final sunY = cy - 60 - 40 * sin(sunAngle * 2 + pi / 2);
    final sunProgressNorm = (sunY - (cy - 20)) / (-80);
    final sunRadius = 28 + 8 * sunProgressNorm.clamp(0.0, 1.0);

    canvas.drawCircle(Offset(cx, sunY), sunRadius * 2.2, Paint()..shader = RadialGradient(colors: [sunColor.withValues(alpha: 0.4), sunColor.withValues(alpha: 0)]).createShader(Rect.fromCircle(center: Offset(cx, sunY), radius: sunRadius * 2.2)));
    canvas.drawCircle(Offset(cx, sunY), sunRadius, Paint()..shader = RadialGradient(colors: [sunColor, sunColor.withValues(alpha: 0.6)], stops: const [0.3, 1.0]).createShader(Rect.fromCircle(center: Offset(cx, sunY), radius: sunRadius)));

    final seaLevel = cy + 40;
    final amplitude = 12.0 + 4 * (isRunning ? progress : 0.3);
    final seaPath = Path()..moveTo(0, seaLevel);
    for (double x = 0; x <= w; x += 2) {
      final nx = x / w;
      final y = seaLevel + sin(nx * 1.8 * 2 * pi + waveOffset) * amplitude
          + sin(nx * 2.7 * pi * 1.8 + waveOffset * 1.3) * amplitude * 0.5
          + sin(nx * 1.3 * pi * 1.8 + waveOffset * 1.7) * amplitude * 0.25;
      seaPath.lineTo(x, y);
    }
    seaPath..lineTo(w, h)..lineTo(0, h)..close();
    final seaPaint = Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [sunColor.withValues(alpha: 0.45), sunColor.withValues(alpha: 0.08)]).createShader(Rect.fromLTWH(0, seaLevel - amplitude * 2, w, h - seaLevel + amplitude * 2));
    canvas.save(); canvas.clipPath(skyPath); canvas.drawPath(seaPath, seaPaint);

    final seaPath2 = Path()..moveTo(0, seaLevel + 4);
    for (double x = 0; x <= w; x += 2) {
      final y = seaLevel + 4 + sin(x / w * 2.5 * 2 * pi + waveOffset * 0.8) * amplitude * 0.4 + sin(x / w * 2 * 2 * pi + waveOffset * 1.5) * amplitude * 0.3;
      seaPath2.lineTo(x, y);
    }
    seaPath2..lineTo(w, h)..lineTo(0, h)..close();
    canvas.drawPath(seaPath2, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [sunColor.withValues(alpha: 0.3), sunColor.withValues(alpha: 0.02)]).createShader(Rect.fromLTWH(0, seaLevel + 4, w, h - seaLevel)));
    canvas.restore();

    canvas.drawCircle(Offset(cx, cy - 10), w * 0.42, Paint()..color = Colors.white.withValues(alpha: 0.15)..style = PaintingStyle.stroke..strokeWidth = 3);
    if (progress > 0.01) {
      final r = Rect.fromCircle(center: Offset(cx, cy - 10), radius: w * 0.42);
      canvas.drawArc(r, -pi / 2, 2 * pi * progress, false, Paint()..style = PaintingStyle.stroke..strokeWidth = 3..strokeCap = StrokeCap.round..color = sunColor.withValues(alpha: 0.8));
    }
    canvas.drawPath(skyPath, Paint()..color = Colors.white.withValues(alpha: 0.12)..style = PaintingStyle.stroke..strokeWidth = 1.5);
  }

  @override
  bool shouldRepaint(covariant _SunWavePainter o) =>
      progress != o.progress || waveOffset != o.waveOffset || sunAngle != o.sunAngle || skyTop != o.skyTop || skyBottom != o.skyBottom || sunColor != o.sunColor || isRunning != o.isRunning;
}
