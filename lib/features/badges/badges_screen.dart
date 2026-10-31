import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/verdant_theme.dart';
import '../../core/widgets/ui.dart';
import '../../data/catalog/badge_catalog.dart';
import '../../state/app_state.dart';
import '../share/share_sheet.dart';

/// Stories 20 & 21: earned badges + every milestone and its requirement.
class BadgesScreen extends StatelessWidget {
  const BadgesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final stats = s.stats;
    final earned = BadgeCatalog.badges.where((b) => s.hasBadge(b.id)).toList();
    final locked = BadgeCatalog.badges.where((b) => !s.hasBadge(b.id)).toList()
      ..sort((a, b) => (b.progress(stats) / b.target).compareTo(a.progress(stats) / a.target));

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(slivers: [
          SliverToBoxAdapter(
            child: TopBar(
              trailing: RoundIconButton(icon: Icons.ios_share_rounded, tooltip: 'Share badges', onTap: () => showShareSheet(context, preselectBadges: true)),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 8),
            sliver: SliverList.list(children: [
              const Eyebrow('Milestones'),
              const SizedBox(height: 8),
              Text('Badges', style: context.text.displaySmall),
              const SizedBox(height: 6),
              Text('${earned.length} earned · ${locked.length} to go', style: context.text.bodyLarge?.copyWith(color: context.v.muted)),
              const SizedBox(height: 22),
              if (earned.isNotEmpty) ...[const SectionHeader('Earned'), const SizedBox(height: 12)],
            ]),
          ),
          if (earned.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              sliver: SliverGrid.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.72),
                itemCount: earned.length,
                itemBuilder: (context, i) {
                  final b = earned[i];
                  final e = s.earnedBadges.firstWhere((x) => x.badgeId == b.id);
                  return VCard(
                    padding: const EdgeInsets.fromLTRB(8, 14, 8, 10),
                    onTap: () => _showDetail(context, b, earnedOn: e.earnedAt),
                    child: Column(children: [
                      BadgeMedal(icon: b.icon, tier: b.tier, size: 60),
                      const SizedBox(height: 10),
                      Text(b.name, textAlign: TextAlign.center, maxLines: 2, style: context.text.labelLarge),
                      const Spacer(),
                      Text(DateFormat('MMM d').format(e.earnedAt), style: context.text.bodySmall),
                    ]),
                  );
                },
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(22, 28, 22, 12),
            sliver: SliverToBoxAdapter(child: SectionHeader('Up next', eyebrow: 'Available milestones')),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 40),
            sliver: SliverList.separated(
              itemCount: locked.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final b = locked[i];
                final p = b.progress(stats).clamp(0, b.target);
                return VCard(
                  onTap: () => _showDetail(context, b),
                  padding: const EdgeInsets.all(14),
                  child: Row(children: [
                    BadgeMedal(icon: b.icon, tier: b.tier, size: 52, locked: true),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Expanded(child: Text(b.name, style: context.text.titleMedium)),
                          Text('$p / ${b.target}', style: context.text.labelLarge?.copyWith(color: context.colors.primary)),
                        ]),
                        const SizedBox(height: 3),
                        Text(b.description, style: context.text.bodySmall),
                        const SizedBox(height: 10),
                        ProgressBar(value: p / b.target, height: 5),
                      ]),
                    ),
                  ]),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }

  void _showDetail(BuildContext context, BadgeDef b, {DateTime? earnedOn}) {
    showModalBottomSheet<void>(
      context: context,
      builder: (c) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          BadgeMedal(icon: b.icon, tier: b.tier, size: 104, locked: earnedOn == null),
          const SizedBox(height: 16),
          Eyebrow('${b.tier.name} badge'),
          const SizedBox(height: 6),
          Text(b.name, style: c.text.headlineMedium),
          const SizedBox(height: 6),
          Text(b.description, textAlign: TextAlign.center, style: c.text.bodyLarge?.copyWith(color: c.v.muted)),
          const SizedBox(height: 10),
          Pill(earnedOn == null ? 'Not earned yet' : 'Earned ${DateFormat('MMMM d, y').format(earnedOn)}'),
        ]),
      ),
    );
  }
}
