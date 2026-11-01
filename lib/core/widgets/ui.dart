import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/catalog/badge_catalog.dart';
import '../theme/verdant_colors.dart';
import '../theme/verdant_theme.dart';

/// SMALL CAPS label that sits above headings.
class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key, this.color});
  final String text;
  final Color? color;
  @override
  Widget build(BuildContext context) =>
      Text(text.toUpperCase(), style: context.text.labelSmall?.copyWith(color: color));
}

/// Flat card with a hairline border — the base surface of the app.
class VCard extends StatelessWidget {
  const VCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
    this.color,
    this.radius = VerdantTheme.radiusLg,
    this.border = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final double radius;
  final bool border;

  @override
  Widget build(BuildContext context) {
    final v = context.v;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: border ? BorderSide(color: v.line) : BorderSide.none,
    );
    return Material(
      color: color ?? v.card,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: onTap, child: Padding(padding: padding, child: child)),
    );
  }
}

/// Scales down slightly while pressed. Wrap any tappable.
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.child, this.onTap, this.scale = 0.97, this.haptic = true});
  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final bool haptic;
  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.onTap == null ? null : (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap == null
          ? null
          : () {
              if (widget.haptic) HapticFeedback.selectionClick();
              widget.onTap!();
            },
      child: AnimatedScale(
        scale: _down ? widget.scale : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Circular progress ring with rounded caps.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.value,
    this.size = 64,
    this.stroke = 7,
    this.color,
    this.track,
    this.child,
  });

  final double value;
  final double size;
  final double stroke;
  final Color? color;
  final Color? track;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOutCubic,
        builder: (context, v, child) => CustomPaint(
          painter: _RingPainter(v, stroke, color ?? context.v.highlight, track ?? context.v.line),
          child: Center(child: child),
        ),
        child: this.child,
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.v, this.stroke, this.color, this.track);
  final double v;
  final double stroke;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final r = rect.deflate(stroke / 2);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(r, 0, math.pi * 2, false, p..color = track);
    if (v > 0) canvas.drawArc(r, -math.pi / 2, math.pi * 2 * v, false, p..color = color);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.v != v || old.color != color || old.track != track;
}

/// Thin linear progress bar.
class ProgressBar extends StatelessWidget {
  const ProgressBar({super.key, required this.value, this.color, this.height = 6, this.track});
  final double value;
  final Color? color;
  final Color? track;
  final double height;
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: SizedBox(
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: track ?? context.v.line),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
              duration: const Duration(milliseconds: 650),
              curve: Curves.easeOutCubic,
              builder: (context, v, _) => FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: v,
                child: ColoredBox(color: color ?? context.colors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small rounded label.
class Pill extends StatelessWidget {
  const Pill(this.label, {super.key, this.color, this.textColor, this.icon, this.dense = false});
  final String label;
  final Color? color;
  final Color? textColor;
  final IconData? icon;
  final bool dense;
  @override
  Widget build(BuildContext context) {
    final fg = textColor ?? context.v.text;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: dense ? 8 : 10, vertical: dense ? 3 : 5),
      decoration: BoxDecoration(color: color ?? context.v.raised, borderRadius: BorderRadius.circular(99)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: dense ? 12 : 14, color: fg), const SizedBox(width: 4)],
          Text(label, style: context.text.labelMedium?.copyWith(color: fg, fontSize: dense ? 11 : 12)),
        ],
      ),
    );
  }
}

/// Segmented control made of pills.
class PillTabs<T> extends StatelessWidget {
  const PillTabs({super.key, required this.values, required this.selected, required this.label, required this.onChanged});
  final List<T> values;
  final T selected;
  final String Function(T) label;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final v = context.v;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: v.raised, borderRadius: BorderRadius.circular(99)),
      child: Row(
        children: [
          for (final item in values)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onChanged(item);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: item == selected ? v.card : Colors.transparent,
                    borderRadius: BorderRadius.circular(99),
                    boxShadow: item == selected
                        ? [BoxShadow(color: Colors.black.o(v.isDark ? 0.3 : 0.06), blurRadius: 8, offset: const Offset(0, 2))]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    label(item),
                    style: context.text.labelLarge?.copyWith(color: item == selected ? v.text : v.muted),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Square icon tile used for habit icons.
class IconSquare extends StatelessWidget {
  const IconSquare(this.icon, {super.key, this.size = 44, this.color, this.iconColor});
  final IconData icon;
  final double size;
  final Color? color;
  final Color? iconColor;
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color ?? context.v.raised, borderRadius: BorderRadius.circular(size * 0.32)),
        child: Icon(icon, size: size * 0.48, color: iconColor ?? context.v.text),
      );
}

/// Medal used for badges. Locked badges render muted.
class BadgeMedal extends StatelessWidget {
  const BadgeMedal({super.key, required this.icon, required this.tier, this.locked = false, this.size = 64});
  final IconData icon;
  final BadgeTier tier;
  final bool locked;
  final double size;

  @override
  Widget build(BuildContext context) {
    final v = context.v;
    final light = locked ? v.raised : tier.light;
    final dark = locked ? v.line : tier.dark;
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _MedalPainter(light, dark, locked),
        child: Center(
          child: Icon(locked ? Icons.lock_rounded : icon,
              size: size * (locked ? 0.32 : 0.42), color: locked ? v.muted : Color.lerp(dark, Colors.black, 0.35)),
        ),
      ),
    );
  }
}

class _MedalPainter extends CustomPainter {
  _MedalPainter(this.light, this.dark, this.locked);
  final Color light;
  final Color dark;
  final bool locked;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    // scalloped rosette
    final path = Path();
    const n = 12;
    for (var i = 0; i <= n * 2; i++) {
      final a = -math.pi / 2 + i * math.pi / n;
      final rr = i.isEven ? r : r * 0.9;
      final p = c + Offset(math.cos(a) * rr, math.sin(a) * rr);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [light, dark])
            .createShader(Offset.zero & size),
    );
    canvas.drawCircle(
      c,
      r * 0.7,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color.lerp(light, Colors.white, locked ? 0 : 0.45)!, light],
        ).createShader(Rect.fromCircle(center: c, radius: r * 0.7)),
    );
    canvas.drawCircle(
      c,
      r * 0.7,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = dark.o(0.35),
    );
  }

  @override
  bool shouldRepaint(_MedalPainter old) => old.light != light || old.dark != dark;
}

/// Back button + title row used on pushed screens.
class TopBar extends StatelessWidget {
  const TopBar({super.key, this.title, this.trailing, this.onBack});
  final String? title;
  final Widget? trailing;
  final VoidCallback? onBack;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        children: [
          RoundIconButton(icon: Icons.arrow_back_rounded, onTap: onBack ?? () => Navigator.of(context).maybePop()),
          const SizedBox(width: 12),
          if (title != null) Expanded(child: Text(title!, style: context.text.titleLarge, overflow: TextOverflow.ellipsis)) else const Spacer(),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class RoundIconButton extends StatelessWidget {
  const RoundIconButton({super.key, required this.icon, this.onTap, this.filled = false, this.size = 44, this.tooltip});
  final IconData icon;
  final VoidCallback? onTap;
  final bool filled;
  final double size;
  final String? tooltip;
  @override
  Widget build(BuildContext context) {
    final v = context.v;
    final btn = Pressable(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: filled ? v.hero : v.card,
          shape: BoxShape.circle,
          border: filled ? null : Border.all(color: v.line),
        ),
        child: Icon(icon, size: size * 0.45, color: filled ? v.onHero : v.text),
      ),
    );
    return tooltip == null ? btn : Tooltip(message: tooltip!, child: btn);
  }
}

/// Section title with optional action.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.action, this.onAction, this.eyebrow});
  final String title;
  final String? eyebrow;
  final String? action;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (eyebrow != null) ...[Eyebrow(eyebrow!), const SizedBox(height: 4)],
              Text(title, style: context.text.headlineSmall),
            ],
          ),
        ),
        if (action != null)
          TextButton(onPressed: onAction, child: Text(action!)),
      ],
    );
  }
}

/// Floating snackbar helper.
void showToast(BuildContext context, String message, {IconData? icon}) {
  final m = ScaffoldMessenger.of(context);
  m.hideCurrentSnackBar();
  m.showSnackBar(SnackBar(
    content: Row(children: [
      if (icon != null) ...[Icon(icon, size: 18, color: context.v.highlight), const SizedBox(width: 10)],
      Expanded(child: Text(message)),
    ]),
    duration: const Duration(milliseconds: 2600),
  ));
}

/// Primary button with built-in loading state.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({super.key, required this.label, required this.onPressed, this.loading = false, this.icon});
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;
  @override
  Widget build(BuildContext context) {
    final fg = context.v.isDark ? VerdantColors.ink : VerdantColors.mist;
    return FilledButton(
      onPressed: loading ? null : onPressed,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child: loading
            ? SizedBox.square(key: const ValueKey('l'), dimension: 20, child: CircularProgressIndicator(strokeWidth: 2.2, color: fg))
            : Row(
                key: const ValueKey('t'),
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label),
                  if (icon != null) ...[const SizedBox(width: 8), Icon(icon, size: 18)],
                ],
              ),
      ),
    );
  }
}
