// Garden-only entry point for working on the garden section (stories 10-15).
//
// Skips the splash, welcome and login screens: signs in to the demo account
// automatically and opens straight onto the Garden screen. Tapping a plant
// still opens its detail page, so completions, growth, interactions and
// celebrations all work as in the full app.
//
// Run with:  flutter run -t lib/main_garden.dart
// or pick "Garden only" in VS Code's Run and Debug panel.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/verdant_theme.dart';
import 'data/repositories/in_memory.dart';
import 'features/garden/garden_screen.dart';
import 'state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final state = AppState(
    auth: InMemoryAuthRepository(),
    garden: InMemoryGardenRepository(),
    email: FakeEmailService(),
    updates: FakeUpdateService(),
  );
  await state.signIn('demo@verdant.app', 'garden123');

  runApp(ChangeNotifierProvider<AppState>.value(
    value: state,
    child: const GardenOnlyApp(),
  ));
}

class GardenOnlyApp extends StatelessWidget {
  const GardenOnlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return MaterialApp(
      title: 'Verdant · Garden',
      debugShowCheckedModeBanner: false,
      themeMode: state.themeMode,
      theme: VerdantTheme.build(brightness: Brightness.light, accent: state.accent, compact: state.settings.compact),
      darkTheme: VerdantTheme.build(brightness: Brightness.dark, accent: state.accent, compact: state.settings.compact),
      home: const Scaffold(body: GardenScreen()),
    );
  }
}
