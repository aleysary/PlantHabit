import 'package:flutter_test/flutter_test.dart';
import 'package:verdant/data/models/models.dart';
import 'package:verdant/data/catalog/habit_catalog.dart';
import 'package:verdant/data/repositories/in_memory.dart';
import 'package:verdant/domain/group_plants.dart';
import 'package:verdant/domain/rules.dart';
import 'package:verdant/state/app_state.dart';

Habit h(String id, HabitFrequency frequency, DateTime created) => Habit(
    id: id,
    templateId: id,
    name: id,
    description: '',
    category: 'Home',
    iconKey: 'spa',
    speciesId: 'monstera',
    potId: 'ivory',
    frequency: frequency,
    createdAt: created);
Completion c(String id, DateTime day) => Completion(
    id: '$id-${Days.key(day)}', habitId: id, day: day, recordedAt: day);

void main() {
  final start = DateTime(2026, 10, 26);
  test('each group has a fixed plant and appropriate maturity target', () {
    expect(HabitGroup.of(const HabitFrequency.daily()).speciesId, 'sunflower');
    expect(HabitGroup.of(const HabitFrequency.weekly(3)).speciesId, 'cactus');
    expect(HabitGroup.of(const HabitFrequency.weekly(1)).speciesId, 'olive');
    expect(HabitGroup.of(const HabitFrequency.biweekly()).speciesId, 'bonsai');
    expect(HabitGroup.of(const HabitFrequency.monthly()).speciesId,
        'cherry_blossom');
    expect(HabitGroup.weekly.targetCycles, 4);
    expect(HabitGroup.biweekly.targetCycles, 4);
    expect(HabitGroup.monthly.targetCycles, 1);
  });
  test('four finished weekly cycles mature; no growth from elapsed time alone',
      () {
    final garden = GroupGarden();
    final habits = [
      h('a', const HabitFrequency.weekly(1), start),
      h('b', const HabitFrequency.weekly(1), start)
    ];
    final entries = <Completion>[];
    garden.sync(habits, entries, start);
    final plant = garden.current.single;
    for (var week = 0; week < 4; week++) {
      entries.add(c('a', Days.add(start, week * 7)));
      garden.sync(habits, entries, Days.add(start, week * 7));
      if (week == 0) expect(plant.progressAt(start), 0);
      entries.add(c('b', Days.add(start, week * 7 + 1)));
      garden.sync(habits, entries, Days.add(start, week * 7 + 1));
      expect(plant.ready, isFalse);
      expect(plant.completedCycles, week);
      garden.sync(habits, entries, Days.add(start, (week + 1) * 7));
      expect(plant.completedCycles, week + 1);
    }
    expect(plant.stageAt(Days.add(start, 28)), 5);
    expect(garden.collection, isEmpty);
    expect(
        garden.collect(HabitGroup.weekly, habits, entries, Days.add(start, 28)),
        isTrue);
    expect(garden.collection.length, 1);
    expect(garden.current.single.progressAt(Days.add(start, 28)), 0);
    garden.sync(habits, entries, Days.add(start, 100));
    expect(garden.current.single.completedCycles, 0);
    expect(garden.collection.length, 1);
  });
  test(
      'an incomplete week does not count; a later completed week can replace it',
      () {
    final garden = GroupGarden();
    final habits = [
      h('a', const HabitFrequency.weekly(1), start),
      h('b', const HabitFrequency.weekly(1), start)
    ];
    garden.sync(habits, [], start);
    final entries = [
      for (var w = 0; w < 4; w++) ...[
        c('a', Days.add(start, w * 7)),
        if (w != 1) c('b', Days.add(start, w * 7 + 1))
      ]
    ];
    garden.sync(habits, entries, Days.add(start, 28));
    expect(garden.current.single.completedCycles, 3);
    expect(garden.current.single.ready, isFalse);
    entries.addAll([c('a', Days.add(start, 28)), c('b', Days.add(start, 29))]);
    garden.sync(habits, entries, Days.add(start, 35));
    expect(garden.current.single.ready, isTrue);
  });
  test('several-times-a-week group requires every target on distinct dates',
      () {
    final garden = GroupGarden();
    final habits = [
      h('exercise', const HabitFrequency.weekly(3), start),
      h('practice', const HabitFrequency.weekly(2), start)
    ];
    garden.sync(habits, [], start);
    final entries = [
      c('exercise', start),
      c('exercise', Days.add(start, 1)),
      c('practice', start),
      c('practice', Days.add(start, 1)),
      Completion(
          id: 'fake-duplicate',
          habitId: 'exercise',
          day: start,
          recordedAt: start)
    ];
    garden.sync(habits, entries, Days.add(start, 2));
    expect(
        garden.current.single.checklist(entries, Days.add(start, 2)).completed,
        4);
    expect(garden.current.single.progressAt(Days.add(start, 2)), 0);
    entries.add(c('exercise', Days.add(start, 2)));
    garden.sync(habits, entries, Days.add(start, 2));
    expect(
        garden.current.single.progressAt(Days.add(start, 2)), greaterThan(0));
    expect(garden.current.single.completedCycles, 0);
    garden.sync(habits, entries, Days.add(start, 7));
    expect(garden.current.single.completedCycles, 1);
  });
  test(
      'bi-weekly plant needs four finished fortnights, not four clicks or weeks',
      () {
    final garden = GroupGarden();
    final habits = [
      h('a', const HabitFrequency.biweekly(), start),
      h('b', const HabitFrequency.biweekly(), start)
    ];
    garden.sync(habits, [], start);
    final entries = <Completion>[];
    for (var p = 0; p < 4; p++) {
      entries.addAll([
        c('a', Days.add(start, p * 14)),
        c('b', Days.add(start, p * 14 + 1))
      ]);
      garden.sync(habits, entries, Days.add(start, p * 14 + 1));
      expect(garden.current.single.ready, isFalse);
      garden.sync(habits, entries, Days.add(start, (p + 1) * 14));
      expect(garden.current.single.completedCycles, p + 1);
    }
    expect(garden.current.single.ready, isTrue);
    expect(
        garden.collect(
            HabitGroup.biweekly, habits, entries, Days.add(start, 56)),
        isTrue);
    expect(garden.current.single.periodAnchor, start);
  });
  test('monthly grows per checked habit and collecting waits until next month',
      () {
    final garden = GroupGarden();
    final habits = [
      h('a', const HabitFrequency.monthly(), start),
      h('b', const HabitFrequency.monthly(), start)
    ];
    garden.sync(habits, [], start);
    final entries = [c('a', start)];
    garden.sync(habits, entries, start);
    expect(garden.current.single.progressAt(start), 0.5);
    expect(garden.current.single.ready, isFalse);
    entries.add(c('b', Days.add(start, 1)));
    garden.sync(habits, entries, Days.add(start, 1));
    expect(garden.current.single.stageAt(Days.add(start, 1)), 5);
    expect(
        garden.collect(HabitGroup.monthly, habits, entries, Days.add(start, 1)),
        isTrue);
    expect(garden.current.single.start, DateTime(2026, 11, 1));
    garden.sync(habits, entries, Days.add(start, 2));
    expect(garden.current.single.progressAt(Days.add(start, 2)), 0);
    entries.add(c('a', DateTime(2026, 11, 1)));
    garden.sync(habits, entries, DateTime(2026, 11, 1));
    expect(garden.current.single.progressAt(DateTime(2026, 11, 1)), 0.5);
    expect(garden.collection.length, 1);
  });
  test(
      'month boundary collects a mature plant but never invents a mature unfinished plant',
      () {
    for (final finish in [false, true]) {
      final garden = GroupGarden();
      final habits = [
        h('a', const HabitFrequency.monthly(), start),
        h('b', const HabitFrequency.monthly(), start)
      ];
      garden.sync(habits, [], start);
      final entries = [c('a', start), if (finish) c('b', start)];
      garden.sync(habits, entries, start);
      garden.sync(habits, entries, DateTime(2026, 11, 1));
      expect(garden.collection.length, finish ? 1 : 0);
      expect(garden.current.single.progressAt(DateTime(2026, 11, 1)), 0);
    }
  });
  test('undo and tracking edits cannot falsely complete a monthly checklist',
      () {
    final garden = GroupGarden();
    final a = h('a', const HabitFrequency.monthly(), start);
    final b = h('b', const HabitFrequency.monthly(), start);
    garden.sync([a, b], [], start);
    final entries = [c('a', start)];
    garden.sync([a, b], entries, start);
    garden.sync([a, b.copyWith(archivedAt: start)], entries, start);
    expect(garden.current.single.progressAt(start), 0.5);
    garden.sync([a, b], entries, Days.add(start, 1));
    entries.add(c('b', Days.add(start, 1)));
    garden.sync([a, b], entries, Days.add(start, 1));
    expect(garden.current.single.ready, isTrue);
    entries.removeLast();
    garden.sync([a, b], entries, Days.add(start, 1));
    expect(garden.current.single.ready, isFalse);
  });
  test(
      'late bi-weekly habit shares the group boundary; undo removes only the current period entry',
      () async {
    var now = start;
    final state = AppState(
        auth: InMemoryAuthRepository(),
        garden: InMemoryGardenRepository(),
        email: FakeEmailService(),
        updates: FakeUpdateService(),
        clock: () => now);
    addTearDown(state.dispose);
    state.user = UserProfile(
        uid: 'test',
        username: 'Test',
        email: 'test@example.com',
        createdAt: start);
    Future<Habit> add(String id) => state.addHabit(
        template: HabitTemplate(
            id: id,
            name: id,
            description: '',
            category: 'Home',
            iconKey: 'spa',
            suggestedSpecies: 'bonsai',
            defaultFrequency: const HabitFrequency.biweekly()),
        speciesId: 'bonsai',
        potId: 'terracotta',
        frequency: const HabitFrequency.biweekly());
    final a = await add('a');
    now = Days.add(start, 3);
    final b = await add('b');
    await state.complete(a);
    await state.complete(b);
    now = Days.add(start, 14);
    expect((await state.complete(b)).status, CompletionStatus.accepted);
    expect(state.periodCount(b), 1);
    now = Days.add(start, 15);
    expect(
        (await state.complete(b)).status, CompletionStatus.periodTargetReached);
    await state.undoGroupCompletion(b);
    expect(state.periodCount(b), 0);
    expect(state.validCount(b.id), 1);
  });
  test('calendars handle leap months and DST using local dates', () {
    expect(HabitGroup.monthly.bounds(DateTime(2028, 2, 29), start).$2,
        DateTime(2028, 3, 1));
    expect(HabitGroup.biweekly.bounds(DateTime(2026, 11, 9), start).$1,
        DateTime(2026, 11, 9));
  });
  test('separate users and app restarts have separate in-memory gardens', () {
    final state = AppState(
        auth: InMemoryAuthRepository(),
        garden: InMemoryGardenRepository(),
        email: FakeEmailService(),
        updates: FakeUpdateService());
    addTearDown(state.dispose);
    state.user = UserProfile(
        uid: 'a', username: 'A', email: 'a@example.com', createdAt: start);
    state.debugSet(habits: [h('daily', const HabitFrequency.daily(), start)]);
    expect(state.groupGarden.current.length, 1);
    state.user = UserProfile(
        uid: 'b', username: 'B', email: 'b@example.com', createdAt: start);
    expect(state.groupGarden.current, isEmpty);
    state.user = UserProfile(
        uid: 'a', username: 'A', email: 'a@example.com', createdAt: start);
    expect(state.groupGarden.current.length, 1);
    expect(GroupGarden().current, isEmpty);
  });
}
