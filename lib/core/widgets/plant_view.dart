import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../data/catalog/plant_catalog.dart';

/// Renders a plant in its pot: pot back → plant → pot front (→ trailing layer).
///
/// * [ambient] adds a slow breeze sway.
/// * [interactive] lets the user tap the plant to make it rustle (story 14);
///   [onTap] fires after the rustle starts.
/// * Changing [stage] cross-fades with a little "pop" so growth feels earned.
class PlantView extends StatefulWidget {
  const PlantView({
    super.key,
    required this.speciesId,
    required this.stage,
    required this.potId,
    this.ambient = false,
    this.interactive = false,
    this.onTap,
    this.silhouette,
    this.showPot = true,
  });

  final String speciesId;
  final int stage;
  final String potId;
  final bool ambient;
  final bool interactive;
  final VoidCallback? onTap;

  /// If set, draws the plant as a flat silhouette (used for locked stages).
  final Color? silhouette;
  final bool showPot;

  /// Plant art viewBox is 240×300.
  static const aspect = 240 / 300;

  @override
  State<PlantView> createState() => PlantViewState();
}

class PlantViewState extends State<PlantView> with TickerProviderStateMixin {
  late final AnimationController _breeze = AnimationController(vsync: this, duration: const Duration(milliseconds: 4200));
  late final AnimationController _rustle = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

  @override
  void initState() {
    super.initState();
    if (widget.ambient) _breeze.repeat();
  }

  @override
  void didUpdateWidget(covariant PlantView old) {
    super.didUpdateWidget(old);
    if (widget.ambient && !_breeze.isAnimating) _breeze.repeat();
    if (!widget.ambient && _breeze.isAnimating) _breeze.stop();
    if (old.stage != widget.stage) rustle();
  }

  @override
  void dispose() {
    _breeze.dispose();
    _rustle.dispose();
    super.dispose();
  }

  /// Plays the tap/grow rustle. Public so parents can trigger it.
  void rustle() => _rustle.forward(from: 0);

  @override
  Widget build(BuildContext context) {
    final species = PlantCatalog.byId(widget.speciesId);
    final pot = PlantCatalog.potById(widget.potId);
    final filter = widget.silhouette == null ? null : ColorFilter.mode(widget.silhouette!, BlendMode.srcIn);

    Widget layer(String asset, {Key? key}) => SvgPicture.asset(
          asset,
          key: key,
          fit: BoxFit.contain,
          colorFilter: filter,
          placeholderBuilder: (_) => const SizedBox.expand(),
        );

    final plant = AnimatedBuilder(
      animation: Listenable.merge([_breeze, _rustle]),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 520),
        switchInCurve: Curves.easeOutBack,
        layoutBuilder: (current, previous) => Stack(
          fit: StackFit.expand,
          children: [...previous, if (current != null) current],
        ),
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: ScaleTransition(scale: Tween(begin: 0.86, end: 1.0).animate(anim), alignment: const Alignment(0, 0.6), child: child),
        ),
        child: layer(species.asset(widget.stage), key: ValueKey('${widget.speciesId}-${widget.stage}')),
      ),
      builder: (context, child) {
        final b = math.sin(_breeze.value * math.pi * 2) * 0.012;
        final r = _rustle.value;
        final wobble = math.sin(r * math.pi * 5) * (1 - r) * 0.07;
        final squash = 1 + math.sin(r * math.pi) * 0.035;
        return Transform(
          // pivot on the soil line (y = 240 of 300 → alignment 0.6)
          alignment: const Alignment(0, 0.6),
          transform: Matrix4.identity()
            ..rotateZ(b + wobble)
            ..scale(1 / squash, squash, 1.0),
          child: child,
        );
      },
    );

    final front = species.frontAsset(widget.stage);

    Widget stack = AspectRatio(
      aspectRatio: PlantView.aspect,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (widget.showPot) layer(pot.back),
          plant,
          if (widget.showPot) layer(pot.front),
          if (front != null) layer(front),
        ],
      ),
    );

    if (widget.interactive) {
      stack = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          rustle();
          widget.onTap?.call();
        },
        child: stack,
      );
    }
    return stack;
  }
}

/// A plant on a soft backdrop "tile" — used in grids and cards.
class PlantTile extends StatelessWidget {
  const PlantTile({
    super.key,
    required this.speciesId,
    required this.stage,
    required this.potId,
    required this.backdrop,
    this.radius = 22,
    this.padding = const EdgeInsets.fromLTRB(10, 14, 10, 4),
    this.ambient = false,
  });

  final String speciesId;
  final int stage;
  final String potId;
  final List<Color> backdrop;
  final double radius;
  final EdgeInsets padding;
  final bool ambient;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: backdrop),
        ),
        child: Stack(
          children: [
            // a soft "tabletop" the pot sits on
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 30,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(10),
                  border: Border(top: BorderSide(color: Colors.white.withAlpha(60))),
                ),
              ),
            ),
            Padding(
              padding: padding,
              child: Center(child: PlantView(speciesId: speciesId, stage: stage, potId: potId, ambient: ambient)),
            ),
          ],
        ),
      ),
    );
  }
}
