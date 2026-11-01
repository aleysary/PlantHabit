# Switching Verdant to Firebase

The UI only talks to the interfaces in `lib/data/repositories/repositories.dart`. To move from the in-memory demo to Firebase, you swap the implementations and leave every screen as it is.

## 1. Create the project

```bash
dart pub global activate flutterfire_cli
flutterfire configure            # creates lib/firebase_options.dart
```

In the Firebase console:
- **Authentication → Sign-in method:** enable *Email/Password*
- **Firestore:** create a database, then paste `firebase_templates/firestore.rules` into *Rules*
- **(Story 24) Extensions:** install **Trigger Email from Firestore** and point it at the `mail` collection

## 2. Add packages

Uncomment these lines in `pubspec.yaml`, then run `flutter pub get`:

```yaml
firebase_core: ^3.6.0
firebase_auth: ^5.3.1
cloud_firestore: ^5.4.4
```

> Android: Firebase Auth needs `minSdkVersion 23`. Set it in `android/app/build.gradle`.

## 3. Drop in the repositories

```bash
cp firebase_templates/firebase_repositories.dart lib/data/repositories/firebase.dart
```

## 4. Wire it up in `lib/main.dart`

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'data/repositories/firebase.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final state = AppState(
    auth: FirebaseAuthRepository(),
    garden: FirestoreGardenRepository(),
    email: FirestoreEmailService(),
    updates: FakeUpdateService(), // or your own (e.g. Remote Config / store APIs)
  );
  state.bootstrap();
  runApp(ChangeNotifierProvider<AppState>.value(value: state, child: const VerdantApp()));
}
```

## Data model

```
users/{uid}                       profile + settings (appearance prefs, story 26)
users/{uid}/habits/{habitId}      Habit (archivedAt set when removed — history kept)
users/{uid}/completions/{id}      Completion, id = <habitId>-<yyyymmdd>  (dupes impossible)
users/{uid}/badges/{badgeId}      EarnedBadge, keyed by badge id      (awarded once)
usernames/{lowercase}             { uid }  — reserves unique usernames (story 1)
mail/{id}                         outgoing email queue (story 24)
```

## Password reset (story 23)

Firebase sends a reset **link**, not a 6-digit code. You have two options:
- **Simplest:** let users finish on Firebase's hosted page. Change the second step of `ForgotPasswordScreen` to say "Check your email" and stop there.
- **In-app:** set up a custom action URL or deep link, read the `oobCode` from it, and pass it to `confirmPasswordReset` as `code`.

## Admins (story 25)

Set `isAdmin: true` on a user's `users/{uid}` document. To harden this, use a custom claim and check `request.auth.token.admin` in the rules.
