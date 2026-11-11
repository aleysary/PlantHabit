import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:verdant/core/theme/verdant_theme.dart';
import 'package:verdant/data/catalog/habit_catalog.dart';
import 'package:verdant/data/models/models.dart';
import 'package:verdant/data/repositories/in_memory.dart';
import 'package:verdant/features/habits/habit_library_screen.dart';
import 'package:verdant/state/app_state.dart';

AppState stateFor() => AppState(
    auth: InMemoryAuthRepository(),
    garden: InMemoryGardenRepository(),
    email: FakeEmailService(),
    updates: FakeUpdateService())
  ..user = UserProfile(
      uid: 'test',
      username: 'Tester',
      email: 'tester@example.com',
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

/// The habit form shows a plant that sways forever, so pumpAndSettle would
/// never finish; step time forward instead.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 300));
  }
}

Future<void> pumpLibrary(WidgetTester tester, AppState state) async {
  tester.view.physicalSize = const Size(390, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(ChangeNotifierProvider(
      create: (_) => state,
      child: MaterialApp(theme: theme, home: const HabitLibraryScreen())));
  await settle(tester);
}

void main() {
  testWidgets('creating your own habit comes first and ideas are a short list',
      (tester) async {
    await pumpLibrary(tester, stateFor());
    expect(find.text('Create your own habit'), findsOneWidget);
    expect(find.text('Need ideas?'), findsOneWidget);
    // With no habits yet, the ideas start open, and only the short list shows.
    for (final idea in HabitCatalog.suggestions) {
      expect(find.text(idea.name), findsOneWidget);
    }
    expect(find.text('Morning sunlight'), findsNothing);
    expect(HabitCatalog.suggestions.length,
        lessThan(HabitCatalog.templates.length));
    expect(tester.takeException(), isNull);
  });

  testWidgets('a habit written from scratch is added with its own name',
      (tester) async {
    final state = stateFor();
    addTearDown(state.dispose);
    await pumpLibrary(tester, state);

    await tester.tap(find.text('Create your own habit'));
    await settle(tester);
    expect(find.text('Create a habit'), findsOneWidget);

    // A name is required.
    await tester.tap(find.text('Add habit'));
    await settle(tester);
    expect(state.activeHabits, isEmpty);
    // Let the "Give your habit a name" message clear the Add button.
    await tester.pump(const Duration(seconds: 3));
    await settle(tester);

    await tester.enterText(find.byType(TextField).first, 'Stretch before bed');
    await tester.tap(find.text('Add habit'));
    await settle(tester);

    final habit = state.activeHabits.single;
    expect(habit.name, 'Stretch before bed');
    expect(habit.frequency.type, FrequencyType.daily);
    expect(habit.templateId, startsWith('custom-'));

    // Back on the library: listed under Tracking, ideas tucked away.
    expect(find.text('Stretch before bed'), findsOneWidget);
    expect(find.text('Drink 8 glasses of water'), findsNothing);
    await tester.tap(find.text('Need ideas?'));
    await settle(tester);
    expect(find.text('Drink 8 glasses of water'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an idea opens prefilled so it can be personalised',
      (tester) async {
    final state = stateFor();
    addTearDown(state.dispose);
    await pumpLibrary(tester, state);

    await tester.tap(find.text('Read 20 pages'));
    await settle(tester);
    expect(find.widgetWithText(TextField, 'Read 20 pages'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'Read 10 pages');
    await tester.tap(find.text('Add habit'));
    await settle(tester);

    final habit = state.activeHabits.single;
    expect(habit.name, 'Read 10 pages');
    expect(habit.templateId, 'read');

    // A used idea is no longer suggested.
    await tester.tap(find.text('Need ideas?'));
    await settle(tester);
    expect(find.text('Read 20 pages'), findsNothing);
    expect(find.text('Drink 8 glasses of water'), findsOneWidget);
  });

  testWidgets('resting habits can be resumed from the library',
      (tester) async {
    final state = stateFor();
    addTearDown(state.dispose);
    final template = HabitCatalog.byId('hydrate')!;
    await state.setHabitTracked(template, true);
    await state.setHabitTracked(template, false);
    expect(state.activeHabits, isEmpty);

    await pumpLibrary(tester, state);
    expect(find.text('Resting'), findsOneWidget);
    await tester.tap(find.text('Resume'));
    await settle(tester);
    expect(state.activeHabits.single.templateId, 'hydrate');
    expect(state.habits.length, 1);
  });
}
