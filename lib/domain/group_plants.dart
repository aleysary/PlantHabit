import '../data/models/models.dart';
import 'rules.dart';

enum HabitGroup {
  daily('Daily habits', 'sunflower', HabitFrequency.daily()),
  several('A few times a week', 'cactus', HabitFrequency.weekly(3)),
  weekly('Weekly habits', 'olive', HabitFrequency.weekly(1)),
  biweekly('Every two weeks', 'bonsai', HabitFrequency.biweekly()),
  monthly('Monthly habits', 'cherry_blossom', HabitFrequency.monthly());

  const HabitGroup(this.label, this.speciesId, this.frequency);
  final String label;

  /// The plant a group starts with. Users can pick a different one; see
  /// [groupSpecies] for the plant a group actually grows.
  final String speciesId;
  final HabitFrequency frequency;
  String get potId => 'terracotta';
  int get targetCycles => this == daily
      ? 7
      : this == monthly
          ? 1
          : 4;
  String get maturityLabel => switch (this) {
        daily => '7 completed days',
        several || weekly => '4 completed weeks',
        biweekly => '4 completed fortnights',
        monthly => 'One full monthly checklist',
      };
  String get instructions => switch (this) {
        daily =>
          'Complete every daily habit to grow your plant once a day. Seven completed days make it fully grown. Missed days pause progress.',
        several =>
          'Log each habit on the days you do it until its weekly target is met. Meeting every target grows your plant. Four finished, fully completed weeks make it fully grown.',
        weekly =>
          'Check off every habit this week to grow your plant. Four finished, fully completed weeks make it fully grown. Weeks reset on Monday.',
        biweekly =>
          'Check off every habit in each two-week period to grow your plant. Four finished, fully completed fortnights make it fully grown.',
        monthly =>
          'Each monthly habit you check grows your plant. Complete the whole checklist to make it fully grown. Collect it when ready; your next seed starts next month.',
      };
  static HabitGroup of(HabitFrequency frequency) => switch (frequency.type) {
        FrequencyType.daily => daily,
        FrequencyType.weekly => frequency.timesPerWeek == 1 ? weekly : several,
        FrequencyType.biweekly => biweekly,
        FrequencyType.monthly => monthly,
      };
  (DateTime, DateTime) bounds(DateTime day, DateTime anchor) {
    final date = Days.of(day);
    return switch (this) {
      daily => (date, Days.add(date, 1)),
      several || weekly => (
          Days.weekStart(date),
          Days.add(Days.weekStart(date), 7)
        ),
      monthly => (
          DateTime(day.year, day.month),
          DateTime(day.year, day.month + 1)
        ),
      biweekly => _fortnight(date, anchor),
    };
  }

  static (DateTime, DateTime) _fortnight(DateTime day, DateTime anchor) {
    final days = DateTime.utc(day.year, day.month, day.day)
        .difference(DateTime.utc(anchor.year, anchor.month, anchor.day))
        .inDays;
    final from = Days.add(anchor, (days / 14).floor() * 14);
    return (from, Days.add(from, 14));
  }
}

/// The plant [group] grows. Habits in a group share one plant, so this is the
/// plant its active habits use (chosen by the user when creating or editing a
/// habit), then a resting habit's, then the group's default.
String groupSpecies(HabitGroup group, Iterable<Habit> habits,
    {String? exceptId}) {
  String? resting;
  for (final h in habits) {
    if (h.id == exceptId || HabitGroup.of(h.frequency) != group) continue;
    if (h.isActive) return h.speciesId;
    resting ??= h.speciesId;
  }
  return resting ?? group.speciesId;
}

class GroupCare {
  const GroupCare(this.completed, this.required);
  final int completed;
  final int required;
  bool get flower => required > 0 && completed >= required;
  double get ratio =>
      required == 0 ? 0 : (completed / required).clamp(0.0, 1.0);
  String get label => required == 0
      ? 'No checklist started yet'
      : '$completed of $required care tasks completed';
}

class _Membership {
  _Membership(this.habit, this.joined, this.existingIds);
  final Habit habit;
  final DateTime joined;
  final Set<String> existingIds;
  DateTime? left;
}

class _Plan {
  _Plan(this.start, this.end, this.goals);
  final DateTime start;
  final DateTime end;
  final Map<String, int> goals;
}

/// Checklists freeze when their first entry is recorded. Editing tracking cannot
/// turn an unfinished checklist into a completed period retroactively.
class GroupPlantCycle {
  GroupPlantCycle(this.group, this.start, {DateTime? anchor})
      : periodAnchor = anchor ?? start;
  final HabitGroup group;
  final DateTime start;
  final DateTime periodAnchor;
  final List<_Membership> _members = [];
  final Set<String> _eligibleIds = {};
  final Map<int, _Plan> _plans = {};
  int _completedCycles = 0;
  double _progress = 0;
  int get completedCycles => _completedCycles;
  int get dailyCompletedDays =>
      group == HabitGroup.daily ? _completedCycles : 0;
  bool get ready => _progress >= 1;
  DateTime get end => group.bounds(start, periodAnchor).$2;
  int dayAt(DateTime now) =>
      DateTime.utc(now.year, now.month, now.day)
          .difference(DateTime.utc(start.year, start.month, start.day))
          .inDays +
      1;
  double progressAt(DateTime now) => _progress;
  int stageAt(DateTime now) {
    if (group == HabitGroup.daily) {
      return const [0, 1, 2, 3, 3, 4, 4, 5][dailyCompletedDays];
    }
    if (ready) return 5;
    return _progress == 0 ? 0 : (_progress * 4).ceil().clamp(1, 4);
  }

  String growthLabelAt(DateTime now) => switch (group) {
        HabitGroup.daily => '$dailyCompletedDays of 7 completed days',
        HabitGroup.several ||
        HabitGroup.weekly =>
          '$completedCycles of 4 completed weeks',
        HabitGroup.biweekly => '$completedCycles of 4 completed fortnights',
        HabitGroup.monthly =>
          '${(_progress * 100).round()}% of monthly checklist',
      };
  _Plan _planFor(DateTime day) {
    final (from, until) = group.bounds(day, periodAnchor);
    final goals = <String, int>{};
    for (final m in _members.where((m) =>
        !day.isBefore(m.joined) && (m.left == null || day.isBefore(m.left!)))) {
      var goal = 1;
      if (group == HabitGroup.several) {
        final joined = m.joined.isAfter(from) ? m.joined : from;
        final available = DateTime.utc(until.year, until.month, until.day)
            .difference(DateTime.utc(joined.year, joined.month, joined.day))
            .inDays;
        goal = m.habit.frequency.timesPerWeek.clamp(1, available.clamp(1, 7));
      }
      goals[m.habit.id] = goal;
    }
    return _Plan(from, until, goals);
  }

  GroupCare _count(_Plan plan, Iterable<Completion> completions, DateTime now) {
    var done = 0;
    var required = 0;
    for (final goal in plan.goals.entries) {
      final dates = completions
          .where((c) =>
              _eligibleIds.contains(c.id) &&
              c.habitId == goal.key &&
              !c.day.isBefore(plan.start) &&
              c.day.isBefore(plan.end) &&
              !c.day.isAfter(Days.of(now)))
          .map((c) => Days.key(c.day))
          .toSet();
      done += dates.length.clamp(0, goal.value);
      required += goal.value;
    }
    return GroupCare(done, required);
  }

  GroupCare checklist(Iterable<Completion> completions, DateTime now) {
    if (now.isBefore(start)) return const GroupCare(0, 0);
    final key = Days.key(group.bounds(now, periodAnchor).$1);
    return _count(_plans[key] ?? _planFor(now), completions, now);
  }

  GroupCare dailyChecklist(Iterable<Completion> completions, DateTime now) =>
      checklist(completions, now);
  GroupCare care(Iterable<Completion> completions, DateTime now) {
    var done = 0;
    var required = 0;
    for (final plan in _plans.values) {
      final count = _count(plan, completions, now);
      done += count.completed;
      required += count.required;
    }
    return GroupCare(done, required);
  }

  void _syncMembers(
      List<Habit> habits, List<Completion> completions, DateTime now) {
    final active = {
      for (final h in habits
          .where((h) => h.isActive && HabitGroup.of(h.frequency) == group))
        h.id: h
    };
    for (final member in _members.where((m) => m.left == null)) {
      final latest = active[member.habit.id];
      if (latest == null || latest.frequency != member.habit.frequency) {
        member.left = Days.of(now);
      }
    }
    for (final h in active.values) {
      if (!_members.any((m) => m.left == null && m.habit.id == h.id)) {
        _members.add(_Membership(
            h,
            now.isBefore(start) ? start : Days.of(now),
            completions
                .where((c) => c.habitId == h.id)
                .map((c) => c.id)
                .toSet()));
      }
    }
  }

  void _capture(List<Completion> completions, DateTime now) {
    for (final entry in completions) {
      if (entry.day.isBefore(start) || entry.day.isAfter(Days.of(now))) {
        continue;
      }
      if (_members.any((m) =>
          m.habit.id == entry.habitId &&
          !m.existingIds.contains(entry.id) &&
          !entry.day.isBefore(m.joined) &&
          (m.left == null || entry.day.isBefore(m.left!)))) {
        final key = Days.key(group.bounds(entry.day, periodAnchor).$1);
        _plans.putIfAbsent(key, () => _planFor(entry.day));
        _eligibleIds.add(entry.id);
      }
    }
    final relevant = group == HabitGroup.monthly
        ? _plans.values.where(
            (p) => Days.same(p.start, group.bounds(start, periodAnchor).$1))
        : _plans.values;
    _completedCycles = relevant
        .where((p) =>
            _count(p, completions, now).flower &&
            (group == HabitGroup.daily ||
                group == HabitGroup.monthly ||
                !now.isBefore(p.end)))
        .length
        .clamp(0, group.targetCycles);
    if (group == HabitGroup.monthly) {
      final key = Days.key(group.bounds(start, periodAnchor).$1);
      _progress = _plans[key] == null
          ? 0
          : _count(_plans[key]!, completions, now).ratio;
    } else {
      _progress = _completedCycles / group.targetCycles;
      if (group != HabitGroup.daily && !ready) {
        // A completed checklist gives visible growth while awaiting the period end.
        if (checklist(completions, now).flower) {
          _progress =
              ((_completedCycles + 0.5) / group.targetCycles).clamp(0.0, 0.99);
        }
      }
    }
  }
}

class CollectedGroupPlant {
  CollectedGroupPlant(this.group, this.start, this.finished, this.care,
      [String? speciesId])
      : speciesId = speciesId ?? group.speciesId;
  final HabitGroup group;

  /// The plant that was grown, kept so the collection still shows it after
  /// the group switches to a different plant.
  final String speciesId;
  final DateTime start;
  final DateTime finished;
  final GroupCare care;
}

class GroupGarden {
  final Map<HabitGroup, GroupPlantCycle> _current = {};
  final List<CollectedGroupPlant> _collection = [];
  List<GroupPlantCycle> get current => List.unmodifiable(_current.values);
  List<CollectedGroupPlant> get collection =>
      List.unmodifiable(_collection.reversed);
  GroupPlantCycle? cycleFor(HabitGroup group) => _current[group];
  void sync(List<Habit> habits, List<Completion> completions, DateTime now) {
    final today = Days.of(now);
    for (final group in HabitGroup.values) {
      var cycle = _current[group];
      cycle?._capture(completions, today);
      if (group == HabitGroup.monthly &&
          cycle != null &&
          !today.isBefore(cycle.end)) {
        if (cycle.ready) {
          _collection.add(CollectedGroupPlant(
              group,
              cycle.start,
              cycle.end,
              cycle.care(completions, Days.add(cycle.end, -1)),
              groupSpecies(group, habits)));
        }
        _current.remove(group);
        cycle = null;
      }
      final active = habits
          .where((h) => h.isActive && HabitGroup.of(h.frequency) == group)
          .toList();
      if (cycle == null && active.isNotEmpty) {
        cycle = GroupPlantCycle(group, today);
        _current[group] = cycle;
      }
      if (cycle != null) {
        cycle._syncMembers(habits, completions, today);
        cycle._capture(completions, today);
      }
    }
  }

  bool collect(HabitGroup group, List<Habit> habits,
      List<Completion> completions, DateTime now) {
    sync(habits, completions, now);
    final cycle = _current[group];
    if (cycle == null || !cycle.ready) return false;
    final today = Days.of(now);
    _collection.add(CollectedGroupPlant(group, cycle.start, Days.add(today, 1),
        cycle.care(completions, today), groupSpecies(group, habits)));
    _current.remove(group);
    final (periodStart, periodEnd) = group.bounds(today, cycle.periodAnchor);
    final nextStart = group == HabitGroup.daily ||
            group == HabitGroup.monthly ||
            !Days.same(today, periodStart)
        ? periodEnd
        : periodStart;
    final active = habits
        .where((h) => h.isActive && HabitGroup.of(h.frequency) == group)
        .toList();
    if (active.isNotEmpty) {
      final next =
          GroupPlantCycle(group, nextStart, anchor: cycle.periodAnchor);
      next._syncMembers(habits, completions, nextStart);
      _current[group] = next;
    }
    return true;
  }

  bool collectDaily(
          List<Habit> habits, List<Completion> completions, DateTime now) =>
      collect(HabitGroup.daily, habits, completions, now);
}
