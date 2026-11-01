import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/verdant_colors.dart';
import '../../core/theme/verdant_theme.dart';
import '../../core/widgets/plant_view.dart';
import '../../core/widgets/ui.dart';
import '../../data/catalog/habit_catalog.dart';
import '../../data/catalog/plant_catalog.dart';
import '../../data/models/models.dart';
import '../../data/repositories/repositories.dart';
import '../../state/app_state.dart';
import '../../domain/group_plants.dart';

/// Stories 6 & 7: add a built-in habit, choosing its plant, pot and target.
class HabitSetupScreen extends StatefulWidget {
  const HabitSetupScreen(
      {super.key, required this.template, this.custom = false});
  final HabitTemplate template;
  final bool custom;
  @override
  State<HabitSetupScreen> createState() => _HabitSetupScreenState();
}

class _HabitSetupScreenState extends State<HabitSetupScreen> {
  String get _species => HabitGroup.of(_freq).speciesId;
  String get _pot => HabitGroup.of(_freq).potId;
  late HabitFrequency _freq = widget.template.defaultFrequency;

  final _habitName = TextEditingController();
  final _description = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _habitName.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy) return;
    if (widget.custom && _habitName.text.trim().isEmpty) {
      showToast(context, 'Give your habit a name.');
      return;
    }
    setState(() => _busy = true);
    try {
      final h = await context.read<AppState>().addHabit(
            template: widget.custom
                ? HabitTemplate(
                    id: widget.template.id,
                    name: _habitName.text.trim(),
                    description: _description.text.trim(),
                    category: widget.template.category,
                    iconKey: widget.template.iconKey,
                    suggestedSpecies: _species,
                    defaultFrequency: _freq,
                  )
                : widget.template,
            speciesId: _species,
            potId: _pot,
            frequency: _freq,
          );
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      showToast(context, 'Added to ${context.read<AppState>().plantLabel(h)}.',
          icon: Icons.spa_rounded);
      Navigator.of(context).popUntil((r) => r.isFirst);
    } on VerdantException catch (e) {
      if (mounted) showToast(context, e.message);
    } catch (_) {
      if (mounted) {
        showToast(context, 'Could not save your habit. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _HabitFormScaffold(
      eyebrow: widget.template.category,
      title: widget.custom ? 'Create a habit' : widget.template.name,
      species: _species,
      pot: _pot,
      previewStage: 5,
      previewCaption: 'Your shared group plant',
      body: [
        if (widget.custom) ...[
          const Eyebrow('Habit name'),
          const SizedBox(height: 10),
          TextField(
              controller: _habitName,
              maxLength: 80,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                  hintText: 'What would you like to do?')),
          const SizedBox(height: 12),
          TextField(
              controller: _description,
              maxLength: 240,
              maxLines: 2,
              decoration:
                  const InputDecoration(labelText: 'Description (optional)')),
          const SizedBox(height: 26),
        ],
        const Text(
            'Your frequency selects the shared group plant. Daily: seven completed days. Weekly and bi-weekly: four completed cycles. Monthly: finish the whole checklist.'),
        const SizedBox(height: 18),
        _FrequencyPicker(
            value: _freq, onChanged: (v) => setState(() => _freq = v)),
        const SizedBox(height: 26),
      ],
      action: PrimaryButton(
          label: 'Add habit',
          icon: Icons.spa_rounded,
          loading: _busy,
          onPressed: _save),
    );
  }
}

/// Stories 8 & 9: edit an existing habit or stop tracking it.
class HabitEditorScreen extends StatefulWidget {
  const HabitEditorScreen({super.key, required this.habitId});
  final String habitId;
  @override
  State<HabitEditorScreen> createState() => _HabitEditorScreenState();
}

class _HabitEditorScreenState extends State<HabitEditorScreen> {
  late final Habit _original =
      context.read<AppState>().habitById(widget.habitId)!;
  String get _pot => HabitGroup.of(_freq).potId;
  late HabitFrequency _freq = _original.frequency;
  late final _name = TextEditingController(text: _original.name);

  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();

    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      showToast(context, 'Give your habit a name.');
      return;
    }
    setState(() => _busy = true);
    try {
      final s = context.read<AppState>();
      await s.updateHabit(Habit(
        id: _original.id,
        templateId: _original.templateId,
        name: _name.text.trim(),
        description: _original.description,
        category: _original.category,
        iconKey: _original.iconKey,
        speciesId: _original.speciesId,
        potId: _pot,
        frequency: _freq,
        createdAt: _original.createdAt,
        plantName: _original.plantName,
        archivedAt: _original.archivedAt,
      ));
      if (!mounted) return;
      showToast(context, 'Saved. Your completion history is kept.',
          icon: Icons.check_circle_rounded);
      Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        showToast(context, 'Could not save changes. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Stop tracking this habit?'),
        content: const Text(
            'This habit will stop contributing care goals to its group plant. Its history is kept, and you can resume it from the group screen.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            style: TextButton.styleFrom(foregroundColor: VerdantColors.danger),
            child: const Text('Stop tracking'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await context.read<AppState>().archiveHabit(_original);
    } catch (_) {
      if (mounted) {
        showToast(context, 'Could not stop tracking. Please try again.');
      }
      return;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (!mounted) return;
    showToast(context, 'Habit removed. Its history is safe.',
        icon: Icons.bedtime_rounded);
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final stage = context.watch<AppState>().stageOf(_original);
    return _HabitFormScaffold(
      eyebrow: 'Edit habit',
      title: _original.name,
      species: HabitGroup.of(_freq).speciesId,
      pot: _pot,
      previewStage: stage,
      previewCaption: 'Current stage',
      body: [
        const Eyebrow('Habit name'),
        const SizedBox(height: 10),
        TextField(
            controller: _name,
            textCapitalization: TextCapitalization.sentences),
        const SizedBox(height: 18),
        const Text(
            'Changing frequency moves this habit to its new shared plant. Its completion history is kept.'),
        const SizedBox(height: 18),
        _FrequencyPicker(
            value: _freq, onChanged: (v) => setState(() => _freq = v)),
        const SizedBox(height: 30),
        if (_original.isActive)
          OutlinedButton.icon(
            onPressed: _busy ? null : _remove,
            style:
                OutlinedButton.styleFrom(foregroundColor: VerdantColors.danger),
            icon: const Icon(Icons.remove_circle_outline_rounded),
            label: const Text('Remove from tracking'),
          ),
      ],
      action: PrimaryButton(
          label: 'Save changes', loading: _busy, onPressed: _save),
    );
  }
}

// ---------------------------------------------------------------------------

class _HabitFormScaffold extends StatelessWidget {
  const _HabitFormScaffold({
    required this.eyebrow,
    required this.title,
    required this.species,
    required this.pot,
    required this.previewStage,
    required this.previewCaption,
    required this.body,
    required this.action,
  });

  final String eyebrow;
  final String title;
  final String species;
  final String pot;
  final int previewStage;
  final String previewCaption;
  final List<Widget> body;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    final v = context.v;
    final sp = PlantCatalog.byId(species);
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          Expanded(
            child: CustomScrollView(slivers: [
              const SliverToBoxAdapter(child: TopBar()),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
                sliver: SliverList.list(children: [
                  Eyebrow(eyebrow),
                  const SizedBox(height: 6),
                  Text(title, style: context.text.headlineLarge),
                  const SizedBox(height: 18),
                  Container(
                    height: 280,
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(VerdantTheme.radiusLg),
                      gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: v.backdropFor(pot)),
                    ),
                    child: Stack(children: [
                      Positioned.fill(
                        top: 16,
                        bottom: 10,
                        child: Center(
                            child: PlantView(
                                speciesId: species,
                                stage: previewStage,
                                potId: pot,
                                ambient: true,
                                interactive: true)),
                      ),
                      Positioned(
                        left: 16,
                        top: 16,
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Eyebrow(previewCaption),
                              const SizedBox(height: 2),
                              Text(sp.name, style: context.text.titleLarge),
                              Text(sp.latin,
                                  style: context.text.bodySmall
                                      ?.copyWith(fontStyle: FontStyle.italic)),
                            ]),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 24),
                  ...body,
                ]),
              ),
            ]),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 16),
            decoration: BoxDecoration(
                color: context.colors.surface,
                border: Border(top: BorderSide(color: v.line))),
            child: action,
          ),
        ]),
      ),
    );
  }
}

class _FrequencyPicker extends StatelessWidget {
  const _FrequencyPicker({required this.value, required this.onChanged});
  final HabitFrequency value;
  final ValueChanged<HabitFrequency> onChanged;
  @override
  Widget build(BuildContext context) {
    final weekly = value.type == FrequencyType.weekly;
    final n = weekly ? value.timesPerWeek : 3;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Eyebrow('Target frequency'),
      const SizedBox(height: 12),
      Text('Choose your rhythm and see your fully grown plant.',
          style: context.text.bodySmall),
      const SizedBox(height: 12),
      LayoutBuilder(builder: (context, constraints) {
        final width = ((constraints.maxWidth - 10) / 2).clamp(0.0, 220.0);
        return Wrap(spacing: 10, runSpacing: 10, children: [
          for (final group in HabitGroup.values)
            SizedBox(
                width: width,
                child: Semantics(
                  selected: HabitGroup.of(value) == group,
                  button: true,
                  child: VCard(
                    color: HabitGroup.of(value) == group
                        ? context.v.raised
                        : context.v.card,
                    padding: const EdgeInsets.all(12),
                    onTap: () => onChanged(
                        group == HabitGroup.several && weekly && n > 1
                            ? HabitFrequency.weekly(n)
                            : group.frequency),
                    child: Column(children: [
                      ExcludeSemantics(
                          child: SizedBox(
                              height: 100,
                              width: 80,
                              child: PlantView(
                                  speciesId: group.speciesId,
                                  potId: group.potId,
                                  stage: 5))),
                      const SizedBox(height: 6),
                      Text(group.label,
                          textAlign: TextAlign.center, softWrap: true),
                      const SizedBox(height: 4),
                      Text(PlantCatalog.byId(group.speciesId).name,
                          style: context.text.bodySmall,
                          textAlign: TextAlign.center),
                      const SizedBox(height: 4),
                      Text('Fully grown · ${group.maturityLabel}',
                          style: context.text.bodySmall,
                          textAlign: TextAlign.center),
                      if (HabitGroup.of(value) == group)
                        const Icon(Icons.check_circle_rounded, size: 18),
                    ]),
                  ),
                )),
        ]);
      }),
      AnimatedSize(
        duration: const Duration(milliseconds: 220),
        child: weekly
            ? Padding(
                padding: const EdgeInsets.only(top: 14),
                child: VCard(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(children: [
                    Expanded(
                        child: Text('Times per week',
                            style: context.text.titleMedium)),
                    RoundIconButton(
                        icon: Icons.remove_rounded,
                        size: 38,
                        onTap: n > 1
                            ? () => onChanged(HabitFrequency.weekly(n - 1))
                            : null),
                    SizedBox(
                        width: 44,
                        child: Text('$n',
                            textAlign: TextAlign.center,
                            style: context.text.headlineSmall)),
                    RoundIconButton(
                        icon: Icons.add_rounded,
                        size: 38,
                        onTap: n < 6
                            ? () => onChanged(HabitFrequency.weekly(n + 1))
                            : null),
                  ]),
                ),
              )
            : const SizedBox(width: double.infinity),
      ),
      const SizedBox(height: 8),
      Text(
        switch (value.type) {
          FrequencyType.weekly =>
            'Log up to $n times a week (once per day). Resets every Monday.',
          FrequencyType.daily =>
            'Log once every day. Each day you show up, your plant grows.',
          FrequencyType.biweekly =>
            'Log once in each shared 14-day group period.',
          FrequencyType.monthly =>
            'Log once per calendar month. Resets on the first of each month.',
        },
        style: context.text.bodySmall,
      ),
    ]);
  }
}
