import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/verdant_colors.dart';
import '../../core/theme/verdant_theme.dart';
import '../../core/widgets/plant_view.dart';
import '../../core/widgets/ui.dart';
import '../../data/catalog/habit_catalog.dart';
import '../../data/catalog/plant_catalog.dart';
import '../../state/app_state.dart';
import 'habit_editor_screen.dart';

/// Story 5: browse built-in habits.
class HabitLibraryScreen extends StatefulWidget {
  const HabitLibraryScreen({super.key});
  @override
  State<HabitLibraryScreen> createState() => _HabitLibraryScreenState();
}

class _HabitLibraryScreenState extends State<HabitLibraryScreen> {
  String _category = 'All';
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final tracked = s.activeHabits.map((h) => h.templateId).toSet();
    final q = _query.trim().toLowerCase();
    final items = HabitCatalog.templates.where((t) {
      final catOk = _category == 'All' || t.category == _category;
      final qOk = q.isEmpty || t.name.toLowerCase().contains(q) || t.description.toLowerCase().contains(q);
      return catOk && qOk;
    }).toList();

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: TopBar()),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(22, 4, 22, 0),
              sliver: SliverList.list(children: [
                const Eyebrow('Habit library'),
                const SizedBox(height: 8),
                Text('What will you\ngrow next?', style: context.text.displaySmall),
                const SizedBox(height: 18),
                TextField(
                  onChanged: (v) => setState(() => _query = v),
                  decoration: const InputDecoration(hintText: 'Search habits', prefixIcon: Icon(Icons.search_rounded)),
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
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: sel ? v.hero : v.card,
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(color: sel ? v.hero : v.line),
                          ),
                          child: Text(c, style: context.text.labelLarge?.copyWith(color: sel ? v.onHero : v.text)),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 18),
              ]),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 40),
              sliver: SliverList.separated(
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final t = items[i];
                  final added = tracked.contains(t.id);
                  return _TemplateTile(
                    template: t,
                    added: added,
                    onTap: added
                        ? () => showToast(context, 'Already in your garden.', icon: Icons.check_circle_rounded)
                        : () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => HabitSetupScreen(template: t))),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TemplateTile extends StatelessWidget {
  const _TemplateTile({required this.template, required this.added, required this.onTap});
  final HabitTemplate template;
  final bool added;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final v = context.v;
    final sp = PlantCatalog.byId(template.suggestedSpecies);
    return VCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
      child: Row(children: [
        IconSquare(HabitCatalog.icon(template.iconKey), color: sp.tint.o(0.14), iconColor: sp.tint),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(template.name, style: context.text.titleMedium),
            const SizedBox(height: 3),
            Text(template.description, style: context.text.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            Row(children: [
              Pill(template.category, dense: true),
              const SizedBox(width: 6),
              Pill(template.defaultFrequency.label, dense: true),
            ]),
          ]),
        ),
        const SizedBox(width: 8),
        SizedBox(
          height: 74,
          child: Stack(children: [
            PlantView(speciesId: sp.id, stage: 4, potId: 'ivory'),
            if (added)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(color: v.highlight, shape: BoxShape.circle),
                  child: Icon(Icons.check_rounded, size: 14, color: v.onHighlight),
                ),
              ),
          ]),
        ),
      ]),
    );
  }
}
