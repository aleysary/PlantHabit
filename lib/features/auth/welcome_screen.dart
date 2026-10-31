import 'package:flutter/material.dart';

import '../../core/theme/verdant_colors.dart';
import '../../core/theme/verdant_theme.dart';
import '../../core/widgets/plant_view.dart';
import '../shell/splash_screen.dart';
import 'auth_screens.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    return Scaffold(
      backgroundColor: VerdantColors.ink,
      body: Column(
        children: [
          Expanded(
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(24, 12, 24, 0),
                    child: Row(children: [VerdantWordmark(size: 26, color: VerdantColors.mist), Spacer()]),
                  ),
                  Expanded(
                    child: LayoutBuilder(builder: (context, c) {
                      final h = c.maxHeight;
                      return Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          // soft halo
                          Positioned(
                            bottom: h * 0.08,
                            child: Container(
                              width: h * 0.9,
                              height: h * 0.9,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(colors: [VerdantColors.fern.o(0.35), VerdantColors.ink.o(0)]),
                              ),
                            ),
                          ),
                          Positioned(left: -h * 0.04, bottom: 0, height: h * 0.62, child: const PlantView(speciesId: 'monstera', stage: 4, potId: 'terracotta', ambient: true)),
                          Positioned(right: -h * 0.03, bottom: 0, height: h * 0.58, child: const PlantView(speciesId: 'bird_of_paradise', stage: 5, potId: 'midnight', ambient: true)),
                          Positioned(bottom: 0, height: h * 0.86, child: const PlantView(speciesId: 'cherry_blossom', stage: 5, potId: 'ivory', ambient: true)),
                        ],
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            ),
            padding: EdgeInsets.fromLTRB(24, 28, 24, 20 + MediaQuery.of(context).padding.bottom),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Grow a garden,\none habit at a time.', style: t.displaySmall),
                const SizedBox(height: 12),
                Text(
                  'Every habit you keep waters a plant. Miss a day and it waits for you. Keep going and watch it bloom.',
                  style: t.bodyLarge?.copyWith(color: context.v.muted),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const RegisterScreen())),
                  child: const Text('Start growing'),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const LoginScreen())),
                  child: const Text('I already have an account'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
