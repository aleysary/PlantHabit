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
import '../../state/app_state.dart';
import '../habits/habit_editor_screen.dart';
import '../share/share_sheet.dart';
import 'celebrations.dart';

/// Stories 13, 14, 15: view the plant, interact with it, see its stages.
class PlantDetailScreen extends StatefulWidget {
  const PlantDetailScreen({super.key, required this.habitId});
  final String habitId;
  @override
  State<PlantDetailScreen> createState() => _PlantDetailScreenState();
}

class _PlantDetailScreenState extends State<PlantDetailScreen> {
  String? _bubble;
  int _bubbleKey = 0;

  void _onPlantTap(AppState s, Habit h) {
    setState(() {
      _bubble = plantChatter(s, h);
      _bubbleKey++;
    });
    final k = _bubbleKey;
    Future<void>.delayed(const Duration(seconds: 3), () {
      if (mounted && k == _bubbleKey) setState(() => _bubble = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final h = s.habitById(widget.habitId);
    if (h == null) return const Scaffold(body: Center(child: Text('This plant is no longer here.')));
    final v = context.v;
    final species = PlantCatalog.byId(h.speciesId);
    final n = s.validCount(h.id);
    final stage = s.stageOf(h);
    final next = AppState.growth.nextThreshold(n);
    final backdrop = v.backdropFor(h.potId);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              height: size.height * 0.58,
              decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: backdrop),
              ),
              child: SafeArea(
                bottom: false,
                child: Stack(
                  children: [
                    Positioned.fill(
                      top: 60,
                      bottom: 18,
                      child: Center(
                        child: PlantView(
                          speciesId: h.speciesId,
                          stage: stage,
                          potId: h.potId,
                          ambient: s.settings.ambientMotion,
                          interactive: true,
                          onTap: () => _onPlantTap(s, h),
                        ),
                      ),
                    ),
                    TopBar(
                      trailing: Row(children: [
                        RoundIconButton(
                          icon: Icons.ios_share_rounded,
                          tooltip: 'Share',
                          onTap: () => showShareSheet(context, focusHabitId: h.id),
                        ),
                        const SizedBox(width: 8),
                        RoundIconButton(
                          icon: Icons.tune_rounded,
                          tooltip: 'Edit habit',
                          onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => HabitEditorScreen(habitId: h.id))),
                        ),
                      ]),
                    ),
                    Positioned(
                      top: 70,
                      left: 24,
                      right: 24,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: _bubble == null
                            ? Center(
                                key: const ValueKey('hint'),
                                child: Pill('Tap your plant', icon: Icons.touch_app_rounded, color: v.card.o(0.8), dense: true),
                              )
                            : _SpeechBubble(key: ValueKey(_bubbleKey), text: _bubble!),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 40),
            sliver: SliverList.list(children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Eyebrow('${species.latin} · ${species.rarity.label}'),
                      const SizedBox(height: 6),
                      Text(s.plantLabel(h), style: context.text.displaySmall),
                    ]),
                  ),
                  Pill(PlantCatalog.stageName(species, stage), color: v.highlight, textColor: VerdantColors.ink),
                ],
              ),
              const SizedBox(height: 10),
              Row(children: [
                Icon(HabitCatalog.icon(h.iconKey), size: 16, color: v.muted),
                const SizedBox(width: 6),
                Expanded(child: Text('${h.name} · ${h.frequency.label}', style: context.text.bodyMedium?.copyWith(color: v.muted))),
              ]),
              const SizedBox(height: 22),
              _GrowthCard(n: n, next: next, species: species, stage: stage),
              const SizedBox(height: 14),
              _DoneTodayButton(habit: h),
              const SizedBox(height: 28),
              const SectionHeader('Growth stages', eyebrow: 'Your journey'),
              const SizedBox(height: 12),
              _StageStrip(habit: h, stage: stage, validCount: n),
              const SizedBox(height: 28),
              const SectionHeader('Recent care'),
              const SizedBox(height: 8),
              ...s.completionsFor(h.id).take(6).map((c) => _HistoryRow(day: c.day)),
              if (s.completionsFor(h.id).isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text('No care logged yet. Today’s a great day to start.', style: context.text.bodyMedium?.copyWith(color: v.muted)),
                ),
              const SizedBox(height: 24),
              _AboutSpecies(species: species),
            ]),
          ),
        ],
      ),
    );
  }
}

class _SpeechBubble extends StatelessWidget {
  const _SpeechBubble({super.key, required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.8, end: 1),
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutBack,
      builder: (_, s, child) => Transform.scale(scale: s, child: child),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: context.v.hero,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.o(0.15), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Text(text, textAlign: TextAlign.center, style: context.text.bodyMedium?.copyWith(color: context.v.onHero)),
      ),
    );
  }
}

class _GrowthCard extends StatelessWidget {
  const _GrowthCard({required this.n, required this.next, required this.species, required this.stage});
  final int n;
  final int? next;
  final PlantSpecies species;
  final int stage;
  @override
  Widget build(BuildContext context) {
    return VCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text(
              next == null ? 'Fully grown' : 'Next: ${PlantCatalog.stageName(species, stage + 1)}',
              style: context.text.titleMedium,
            ),
          ),
          Text(next == null ? '$n waterings' : '$n / $next', style: context.text.titleMedium?.copyWith(color: context.colors.primary)),
        ]),
        const SizedBox(height: 12),
        ProgressBar(value: AppState.growth.stageProgress(n), height: 8),
        const SizedBox(height: 10),
        Text(
          next == null
              ? 'Every completion keeps it thriving and counts toward badges.'
              : 'Each valid completion waters your plant. Only one per day counts.',
          style: context.text.bodySmall,
        ),
      ]),
    );
  }
}

class _DoneTodayButton extends StatelessWidget {
  const _DoneTodayButton({required this.habit});
  final Habit habit;
  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    if (!habit.isActive) {
      return OutlinedButton.icon(
        onPressed: () => s.restoreHabit(habit),
        icon: const Icon(Icons.restore_rounded),
        label: const Text('Resume tracking'),
      );
    }
    final done = s.isDoneToday(habit);
    final canLog = s.isDueToday(habit);
    return FilledButton.icon(
      onPressed: done || !canLog ? null : () => completeWithFeedback(context, habit),
      icon: Icon(done ? Icons.check_rounded : Icons.water_drop_rounded),
      label: Text(done ? 'Watered today' : (canLog ? 'Water it — mark done' : 'Weekly target reached')),
    );
  }
}

class _StageStrip extends StatelessWidget {
  const _StageStrip({required this.habit, required this.stage, required this.validCount});
  final Habit habit;
  final int stage;
  final int validCount;
  @override
  Widget build(BuildContext context) {
    final v = context.v;
    final species = PlantCatalog.byId(habit.speciesId);
    return SizedBox(
      height: 178,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: PlantCatalog.stages.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final st = PlantCatalog.stages[i];
          final reached = i <= stage;
          final current = i == stage;
          return Container(
            width: 112,
            padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
            decoration: BoxDecoration(
              color: current ? v.hero : v.card,
              borderRadius: BorderRadius.circular(VerdantTheme.radiusMd),
              border: Border.all(color: current ? v.hero : v.line),
            ),
            child: Column(children: [
              Expanded(
                child: PlantView(
                  speciesId: habit.speciesId,
                  stage: i,
                  potId: habit.potId,
                  silhouette: reached ? null : (v.isDark ? Colors.white.o(0.12) : Colors.black.o(0.12)),
                  showPot: true,
                ),
              ),
              const SizedBox(height: 6),
              Text(PlantCatalog.stageName(species, i),
                  style: context.text.labelLarge?.copyWith(color: current ? v.onHero : (reached ? v.text : v.muted))),
              Text(
                reached ? (current ? 'Now' : 'Reached') : '${st.threshold - validCount} to go',
                style: context.text.bodySmall?.copyWith(color: current ? v.highlight : v.muted),
              ),
            ]),
          );
        },
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.day});
  final DateTime day;
  @override
  Widget build(BuildContext context) {
    final rel = relativeDay(day);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: context.colors.primary, shape: BoxShape.circle)),
        const SizedBox(width: 14),
        Expanded(child: Text(DateFormat('EEEE, MMM d').format(day), style: context.text.bodyLarge)),
        if (rel.isNotEmpty) Text(rel, style: context.text.bodySmall),
      ]),
    );
  }
}

class _AboutSpecies extends StatelessWidget {
  const _AboutSpecies({required this.species});
  final PlantSpecies species;
  @override
  Widget build(BuildContext context) {
    return VCard(
      color: context.v.raised,
      border: false,
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Eyebrow('About this plant'),
            const SizedBox(height: 6),
            Text(species.vibe, style: context.text.headlineSmall),
            const SizedBox(height: 6),
            Text('Real-life care: ${species.care.toLowerCase()}.', style: context.text.bodyMedium?.copyWith(color: context.v.muted)),
          ]),
        ),
        SizedBox(height: 96, child: PlantView(speciesId: species.id, stage: 5, potId: 'ivory')),
      ]),
    );
  }
}
