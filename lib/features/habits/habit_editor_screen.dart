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

/// Stories 6 & 7: create a habit. Users write their own (blank template) or
/// start from a suggestion; either way the name, rhythm and plant are theirs
/// to set before it is added.
class HabitSetupScreen extends StatefulWidget {
  const HabitSetupScreen({super.key, required this.template});
  final HabitTemplate template;
  @override
  State<HabitSetupScreen> createState() => _HabitSetupScreenState();
}

class _HabitSetupScreenState extends State<HabitSetupScreen> {
  late HabitFrequency _freq = widget.template.defaultFrequency;

  /// A plant the user tapped; null means "the plant this rhythm already
  /// grows", or its default for a rhythm with no habits yet.
  String? _picked;

  late final _habitName = TextEditingController(text: widget.template.name);
  late final _description =
      TextEditingController(text: widget.template.description);
  bool _busy = false;

  bool get _fromScratch => widget.template.name.isEmpty;
  HabitGroup get _group => HabitGroup.of(_freq);
  String _species(AppState s) =>
      _picked ?? s.existingPlant(_group) ?? _group.speciesId;

  void _setFrequency(HabitFrequency next) {
    final s = context.read<AppState>();
    setState(() {
      // Moving to a rhythm that already has a plant joins that plant;
      // a pick only carries over to a rhythm that has none yet.
      if (s.existingPlant(HabitGroup.of(next)) != null) _picked = null;
      _freq = next;
    });
  }

  @override
  void dispose() {
    _habitName.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy) return;
    final name = _habitName.text.trim();
    if (name.isEmpty) {
      showToast(context, 'Give your habit a name.');
      return;
    }
    setState(() => _busy = true);
    try {
      final s = context.read<AppState>();
      final t = widget.template;
      final species = _species(s);
      final h = await s.addHabit(
        template: HabitTemplate(
          id: t.id,
          name: name,
          description: _description.text.trim(),
          category: t.category,
          iconKey: t.iconKey,
          suggestedSpecies: species,
          defaultFrequency: _freq,
        ),
        speciesId: species,
        potId: _group.potId,
        frequency: _freq,
      );
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      showToast(context,
          '${h.name} added. It grows your ${PlantCatalog.byId(species).name}.',
          icon: Icons.spa_rounded);
      Navigator.of(context).pop();
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
    final s = context.watch<AppState>();
    final species = _species(s);
    return _HabitFormScaffold(
      eyebrow: _fromScratch ? 'Your own habit' : 'Make it yours',
      title: _fromScratch ? 'Create a habit' : widget.template.name,
      species: species,
      pot: _group.potId,
      previewStage: 5,
      previewCaption: 'Fully grown',
      body: [
        const Eyebrow('Habit name'),
        const SizedBox(height: 10),
        TextField(
            controller: _habitName,
            autofocus: _fromScratch,
            maxLength: 80,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
                hintText: 'What would you like to do?')),
        const SizedBox(height: 4),
        TextField(
            controller: _description,
            maxLength: 240,
            maxLines: 2,
            decoration:
                const InputDecoration(labelText: 'Description (optional)')),
        const SizedBox(height: 20),
        _RhythmPicker(value: _freq, onChanged: _setFrequency),
        const SizedBox(height: 28),
        _PlantPicker(
            selected: species,
            sharing: s.habitsSharing(_group),
            onChanged: (id) => setState(() => _picked = id)),
        const SizedBox(height: 12),
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
  late HabitFrequency _freq = _original.frequency;
  String? _picked;
  late final _name = TextEditingController(text: _original.name);

  bool _busy = false;

  HabitGroup get _group => HabitGroup.of(_freq);
  String _species(AppState s) =>
      _picked ??
      s.existingPlant(_group, exceptId: _original.id) ??
      _original.speciesId;

  void _setFrequency(HabitFrequency next) {
    final s = context.read<AppState>();
    setState(() {
      if (s.existingPlant(HabitGroup.of(next), exceptId: _original.id) !=
          null) {
        _picked = null;
      }
      _freq = next;
    });
  }

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
        speciesId: _species(s),
        potId: _group.potId,
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
            'This habit will stop contributing care goals to its plant. Its history is kept, and you can resume it from the Habits screen.'),
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
    showToast(context, 'Habit paused. Its history is safe.',
        icon: Icons.bedtime_rounded);
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final species = _species(s);
    return _HabitFormScaffold(
      eyebrow: 'Edit habit',
      title: _original.name,
      species: species,
      pot: _group.potId,
      previewStage: s.stageOf(_original),
      previewCaption: 'Current stage',
      body: [
        const Eyebrow('Habit name'),
        const SizedBox(height: 10),
        TextField(
            controller: _name,
            textCapitalization: TextCapitalization.sentences),
        const SizedBox(height: 20),
        _RhythmPicker(value: _freq, onChanged: _setFrequency),
        const SizedBox(height: 8),
        Text('Changing how often keeps your completion history.',
            style: context.text.bodySmall),
        const SizedBox(height: 28),
        _PlantPicker(
            selected: species,
            sharing: s.habitsSharing(_group, exceptId: _original.id),
            onChanged: (id) => setState(() => _picked = id)),
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
                    height: 220,
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

/// How often: four plain choices, plus times per week for weekly habits.
class _RhythmPicker extends StatelessWidget {
  const _RhythmPicker({required this.value, required this.onChanged});
  final HabitFrequency value;
  final ValueChanged<HabitFrequency> onChanged;

  static const _options = [
    (FrequencyType.daily, 'Every day'),
    (FrequencyType.weekly, 'Weekly'),
    (FrequencyType.biweekly, 'Every 2 weeks'),
    (FrequencyType.monthly, 'Monthly'),
  ];

  @override
  Widget build(BuildContext context) {
    final weekly = value.type == FrequencyType.weekly;
    final n = weekly ? value.timesPerWeek : 1;
    final group = HabitGroup.of(value);
    final rule = switch (value.type) {
      FrequencyType.daily => 'Log once every day.',
      FrequencyType.weekly => n == 1
          ? 'Log once a week. Resets every Monday.'
          : 'Log on $n different days a week. Resets every Monday.',
      FrequencyType.biweekly => 'Log once in each two-week period.',
      FrequencyType.monthly => 'Log once a month. Resets on the 1st.',
    };
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Eyebrow('How often?'),
      const SizedBox(height: 12),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final (type, label) in _options)
          ChoiceChip(
            label: Text(label),
            selected: value.type == type,
            onSelected: (_) => onChanged(switch (type) {
              FrequencyType.daily => const HabitFrequency.daily(),
              FrequencyType.weekly => HabitFrequency.weekly(n),
              FrequencyType.biweekly => const HabitFrequency.biweekly(),
              FrequencyType.monthly => const HabitFrequency.monthly(),
            }),
          ),
      ]),
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
                        tooltip: 'Fewer times',
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
                        tooltip: 'More times',
                        onTap: n < 6
                            ? () => onChanged(HabitFrequency.weekly(n + 1))
                            : null),
                  ]),
                ),
              )
            : const SizedBox(width: double.infinity),
      ),
      const SizedBox(height: 10),
      Text(
        '$rule Its plant is fully grown after '
        '${group.maturityLabel.toLowerCase()}.',
        style: context.text.bodySmall,
      ),
    ]);
  }
}

/// Every plant in the catalogue, to choose what this habit grows.
///
/// Habits with the same rhythm share one plant, so if others already grow
/// one, that plant is preselected and picking another changes it for all.
class _PlantPicker extends StatelessWidget {
  const _PlantPicker(
      {required this.selected, required this.sharing, required this.onChanged});
  final String selected;
  final int sharing;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final v = context.v;
    final name = PlantCatalog.byId(selected).name;
    final all = PlantCatalog.species;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Eyebrow('Your plant'),
      const SizedBox(height: 8),
      Text(
          sharing == 0
              ? 'Pick the plant this habit grows. Scroll for all ${all.length}.'
              : 'Joins the $name you grow with $sharing other '
                  '${sharing == 1 ? 'habit' : 'habits'} on this schedule. '
                  'Pick another to change it for all of them.',
          style: context.text.bodySmall),
      const SizedBox(height: 12),
      SizedBox(
        height: 150,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: all.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (context, i) {
            final sp = all[i];
            final isSelected = sp.id == selected;
            return Semantics(
              button: true,
              selected: isSelected,
              label: sp.name,
              child: VCard(
                onTap: () => onChanged(sp.id),
                color: isSelected ? v.raised : v.card,
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
                child: SizedBox(
                  width: 88,
                  child: Column(children: [
                    Expanded(
                        child: ExcludeSemantics(
                            child: PlantView(
                                speciesId: sp.id,
                                stage: 5,
                                potId: 'terracotta'))),
                    const SizedBox(height: 6),
                    Text(sp.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: context.text.labelMedium),
                    Icon(Icons.check_circle_rounded,
                        size: 16,
                        color: isSelected
                            ? context.colors.primary
                            : Colors.transparent),
                  ]),
                ),
              ),
            );
          },
        ),
      ),
    ]);
  }
}
