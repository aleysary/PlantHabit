import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'data/repositories/in_memory.dart';
import 'state/app_state.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(statusBarColor: Colors.transparent));

  // Swap these for the Firebase implementations once your project is set up
  // (see docs/FIREBASE.md). Nothing else in the app needs to change.
  final state = AppState(
    auth: InMemoryAuthRepository(),
    garden: InMemoryGardenRepository(),
    email: FakeEmailService(),
    updates: FakeUpdateService(),
  );
  state.bootstrap();

  runApp(ChangeNotifierProvider<AppState>.value(value: state, child: const VerdantApp()));
}
