import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/verdant_colors.dart';
import '../../core/theme/verdant_theme.dart';
import '../../core/widgets/plant_view.dart';
import '../../core/widgets/ui.dart';
import '../../data/catalog/badge_catalog.dart';
import '../../data/catalog/habit_catalog.dart';
import '../../data/models/models.dart';
import '../../domain/rules.dart';
import '../../state/app_state.dart';
import '../badges/badges_screen.dart';
import '../share/share_sheet.dart';

enum Period {
  week('Week', 7),
  month('Month', 30),
  quarter('3 Months', 91);

  const Period(this.label, this.days);
  final String label;
  final int days;
}

/// Stories 16, 17, 18.
class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});
  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  Period _period = Period.week;
  int _historyShown = 12;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final today = Days.today();
    final start = Days.add(today, -(_period.days - 1));
    final inPeriod = s.completions.where((c) => !c.day.isBefore(start) && !c.day.isAfter(today)).toList();

    // expected completions in the period → completion rate
    var expected = 0.0;
    for (final h in s.activeHabits) {
      final from = h.createdAt.isAfter(start) ? Days.of(h.createdAt) : start;
      final days = today.difference(from).inDays + 1;
      if (days <= 0) continue;
      expected += h.frequency.type == FrequencyType.daily ? days : days * h.frequency.timesPerWeek / 7;
    }
    final rate = expected == 0 ? 0.0 : (inPeriod.length / expected).clamp(0.0, 1.0);
    final stats = s.stats;

    // chart buckets
    final buckets = <_Bucket>[];
    if (_period == Period.quarter) {
      var ws = Days.weekStart(start);
      while (!ws.isAfter(today)) {
        final we = Days.add(ws, 7);
        buckets.add(_Bucket(DateFormat('MMM d').format(ws), inPeriod.where((c) => !c.day.isBefore(ws) && c.day.isBefore(we)).length, Days.same(ws, Days.weekStart(today))));
        ws = we;
      }
    } else {
      for (var i = 0; i < _period.days; i++) {
        final d = Days.add(start, i);
        final label = _period == Period.week ? DateFormat('E').format(d).substring(0, 2) : (d.day % 5 == 0 ? '${d.day}' : '');
        buckets.add(_Bucket(label, inPeriod.where((c) => Days.same(c.day, d)).length, Days.same(d, today)));
      }
    }

    final history = [...s.completions]..sort((a, b) => b.day.compareTo(a.day));

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 130),
        children: [
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Eyebrow('Insights'),
                const SizedBox(height: 8),
                Text('Progress', style: context.text.displaySmall),
              ]),
            ),
            RoundIconButton(icon: Icons.ios_share_rounded, tooltip: 'Share progress', onTap: () => showShareSheet(context)),
          ]),
          const SizedBox(height: 18),
          PillTabs<Period>(values: Period.values, selected: _period, label: (p) => p.label, onChanged: (p) => setState(() => _period = p)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _Stat(value: '${inPeriod.length}', label: 'Completions')),
            const SizedBox(width: 10),
            Expanded(child: _Stat(value: '${(rate * 100).round()}%', label: 'On target')),
            const SizedBox(width: 10),
            Expanded(child: _Stat(value: '${stats.longestStreak}d', label: 'Best streak')),
          ]),
          const SizedBox(height: 12),
          VCard(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(_period == Period.quarter ? 'Weekly Habit Completions' : 'Daily Habit Completions', style: context.text.titleMedium)),
                Text('${DateFormat('MMM d').format(start)} – ${DateFormat('MMM d').format(today)}', style: context.text.bodySmall),
              ]),
              const SizedBox(height: 18),
              SizedBox(height: 150, child: _BarChart(buckets: buckets)),
            ]),
          ),
          const SizedBox(height: 28),
          SectionHeader('This week’s goals', eyebrow: 'Story so far'),
          const SizedBox(height: 12),
          if (s.activeHabits.isEmpty)
            Text('Add a habit to start tracking goals.', style: context.text.bodyMedium?.copyWith(color: context.v.muted)),
          ...s.activeHabits.map((h) => Padding(padding: const EdgeInsets.only(bottom: 10), child: _GoalRow(habit: h))),
          const SizedBox(height: 18),
          const _BadgesTeaser(),
          const SizedBox(height: 28),
          const SectionHeader('History', eyebrow: 'Every watering'),
          const SizedBox(height: 6),
          ..._historyRows(context, s, history.take(_historyShown).toList()),
          if (history.length > _historyShown)
            TextButton(onPressed: () => setState(() => _historyShown += 20), child: const Text('Show more')),
          if (history.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text('Your habit completion history will appear here.', style: context.text.bodyMedium?.copyWith(color: context.v.muted)),
            ),
        ],
      ),
    );
  }

  List<Widget> _historyRows(BuildContext context, AppState s, List<Completion> items) {
    final out = <Widget>[];
    DateTime? lastDay;
    for (final c in items) {
      if (lastDay == null || !Days.same(lastDay, c.day)) {
        out.add(Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 6),
          child: Eyebrow(Days.same(c.day, Days.today())
              ? 'Today'
              : Days.same(c.day, Days.add(Days.today(), -1))
                  ? 'Yesterday'
                  : DateFormat('EEEE, MMM d').format(c.day)),
        ));
        lastDay = c.day;
      }
      final h = s.habitById(c.habitId);
      if (h == null) continue;
      out.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          SizedBox(width: 34, height: 40, child: PlantView(speciesId: h.speciesId, stage: s.stageOf(h), potId: h.potId)),
          const SizedBox(width: 12),
          Expanded(child: Text(h.name, style: context.text.bodyLarge)),
          Icon(HabitCatalog.icon(h.iconKey), size: 16, color: context.v.muted),
        ]),
      ));
    }
    return out;
  }
}

class _Bucket {
  const _Bucket(this.label, this.value, this.current);
  final String label;
  final int value;
  final bool current;
}

class _BarChart extends StatelessWidget {
  const _BarChart({required this.buckets});
  final List<_Bucket> buckets;
  @override
  Widget build(BuildContext context) {
    final v = context.v;
    final maxV = math.max(1, buckets.fold<int>(0, (m, b) => math.max(m, b.value)));
    final thin = buckets.length > 14;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final b in buckets)
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: thin ? 1.2 : 5),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (!thin && b.value > 0) Text('${b.value}', style: context.text.labelSmall?.copyWith(color: v.text, letterSpacing: 0)),
                  const SizedBox(height: 4),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: b.value / maxV),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutCubic,
                    builder: (context, f, _) => Container(
                      height: math.max(3.0, 104 * f),
                      decoration: BoxDecoration(
                        color: b.current ? v.highlight : (b.value == 0 ? v.line : context.colors.primary),
                        borderRadius: BorderRadius.circular(thin ? 3 : 8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 14,
                    child: Text(b.label, maxLines: 1, overflow: TextOverflow.visible, softWrap: false, style: context.text.labelSmall?.copyWith(letterSpacing: 0, fontSize: thin ? 9 : 10.5)),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) => VCard(
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: context.text.headlineMedium),
          const SizedBox(height: 4),
          Text(label, style: context.text.bodySmall),
        ]),
      );
}

class _GoalRow extends StatelessWidget {
  const _GoalRow({required this.habit});
  final Habit habit;
  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final done = s.weekCount(habit);
    // daily habits aim for 7 per Mon–Sun week
    final goal = habit.frequency.type == FrequencyType.daily ? 7 : habit.frequency.timesPerWeek;
    final ratio = (done / goal).clamp(0.0, 1.0);
    final met = done >= goal;
    return VCard(
      padding: const EdgeInsets.all(14),
      child: Row(children: [
        IconSquare(HabitCatalog.icon(habit.iconKey), size: 40),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(habit.name, style: context.text.titleSmall, overflow: TextOverflow.ellipsis)),
              Text('$done of $goal', style: context.text.labelLarge?.copyWith(color: met ? context.colors.primary : context.v.text)),
            ]),
            const SizedBox(height: 8),
            ProgressBar(value: ratio, color: met ? VerdantColors.fern : null),
          ]),
        ),
      ]),
    );
  }
}

class _BadgesTeaser extends StatelessWidget {
  const _BadgesTeaser();
  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final v = context.v;
    final earned = s.earnedBadges.length;
    final recent = BadgeCatalog.badges.where((b) => s.hasBadge(b.id)).take(4).toList();
    return VCard(
      onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const BadgesScreen())),
      color: v.hero,
      border: false,
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Eyebrow('Badges', color: v.onHero.o(0.6)),
            const SizedBox(height: 4),
            Text('$earned of ${BadgeCatalog.badges.length} earned', style: context.text.headlineSmall?.copyWith(color: v.onHero)),
            const SizedBox(height: 4),
            Text('See your milestones and see what’s next', style: context.text.bodySmall?.copyWith(color: v.onHero.o(0.6))),
          ]),
        ),
        SizedBox(
          width: 108,
          height: 56,
          child: Stack(children: [
            for (var i = 0; i < recent.length; i++)
              Positioned(left: i * 18.0, child: BadgeMedal(icon: recent[i].icon, tier: recent[i].tier, size: 52)),
          ]),
        ),
      ]),
    );
  }
}
