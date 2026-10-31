import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/verdant_theme.dart';
import 'features/auth/welcome_screen.dart';
import 'features/shell/home_shell.dart';
import 'features/shell/splash_screen.dart';
import 'state/app_state.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

class VerdantApp extends StatelessWidget {
  const VerdantApp({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return MaterialApp(
      title: 'Verdant',
      debugShowCheckedModeBanner: false,
      navigatorKey: rootNavigatorKey,
      themeMode: state.themeMode,
      theme: VerdantTheme.build(brightness: Brightness.light, accent: state.accent, compact: state.settings.compact),
      darkTheme: VerdantTheme.build(brightness: Brightness.dark, accent: state.accent, compact: state.settings.compact),
      home: const AuthGate(),
    );
  }
}

/// Shows splash → welcome/auth → home depending on [AuthStatus], and clears
/// any pushed routes whenever the auth state flips (login / logout).
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  AuthStatus? _last;

  @override
  Widget build(BuildContext context) {
    final status = context.select<AppState, AuthStatus>((s) => s.status);
    if (_last != null && _last != status) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        rootNavigatorKey.currentState?.popUntil((r) => r.isFirst);
      });
    }
    _last = status;
    final child = switch (status) {
      AuthStatus.unknown => const SplashScreen(),
      AuthStatus.signedOut => const WelcomeScreen(),
      AuthStatus.signedIn => const HomeShell(),
    };
    return AnimatedSwitcher(duration: const Duration(milliseconds: 450), child: KeyedSubtree(key: ValueKey(status), child: child));
  }
}
