import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:verdant/core/theme/verdant_theme.dart';
import 'package:verdant/data/models/models.dart';
import 'package:verdant/data/repositories/in_memory.dart';
import 'package:verdant/features/habits/habit_library_screen.dart';
import 'package:verdant/state/app_state.dart';

void main() {
  testWidgets('groups limit cards, More expands, and custom creation saves',
      (tester) async {
    tester.view.physicalSize = const Size(390, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final state = AppState(
        auth: InMemoryAuthRepository(),
        garden: InMemoryGardenRepository(),
        email: FakeEmailService(),
        updates: FakeUpdateService());
    state.user = UserProfile(
        uid: 'test-user',
        username: 'Tester',
        email: 'tester@example.com',
        createdAt: DateTime.now());
    await tester.pumpWidget(ChangeNotifierProvider(
        create: (_) => state,
        child: MaterialApp(
          theme: ThemeData(
              filledButtonTheme: FilledButtonThemeData(
                  style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(56))),
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
              ]),
          home: const HabitLibraryScreen(),
        )));
    await tester.pumpAndSettle();
    expect(find.text('Drink 8 glasses of water'), findsOneWidget);
    expect(find.text('Read 20 pages'), findsNothing);
    await tester.tap(find.textContaining('More (').first);
    await tester.pumpAndSettle();
    expect(find.text('Read 20 pages'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Less'), 400,
        scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Less'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Less'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CustomScrollView), const Offset(0, 10000));
    await tester.pumpAndSettle();
    expect(find.text('Read 20 pages'), findsNothing);
    await tester.enterText(
        find.byType(TextField).first, 'Reflect on your month');
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
        find.byWidgetPredicate((widget) =>
            widget is Text && widget.data == 'Reflect on your month'),
        400,
        scrollable: find.byType(Scrollable).first);
    expect(
        find.byWidgetPredicate((widget) =>
            widget is Text && widget.data == 'Reflect on your month'),
        findsOneWidget);
    expect(find.text('Monthly Habits'), findsOneWidget);
    expect(find.text('Drink 8 glasses of water'), findsNothing);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, 10000));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add habit').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Create a habit'), findsOneWidget);
    await tester.tap(find.text('Add to selection'));
    await tester.pump();
    expect(state.activeHabits, isEmpty);
    await tester.enterText(find.byType(TextFormField).first, 'My daily ritual');
    await tester.tap(find.text('Add to selection'));
    await tester.pumpAndSettle();
    expect(state.activeHabits, isEmpty);
    expect(find.text('My daily ritual'), findsOneWidget);
    await tester.tap(find.text('Save'));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(seconds: 1));
    expect(state.activeHabits.single.name, 'My daily ritual');
    expect(state.activeHabits.single.frequency.type, FrequencyType.daily);
    expect(find.text('My daily ritual'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
