import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/verdant_colors.dart';
import '../../core/theme/verdant_theme.dart';
import '../../core/widgets/plant_view.dart';
import '../../core/widgets/ui.dart';
import '../../data/catalog/badge_catalog.dart';
import '../../data/catalog/plant_catalog.dart';
import '../../data/models/models.dart';
import '../../domain/rules.dart';
import '../../domain/group_plants.dart';
import '../../state/app_state.dart';

/// Records a completion and plays the right feedback: toast, growth
/// celebration and/or new-badge reveal. Used by every "done" button.
Future<void> completeWithFeedback(BuildContext context, Habit habit) async {
  final state = context.read<AppState>();
  try {
    final outcome = await state.complete(habit);
    if (!context.mounted) return;
    if (!outcome.accepted) {
      HapticFeedback.heavyImpact();
      showToast(context, outcome.status.message,
          icon: Icons.info_outline_rounded);
      return;
    }
    HapticFeedback.mediumImpact();
    if (outcome.grewStage) {
      await showGrowthCelebration(context, habit, outcome.stageAfter);
    } else {
      final label = state.plantLabel(habit);
      final checklist = state
          .cycleOf(habit)
          ?.dailyChecklist(state.completions, state.plantToday);
      showToast(
        context,
        HabitGroup.of(habit.frequency) == HabitGroup.daily
            ? 'Today: ${checklist?.completed ?? 0}/${checklist?.required ?? 0} habits complete · ${state.cycleOf(habit)?.dailyCompletedDays ?? 0} of 7 completed days.'
            : 'Care recorded for $label · ${state.cycleOf(habit)?.growthLabelAt(state.plantToday) ?? 'Your journey has started'}.',
        icon: Icons.water_drop_rounded,
      );
    }
    for (final b in outcome.newBadges) {
      if (!context.mounted) return;
      await showBadgeEarned(context, b);
    }
  } catch (_) {
    if (context.mounted)
      showToast(
          context, 'Couldn’t save that. Check your connection and try again.',
          icon: Icons.cloud_off_rounded);
  }
}

Future<void> showGrowthCelebration(
    BuildContext context, Habit habit, int stage) {
  final state = context.read<AppState>();
  final species = PlantCatalog.byId(state.speciesOf(habit));
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close',
    barrierColor: VerdantColors.ink.o(0.86),
    transitionDuration: const Duration(milliseconds: 380),
    transitionBuilder: (context, a, _, child) => FadeTransition(
      opacity: a,
      child: ScaleTransition(
          scale: Tween(begin: 0.92, end: 1.0)
              .animate(CurvedAnimation(parent: a, curve: Curves.easeOutBack)),
          child: child),
    ),
    pageBuilder: (context, _, __) => SafeArea(
      child: Material(
        type: MaterialType.transparency,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              const Spacer(),
              Pill('NEW STAGE',
                  color: VerdantColors.lime, textColor: VerdantColors.ink),
              const SizedBox(height: 16),
              Text(
                '${state.plantLabel(habit)} is now\n${PlantCatalog.stageName(species, stage).toLowerCase()}.',
                textAlign: TextAlign.center,
                style: context.text.displaySmall
                    ?.copyWith(color: VerdantColors.mist),
              ),
              const SizedBox(height: 8),
              Text(PlantCatalog.stages[stage].blurb,
                  textAlign: TextAlign.center,
                  style: context.text.bodyLarge
                      ?.copyWith(color: VerdantColors.mistMuted)),
              const SizedBox(height: 12),
              Expanded(
                flex: 6,
                child: _GrowReveal(
                    speciesId: state.speciesOf(habit),
                    potId: state.potOf(habit),
                    stage: stage),
              ),
              const SizedBox(height: 20),
              FilledButton(
                style: FilledButton.styleFrom(
                    backgroundColor: VerdantColors.lime,
                    foregroundColor: VerdantColors.ink),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Beautiful'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Shows the previous stage, then swaps to the new one with a rustle.
class _GrowReveal extends StatefulWidget {
  const _GrowReveal(
      {required this.speciesId, required this.potId, required this.stage});
  final String speciesId;
  final String potId;
  final int stage;
  @override
  State<_GrowReveal> createState() => _GrowRevealState();
}

class _GrowRevealState extends State<_GrowReveal> {
  late int _shown = widget.stage > 0 ? widget.stage - 1 : 0;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 650), () {
      if (mounted) setState(() => _shown = widget.stage);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
                colors: [VerdantColors.lime.o(0.28), VerdantColors.lime.o(0)]),
          ),
        ),
        PlantView(
            speciesId: widget.speciesId,
            stage: _shown,
            potId: widget.potId,
            ambient: true),
      ],
    );
  }
}

Future<void> showBadgeEarned(BuildContext context, BadgeDef badge) {
  return showModalBottomSheet<void>(
    context: context,
    builder: (context) => Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.4, end: 1),
            duration: const Duration(milliseconds: 700),
            curve: Curves.elasticOut,
            builder: (_, s, child) => Transform.scale(scale: s, child: child),
            child: BadgeMedal(icon: badge.icon, tier: badge.tier, size: 112),
          ),
          const SizedBox(height: 18),
          const Eyebrow('Badge earned'),
          const SizedBox(height: 6),
          Text(badge.name, style: context.text.headlineMedium),
          const SizedBox(height: 6),
          Text(badge.description,
              textAlign: TextAlign.center,
              style: context.text.bodyLarge?.copyWith(color: context.v.muted)),
          const SizedBox(height: 22),
          FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Keep growing')),
        ],
      ),
    ),
  );
}

/// Friendly lines for tapping a plant (story 14).
String plantChatter(AppState state, Habit h) {
  final stage = state.stageOf(h);
  final species = PlantCatalog.byId(state.speciesOf(h));
  final done = state.isDoneToday(h);
  final lines = <String>[
    if (done)
      'Thanks for today’s care. I can feel it in my roots.'
    else
      'Psst — I’m a little thirsty today.',
    state.cycleOf(h)?.growthLabelAt(state.plantToday) ?? 'Ready to grow.',
    'I’m a ${species.name.toLowerCase()}. ${species.care}.',
    'Stage ${stage + 1} of ${PlantCatalog.stages.length}: ${PlantCatalog.stageName(species, stage)}.',
  ];
  return lines[DateTime.now().millisecond % lines.length];
}

/// Small helper reused by tiles: "2/3 this week" or "Done today".
String cadenceLabel(AppState s, Habit h) {
  if (h.frequency.type == FrequencyType.daily)
    return s.isDoneToday(h) ? 'Done today' : 'Every day';
  final period = h.frequency.type == FrequencyType.biweekly
      ? 'this fortnight'
      : h.frequency.type == FrequencyType.monthly
          ? 'this month'
          : 'this week';
  return '${s.periodCount(h)}/${h.frequency.timesPerWeek} $period';
}

/// Used for history text.
String relativeDay(DateTime d) {
  final t = Days.today();
  if (Days.same(d, t)) return 'Today';
  if (Days.same(d, Days.add(t, -1))) return 'Yesterday';
  return '';
}
