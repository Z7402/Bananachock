import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'provider_glass.dart';

/// 液态玻璃设计规范：统一圆角、模糊强度与弹簧动效参数。
abstract final class Glass {
  static const double cardRadius = 24;
  static const double dialogRadius = 28;
  static const double buttonRadius = 14;
  static const double blurSigma = 14;
  static const Curve spring = LiquidSpringCurve();
  static const Duration springDuration = Duration(milliseconds: 340);
  static const Duration quickDuration = Duration(milliseconds: 220);
}

/// 欠阻尼弹簧曲线（刚度≈380、阻尼≈32），带轻微回弹。
class LiquidSpringCurve extends Curve {
  const LiquidSpringCurve();

  @override
  double transformInternal(double t) {
    const omega = 19.5, zeta = 0.82;
    final damped = omega * math.sqrt(1 - zeta * zeta);
    return 1 - math.exp(-zeta * omega * t) * math.cos(damped * t);
  }
}

/// 核心玻璃容器：半透明填充 + 背景模糊 + 白色内描边 + 渐变高光 + 双层阴影。
/// [frosted] 为 true 时启用真实背景模糊（悬浮层/弹层）；列表内的内容卡片
/// 使用 false 以保证滚动流畅。全局关闭玻璃效果时自动退化为半透明纯色。
class LiquidGlass extends ConsumerWidget {
  final Widget child;
  final double radius;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final bool frosted;
  final bool shadow;
  final Color? tint;

  const LiquidGlass({
    super.key,
    required this.child,
    this.radius = Glass.cardRadius,
    this.borderRadius,
    this.padding,
    this.margin,
    this.frosted = false,
    this.shadow = false,
    this.tint,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final blurOn = frosted && ref.watch(glassEffectsProvider);
    final shape = borderRadius ?? BorderRadius.circular(radius);

    // 模糊关闭时提高不透明度，保证文字对比度。
    final baseFill = dark
        ? const Color(0xFF1E1E23).withValues(alpha: blurOn ? 0.55 : 0.78)
        : Colors.white.withValues(alpha: blurOn ? 0.55 : 0.80);
    final fill = tint == null
        ? baseFill
        : Color.alphaBlend(
            tint!.withValues(alpha: dark ? 0.22 : 0.16), baseFill);

    Widget panel = Container(
      padding: padding,
      decoration: BoxDecoration(color: fill, borderRadius: shape),
      foregroundDecoration: BoxDecoration(
        borderRadius: shape,
        border: Border.all(
          color: Colors.white.withValues(alpha: dark ? 0.16 : 0.55),
          width: 1,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: dark ? 0.07 : 0.16),
            Colors.white.withValues(alpha: 0),
          ],
          stops: const [0, 0.55],
        ),
      ),
      // 透明 Material 让 ListTile 等 Material 组件的墨水效果绘制在玻璃之上，
      // 也避免新版 Flutter "ink splashes may be invisible" 断言。
      child: Material(type: MaterialType.transparency, child: child),
    );
    if (blurOn) {
      panel = BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: Glass.blurSigma,
          sigmaY: Glass.blurSigma,
        ),
        child: panel,
      );
    }
    panel = ClipRRect(borderRadius: shape, child: panel);
    if (margin == null && !shadow) return panel;
    return Container(
      margin: margin,
      decoration: shadow
          ? BoxDecoration(
              borderRadius: shape,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: dark ? 0.30 : 0.08),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: dark ? 0.26 : 0.10),
                  blurRadius: 30,
                  offset: const Offset(0, 14),
                ),
              ],
            )
          : null,
      child: panel,
    );
  }
}

/// 按下缩放 + 降亮度、松开弹簧回弹的交互包装，可附带触觉反馈。
class GlassPressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double pressedScale;
  final bool haptic;

  const GlassPressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.pressedScale = 0.96,
    this.haptic = true,
  });

  @override
  State<GlassPressable> createState() => _GlassPressableState();
}

class _GlassPressableState extends State<GlassPressable> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value && mounted) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapCancel: () => _setPressed(false),
      onTapUp: (_) => _setPressed(false),
      onTap: widget.onTap == null
          ? null
          : () {
              if (widget.haptic) HapticFeedback.lightImpact();
              widget.onTap!();
            },
      onLongPress: widget.onLongPress,
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1,
        duration:
            _pressed ? const Duration(milliseconds: 90) : Glass.springDuration,
        curve: _pressed ? Curves.easeOut : Glass.spring,
        child: AnimatedOpacity(
          opacity: _pressed ? 0.82 : 1,
          duration: const Duration(milliseconds: 120),
          child: widget.child,
        ),
      ),
    );
  }
}

/// 柔和的多彩弥散渐变背景：以主题色渲染数个大范围柔光斑，衬托玻璃质感。
class MeshBackground extends StatelessWidget {
  const MeshBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return RepaintBoundary(
      child: CustomPaint(
        size: Size.infinite,
        painter: _MeshPainter(
          base: dark
              ? Color.lerp(cs.surface, const Color(0xFF0A0C13), 0.55)!
              : Color.lerp(cs.surface, Colors.white, 0.35)!,
          blobs: [
            (cs.primary, const Alignment(-0.9, -0.95), 0.95, dark ? .18 : .24),
            (cs.tertiary, const Alignment(1.1, -0.2), 0.75, dark ? .14 : .20),
            (cs.secondary, const Alignment(-0.3, 1.1), 0.85, dark ? .12 : .18),
          ],
        ),
      ),
    );
  }
}

class _MeshPainter extends CustomPainter {
  final Color base;
  final List<(Color, Alignment, double, double)> blobs;

  const _MeshPainter({required this.base, required this.blobs});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = base);
    final longest = size.longestSide;
    for (final (color, alignment, extent, alpha) in blobs) {
      final center = Offset(
        size.width * (alignment.x + 1) / 2,
        size.height * (alignment.y + 1) / 2,
      );
      final radius = longest * extent;
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [
              color.withValues(alpha: alpha),
              color.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromCircle(center: center, radius: radius)),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MeshPainter old) =>
      old.base != base || !listEquals(old.blobs, blobs);

  static bool listEquals(
    List<(Color, Alignment, double, double)> a,
    List<(Color, Alignment, double, double)> b,
  ) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// 顶栏玻璃填充：配合透明 AppBar 使用，内容滚动时从其背后透出并模糊。
class GlassAppBarFill extends ConsumerWidget {
  const GlassAppBarFill({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final blurOn = ref.watch(glassEffectsProvider);
    Widget fill = DecoratedBox(
      decoration: BoxDecoration(
        color: dark
            ? const Color(0xFF14141A).withValues(alpha: blurOn ? 0.42 : 0.72)
            : Colors.white.withValues(alpha: blurOn ? 0.45 : 0.75),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: dark ? 0.08 : 0.40),
            width: 1,
          ),
        ),
      ),
      child: const SizedBox.expand(),
    );
    if (blurOn) {
      fill = BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: Glass.blurSigma,
          sigmaY: Glass.blurSigma,
        ),
        child: fill,
      );
    }
    return ClipRect(child: fill);
  }
}

class GlassNavDestination {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const GlassNavDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}

/// 悬浮胶囊式毛玻璃底部导航栏。
class GlassNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final List<GlassNavDestination> destinations;

  const GlassNavBar({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
    required this.destinations,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      child: LiquidGlass(
        radius: 32,
        frosted: true,
        shadow: true,
        padding: const EdgeInsets.all(6),
        child: Row(
          children: [
            for (var i = 0; i < destinations.length; i++)
              Expanded(
                child: _GlassNavItem(
                  destination: destinations[i],
                  selected: i == selectedIndex,
                  onTap: () {
                    if (i != selectedIndex) {
                      HapticFeedback.selectionClick();
                      onSelected(i);
                    }
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _GlassNavItem extends StatelessWidget {
  final GlassNavDestination destination;
  final bool selected;
  final VoidCallback onTap;

  const _GlassNavItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return GlassPressable(
      onTap: onTap,
      haptic: false,
      child: AnimatedContainer(
        duration: Glass.springDuration,
        curve: Glass.spring,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? cs.primary.withValues(alpha: dark ? 0.24 : 0.16)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: selected
                ? Colors.white.withValues(alpha: dark ? 0.14 : 0.45)
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: Glass.quickDuration,
              switchInCurve: Curves.easeOutBack,
              child: Icon(
                selected ? destination.selectedIcon : destination.icon,
                key: ValueKey(selected),
                size: 24,
                color: selected
                    ? cs.primary
                    : cs.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              destination.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected
                    ? cs.primary
                    : cs.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 玻璃弹窗面板：标题 / 内容 / 操作按钮，配合 [showGlassDialog] 使用。
class GlassDialog extends StatelessWidget {
  final Widget? icon;
  final Widget? title;
  final Widget? content;
  final List<Widget> actions;

  const GlassDialog({
    super.key,
    this.icon,
    this.title,
    this.content,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: AnimatedPadding(
        duration: Glass.quickDuration,
        curve: Curves.easeOutCubic,
        padding: MediaQuery.viewInsetsOf(context),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: LiquidGlass(
                radius: Glass.dialogRadius,
                frosted: true,
                shadow: true,
                padding: const EdgeInsets.fromLTRB(24, 22, 24, 14),
                child: Material(
                  type: MaterialType.transparency,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (icon != null) ...[
                        IconTheme(
                          data: IconThemeData(
                            color: theme.colorScheme.primary,
                            size: 30,
                          ),
                          child: Center(child: icon!),
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (title != null) ...[
                        DefaultTextStyle(
                          style: theme.textTheme.titleLarge!
                              .copyWith(fontWeight: FontWeight.w700),
                          child: title!,
                        ),
                        const SizedBox(height: 14),
                      ],
                      if (content != null)
                        Flexible(
                          child: DefaultTextStyle(
                            style: theme.textTheme.bodyMedium!
                                .copyWith(height: 1.5),
                            child: content!,
                          ),
                        ),
                      if (actions.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            for (var i = 0; i < actions.length; i++) ...[
                              if (i > 0) const SizedBox(width: 8),
                              actions[i],
                            ],
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 弹出玻璃弹窗：背景动态加深并模糊，面板以弹簧曲线缩放入场。
Future<T?> showGlassDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  final blurOn = ProviderScope.containerOf(context, listen: false)
      .read(glassEffectsProvider);
  final dark = Theme.of(context).brightness == Brightness.dark;
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: '关闭',
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 320),
    pageBuilder: (ctx, _, __) => builder(ctx),
    transitionBuilder: (ctx, animation, _, child) {
      final fade = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      Widget backdrop = DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black
              .withValues(alpha: (dark ? 0.52 : 0.30) * fade.value),
        ),
        child: FadeTransition(
          opacity: fade,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.90, end: 1).animate(
              CurvedAnimation(
                parent: animation,
                curve: Glass.spring,
                reverseCurve: Curves.easeInCubic,
              ),
            ),
            child: child,
          ),
        ),
      );
      if (blurOn) {
        backdrop = BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 10 * fade.value,
            sigmaY: 10 * fade.value,
          ),
          child: backdrop,
        );
      }
      return backdrop;
    },
  );
}

/// 子页面过渡：轻微上移 + 淡入。
class GlassPageRoute<T> extends PageRouteBuilder<T> {
  GlassPageRoute({required WidgetBuilder builder})
      : super(
          transitionDuration: const Duration(milliseconds: 380),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          pageBuilder: (context, _, __) => builder(context),
          transitionsBuilder: (context, animation, _, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.05),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              ),
            );
          },
        );
}
