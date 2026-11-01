import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/verdant_colors.dart';
import '../../core/theme/verdant_theme.dart';

/// Brand wordmark: "verdant" set in Fraunces italic with a lime seed dot.
class VerdantWordmark extends StatelessWidget {
  const VerdantWordmark({super.key, this.size = 28, this.color});
  final double size;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    final c = color ?? context.v.text;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text('verdant',
            style: GoogleFonts.fraunces(fontSize: size, fontStyle: FontStyle.italic, fontWeight: FontWeight.w600, letterSpacing: -size * 0.04, color: c, height: 1)),
        Padding(
          padding: EdgeInsets.only(left: size * 0.08, bottom: size * 0.12),
          child: Container(width: size * 0.22, height: size * 0.22, decoration: const BoxDecoration(color: VerdantColors.lime, shape: BoxShape.circle)),
        ),
      ],
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: VerdantColors.ink,
      body: Center(child: VerdantWordmark(size: 44, color: VerdantColors.mist)),
    );
  }
}
