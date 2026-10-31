import '../models/models.dart';

/// Thrown by repositories with a user-facing message.
class VerdantException implements Exception {
  const VerdantException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Authentication (stories 1, 2, 4, 23).
abstract class AuthRepository {
  Future<UserProfile> register({required String username, required String email, required String password});
  Future<UserProfile> signIn({required String email, required String password});
  Future<void> signOut();
  Future<UserProfile?> currentUser();

  /// Sends a reset link or code to the user's email.
  Future<void> requestPasswordReset(String email);

  /// Completes the reset with the code from the email.
  Future<void> confirmPasswordReset({required String email, required String code, required String newPassword});
}

/// Per-user garden data. In Firestore this maps to:
///   users/{uid}                     -> profile + settings
///   users/{uid}/habits/{habitId}
///   users/{uid}/completions/{id}
///   users/{uid}/badges/{badgeId}
abstract class GardenRepository {
  Future<List<Habit>> loadHabits(String uid);
  Future<void> saveHabit(String uid, Habit habit);

  Future<List<Completion>> loadCompletions(String uid);
  Future<void> addCompletion(String uid, Completion completion);
  Future<void> removeCompletion(String uid, String completionId);

  Future<List<EarnedBadge>> loadBadges(String uid);
  Future<void> saveBadge(String uid, EarnedBadge badge);

  Future<AppSettings> loadSettings(String uid);
  Future<void> saveSettings(String uid, AppSettings settings);
}

/// Sends progress emails (story 24). With Firebase, write to a `mail`
/// collection consumed by the "Trigger Email" extension.
abstract class EmailService {
  Future<void> send({required String to, required String subject, required String body});
}

class AppUpdate {
  const AppUpdate({required this.version, required this.releasedAt, required this.notes, required this.sizeMb});
  final String version;
  final DateTime releasedAt;
  final Map<String, List<String>> notes; // section -> bullet points
  final double sizeMb;
}

/// App updates (story 25).
abstract class UpdateService {
  String get currentVersion;
  Future<AppUpdate?> checkForUpdate();

  /// Streams install progress 0..1. Throws [VerdantException] on failure.
  Stream<double> install(AppUpdate update);
}
