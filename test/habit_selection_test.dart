import 'package:flutter_test/flutter_test.dart';
import 'package:verdant/data/catalog/habit_catalog.dart';
import 'package:verdant/data/models/models.dart';
import 'package:verdant/data/repositories/in_memory.dart';
import 'package:verdant/data/repositories/repositories.dart';
import 'package:verdant/state/app_state.dart';

AppState stateFor() => AppState(
    auth: InMemoryAuthRepository(),
    garden: InMemoryGardenRepository(),
    email: FakeEmailService(),
    updates: FakeUpdateService())
  ..user = UserProfile(
      uid: 'test',
      username: 'Test',
      email: 'test@example.com',
      createdAt: DateTime.now());

HabitTemplate custom(String id, String name) => HabitTemplate(
    id: id,
    name: name,
    description: '',
    category: 'Personal',
    iconKey: 'spa',
    suggestedSpecies: 'sunflower',
    defaultFrequency: const HabitFrequency.daily());

void main() {
  test('unchecking archives history and rechecking resumes the same record',
      () async {
    final state = stateFor();
    addTearDown(state.dispose);
    final template = HabitCatalog.byId('hydrate')!;
    await state.setHabitTracked(template, true);
    final original = state.activeHabits.single;
    await state.complete(original);
    await state.setHabitTracked(template, false);
    expect(state.activeHabits, isEmpty);
    expect(state.validCount(original.id), 1);
    await state.setHabitTracked(template, true);
    expect(state.activeHabits.single.id, original.id);
    expect(state.validCount(original.id), 1);
    await state.setHabitTracked(template, true);
    expect(state.habits.length, 1);
  });

  test('two active habits cannot share a name', () async {
    final state = stateFor();
    addTearDown(state.dispose);
    Future<Habit> add(HabitTemplate t) => state.addHabit(
        template: t,
        speciesId: 'sunflower',
        potId: 'terracotta',
        frequency: t.defaultFrequency);

    final first = await add(custom('custom-1', 'Stretch'));
    await expectLater(
        add(custom('custom-2', '  stretch ')), throwsA(isA<VerdantException>()));
    expect(state.activeHabits.length, 1);

    // Once the first one is resting, the name is free again.
    await state.archiveHabit(first);
    await add(custom('custom-3', 'Stretch'));
    expect(state.activeHabits.single.templateId, 'custom-3');
  });
}
