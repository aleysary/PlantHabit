import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/verdant_colors.dart';
import '../../core/theme/verdant_theme.dart';
import '../../core/widgets/plant_view.dart';
import '../../core/widgets/ui.dart';
import '../../data/models/models.dart';
import '../../state/app_state.dart';

/// Story 26: customise appearance, layout and home widgets — with a live
/// preview before applying. Saved per user, so it survives logout/login.
class AppearanceScreen extends StatefulWidget {
  const AppearanceScreen({super.key});
  @override
  State<AppearanceScreen> createState() => _AppearanceScreenState();
}

class _AppearanceScreenState extends State<AppearanceScreen> {
  late AppSettings _draft = context.read<AppState>().settings;
  bool _saving = false;

  void _set(AppSettings s) => setState(() => _draft = s);

  Brightness _previewBrightness(BuildContext context) => switch (_draft.themeMode) {
        'light' => Brightness.light,
        'dark' => Brightness.dark,
        _ => MediaQuery.of(context).platformBrightness,
      };

  Future<void> _apply() async {
    setState(() => _saving = true);
    await context.read<AppState>().saveSettings(_draft);
    if (!mounted) return;
    setState(() => _saving = false);
    showToast(context, 'Appearance saved.', icon: Icons.palette_rounded);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final current = context.watch<AppState>().settings;
    final dirty = current.toJson().toString() != _draft.toJson().toString();
    final accent = AccentOption.values.firstWhere((a) => a.name == _draft.accent, orElse: () => AccentOption.moss);
    final previewTheme = VerdantTheme.build(brightness: _previewBrightness(context), accent: accent, compact: _draft.compact);

    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          TopBar(
            title: 'Appearance',
            trailing: TextButton(onPressed: () => _set(const AppSettings()), child: const Text('Reset')),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(22, 4, 22, 24),
              children: [
                const Eyebrow('Live preview'),
                const SizedBox(height: 10),
                AnimatedTheme(data: previewTheme, child: _Preview(settings: _draft)),
                const SizedBox(height: 26),
                const Eyebrow('Theme'),
                const SizedBox(height: 10),
                PillTabs<String>(
                  values: const ['system', 'light', 'dark'],
                  selected: _draft.themeMode,
                  label: (m) => m[0].toUpperCase() + m.substring(1),
                  onChanged: (m) => _set(_draft.copyWith(themeMode: m)),
                ),
                const SizedBox(height: 22),
                const Eyebrow('Accent colour'),
                const SizedBox(height: 12),
                Wrap(spacing: 14, runSpacing: 12, children: [
                  for (final a in AccentOption.values)
                    Pressable(
                      onTap: () => _set(_draft.copyWith(accent: a.name)),
                      child: Column(children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 52,
                          height: 52,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: a.name == _draft.accent ? context.v.text : Colors.transparent, width: 2),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: SweepGradient(colors: [a.primary, a.primary, a.highlight, a.highlight, a.primary], stops: const [0, 0.5, 0.5, 1, 1]),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(a.label, style: context.text.labelMedium),
                      ]),
                    ),
                ]),
                const SizedBox(height: 22),
                const Eyebrow('Layout'),
                const SizedBox(height: 10),
                VCard(
                  padding: EdgeInsets.zero,
                  child: Column(children: [
                    _SwitchRow(
                      title: 'Garden as list',
                      subtitle: 'Show plants in a list instead of a grid',
                      value: _draft.gardenLayout == GardenLayout.list,
                      onChanged: (x) => _set(_draft.copyWith(gardenLayout: x ? GardenLayout.list : GardenLayout.grid)),
                    ),
                    _SwitchRow(title: 'Compact density', subtitle: 'Tighter spacing on controls', value: _draft.compact, onChanged: (x) => _set(_draft.copyWith(compact: x))),
                    _SwitchRow(title: 'Ambient motion', subtitle: 'Plants sway gently in a breeze', value: _draft.ambientMotion, onChanged: (x) => _set(_draft.copyWith(ambientMotion: x))),
                  ]),
                ),
                const SizedBox(height: 22),
                const Eyebrow('Home widgets'),
                const SizedBox(height: 10),
                VCard(
                  padding: EdgeInsets.zero,
                  child: Column(children: [
                    _SwitchRow(title: 'Week strip', value: _draft.showWeekStrip, onChanged: (x) => _set(_draft.copyWith(showWeekStrip: x))),
                    _SwitchRow(title: 'Streak cards', value: _draft.showStreakCard, onChanged: (x) => _set(_draft.copyWith(showStreakCard: x))),
                    _SwitchRow(title: 'Daily quote', value: _draft.showDailyQuote, onChanged: (x) => _set(_draft.copyWith(showDailyQuote: x))),
                  ]),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 16),
            child: PrimaryButton(label: dirty ? 'Apply & save' : 'No changes', loading: _saving, onPressed: dirty ? _apply : null),
          ),
        ]),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({required this.title, required this.value, required this.onChanged, this.subtitle});
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: context.text.titleSmall),
              if (subtitle != null) Text(subtitle!, style: context.text.bodySmall),
            ]),
          ),
          Switch(value: value, onChanged: onChanged),
        ]),
      );
}

/// A miniature home screen rendered with the draft theme.
class _Preview extends StatelessWidget {
  const _Preview({required this.settings});
  final AppSettings settings;
  @override
  Widget build(BuildContext context) {
    final v = context.v;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(VerdantTheme.radiusLg),
        border: Border.all(color: v.line),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Good evening.', style: context.text.headlineSmall),
        const SizedBox(height: 10),
        Container(
          height: 120,
          decoration: BoxDecoration(color: v.hero, borderRadius: BorderRadius.circular(18)),
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            ProgressRing(value: 0.6, size: 56, stroke: 6, track: v.onHero.o(0.12), child: Text('3/5', style: context.text.labelLarge?.copyWith(color: v.onHero))),
            const Spacer(),
            const PlantView(speciesId: 'monstera', stage: 4, potId: 'terracotta'),
          ]),
        ),
        if (settings.showWeekStrip) ...[
          const SizedBox(height: 8),
          Row(children: List.generate(7, (i) => Expanded(
                child: Container(
                  height: 22,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: i < 4 ? context.colors.primary.o(0.25 + i * 0.18) : v.raised,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ))),
        ],
        if (settings.showStreakCard) ...[
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: Container(height: 34, decoration: BoxDecoration(color: v.card, borderRadius: BorderRadius.circular(10), border: Border.all(color: v.line)))),
            const SizedBox(width: 6),
            Expanded(child: Container(height: 34, decoration: BoxDecoration(color: v.card, borderRadius: BorderRadius.circular(10), border: Border.all(color: v.line)))),
          ]),
        ],
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: FilledButton(onPressed: () {}, child: const Text('Button'))),
          const SizedBox(width: 8),
          Pill('Accent', color: v.highlight, textColor: VerdantColors.ink),
        ]),
        if (settings.showDailyQuote) ...[
          const SizedBox(height: 8),
          Text('“To plant a garden is to believe in tomorrow.”', style: context.text.bodySmall),
        ],
      ]),
    );
  }
}
