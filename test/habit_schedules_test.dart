import 'package:flutter_test/flutter_test.dart';
import 'package:verdant/data/catalog/habit_catalog.dart';
import 'package:verdant/data/models/models.dart';
import 'package:verdant/data/repositories/in_memory.dart';
import 'package:verdant/domain/rules.dart';
import 'package:verdant/state/app_state.dart';

Habit habit(HabitFrequency frequency, DateTime created) => Habit(
      id: 'h',
      templateId: 'custom-h',
      name: 'My habit',
      description: '',
      category: 'Home',
      iconKey: 'spa',
      speciesId: 'olive',
      potId: 'ivory',
      frequency: frequency,
      createdAt: created,
    );
Completion completion(DateTime day) =>
    Completion(id: 'c', habitId: 'h', day: day, recordedAt: day);

void main() {
  const rules = CompletionRules();
  test('all frequency values survive storage round trips', () {
    for (final frequency in [
      const HabitFrequency.daily(),
      const HabitFrequency.weekly(3),
      const HabitFrequency.biweekly(),
      const HabitFrequency.monthly()
    ]) {
      expect(HabitFrequency.fromJson(frequency.toJson()), frequency);
    }
  });
  test('fortnight resets exactly 14 calendar days after creation', () {
    final h = habit(const HabitFrequency.biweekly(), DateTime(2026, 10, 25));
    final existing = [completion(DateTime(2026, 10, 26))];
    expect(
        rules.validate(
            habit: h,
            day: DateTime(2026, 11, 7),
            existing: existing,
            now: DateTime(2026, 11, 9)),
        CompletionStatus.periodTargetReached);
    expect(
        rules.validate(
            habit: h,
            day: DateTime(2026, 11, 8),
            existing: existing,
            now: DateTime(2026, 11, 9)),
        CompletionStatus.accepted);
  });
  test('monthly target resets on next calendar month including leap years', () {
    final h = habit(const HabitFrequency.monthly(), DateTime(2028, 2, 1));
    final existing = [completion(DateTime(2028, 2, 2))];
    expect(
        rules.validate(
            habit: h,
            day: DateTime(2028, 2, 29),
            existing: existing,
            now: DateTime(2028, 3, 1)),
        CompletionStatus.periodTargetReached);
    expect(
        rules.validate(
            habit: h,
            day: DateTime(2028, 3, 1),
            existing: existing,
            now: DateTime(2028, 3, 1)),
        CompletionStatus.accepted);
  });
  test('longer schedules retain duplicate and future-date protections', () {
    final day = DateTime(2026, 10, 30);
    final h = habit(const HabitFrequency.monthly(), day);
    expect(
        rules.validate(
            habit: h, day: day, existing: [completion(day)], now: day),
        CompletionStatus.duplicateToday);
    expect(
        rules.validate(habit: h, day: Days.add(day, 1), existing: [], now: day),
        CompletionStatus.futureDate);
  });
  test('custom habit preserves schedule, plant and name in the repository',
      () async {
    final repository = InMemoryGardenRepository();
    final state = AppState(
        auth: InMemoryAuthRepository(),
        garden: repository,
        email: FakeEmailService(),
        updates: FakeUpdateService());
    addTearDown(state.dispose);
    await state.signIn(kDemoEmail, kDemoPassword);
    final h = await state.addHabit(
      template: const HabitTemplate(
          id: 'custom-test',
          name: 'Wash bedding',
          description: 'Fresh sheets',
          category: 'Home',
          iconKey: 'tidy',
          suggestedSpecies: 'olive',
          defaultFrequency: HabitFrequency.biweekly()),
      speciesId: 'olive',
      potId: 'ivory',
      frequency: const HabitFrequency.biweekly(),
    );
    expect(
        (await repository.loadHabits(state.user!.uid))
            .any((saved) => saved.id == h.id && saved.name == 'Wash bedding'),
        isTrue);
    await state.complete(h);
    expect(state.periodCount(h), 1);
    expect((await state.complete(h)).status, CompletionStatus.duplicateToday);
    state.debugSet(completions: [
      Completion(
          id: 'previous',
          habitId: h.id,
          day: Days.add(Days.today(), -1),
          recordedAt: Days.today())
    ]);
    final monthly = h.copyWith(frequency: const HabitFrequency.monthly());
    if (Days.today().day > 1) expect(state.isDueToday(monthly), isFalse);
  });
}
