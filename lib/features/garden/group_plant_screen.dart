import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/verdant_theme.dart';
import '../../core/widgets/plant_view.dart';
import '../../core/widgets/ui.dart';
import '../../data/catalog/plant_catalog.dart';
import '../../domain/group_plants.dart';
import '../../state/app_state.dart';
import '../habits/habit_editor_screen.dart';
import 'celebrations.dart';

class GroupPlantCard extends StatelessWidget {
  const GroupPlantCard(
      {super.key,
      required this.group,
      this.openOnTap = true,
      this.selectionPreview = false});
  final HabitGroup group;
  final bool openOnTap;
  final bool selectionPreview;
  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final cycle = s.groupGarden.cycleFor(group);
    final speciesId = s.speciesForGroup(group);
    final species = PlantCatalog.byId(speciesId);
    final checklist = cycle?.checklist(s.completions, s.plantToday);
    final waiting = cycle != null && cycle.start.isAfter(s.plantToday);
    return VCard(
      onTap: !openOnTap
          ? null
          : () => Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) => GroupPlantScreen(group: group))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          SizedBox(
              width: 86,
              height: 110,
              child: AnimatedScale(
                  scale: selectionPreview
                      ? 1
                      : 0.65 + 0.35 * (cycle?.progressAt(s.plantToday) ?? 0),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutBack,
                  child: PlantView(
                      key: ValueKey(
                          '${selectionPreview ? 'preview' : 'current'}-${group.name}'),
                      speciesId: speciesId,
                      potId: group.potId,
                      stage: selectionPreview
                          ? 5
                          : cycle?.stageAt(s.plantToday) ?? 0))),
          const SizedBox(width: 14),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(group.label, style: context.text.titleLarge),
                const SizedBox(height: 4),
                Text(
                    '${species.name} · ${selectionPreview ? 'Your fully grown goal' : cycle?.growthLabelAt(s.plantToday) ?? 'Select habits to start your journey'}',
                    style: context.text.bodySmall),
                if (!selectionPreview) ...[
                  const SizedBox(height: 10),
                  ProgressBar(value: cycle?.progressAt(s.plantToday) ?? 0),
                  const SizedBox(height: 8),
                  if (waiting)
                    Text(
                        'Next checklist: ${DateFormat.MMMd().format(cycle.start)}',
                        style: context.text.bodySmall)
                  else if (checklist != null)
                    Text(
                        '${group == HabitGroup.daily ? 'Today' : 'This period'}: ${checklist.completed}/${checklist.required} care tasks complete',
                        style: context.text.bodySmall),
                  if (!waiting &&
                      group != HabitGroup.daily &&
                      group != HabitGroup.monthly &&
                      (checklist?.flower ?? false) &&
                      !(cycle?.ready ?? false))
                    Text('Targets met. This cycle counts when the period ends.',
                        style: context.text.bodySmall),
                ],
              ])),
          if (openOnTap) const Icon(Icons.chevron_right_rounded),
        ]),
        if (selectionPreview)
          Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                  'Fully grown after ${group.maturityLabel.toLowerCase()}.')),
        if (!selectionPreview && (cycle?.ready ?? false)) ...[
          const SizedBox(height: 12),
          FilledButton.icon(
              onPressed: () => s.collectGroupPlant(group),
              icon: const Icon(Icons.yard_rounded),
              label: const Text('Collect and plant a new seed')),
        ],
      ]),
    );
  }
}

class GroupPlantScreen extends StatelessWidget {
  const GroupPlantScreen({super.key, required this.group});
  final HabitGroup group;
  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final habits =
        s.habits.where((h) => HabitGroup.of(h.frequency) == group).toList();
    final cycle = s.groupGarden.cycleFor(group);
    final waiting = cycle != null && cycle.start.isAfter(s.plantToday);
    return Scaffold(
        body: SafeArea(
            child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 40),
                children: [
          const TopBar(),
          Text(group.label, style: context.text.headlineLarge),
          const SizedBox(height: 16),
          GroupPlantCard(group: group, openOnTap: false),
          const SizedBox(height: 16),
          Text(group.instructions),
          const SizedBox(height: 20),
          const Eyebrow('Habits in this group'),
          const SizedBox(height: 12),
          if (habits.isEmpty)
            const Text(
                'Add a habit from the Habits library to start this group.'),
          for (final habit in habits)
            Builder(builder: (context) {
              final count = group == HabitGroup.daily
                  ? (s.isDoneToday(habit) ? 1 : 0)
                  : s.periodCount(habit);
              final target =
                  group == HabitGroup.daily ? 1 : habit.frequency.timesPerWeek;
              final checked = s.isDoneToday(habit) || count >= target;
              return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: VCard(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(habit.name, style: context.text.titleMedium),
                        Text(
                            '${habit.frequency.label} · ${s.validCount(habit.id)} completions',
                            style: context.text.bodySmall),
                        const SizedBox(height: 8),
                        Wrap(spacing: 8, runSpacing: 8, children: [
                          if (habit.isActive)
                            Row(mainAxisSize: MainAxisSize.min, children: [
                              Checkbox(
                                  value: checked,
                                  semanticLabel:
                                      'Complete ${habit.name} ${group == HabitGroup.daily ? 'today' : 'this period'}',
                                  onChanged: waiting
                                      ? null
                                      : (selected) async {
                                          if (selected == true) {
                                            await completeWithFeedback(
                                                context, habit);
                                          } else {
                                            try {
                                              await s
                                                  .undoGroupCompletion(habit);
                                            } catch (_) {
                                              if (context.mounted) {
                                                showToast(context,
                                                    'Could not undo this entry. Please try again.');
                                              }
                                            }
                                          }
                                        }),
                              Flexible(
                                  child: Text(group == HabitGroup.several
                                      ? '$count/$target this week'
                                      : checked
                                          ? 'Done'
                                          : group == HabitGroup.daily
                                              ? 'Complete today'
                                              : 'Complete this period')),
                            ]),
                          OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(0, 48)),
                              icon: const Icon(Icons.edit_outlined),
                              label: Text(habit.isActive
                                  ? 'Edit habit'
                                  : 'Edit resting habit'),
                              onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                      builder: (_) => HabitEditorScreen(
                                          habitId: habit.id)))),
                          if (!habit.isActive)
                            TextButton(
                                onPressed: () async {
                                  try {
                                    await s.restoreHabit(habit);
                                  } catch (_) {
                                    if (context.mounted) {
                                      showToast(context,
                                          'Could not resume this habit. Please try again.');
                                    }
                                  }
                                },
                                child: const Text('Resume')),
                        ]),
                      ])));
            }),
        ])));
  }
}
