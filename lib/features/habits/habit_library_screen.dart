import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/verdant_colors.dart';
import '../../core/theme/verdant_theme.dart';
import '../../core/widgets/ui.dart';
import '../../data/catalog/habit_catalog.dart';
import '../../data/catalog/plant_catalog.dart';
import '../../data/models/models.dart';
import '../../domain/group_plants.dart';
import '../../state/app_state.dart';
import 'habit_editor_screen.dart';

/// Stories 5–9: the user's habits.
///
/// Creating your own habit comes first. A short list of ideas sits below it,
/// collapsed once you have habits of your own, and every idea opens in the
/// same editor so it can be renamed and re-timed before it is added.
/// Group plants live on the Garden tab, so they are not repeated here.
class HabitLibraryScreen extends StatefulWidget {
  const HabitLibraryScreen({super.key});
  @override
  State<HabitLibraryScreen> createState() => _HabitLibraryScreenState();
}

class _HabitLibraryScreenState extends State<HabitLibraryScreen> {
  bool? _ideasOpen;

  void _open(Widget screen) => Navigator.of(context)
      .push(MaterialPageRoute<void>(builder: (_) => screen));

  Future<void> _resume(AppState s, Habit h) async {
    try {
      await s.restoreHabit(h);
      if (mounted) {
        showToast(context, '${h.name} is back in your garden.',
            icon: Icons.spa_rounded);
      }
    } catch (_) {
      if (mounted) {
        showToast(context, 'Could not resume this habit. Please try again.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final active = s.activeHabits;
    final resting = s.archivedHabits;
    // Hide ideas the user already has, active or resting.
    final usedTemplates = s.habits.map((h) => h.templateId).toSet();
    final ideas = HabitCatalog.suggestions
        .where((t) => !usedTemplates.contains(t.id))
        .toList();
    final ideasOpen = _ideasOpen ?? active.isEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Habits')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 4, 22, 40),
          children: [
            const Eyebrow('Your habits'),
            const SizedBox(height: 8),
            Text('What will you\ngrow next?', style: context.text.displaySmall),
            const SizedBox(height: 18),
            _CreateCard(
                onTap: () => _open(HabitSetupScreen(
                    template: HabitCatalog.blank()))),
            const SizedBox(height: 28),
            SectionHeader('Tracking', eyebrow: '${active.length} active'),
            const SizedBox(height: 12),
            if (active.isEmpty)
              Text('No habits yet. Create one above to plant your first seed.',
                  style: context.text.bodyMedium
                      ?.copyWith(color: context.v.muted)),
            for (final h in active)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _HabitTile(
                  habit: h,
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _open(HabitEditorScreen(habitId: h.id)),
                ),
              ),
            if (resting.isNotEmpty) ...[
              const SizedBox(height: 18),
              SectionHeader('Resting',
                  eyebrow: 'Paused · history kept'),
              const SizedBox(height: 12),
              for (final h in resting)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _HabitTile(
                    habit: h,
                    muted: true,
                    trailing: TextButton(
                        onPressed: () => _resume(s, h),
                        child: const Text('Resume')),
                    onTap: () => _open(HabitEditorScreen(habitId: h.id)),
                  ),
                ),
            ],
            if (ideas.isNotEmpty) ...[
              const SizedBox(height: 18),
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => setState(() => _ideasOpen = !ideasOpen),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(children: [
                    Expanded(
                        child: Text('Need ideas?',
                            style: context.text.titleLarge)),
                    Icon(ideasOpen
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded),
                  ]),
                ),
              ),
              if (ideasOpen) ...[
                Text(
                    'A few examples to get you started. Tap one to make it your own.',
                    style: context.text.bodySmall),
                const SizedBox(height: 12),
                for (final t in ideas)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _IdeaTile(
                        template: t,
                        onTap: () => _open(HabitSetupScreen(template: t))),
                  ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _CreateCard extends StatelessWidget {
  const _CreateCard({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final v = context.v;
    return VCard(
      onTap: onTap,
      color: v.hero,
      border: false,
      padding: const EdgeInsets.all(20),
      child: Row(children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
              color: v.highlight, borderRadius: BorderRadius.circular(16)),
          child: const Icon(Icons.add_rounded, color: VerdantColors.ink),
        ),
        const SizedBox(width: 16),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Create your own habit',
                style: context.text.titleLarge?.copyWith(color: v.onHero)),
            const SizedBox(height: 4),
            Text('Name it, pick how often, and grow its plant.',
                style: context.text.bodySmall
                    ?.copyWith(color: v.onHero.o(0.7))),
          ]),
        ),
      ]),
    );
  }
}

class _HabitTile extends StatelessWidget {
  const _HabitTile(
      {required this.habit,
      required this.trailing,
      required this.onTap,
      this.muted = false});
  final Habit habit;
  final Widget trailing;
  final VoidCallback onTap;
  final bool muted;
  @override
  Widget build(BuildContext context) {
    final sp = PlantCatalog.byId(HabitGroup.of(habit.frequency).speciesId);
    return VCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      child: Row(children: [
        IconSquare(HabitCatalog.icon(habit.iconKey),
            color: sp.tint.o(0.14), iconColor: sp.tint),
        const SizedBox(width: 14),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(habit.name,
                style: context.text.titleMedium
                    ?.copyWith(color: muted ? context.v.muted : null)),
            const SizedBox(height: 3),
            Text(habit.frequency.label, style: context.text.bodySmall),
          ]),
        ),
        trailing,
      ]),
    );
  }
}

class _IdeaTile extends StatelessWidget {
  const _IdeaTile({required this.template, required this.onTap});
  final HabitTemplate template;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final sp =
        PlantCatalog.byId(HabitGroup.of(template.defaultFrequency).speciesId);
    return VCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      child: Row(children: [
        IconSquare(HabitCatalog.icon(template.iconKey),
            size: 40, color: sp.tint.o(0.14), iconColor: sp.tint),
        const SizedBox(width: 14),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(template.name, style: context.text.titleMedium),
            const SizedBox(height: 3),
            Text(template.defaultFrequency.label,
                style: context.text.bodySmall),
          ]),
        ),
        Icon(Icons.add_rounded, color: context.v.muted),
      ]),
    );
  }
}
