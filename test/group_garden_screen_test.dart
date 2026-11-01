import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:verdant/core/theme/verdant_theme.dart';
import 'package:verdant/core/widgets/plant_view.dart';
import 'package:verdant/data/models/models.dart';
import 'package:verdant/data/repositories/in_memory.dart';
import 'package:verdant/features/garden/garden_screen.dart';
import 'package:verdant/state/app_state.dart';

void main() {
  testWidgets(
      'phone garden shows shared seed, maturity, collection and group management',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var now = DateTime(2026, 10, 26);
    final state = AppState(
        auth: InMemoryAuthRepository(),
        garden: InMemoryGardenRepository(),
        email: FakeEmailService(),
        updates: FakeUpdateService(),
        clock: () => now);
    state.user = UserProfile(
        uid: 'test',
        username: 'Tester',
        email: 'test@example.com',
        createdAt: now);
    state.debugSet(habits: [
      for (final name in ['Water', 'Read'])
        Habit(
            id: name,
            templateId: name,
            name: name,
            description: '',
            category: 'Growth',
            iconKey: 'spa',
            speciesId: 'monstera',
            potId: 'ivory',
            frequency: const HabitFrequency.daily(),
            createdAt: now),
    ]);
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
            home: const Scaffold(body: GardenScreen()))));
    await tester.pumpAndSettle();
    expect(find.byType(PlantView), findsOneWidget);
    expect(
        tester
            .widget<PlantView>(find.byKey(const ValueKey('current-daily')))
            .speciesId,
        'sunflower');
    expect(find.textContaining('0 of 7 completed days'), findsOneWidget);
    now = DateTime(2026, 11, 1);
    state.refreshGroupPlants();
    await tester.pumpAndSettle();
    expect(state.stageOf(state.activeHabits.first), 0);
    state.debugSet(completions: [
      for (var i = 0; i < 14; i++)
        Completion(
            id: 'entry-$i',
            habitId: i.isEven ? 'Water' : 'Read',
            day: DateTime(2026, 10, 26 + i ~/ 2),
            recordedAt: DateTime(2026, 10, 26 + i ~/ 2)),
    ]);
    state.refreshGroupPlants();
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<PlantView>(find.byKey(const ValueKey('current-daily')))
            .stage,
        5);
    await tester.ensureVisible(find.text('Collect and plant a new seed'));
    await tester.tap(find.text('Collect and plant a new seed'));
    await tester.pumpAndSettle();
    expect(state.groupGarden.collection.length, 1);
    expect(find.textContaining('0 of 7 completed days'), findsOneWidget);
    expect(state.groupGarden.collection.single.group.name, 'daily');
    expect(
        tester
            .widget<PlantView>(find.byKey(const ValueKey('current-daily')))
            .stage,
        0);
    await tester.tap(find.text('Daily habits').first);
    await tester.pumpAndSettle();
    expect(find.text('Water'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Read'), 250,
        scrollable: find.byType(Scrollable).last);
    expect(find.text('Read'), findsOneWidget);
    expect(find.text('Edit habit'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });
}
