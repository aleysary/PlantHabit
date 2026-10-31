import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/verdant_colors.dart';
import '../../core/theme/verdant_theme.dart';
import '../../core/widgets/plant_view.dart';
import '../../core/widgets/ui.dart';
import '../../data/catalog/plant_catalog.dart';
import '../../state/app_state.dart';
import '../habits/habit_library_screen.dart';

/// Every species the user can grow, with a stage-by-stage look at each.
class PlantCatalogScreen extends StatelessWidget {
  const PlantCatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final owned = s.habits.map((h) => h.speciesId).toSet();
    final v = context.v;
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(slivers: [
          const SliverToBoxAdapter(child: TopBar()),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 18),
            sliver: SliverList.list(children: [
              Eyebrow('${owned.length} of ${PlantCatalog.species.length} collected'),
              const SizedBox(height: 8),
              Text('Plant\ncatalogue', style: context.text.displaySmall),
              const SizedBox(height: 14),
              ProgressBar(value: owned.length / PlantCatalog.species.length, height: 6),
            ]),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 40),
            sliver: SliverGrid.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.7),
              itemCount: PlantCatalog.species.length,
              itemBuilder: (context, i) {
                final sp = PlantCatalog.species[i];
                final pot = PlantCatalog.pots[i % PlantCatalog.pots.length];
                final has = owned.contains(sp.id);
                return Pressable(
                  onTap: () => showSpeciesSheet(context, sp, initialPot: pot.id),
                  child: Container(
                    decoration: BoxDecoration(color: v.card, borderRadius: BorderRadius.circular(VerdantTheme.radiusLg), border: Border.all(color: v.line)),
                    padding: const EdgeInsets.all(6),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Expanded(
                        child: Stack(children: [
                          Positioned.fill(child: PlantTile(speciesId: sp.id, stage: 5, potId: pot.id, backdrop: v.backdropFor(pot.id), radius: 18)),
                          Positioned(top: 8, left: 8, child: Pill(sp.rarity.label, dense: true, color: v.card.o(0.85))),
                          if (has)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(color: v.highlight, shape: BoxShape.circle),
                                child: const Icon(Icons.check_rounded, size: 13, color: VerdantColors.ink),
                              ),
                            ),
                        ]),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 10, 8, 6),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(sp.name, style: context.text.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text(sp.latin, style: context.text.bodySmall?.copyWith(fontStyle: FontStyle.italic), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ]),
                      ),
                    ]),
                  ),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}

Future<void> showSpeciesSheet(BuildContext context, PlantSpecies sp, {String initialPot = 'terracotta'}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _SpeciesSheet(species: sp, initialPot: initialPot),
  );
}

class _SpeciesSheet extends StatefulWidget {
  const _SpeciesSheet({required this.species, required this.initialPot});
  final PlantSpecies species;
  final String initialPot;
  @override
  State<_SpeciesSheet> createState() => _SpeciesSheetState();
}

class _SpeciesSheetState extends State<_SpeciesSheet> {
  late String _pot = widget.initialPot;
  int _stage = 5;

  @override
  Widget build(BuildContext context) {
    final sp = widget.species;
    final v = context.v;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Eyebrow('${sp.rarity.label} · ${sp.vibe}'),
        const SizedBox(height: 6),
        Text(sp.name, style: context.text.headlineLarge),
        Text(sp.latin, style: context.text.bodyMedium?.copyWith(fontStyle: FontStyle.italic, color: v.muted)),
        const SizedBox(height: 16),
        Container(
          height: 300,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(VerdantTheme.radiusLg),
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: v.backdropFor(_pot)),
          ),
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
          child: Center(child: PlantView(speciesId: sp.id, stage: _stage, potId: _pot, ambient: true, interactive: true)),
        ),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: Text(PlantCatalog.stageName(sp, _stage), style: context.text.titleLarge)),
          Text('Stage ${_stage + 1} of ${PlantCatalog.stages.length}', style: context.text.bodySmall),
        ]),
        const SizedBox(height: 4),
        Slider(
          value: _stage.toDouble(),
          min: 0,
          max: (PlantCatalog.stages.length - 1).toDouble(),
          divisions: PlantCatalog.stages.length - 1,
          label: PlantCatalog.stageName(sp, _stage),
          onChanged: (x) => setState(() => _stage = x.round()),
        ),
        Text(PlantCatalog.stages[_stage].blurb, style: context.text.bodySmall),
        const SizedBox(height: 18),
        const Eyebrow('Try a pot'),
        const SizedBox(height: 10),
        Wrap(spacing: 10, children: [
          for (final p in PlantCatalog.pots)
            ChoiceChip(
              label: Text(p.name),
              avatar: CircleAvatar(backgroundColor: p.swatch, radius: 8),
              selected: p.id == _pot,
              onSelected: (_) => setState(() => _pot = p.id),
            ),
        ]),
        const SizedBox(height: 18),
        VCard(
          color: v.raised,
          border: false,
          child: Row(children: [
            Icon(Icons.wb_sunny_outlined, color: v.muted),
            const SizedBox(width: 10),
            Expanded(child: Text('In real life: ${sp.care.toLowerCase()}.', style: context.text.bodyMedium)),
          ]),
        ),
        const SizedBox(height: 18),
        FilledButton(
          onPressed: () {
            final nav = Navigator.of(context);
            nav.pop();
            nav.push(MaterialPageRoute<void>(builder: (_) => const HabitLibraryScreen()));
          },
          child: const Text('Grow one with a habit'),
        ),
      ]),
    );
  }
}
