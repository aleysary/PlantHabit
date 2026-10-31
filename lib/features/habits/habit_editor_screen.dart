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

/// Stories 6 & 7: add a built-in habit, choosing its plant, pot and target.
class HabitSetupScreen extends StatefulWidget {
  const HabitSetupScreen({super.key, required this.template});
  final HabitTemplate template;
  @override
  State<HabitSetupScreen> createState() => _HabitSetupScreenState();
}

class _HabitSetupScreenState extends State<HabitSetupScreen> {
  late String _species = widget.template.suggestedSpecies;
  String _pot = 'terracotta';
  late HabitFrequency _freq = widget.template.defaultFrequency;
  final _nick = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _nick.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      final h = await context.read<AppState>().addHabit(
            template: widget.template,
            speciesId: _species,
            potId: _pot,
            frequency: _freq,
            plantName: _nick.text,
          );
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      showToast(context, 'Planted! ${context.read<AppState>().plantLabel(h)} is in your garden.', icon: Icons.spa_rounded);
      Navigator.of(context).popUntil((r) => r.isFirst);
    } on VerdantException catch (e) {
      if (mounted) showToast(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _HabitFormScaffold(
      eyebrow: widget.template.category,
      title: widget.template.name,
      species: _species,
      pot: _pot,
      previewStage: 5,
      previewCaption: 'What it becomes',
      body: [
        _PlantPicker(selected: _species, onChanged: (v) => setState(() => _species = v)),
        const SizedBox(height: 26),
        _PotPicker(selected: _pot, onChanged: (v) => setState(() => _pot = v)),
        const SizedBox(height: 26),
        _FrequencyPicker(value: _freq, onChanged: (v) => setState(() => _freq = v)),
        const SizedBox(height: 26),
        const Eyebrow('Name your plant (optional)'),
        const SizedBox(height: 10),
        TextField(controller: _nick, textCapitalization: TextCapitalization.words, decoration: InputDecoration(hintText: PlantCatalog.byId(_species).name)),
      ],
      action: PrimaryButton(label: 'Plant it', icon: Icons.spa_rounded, loading: _busy, onPressed: _save),
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
  late final Habit _original = context.read<AppState>().habitById(widget.habitId)!;
  late String _pot = _original.potId;
  late HabitFrequency _freq = _original.frequency;
  late final _name = TextEditingController(text: _original.name);
  late final _nick = TextEditingController(text: _original.plantName ?? '');
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _nick.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      showToast(context, 'Give your habit a name.');
      return;
    }
    setState(() => _busy = true);
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
      plantName: _nick.text.trim().isEmpty ? null : _nick.text.trim(),
      archivedAt: _original.archivedAt,
    ));
    if (!mounted) return;
    showToast(context, 'Saved. Your history and growth are untouched.', icon: Icons.check_circle_rounded);
    Navigator.of(context).pop();
  }

  Future<void> _remove() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Stop tracking this habit?'),
        content: const Text('Your plant will move to “Resting” in your garden. All past completions are kept, and you can resume any time.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            style: TextButton.styleFrom(foregroundColor: VerdantColors.danger),
            child: const Text('Stop tracking'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await context.read<AppState>().archiveHabit(_original);
    if (!mounted) return;
    showToast(context, 'Habit removed. Its history is safe.', icon: Icons.bedtime_rounded);
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final stage = context.watch<AppState>().stageOf(_original);
    return _HabitFormScaffold(
      eyebrow: 'Edit habit',
      title: _original.name,
      species: _original.speciesId,
      pot: _pot,
      previewStage: stage,
      previewCaption: 'Current stage',
      body: [
        const Eyebrow('Habit name'),
        const SizedBox(height: 10),
        TextField(controller: _name, textCapitalization: TextCapitalization.sentences),
        const SizedBox(height: 18),
        const Eyebrow('Plant nickname'),
        const SizedBox(height: 10),
        TextField(controller: _nick, textCapitalization: TextCapitalization.words, decoration: InputDecoration(hintText: PlantCatalog.byId(_original.speciesId).name)),
        const SizedBox(height: 26),
        _PotPicker(selected: _pot, onChanged: (v) => setState(() => _pot = v)),
        const SizedBox(height: 26),
        _FrequencyPicker(value: _freq, onChanged: (v) => setState(() => _freq = v)),
        const SizedBox(height: 30),
        if (_original.isActive)
          OutlinedButton.icon(
            onPressed: _remove,
            style: OutlinedButton.styleFrom(foregroundColor: VerdantColors.danger),
            icon: const Icon(Icons.remove_circle_outline_rounded),
            label: const Text('Remove from tracking'),
          ),
      ],
      action: PrimaryButton(label: 'Save changes', loading: _busy, onPressed: _save),
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
                      borderRadius: BorderRadius.circular(VerdantTheme.radiusLg),
                      gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: v.backdropFor(pot)),
                    ),
                    child: Stack(children: [
                      Positioned.fill(
                        top: 16,
                        bottom: 10,
                        child: Center(child: PlantView(speciesId: species, stage: previewStage, potId: pot, ambient: true, interactive: true)),
                      ),
                      Positioned(
                        left: 16,
                        top: 16,
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Eyebrow(previewCaption),
                          const SizedBox(height: 2),
                          Text(sp.name, style: context.text.titleLarge),
                          Text(sp.latin, style: context.text.bodySmall?.copyWith(fontStyle: FontStyle.italic)),
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
            decoration: BoxDecoration(color: context.colors.surface, border: Border(top: BorderSide(color: v.line))),
            child: action,
          ),
        ]),
      ),
    );
  }
}

class _PlantPicker extends StatelessWidget {
  const _PlantPicker({required this.selected, required this.onChanged});
  final String selected;
  final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context) {
    final v = context.v;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Expanded(child: Eyebrow('Choose your plant')),
        Text('${PlantCatalog.species.length} species', style: context.text.bodySmall),
      ]),
      const SizedBox(height: 12),
      SizedBox(
        height: 150,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: PlantCatalog.species.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (context, i) {
            final sp = PlantCatalog.species[i];
            final sel = sp.id == selected;
            return Pressable(
              onTap: () => onChanged(sp.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 104,
                padding: const EdgeInsets.fromLTRB(6, 8, 6, 8),
                decoration: BoxDecoration(
                  color: sel ? v.hero : v.card,
                  borderRadius: BorderRadius.circular(VerdantTheme.radiusMd),
                  border: Border.all(color: sel ? v.hero : v.line, width: sel ? 1.6 : 1),
                ),
                child: Column(children: [
                  Expanded(child: PlantView(speciesId: sp.id, stage: 5, potId: 'ivory')),
                  const SizedBox(height: 6),
                  Text(sp.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.labelMedium?.copyWith(color: sel ? v.onHero : v.text)),
                ]),
              ),
            );
          },
        ),
      ),
    ]);
  }
}

class _PotPicker extends StatelessWidget {
  const _PotPicker({required this.selected, required this.onChanged});
  final String selected;
  final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context) {
    final v = context.v;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Expanded(child: Eyebrow('Pot')),
        Text(PlantCatalog.potById(selected).name, style: context.text.bodySmall),
      ]),
      const SizedBox(height: 12),
      Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (final p in PlantCatalog.pots)
            Pressable(
              onTap: () => onChanged(p.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 46,
                height: 46,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: p.id == selected ? v.text : Colors.transparent, width: 2),
                ),
                child: Container(
                  decoration: BoxDecoration(color: p.swatch, shape: BoxShape.circle, border: Border.all(color: v.line)),
                ),
              ),
            ),
        ],
      ),
    ]);
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
      PillTabs<FrequencyType>(
        values: FrequencyType.values,
        selected: value.type,
        label: (t) => t == FrequencyType.daily ? 'Daily' : 'Weekly',
        onChanged: (t) => onChanged(t == FrequencyType.daily ? const HabitFrequency.daily() : HabitFrequency.weekly(n)),
      ),
      AnimatedSize(
        duration: const Duration(milliseconds: 220),
        child: weekly
            ? Padding(
                padding: const EdgeInsets.only(top: 14),
                child: VCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(children: [
                    Expanded(child: Text('Times per week', style: context.text.titleMedium)),
                    RoundIconButton(icon: Icons.remove_rounded, size: 38, onTap: n > 1 ? () => onChanged(HabitFrequency.weekly(n - 1)) : null),
                    SizedBox(width: 44, child: Text('$n', textAlign: TextAlign.center, style: context.text.headlineSmall)),
                    RoundIconButton(icon: Icons.add_rounded, size: 38, onTap: n < 6 ? () => onChanged(HabitFrequency.weekly(n + 1)) : null),
                  ]),
                ),
              )
            : const SizedBox(width: double.infinity),
      ),
      const SizedBox(height: 8),
      Text(
        weekly ? 'Log up to $n times a week (once per day). Resets every Monday.' : 'Log once every day. Each day you show up, your plant grows.',
        style: context.text.bodySmall,
      ),
    ]);
  }
}
