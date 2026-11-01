import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/verdant_colors.dart';
import '../../core/theme/verdant_theme.dart';
import '../../domain/group_plants.dart';
import '../garden/group_plant_screen.dart';
import '../../core/widgets/ui.dart';
import '../../data/catalog/habit_catalog.dart';
import '../../data/catalog/plant_catalog.dart';
import '../../data/models/models.dart';
import '../../state/app_state.dart';

/// Story 5: browse built-in habits.
class HabitLibraryScreen extends StatefulWidget {
  const HabitLibraryScreen({super.key});
  @override
  State<HabitLibraryScreen> createState() => _HabitLibraryScreenState();
}

class _HabitLibraryScreenState extends State<HabitLibraryScreen> {
  String _category = 'All';
  String _query = '';
  final _search = TextEditingController();
  final Set<String> _expanded = {};
  final Map<String, bool> _pending = {};
  final Map<String, HabitTemplate> _customDrafts = {};
  bool _saving = false;
  bool _allowLeave = false;

  void _toggle(HabitTemplate template) {
    if (_saving) return;
    final tracked = context
        .read<AppState>()
        .activeHabits
        .any((h) => h.templateId == template.id);
    final selected = _pending[template.id] ?? tracked;
    final next = !selected;
    setState(() {
      if (next == tracked) {
        _pending.remove(template.id);
      } else {
        _pending[template.id] = next;
      }
    });
  }

  Future<void> _save(Map<String, HabitTemplate> templates) async {
    if (_saving || _pending.isEmpty) return;
    setState(() => _saving = true);
    final state = context.read<AppState>();
    try {
      for (final change in _pending.entries.toList()) {
        await state.setHabitTracked(templates[change.key]!, change.value);
        _pending.remove(change.key);
        _customDrafts.remove(change.key);
      }
      if (mounted) {
        showToast(context, 'Habit choices saved. Your history is kept.',
            icon: Icons.check_circle_rounded);
      }
    } catch (_) {
      // Keep only choices that still need applying after a partial failure.
      final tracked = state.activeHabits.map((h) => h.templateId).toSet();
      _pending.removeWhere((id, selected) => tracked.contains(id) == selected);
      if (mounted) {
        showToast(context,
            'Some changes could not be saved. Your remaining choices are kept; tap Save to retry.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmLeave() async {
    final discard = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
              title: const Text('Leave without saving?'),
              content: const Text(
                  'Your checked and unchecked choices have not been saved.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(c, false),
                    child: const Text('Keep editing')),
                TextButton(
                    onPressed: () => Navigator.pop(c, true),
                    child: const Text('Discard changes')),
              ],
            ));
    if (discard != true || !mounted) return;
    setState(() => _allowLeave = true);
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _addCustom(HabitFrequency frequency, String species) async {
    if (_saving) return;
    final result = await showDialog<({String name, String description})>(
        context: context,
        builder: (_) => _CustomHabitDialog(group: HabitGroup.of(frequency)));
    if (result == null || !mounted) return;
    final template = HabitTemplate(
      id: 'custom-${DateTime.now().microsecondsSinceEpoch}',
      name: result.name,
      description: result.description,
      category: _category == 'All' ? 'Growth' : _category,
      iconKey: 'spa',
      suggestedSpecies: species,
      defaultFrequency: frequency,
    );
    setState(() {
      _customDrafts[template.id] = template;
      _pending[template.id] = true;
      _expanded.add(HabitGroup.of(frequency).label);
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final tracked = s.activeHabits.map((h) => h.templateId).toSet();
    final q = _query.trim().toLowerCase();
    HabitTemplate fromHabit(Habit h) => HabitTemplate(
        id: h.templateId,
        name: h.name,
        description: h.description,
        category: h.category,
        iconKey: h.iconKey,
        suggestedSpecies: s.speciesOf(h),
        defaultFrequency: h.frequency);
    final activeByTemplate = {
      for (final h in s.archivedHabits) h.templateId: h,
      for (final h in s.activeHabits) h.templateId: h,
    };
    final templates = [
      ..._customDrafts.values,
      for (final h in activeByTemplate.values.where((h) =>
          h.templateId.startsWith('custom-') &&
          !_customDrafts.containsKey(h.templateId)))
        HabitTemplate(
            id: h.templateId,
            name: h.name,
            description: h.description,
            category: h.category,
            iconKey: h.iconKey,
            suggestedSpecies: h.speciesId,
            defaultFrequency: h.frequency),
      for (final template in HabitCatalog.templates)
        activeByTemplate.containsKey(template.id)
            ? fromHabit(activeByTemplate[template.id]!)
            : template,
    ];
    final items = templates.where((t) {
      final catOk = _category == 'All' || t.category == _category;
      final qOk = q.isEmpty ||
          t.name.toLowerCase().contains(q) ||
          t.description.toLowerCase().contains(q);
      return catOk && qOk;
    }).toList();

    final groups = [
      for (final group in HabitGroup.values)
        (
          title: group.label,
          frequency: group.frequency,
          species: group.speciesId,
          group: group,
          habits: items
              .where((t) => HabitGroup.of(t.defaultFrequency) == group)
              .toList()
        ),
    ];
    final byId = {for (final t in templates) t.id: t};
    return PopScope(
        canPop: !_saving && (_pending.isEmpty || _allowLeave),
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && !_saving && _pending.isNotEmpty) _confirmLeave();
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Habits'),
            actions: [
              Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: FilledButton.icon(
                    style:
                        FilledButton.styleFrom(minimumSize: const Size(0, 40)),
                    onPressed:
                        _saving || _pending.isEmpty ? null : () => _save(byId),
                    icon: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.check_rounded),
                    label: Text(_saving ? 'Saving…' : 'Save'),
                  )),
            ],
          ),
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(22, 4, 22, 0),
                  sliver: SliverList.list(children: [
                    const Eyebrow('Habit library'),
                    const SizedBox(height: 8),
                    Text('What will you\ngrow next?',
                        style: context.text.displaySmall),
                    const SizedBox(height: 18),
                    const Text(
                        'Check habits to track them. Uncheck to stop tracking. Tap Save to apply your choices.'),
                    if (_pending.isNotEmpty)
                      Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text('${_pending.length} unsaved changes',
                              style: context.text.labelLarge)),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _search,
                      onChanged: (v) => setState(() => _query = v),
                      decoration: const InputDecoration(
                          hintText: 'Search habits',
                          prefixIcon: Icon(Icons.search_rounded)),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 40,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: HabitCatalog.categories.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, i) {
                          final c = HabitCatalog.categories[i];
                          final sel = c == _category;
                          final v = context.v;

                          return Pressable(
                            onTap: () => setState(() => _category = c),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: sel ? v.hero : v.card,
                                borderRadius: BorderRadius.circular(99),
                                border:
                                    Border.all(color: sel ? v.hero : v.line),
                              ),
                              child: Text(c,
                                  style: context.text.labelLarge?.copyWith(
                                      color: sel ? v.onHero : v.text)),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 18),
                  ]),
                ),
                if (items.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(22, 24, 22, 40),
                      child: Column(children: [
                        const Icon(Icons.search_off_rounded, size: 36),
                        const SizedBox(height: 12),
                        Text('No habits found', style: context.text.titleLarge),
                        const SizedBox(height: 6),
                        const Text('Try another search or category.',
                            textAlign: TextAlign.center),
                      ]),
                    ),
                  ),
                for (final group in groups) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(22, 4, 22, 14),
                      child: GroupPlantCard(
                          group: group.group,
                          selectionPreview:
                              s.groupGarden.cycleFor(group.group) == null &&
                                  !templates.any((t) =>
                                      HabitGroup.of(t.defaultFrequency) ==
                                          group.group &&
                                      (_pending[t.id] ??
                                          tracked.contains(t.id)))),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(22, 0, 22, 28),
                    sliver: SliverList.separated(
                      itemCount: _expanded.contains(group.title)
                          ? group.habits.length
                          : group.habits.take(2).length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final t = group.habits[i];
                        final added = _pending[t.id] ?? tracked.contains(t.id);
                        return _TemplateTile(
                          template: t,
                          added: added,
                          onTap: _saving ? null : () => _toggle(t),
                        );
                      },
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(22, 0, 22, 28),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (group.habits.isEmpty)
                              Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Text(
                                      'No matching habits yet. Add your own.',
                                      style: context.text.bodySmall)),
                            Wrap(spacing: 12, runSpacing: 8, children: [
                              OutlinedButton.icon(
                                icon: const Icon(Icons.add_rounded),
                                label: const Text('Add habit'),
                                onPressed: _saving
                                    ? null
                                    : () => _addCustom(
                                        group.frequency, group.species),
                              ),
                              if (group.habits.length > 2)
                                TextButton(
                                  onPressed: () => setState(() {
                                    if (!_expanded.add(group.title)) {
                                      _expanded.remove(group.title);
                                    }
                                  }),
                                  child: Text(_expanded.contains(group.title)
                                      ? 'Less'
                                      : 'More (${group.habits.length - 2})'),
                                ),
                            ]),
                          ]),
                    ),
                  ),
                ],
                const SliverToBoxAdapter(child: SizedBox(height: 12)),
              ],
            ),
          ),
        ));
  }
}

class _TemplateTile extends StatelessWidget {
  const _TemplateTile(
      {required this.template, required this.added, required this.onTap});
  final HabitTemplate template;
  final bool added;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final sp =
        PlantCatalog.byId(HabitGroup.of(template.defaultFrequency).speciesId);
    return VCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
      child: Row(children: [
        IconSquare(HabitCatalog.icon(template.iconKey),
            color: sp.tint.o(0.14), iconColor: sp.tint),
        const SizedBox(width: 14),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(template.name, style: context.text.titleMedium),
            const SizedBox(height: 3),
            Text(template.description,
                style: context.text.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 6, children: [
              Pill(template.category, dense: true),
              Pill(template.defaultFrequency.label, dense: true),
            ]),
          ]),
        ),
        const SizedBox(width: 8),
        Checkbox(
            value: added,
            semanticLabel: 'Track ${template.name}',
            onChanged: onTap == null ? null : (_) => onTap!()),
      ]),
    );
  }
}

class _CustomHabitDialog extends StatefulWidget {
  const _CustomHabitDialog({required this.group});
  final HabitGroup group;
  @override
  State<_CustomHabitDialog> createState() => _CustomHabitDialogState();
}

class _CustomHabitDialogState extends State<_CustomHabitDialog> {
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _form = GlobalKey<FormState>();
  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Create a habit'),
        content: Form(
            key: _form,
            child: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(widget.group.label),
              const SizedBox(height: 12),
              TextFormField(
                  controller: _name,
                  autofocus: true,
                  maxLength: 80,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(labelText: 'Habit name'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Give your habit a name.'
                      : null),
              TextFormField(
                  controller: _description,
                  maxLength: 240,
                  maxLines: 2,
                  decoration: const InputDecoration(
                      labelText: 'Description (optional)')),
            ]))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
              onPressed: () {
                if (_form.currentState!.validate()) {
                  Navigator.pop(context, (
                    name: _name.text.trim(),
                    description: _description.text.trim()
                  ));
                }
              },
              child: const Text('Add to selection')),
        ],
      );
}
