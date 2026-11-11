import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/verdant_theme.dart';
import '../../core/widgets/plant_view.dart';
import '../../core/widgets/ui.dart';
import '../../data/catalog/plant_catalog.dart';
import '../../domain/group_plants.dart';
import '../../state/app_state.dart';
import 'group_plant_screen.dart';

class GardenScreen extends StatelessWidget {
  const GardenScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final cycles = s.groupGarden.current;
    final collection = s.groupGarden.collection;
    return SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 130),
          children: [
            Eyebrow(
                '${cycles.length} group plants · ${collection.length} collected'),
            const SizedBox(height: 8),
            Text('Your garden', style: context.text.displaySmall),
            const SizedBox(height: 12),
            Text(
                'Each rhythm grows its own shared plant. Tap one to see how it grows.',
                style: context.text.bodyMedium
                    ?.copyWith(color: context.v.muted)),
            const SizedBox(height: 22),
            for (final group in HabitGroup.values)
              if (cycles.any((cycle) => cycle.group == group) ||
                  s.habits.any((h) => HabitGroup.of(h.frequency) == group))
                Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: GroupPlantCard(group: group)),
            if (cycles.isEmpty)
              const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                      'Create a habit from the Habits button to plant a seed.')),
            const SizedBox(height: 12),
            SectionHeader('Your collection',
                eyebrow: '${collection.length} finished cycles'),
            const SizedBox(height: 12),
            if (collection.isEmpty)
              const Text(
                  'Your fully grown plants will appear here when you collect them.'),
            for (final plant in collection)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: VCard(
                    child: Row(children: [
                  SizedBox(
                      width: 72,
                      height: 90,
                      child: PlantView(
                          speciesId: plant.speciesId,
                          stage: 5,
                          potId:
                              plant.care.flower ? 'blush' : plant.group.potId)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(plant.group.label,
                            style: context.text.titleMedium),
                        Text(PlantCatalog.byId(plant.speciesId).name,
                            style: context.text.bodySmall),
                        Text(
                            '${DateFormat.MMMd().format(plant.start)} – ${DateFormat.MMMd().format(DateTime(plant.finished.year, plant.finished.month, plant.finished.day - 1))}',
                            style: context.text.bodySmall),
                        Text(
                            plant.care.required == 0
                                ? 'Journey complete'
                                : plant.care.flower
                                    ? '✿ Flower earned · all care goals met'
                                    : plant.care.label,
                            style: context.text.bodySmall),
                      ])),
                ])),
              ),
          ],
        ));
  }
}
