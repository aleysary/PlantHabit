import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:verdant/core/theme/verdant_theme.dart';
import 'package:verdant/data/catalog/habit_catalog.dart';
import 'package:verdant/data/models/models.dart';
import 'package:verdant/data/repositories/in_memory.dart';
import 'package:verdant/features/habits/habit_library_screen.dart';
import 'package:verdant/state/app_state.dart';
import 'package:verdant/domain/group_plants.dart';

class FailSecondHabit extends InMemoryGardenRepository {
  int attempts = 0;
  @override
  Future<void> saveHabit(String uid, Habit habit) async {
    attempts++;
    if (attempts == 2) throw Exception('Temporary failure');
    await super.saveHabit(uid, habit);
  }
}

AppState stateFor([InMemoryGardenRepository? repository]) => AppState(
    auth: InMemoryAuthRepository(),
    garden: repository ?? InMemoryGardenRepository(),
    email: FakeEmailService(),
    updates: FakeUpdateService())
  ..user = UserProfile(
      uid: 'test',
      username: 'Test',
      email: 'test@example.com',
      createdAt: DateTime.now());

ThemeData get theme => ThemeData(
        filledButtonTheme: FilledButtonThemeData(
            style:
                FilledButton.styleFrom(minimumSize: const Size.fromHeight(56))),
        outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(56))),
        extensions: const [
          VerdantTokens(
            card: Colors.white,
            raised: Colors.white,
            line: Colors.grey,
            muted: Colors.grey,
            text: Colors.black,
            highlight: Colors.lime,
            onHighlight: Colors.black,
            hero: Colors.green,
            onHero: Colors.white,
            isDark: false,
          )
        ]);

Finder checkbox(String name) => find.byWidgetPredicate(
    (w) => w is Checkbox && w.semanticLabel == 'Track $name');
Future<void> tapCheckbox(WidgetTester tester, String name) async {
  await tester.scrollUntilVisible(checkbox(name), 250,
      scrollable: find.byType(Scrollable).first);
  await tester.pumpAndSettle();
  await tester.ensureVisible(checkbox(name));
  await tester.pumpAndSettle();
  await tester.tap(checkbox(name));
  await tester.pumpAndSettle();
}

Future<void> finishSave(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 400));
  }
  await tester.pumpAndSettle();
}

Future<void> pumpLibrary(WidgetTester tester, AppState state,
    {bool launcher = false}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(ChangeNotifierProvider(
      create: (_) => state,
      child: MaterialApp(
        theme: theme,
        home: launcher
            ? Builder(
                builder: (context) => Scaffold(
                    body: TextButton(
                        onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                                builder: (_) => const HabitLibraryScreen())),
                        child: const Text('Open library'))))
            : const HabitLibraryScreen(),
      )));
  if (launcher) {
    await tester.tap(find.text('Open library'));
  }
  await tester.pumpAndSettle();
}

void main() {
  for (final option in [
    (group: HabitGroup.several, name: 'Take a 30-minute walk'),
    (group: HabitGroup.weekly, name: 'Plan your week'),
    (group: HabitGroup.biweekly, name: 'Review your budget'),
    (group: HabitGroup.monthly, name: 'Reflect on your month'),
  ]) {
    testWidgets(
        '${option.group.name} selection shows a mature preview then only the progress plant',
        (tester) async {
      final state = stateFor();
      await pumpLibrary(tester, state);
      await tester.scrollUntilVisible(checkbox(option.name), 300,
          scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
          find.byKey(ValueKey('preview-${option.group.name}')), -200,
          scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();
      expect(
          find.byKey(ValueKey('preview-${option.group.name}')), findsOneWidget);
      await tapCheckbox(tester, option.name);
      await tester.scrollUntilVisible(
          find.byKey(ValueKey('current-${option.group.name}')), -200,
          scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();
      expect(
          find.byKey(ValueKey('preview-${option.group.name}')), findsNothing);
      await tester.tap(find.text('Save'));
      await finishSave(tester);
      expect(HabitGroup.of(state.activeHabits.single.frequency), option.group);
      await tester.ensureVisible(find.text(option.group.label));
      await tester.pumpAndSettle();
      await tester.tap(find.text(option.group.label));
      await tester.pumpAndSettle();
      expect(
          find.byKey(ValueKey('preview-${option.group.name}')), findsNothing);
      expect(
          find.byWidgetPredicate((w) =>
              w is Checkbox &&
              w.semanticLabel == 'Complete ${option.name} this period'),
          findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
      'checkbox drafts survive search; fixed Save applies additions and removals',
      (tester) async {
    final state = stateFor();
    await pumpLibrary(tester, state);
    await tester.scrollUntilVisible(checkbox('Drink 8 glasses of water'), 250,
        scrollable: find.byType(Scrollable).first);
    expect(find.byKey(const ValueKey('preview-daily')), findsOneWidget);
    await tapCheckbox(tester, 'Drink 8 glasses of water');
    await tester.drag(find.byType(CustomScrollView), const Offset(0, 10000));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('preview-daily')), findsNothing);
    expect(find.byKey(const ValueKey('current-daily')), findsOneWidget);
    expect(state.activeHabits, isEmpty);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, 10000));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Plan your week');
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(checkbox('Plan your week'), 400,
        scrollable: find.byType(Scrollable).first);
    await tapCheckbox(tester, 'Plan your week');
    expect(find.text('Save').hitTestable(), findsOneWidget);
    expect(state.activeHabits, isEmpty);
    await tester.tap(find.text('Save'));
    await finishSave(tester);
    expect(state.activeHabits.map((h) => h.templateId),
        containsAll(['hydrate', 'weekly-plan']));
    expect(state.completions, isEmpty);
    await tapCheckbox(tester, 'Plan your week');
    expect(state.activeHabits.length, 2);
    await tester.tap(find.text('Save'));
    await finishSave(tester);
    expect(state.activeHabits.single.templateId, 'hydrate');
    expect(state.archivedHabits.single.templateId, 'weekly-plan');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'partial save retains remaining selection and retry does not duplicate successes',
      (tester) async {
    final state = stateFor(FailSecondHabit());
    await pumpLibrary(tester, state);
    for (final name in ['Drink 8 glasses of water', 'Meditate 10 minutes']) {
      await tester.scrollUntilVisible(checkbox(name), 200,
          scrollable: find.byType(Scrollable).first);
      await tapCheckbox(tester, name);
    }
    await tester.tap(find.text('Save'));
    await finishSave(tester);
    expect(state.activeHabits.length, 1);
    expect(
        tester.widget<Checkbox>(checkbox('Meditate 10 minutes')).value, isTrue);
    await tester.tap(find.text('Save'));
    await finishSave(tester);
    expect(state.activeHabits.length, 2);
    expect(state.habits.map((h) => h.templateId).toSet().length, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'leaving unsaved choices asks to discard and does not change tracked habits',
      (tester) async {
    final state = stateFor();
    await pumpLibrary(tester, state, launcher: true);
    await tester.scrollUntilVisible(checkbox('Drink 8 glasses of water'), 200,
        scrollable: find.byType(Scrollable).first);
    await tapCheckbox(tester, 'Drink 8 glasses of water');
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Leave without saving?'), findsOneWidget);
    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();
    expect(tester.widget<Checkbox>(checkbox('Drink 8 glasses of water')).value,
        isTrue);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard changes'));
    await tester.pumpAndSettle();
    expect(find.text('Open library'), findsOneWidget);
    expect(state.habits, isEmpty);
    expect(tester.takeException(), isNull);
  });

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
}
