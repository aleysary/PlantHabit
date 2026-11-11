import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/verdant_colors.dart';
import '../../core/theme/verdant_theme.dart';
import '../../core/widgets/plant_view.dart';
import '../../core/widgets/ui.dart';
import '../../data/catalog/habit_catalog.dart';
import '../../data/catalog/plant_catalog.dart';
import '../../data/models/models.dart';
import '../../domain/rules.dart';
import '../../state/app_state.dart';
import '../garden/celebrations.dart';
import '../garden/plant_detail_screen.dart';
import '../habits/habit_editor_screen.dart';
import '../habits/habit_library_screen.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key, required this.onOpenGarden});
  final VoidCallback onOpenGarden;

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 18) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final user = s.user;
    final habits = s.todayHabits;
    final settings = s.settings;

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 0),
            sliver: SliverList.list(children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Eyebrow(DateFormat('EEEE · MMM d')
                              .format(DateTime.now())),
                          const SizedBox(height: 8),
                          Text(
                              '${_greeting()},\n${user?.username ?? 'friend'}.',
                              style: context.text.displaySmall),
                        ]),
                  ),
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: context.v.highlight,
                    child: Text(user?.initials ?? '?',
                        style: context.text.titleMedium
                            ?.copyWith(color: VerdantColors.ink)),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              if (s.activeHabits.isEmpty)
                const _EmptyGarden()
              else ...[
                _HeroCard(onOpenGarden: onOpenGarden),
                if (settings.showWeekStrip) ...[
                  const SizedBox(height: 14),
                  const _WeekStrip()
                ],
                if (settings.showStreakCard) ...[
                  const SizedBox(height: 14),
                  const _StreakRow()
                ],
                const SizedBox(height: 28),
                const SectionHeader('Today’s care'),
                const SizedBox(height: 12),
              ],
            ]),
          ),
          if (habits.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              sliver: SliverList.separated(
                itemCount: habits.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) => HabitCareTile(habit: habits[i]),
              ),
            ),
          if (settings.showDailyQuote && s.activeHabits.isNotEmpty)
            const SliverPadding(
                padding: EdgeInsets.fromLTRB(22, 24, 22, 0),
                sliver: SliverToBoxAdapter(child: _QuoteCard())),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }
}

/// Dark hero: today's ring + the plant that's closest to growing.
class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.onOpenGarden});
  final VoidCallback onOpenGarden;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final v = context.v;
    final today = s.todayHabits;
    final ratio = today.isEmpty ? 0.0 : s.doneTodayCount / today.length;

    // feature the plant nearest to its next stage (or the most grown)
    final active = s.activeHabits;
    Habit featured = active.first;
    double best = -1;
    for (final h in active) {
      final score = s.plantProgress(h);
      if (score > best) {
        best = score;
        featured = h;
      }
    }
    final journey =
        s.cycleOf(featured)?.growthLabelAt(s.plantToday) ?? 'Ready to grow';
    final species = PlantCatalog.byId(s.speciesOf(featured));
    final stage = s.stageOf(featured);

    return Pressable(
      onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => PlantDetailScreen(habitId: featured.id))),
      child: Container(
        height: 236,
        decoration: BoxDecoration(
            color: v.hero,
            borderRadius: BorderRadius.circular(VerdantTheme.radiusLg)),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned(
              right: -30,
              bottom: -40,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                      colors: [species.tint.o(0.55), species.tint.o(0)]),
                ),
              ),
            ),
            Positioned(
              right: 4,
              top: 6,
              bottom: 0,
              child: AnimatedScale(
                  scale: 0.65 + 0.35 * s.plantProgress(featured),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutBack,
                  child: PlantView(
                      speciesId: s.speciesOf(featured),
                      stage: stage,
                      potId: s.potOf(featured),
                      ambient: s.settings.ambientMotion)),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ProgressRing(
                    value: ratio,
                    size: 74,
                    stroke: 8,
                    track: v.onHero.o(0.12),
                    child: Text('${s.doneTodayCount}/${today.length}',
                        style:
                            context.text.titleLarge?.copyWith(color: v.onHero)),
                  ),
                  const Spacer(),
                  Eyebrow('Spotlight', color: v.onHero.o(0.6)),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: 170,
                    child: Text(
                      stage == 5
                          ? '${s.plantLabel(featured)} is ${species.finalStageName.toLowerCase()}.'
                          : '${s.plantLabel(featured)} · $journey.',
                      style: context.text.headlineSmall
                          ?.copyWith(color: v.onHero, fontSize: 22),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Mon–Sun strip showing how much got done each day.
class _WeekStrip extends StatelessWidget {
  const _WeekStrip();
  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final v = context.v;
    final ws = Days.weekStart(Days.today());
    final total = s.activeHabits.length;
    return VCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Row(
        children: List.generate(7, (i) {
          final d = Days.add(ws, i);
          final count = s.completions.where((c) => Days.same(c.day, d)).length;
          final ratio = total == 0 ? 0.0 : (count / total).clamp(0.0, 1.0);
          final isToday = Days.same(d, Days.today());
          final future = d.isAfter(Days.today());
          return Expanded(
            child: Column(children: [
              Text(DateFormat('E').format(d).substring(0, 1),
                  style: context.text.labelSmall
                      ?.copyWith(color: isToday ? v.text : v.muted)),
              const SizedBox(height: 8),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: future
                      ? Colors.transparent
                      : Color.lerp(v.raised, context.colors.primary, ratio),
                  border: isToday
                      ? Border.all(color: v.text, width: 1.6)
                      : (future ? Border.all(color: v.line) : null),
                ),
                alignment: Alignment.center,
                child: Text('${d.day}',
                    style: context.text.labelMedium?.copyWith(
                        color: ratio > 0.5 && !future
                            ? context.colors.onPrimary
                            : v.text)),
              ),
            ]),
          );
        }),
      ),
    );
  }
}

class _StreakRow extends StatelessWidget {
  const _StreakRow();
  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppState>().stats;
    Widget tile(IconData icon, String value, String label, Color color) =>
        Expanded(
          child: VCard(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              IconSquare(icon,
                  size: 40, color: color.o(0.16), iconColor: color),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(value, style: context.text.titleLarge),
                Text(label, style: context.text.bodySmall),
              ]),
            ]),
          ),
        );
    return Row(children: [
      tile(Icons.local_fire_department_rounded, '${st.currentStreak} days',
          'Current streak', VerdantColors.terracotta),
      const SizedBox(width: 10),
      tile(Icons.water_drop_rounded, '${st.totalCompletions}',
          'Total waterings', context.colors.primary),
    ]);
  }
}

/// One habit in today's list (stories 10 & 12).
class HabitCareTile extends StatelessWidget {
  const HabitCareTile({super.key, required this.habit});
  final Habit habit;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final v = context.v;
    final done = s.isDoneToday(habit);
    final species = PlantCatalog.byId(s.speciesOf(habit));

    return VCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => PlantDetailScreen(habitId: habit.id))),
      child: Row(
        children: [
          IconSquare(HabitCatalog.icon(habit.iconKey),
              color: species.tint.o(0.14), iconColor: species.tint),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: context.text.titleMedium!.copyWith(
                    color: done ? v.muted : v.text,
                    decoration: done ? TextDecoration.lineThrough : null,
                    decorationColor: v.muted,
                  ),
                  child: Text(habit.name,
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(height: 4),
                Text(cadenceLabel(s, habit), style: context.text.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _CheckButton(
            done: done,
            onTap: () => done
                ? _confirmUndo(context, s)
                : completeWithFeedback(context, habit),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmUndo(BuildContext context, AppState s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Undo today?'),
        content: Text(
            'This removes today’s entry for “${habit.name}” and updates its care reward. Daily plant growth will also update.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Keep it')),
          TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Undo')),
        ],
      ),
    );
    if (ok == true) await s.undoToday(habit);
  }
}

class _CheckButton extends StatelessWidget {
  const _CheckButton({required this.done, required this.onTap});
  final bool done;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final v = context.v;
    return Semantics(
      button: true,
      label: done ? 'Completed. Tap to undo' : 'Mark complete',
      child: Pressable(
        onTap: onTap,
        scale: 0.88,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutBack,
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: done ? v.highlight : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: done ? v.highlight : v.line, width: 1.6),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
            child: done
                ? const Icon(Icons.check_rounded,
                    key: ValueKey('d'), color: VerdantColors.ink)
                : Icon(Icons.water_drop_outlined,
                    key: const ValueKey('n'), color: v.muted, size: 20),
          ),
        ),
      ),
    );
  }
}

class _QuoteCard extends StatelessWidget {
  const _QuoteCard();
  static const _quotes = [
    (
      'The best time to plant a tree was 20 years ago. The second best time is now.',
      'Proverb'
    ),
    ('We are what we repeatedly do.', 'Will Durant'),
    ('Small steps every day add up to big results.', 'Unknown'),
    ('To plant a garden is to believe in tomorrow.', 'Audrey Hepburn'),
  ];
  @override
  Widget build(BuildContext context) {
    final (q, a) = _quotes[DateTime.now().day % _quotes.length];
    return VCard(
      color: context.v.raised,
      border: false,
      padding: const EdgeInsets.all(22),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.format_quote_rounded, color: context.colors.primary),
        const SizedBox(height: 6),
        Text(q,
            style: context.text.headlineSmall
                ?.copyWith(fontSize: 21, height: 1.2)),
        const SizedBox(height: 10),
        Text('— $a', style: context.text.bodySmall),
      ]),
    );
  }
}

class _EmptyGarden extends StatelessWidget {
  const _EmptyGarden();
  @override
  Widget build(BuildContext context) {
    final v = context.v;
    return VCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: const [
                SizedBox(
                    height: 120,
                    child: PlantView(
                        speciesId: 'echeveria', stage: 0, potId: 'terracotta')),
                SizedBox(
                    height: 190,
                    child: PlantView(
                        speciesId: 'monstera',
                        stage: 1,
                        potId: 'ivory',
                        ambient: true)),
                SizedBox(
                    height: 120,
                    child:
                        PlantView(speciesId: 'tulip', stage: 0, potId: 'sage')),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('Your garden is waiting.',
              style: context.text.headlineMedium, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(
              'Create your first habit to plant its seed. Keep it up and watch your garden grow.',
              textAlign: TextAlign.center,
              style: context.text.bodyLarge?.copyWith(color: v.muted)),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => HabitSetupScreen(template: HabitCatalog.blank()))),
            child: const Text('Create your first habit'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => const HabitLibraryScreen())),
            child: const Text('Or start from an idea'),
          ),
        ],
      ),
    );
  }
}
