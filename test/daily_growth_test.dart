import 'package:flutter_test/flutter_test.dart';
import 'package:verdant/data/models/models.dart';
import 'package:verdant/data/repositories/in_memory.dart';
import 'package:verdant/domain/group_plants.dart';
import 'package:verdant/domain/rules.dart';
import 'package:verdant/state/app_state.dart';

class FailingGarden extends InMemoryGardenRepository {
  bool fail = false;
  @override
  Future<void> addCompletion(String uid, Completion completion) async {
    if (fail) throw Exception('Save failed');
    await super.addCompletion(uid, completion);
  }
}

void main() {
  final start = DateTime(2026, 10, 26);
  var now = start;
  setUp(() => now = start);
  List<Habit> habits() => [
        for (var i = 0; i < 2; i++)
          Habit(
              id: 'habit-$i',
              templateId: 'habit-$i',
              name: 'Habit $i',
              description: '',
              category: 'Growth',
              iconKey: 'spa',
              speciesId: 'sunflower',
              potId: 'terracotta',
              frequency: const HabitFrequency.daily(),
              createdAt: start)
      ];
  AppState setup(InMemoryGardenRepository repository) {
    final state = AppState(
        auth: InMemoryAuthRepository(),
        garden: repository,
        email: FakeEmailService(),
        updates: FakeUpdateService(),
        clock: () => now);
    state.user = UserProfile(
        uid: 'test',
        username: 'Test',
        email: 'test@example.com',
        createdAt: start);
    state.debugSet(habits: habits());
    addTearDown(state.dispose);
    return state;
  }

  test(
      'only completing the entire daily group grows once; duplicate clicks cannot grow again',
      () async {
    final state = setup(InMemoryGardenRepository());
    final h = state.activeHabits;
    final partial = await state.complete(h.first);
    expect(partial.grewStage, isFalse);
    expect(state.stageOf(h.first), 0);
    expect(
        state
            .cycleOf(h.first)!
            .dailyChecklist(state.completions, now)
            .completed,
        1);
    final all = await state.complete(h.last);
    expect(all.grewStage, isTrue);
    expect(state.stageOf(h.first), 1);
    expect(state.plantProgress(h.first), closeTo(1 / 7, 0.00001));
    expect((await state.complete(h.first)).status,
        CompletionStatus.duplicateToday);
    expect((await state.complete(h.last, day: Days.add(now, 1))).status,
        CompletionStatus.futureDate);
    expect(state.cycleOf(h.first)!.dailyCompletedDays, 1);
    expect(state.collectDailyPlant(), isFalse);
  });
  test(
      'seven completed days mature, undo reverses, and replanting starts tomorrow',
      () async {
    final state = setup(InMemoryGardenRepository());
    final h = state.activeHabits;
    for (var day = 0; day < 7; day++) {
      now = Days.add(start, day);
      for (final habit in h) {
        await state.complete(habit);
      }
      expect(state.cycleOf(h.first)!.dailyCompletedDays, day + 1);
      if (day < 6) expect(state.stageOf(h.first), lessThan(5));
    }
    expect(state.stageOf(h.first), 5);
    await state.undoToday(h.last);
    expect(state.cycleOf(h.first)!.dailyCompletedDays, 6);
    expect(state.collectDailyPlant(), isFalse);
    await state.complete(h.last);
    expect(state.collectDailyPlant(), isTrue);
    expect(state.groupGarden.collection.length, 1);
    expect(state.stageOf(h.first), 0);
    expect(state.cycleOf(h.first)!.start, Days.add(now, 1));
    state.refreshGroupPlants();
    expect(state.cycleOf(h.first)!.dailyCompletedDays, 0);
    now = Days.add(now, 1);
    for (final habit in h) {
      await state.complete(habit);
    }
    expect(state.cycleOf(h.first)!.dailyCompletedDays, 1);
    expect(state.validCount(h.first.id), 8);
  });
  test('failed final checkbox does not award growth; retry counts the day once',
      () async {
    final repository = FailingGarden();
    final state = setup(repository);
    final h = state.activeHabits;
    await state.complete(h.first);
    repository.fail = true;
    await expectLater(state.complete(h.last), throwsException);
    expect(state.cycleOf(h.first)!.dailyCompletedDays, 0);
    repository.fail = false;
    await state.complete(h.last);
    expect(state.cycleOf(h.first)!.dailyCompletedDays, 1);
  });
  test(
      'missed days pause growth; historical data and partial checklists do not count',
      () {
    final garden = GroupGarden();
    final h = habits();
    final history = [
      Completion(id: 'old', habitId: h.first.id, day: now, recordedAt: now)
    ];
    garden.sync(h, history, now);
    garden.sync(h, history, Days.add(now, 40));
    expect(garden.cycleFor(HabitGroup.daily)!.dailyCompletedDays, 0);
    final entries = [
      ...history,
      for (final habit in h)
        Completion(
            id: 'new-${habit.id}',
            habitId: habit.id,
            day: Days.add(now, 40),
            recordedAt: Days.add(now, 40))
    ];
    garden.sync(h, entries, Days.add(now, 40));
    expect(garden.cycleFor(HabitGroup.daily)!.dailyCompletedDays, 1);
    garden.sync(h, entries, Days.add(now, 80));
    expect(garden.cycleFor(HabitGroup.daily)!.dailyCompletedDays, 1);
    expect(garden.collection, isEmpty);
  });
  test(
      'removing an unfinished habit does not turn a partial checklist into a completed day',
      () async {
    final state = setup(InMemoryGardenRepository());
    final h = state.activeHabits;
    await state.complete(h.first);
    await state.archiveHabit(h.last);
    expect(state.cycleOf(h.first)!.dailyCompletedDays, 0);
    now = Days.add(now, 1);
    await state.complete(h.first);
    expect(state.cycleOf(h.first)!.dailyCompletedDays, 1);
  });
}
