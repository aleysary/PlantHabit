import '../data/catalog/plant_catalog.dart';
import '../data/models/models.dart';

/// Date helpers. All tracking happens on local calendar days.
class Days {
  Days._();
  static DateTime of(DateTime d) => DateTime(d.year, d.month, d.day);
  static DateTime today() => of(DateTime.now());
  static bool same(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  /// Monday of the week containing [d].
  static DateTime weekStart(DateTime d) => of(d).subtract(Duration(days: d.weekday - 1));
  static DateTime add(DateTime d, int days) => DateTime(d.year, d.month, d.day + days);
  static int key(DateTime d) => d.year * 10000 + d.month * 100 + d.day;
}

/// Outcome of trying to record a completion (stories 10 & 12).
enum CompletionStatus {
  accepted,
  duplicateToday,
  weeklyTargetReached,
  habitInactive,
  futureDate,
}

extension CompletionStatusMessage on CompletionStatus {
  String get message => switch (this) {
        CompletionStatus.accepted => 'Nice — logged.',
        CompletionStatus.duplicateToday => 'Already logged today. Your plant only grows once a day per habit.',
        CompletionStatus.weeklyTargetReached => 'You’ve hit this week’s target. Rest up — it resets Monday.',
        CompletionStatus.habitInactive => 'This habit is no longer being tracked.',
        CompletionStatus.futureDate => 'You can’t log a day that hasn’t happened yet.',
      };
}

/// Validates completions. A completion is accepted only once per habit per day,
/// and for weekly habits only up to the weekly target.
class CompletionRules {
  const CompletionRules();

  CompletionStatus validate({
    required Habit habit,
    required DateTime day,
    required Iterable<Completion> existing,
    DateTime? now,
  }) {
    final d = Days.of(day);
    if (!habit.isActive) return CompletionStatus.habitInactive;
    if (d.isAfter(Days.of(now ?? DateTime.now()))) return CompletionStatus.futureDate;
    final mine = existing.where((c) => c.habitId == habit.id);
    if (mine.any((c) => Days.same(c.day, d))) return CompletionStatus.duplicateToday;
    if (habit.frequency.type == FrequencyType.weekly) {
      final ws = Days.weekStart(d);
      final we = Days.add(ws, 7);
      final inWeek = mine.where((c) => !c.day.isBefore(ws) && c.day.isBefore(we)).length;
      if (inWeek >= habit.frequency.timesPerWeek) return CompletionStatus.weeklyTargetReached;
    }
    return CompletionStatus.accepted;
  }
}

/// Plant growth (stories 11 & 15). Growth is driven only by accepted
/// completions, so invalid/duplicate entries can never inflate a plant.
class GrowthRules {
  const GrowthRules();

  int stageFor(int validCompletions) {
    var stage = 0;
    for (final s in PlantCatalog.stages) {
      if (validCompletions >= s.threshold) stage = s.index;
    }
    return stage;
  }

  /// Completions needed for the next stage, or null if fully grown.
  int? nextThreshold(int validCompletions) {
    final s = stageFor(validCompletions);
    if (s >= PlantCatalog.stages.length - 1) return null;
    return PlantCatalog.stages[s + 1].threshold;
  }

  /// 0..1 progress within the current stage.
  double stageProgress(int validCompletions) {
    final s = stageFor(validCompletions);
    final next = nextThreshold(validCompletions);
    if (next == null) return 1;
    final from = PlantCatalog.stages[s].threshold;
    return ((validCompletions - from) / (next - from)).clamp(0.0, 1.0);
  }
}

/// Aggregates used by progress screens and badge checks.
class GardenStats {
  const GardenStats({
    required this.totalCompletions,
    required this.currentStreak,
    required this.longestStreak,
    required this.activeHabits,
    required this.plantsAtFinalStage,
    required this.distinctSpecies,
    required this.perfectWeeks,
  });

  final int totalCompletions;
  final int currentStreak;
  final int longestStreak;
  final int activeHabits;
  final int plantsAtFinalStage;
  final int distinctSpecies;
  final int perfectWeeks;

  static GardenStats compute(List<Habit> habits, List<Completion> completions, {DateTime? now}) {
    const growth = GrowthRules();
    final today = Days.of(now ?? DateTime.now());
    final days = completions.map((c) => Days.key(c.day)).toSet();

    // current streak: count back from today (or yesterday if today is empty)
    var cursor = days.contains(Days.key(today)) ? today : Days.add(today, -1);
    var current = 0;
    while (days.contains(Days.key(cursor))) {
      current++;
      cursor = Days.add(cursor, -1);
    }

    final sorted = completions.map((c) => Days.of(c.day)).toSet().toList()..sort();
    var longest = 0;
    var run = 0;
    DateTime? prev;
    for (final d in sorted) {
      run = (prev != null && Days.same(Days.add(prev, 1), d)) ? run + 1 : 1;
      if (run > longest) longest = run;
      prev = d;
    }

    final perHabit = <String, int>{};
    for (final c in completions) {
      perHabit[c.habitId] = (perHabit[c.habitId] ?? 0) + 1;
    }
    final finals = habits.where((h) => growth.stageFor(perHabit[h.id] ?? 0) == PlantCatalog.stages.length - 1).length;

    // perfect weeks: weeks where every active daily habit hit 7 and weekly hit target
    var perfect = 0;
    final active = habits.where((h) => h.isActive).toList();
    if (active.isNotEmpty) {
      for (var w = 1; w <= 12; w++) {
        final ws = Days.add(Days.weekStart(today), -7 * w);
        final we = Days.add(ws, 7);
        final ok = active.every((h) {
          if (h.createdAt.isAfter(ws)) return false;
          final n = completions.where((c) => c.habitId == h.id && !c.day.isBefore(ws) && c.day.isBefore(we)).length;
          return n >= h.frequency.timesPerWeek;
        });
        if (ok) perfect++;
      }
    }

    return GardenStats(
      totalCompletions: completions.length,
      currentStreak: current,
      longestStreak: longest,
      activeHabits: active.length,
      plantsAtFinalStage: finals,
      distinctSpecies: habits.map((h) => h.speciesId).toSet().length,
      perfectWeeks: perfect,
    );
  }
}
