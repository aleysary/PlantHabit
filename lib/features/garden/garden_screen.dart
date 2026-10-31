import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/verdant_colors.dart';
import '../../core/theme/verdant_theme.dart';
import '../../core/widgets/plant_view.dart';
import '../../core/widgets/ui.dart';
import '../../data/catalog/plant_catalog.dart';
import '../../data/models/models.dart';
import '../../state/app_state.dart';
import '../catalog/plant_catalog_screen.dart';
import 'plant_detail_screen.dart';

enum _GardenFilter { all, growing, grown, resting }

class GardenScreen extends StatefulWidget {
  const GardenScreen({super.key});
  @override
  State<GardenScreen> createState() => _GardenScreenState();
}

class _GardenScreenState extends State<GardenScreen> {
  _GardenFilter _filter = _GardenFilter.all;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final finalStage = PlantCatalog.stages.length - 1;
    final list = switch (_filter) {
      _GardenFilter.all => s.activeHabits,
      _GardenFilter.growing => s.activeHabits.where((h) => s.stageOf(h) < finalStage).toList(),
      _GardenFilter.grown => s.activeHabits.where((h) => s.stageOf(h) == finalStage).toList(),
      _GardenFilter.resting => s.archivedHabits,
    };
    final grid = s.settings.gardenLayout == GardenLayout.grid;

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 14),
            sliver: SliverList.list(children: [
              Eyebrow('${s.activeHabits.length} plants · ${s.stats.plantsAtFinalStage} fully grown'),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(child: Text('Your garden', style: context.text.displaySmall)),
                  RoundIconButton(
                    icon: grid ? Icons.view_agenda_rounded : Icons.grid_view_rounded,
                    tooltip: 'Switch layout',
                    onTap: () => s.saveSettings(s.settings.copyWith(gardenLayout: grid ? GardenLayout.list : GardenLayout.grid)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final f in _GardenFilter.values)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _FilterChip(
                          label: switch (f) {
                            _GardenFilter.all => 'All',
                            _GardenFilter.growing => 'Growing',
                            _GardenFilter.grown => 'Fully grown',
                            _GardenFilter.resting => 'Resting',
                          },
                          selected: f == _filter,
                          onTap: () => setState(() => _filter = f),
                        ),
                      ),
                  ],
                ),
              ),
            ]),
          ),
          if (list.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Text(
                  _filter == _GardenFilter.resting ? 'No resting plants. Removed habits will rest here with their history.' : 'Nothing here yet.',
                  textAlign: TextAlign.center,
                  style: context.text.bodyLarge?.copyWith(color: context.v.muted),
                ),
              ),
            )
          else if (grid)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              sliver: SliverGrid.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.66,
                ),
                itemCount: list.length,
                itemBuilder: (context, i) => _GardenCard(habit: list[i]),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              sliver: SliverList.separated(
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) => _GardenRow(habit: list[i]),
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 130),
            sliver: SliverToBoxAdapter(child: _CatalogPromo(onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const PlantCatalogScreen())))),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final v = context.v;
    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? v.hero : v.card,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: selected ? v.hero : v.line),
        ),
        child: Text(label, style: context.text.labelLarge?.copyWith(color: selected ? v.onHero : v.text)),
      ),
    );
  }
}

void _open(BuildContext context, Habit h) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => PlantDetailScreen(habitId: h.id)));

class _GardenCard extends StatelessWidget {
  const _GardenCard({required this.habit});
  final Habit habit;
  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final v = context.v;
    final species = PlantCatalog.byId(habit.speciesId);
    final stage = s.stageOf(habit);
    final n = s.validCount(habit.id);
    return Pressable(
      onTap: () => _open(context, habit),
      child: Container(
        decoration: BoxDecoration(
          color: v.card,
          borderRadius: BorderRadius.circular(VerdantTheme.radiusLg),
          border: Border.all(color: v.line),
        ),
        padding: const EdgeInsets.all(6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: PlantTile(speciesId: habit.speciesId, stage: stage, potId: habit.potId, backdrop: v.backdropFor(habit.potId), radius: 18),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Pill(PlantCatalog.stageName(species, stage), dense: true, color: v.card.o(0.85)),
                  ),
                  if (s.isDoneToday(habit))
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(color: v.highlight, shape: BoxShape.circle),
                        child: const Icon(Icons.check_rounded, size: 15, color: VerdantColors.ink),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 10, 8, 6),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s.plantLabel(habit), style: context.text.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(habit.name, style: context.text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                ProgressBar(value: AppState.growth.stageProgress(n), height: 4),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _GardenRow extends StatelessWidget {
  const _GardenRow({required this.habit});
  final Habit habit;
  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final v = context.v;
    final species = PlantCatalog.byId(habit.speciesId);
    final stage = s.stageOf(habit);
    return VCard(
      padding: const EdgeInsets.all(8),
      onTap: () => _open(context, habit),
      child: Row(children: [
        SizedBox(
          width: 96,
          height: 112,
          child: PlantTile(speciesId: habit.speciesId, stage: stage, potId: habit.potId, backdrop: v.backdropFor(habit.potId), radius: 16),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Eyebrow(species.name),
            const SizedBox(height: 4),
            Text(s.plantLabel(habit), style: context.text.headlineSmall),
            const SizedBox(height: 4),
            Text(habit.name, style: context.text.bodySmall),
            const SizedBox(height: 10),
            Pill(PlantCatalog.stageName(species, stage), dense: true),
          ]),
        ),
        Icon(Icons.chevron_right_rounded, color: v.muted),
      ]),
    );
  }
}

class _CatalogPromo extends StatelessWidget {
  const _CatalogPromo({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final v = context.v;
    return Pressable(
      onTap: onTap,
      child: Container(
        height: 150,
        decoration: BoxDecoration(color: v.hero, borderRadius: BorderRadius.circular(VerdantTheme.radiusLg)),
        clipBehavior: Clip.antiAlias,
        child: Stack(children: [
          const Positioned(right: 70, bottom: -6, height: 120, child: PlantView(speciesId: 'bird_of_paradise', stage: 5, potId: 'midnight')),
          const Positioned(right: -8, bottom: -6, height: 100, child: PlantView(speciesId: 'cactus', stage: 5, potId: 'terracotta')),
          const Positioned(right: 140, bottom: -6, height: 80, child: PlantView(speciesId: 'echeveria', stage: 5, potId: 'blush')),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Eyebrow('Plant catalogue', color: v.onHero.o(0.6)),
              const SizedBox(height: 6),
              Text('${PlantCatalog.species.length} species\nto collect.', style: context.text.headlineSmall?.copyWith(color: v.onHero)),
              const Spacer(),
              Row(children: [
                Text('Explore', style: context.text.labelLarge?.copyWith(color: v.highlight)),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward_rounded, size: 16, color: v.highlight),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}
