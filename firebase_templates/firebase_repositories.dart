// Firebase-backed implementations of the Verdant repositories.
//
// 1. Add firebase_core, firebase_auth and cloud_firestore to pubspec.yaml
// 2. Run `flutterfire configure` (creates lib/firebase_options.dart)
// 3. Copy this file to lib/data/repositories/firebase.dart
// 4. Wire it up in lib/main.dart (see docs/FIREBASE.md)
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/models.dart';
import 'repositories.dart';

String _friendly(FirebaseAuthException e) => switch (e.code) {
      'email-already-in-use' => 'An account with this email already exists.',
      'invalid-email' => 'That email doesn’t look right.',
      'weak-password' => 'Choose a stronger password (8+ characters).',
      'user-not-found' || 'wrong-password' || 'invalid-credential' => 'Email or password is incorrect.',
      'too-many-requests' => 'Too many attempts. Try again in a few minutes.',
      'expired-action-code' || 'invalid-action-code' => 'That code is invalid or has expired.',
      _ => e.message ?? 'Something went wrong. Please try again.',
    };

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({FirebaseAuth? auth, FirebaseFirestore? db})
      : _auth = auth ?? FirebaseAuth.instance,
        _db = db ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) => _db.collection('users').doc(uid);

  Future<UserProfile> _profile(User u) async {
    final snap = await _userDoc(u.uid).get();
    if (snap.exists) return UserProfile.fromJson({...snap.data()!, 'uid': u.uid});
    // Profile missing (e.g. created in console) — create a minimal one.
    final p = UserProfile(uid: u.uid, username: u.email?.split('@').first ?? 'gardener', email: u.email ?? '', createdAt: DateTime.now());
    await _userDoc(u.uid).set(p.toJson());
    return p;
  }

  @override
  Future<UserProfile?> currentUser() async {
    final u = _auth.currentUser;
    return u == null ? null : _profile(u);
  }

  @override
  Future<UserProfile> register({required String username, required String email, required String password}) async {
    final handle = username.trim().toLowerCase();
    if (handle.length < 3) throw const VerdantException('Username must be at least 3 characters.');
    final nameRef = _db.collection('usernames').doc(handle);
    if ((await nameRef.get()).exists) throw const VerdantException('That username is taken. Try another.');
    try {
      final cred = await _auth.createUserWithEmailAndPassword(email: email.trim(), password: password);
      final uid = cred.user!.uid;
      final profile = UserProfile(uid: uid, username: username.trim(), email: email.trim().toLowerCase(), createdAt: DateTime.now());
      // Reserve the username atomically; fails if someone grabbed it meanwhile.
      await _db.runTransaction((tx) async {
        final taken = await tx.get(nameRef);
        if (taken.exists) throw const VerdantException('That username is taken. Try another.');
        tx.set(nameRef, {'uid': uid});
        tx.set(_userDoc(uid), profile.toJson());
      });
      return profile;
    } on FirebaseAuthException catch (e) {
      throw VerdantException(_friendly(e));
    } on VerdantException {
      await _auth.currentUser?.delete();
      rethrow;
    }
  }

  @override
  Future<UserProfile> signIn({required String email, required String password}) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
      return _profile(cred.user!);
    } on FirebaseAuthException catch (e) {
      throw VerdantException(_friendly(e));
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<void> requestPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      // Don't reveal whether an account exists.
      if (e.code != 'user-not-found') throw VerdantException(_friendly(e));
    }
  }

  /// [code] is the `oobCode` from the reset link (configure a custom action
  /// URL / deep link to bring it into the app), or let users finish on
  /// Firebase's hosted page and skip this step.
  @override
  Future<void> confirmPasswordReset({required String email, required String code, required String newPassword}) async {
    try {
      await _auth.confirmPasswordReset(code: code.trim(), newPassword: newPassword);
    } on FirebaseAuthException catch (e) {
      throw VerdantException(_friendly(e));
    }
  }
}

class FirestoreGardenRepository implements GardenRepository {
  FirestoreGardenRepository({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;
  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _user(String uid) => _db.collection('users').doc(uid);
  CollectionReference<Map<String, dynamic>> _col(String uid, String name) => _user(uid).collection(name);

  @override
  Future<List<Habit>> loadHabits(String uid) async {
    final q = await _col(uid, 'habits').orderBy('createdAt').get();
    return q.docs.map((d) => Habit.fromJson(d.data())).toList();
  }

  @override
  Future<void> saveHabit(String uid, Habit habit) => _col(uid, 'habits').doc(habit.id).set(habit.toJson());

  @override
  Future<List<Completion>> loadCompletions(String uid) async {
    final q = await _col(uid, 'completions').get();
    return q.docs.map((d) => Completion.fromJson(d.data())).toList();
  }

  /// Completion ids are `<habitId>-<yyyymmdd>`, so a duplicate for the same
  /// habit/day maps to the same document. The transaction refuses to
  /// overwrite, giving server-side duplicate protection (story 12).
  @override
  Future<void> addCompletion(String uid, Completion completion) async {
    final ref = _col(uid, 'completions').doc(completion.id);
    await _db.runTransaction((tx) async {
      if ((await tx.get(ref)).exists) throw const VerdantException('Already logged today.');
      tx.set(ref, completion.toJson());
    });
  }

  @override
  Future<void> removeCompletion(String uid, String completionId) => _col(uid, 'completions').doc(completionId).delete();

  @override
  Future<List<EarnedBadge>> loadBadges(String uid) async {
    final q = await _col(uid, 'badges').get();
    return q.docs.map((d) => EarnedBadge.fromJson(d.data())).toList();
  }

  /// Keyed by badge id — a badge can only ever be stored once (story 19).
  @override
  Future<void> saveBadge(String uid, EarnedBadge badge) async {
    final ref = _col(uid, 'badges').doc(badge.badgeId);
    await _db.runTransaction((tx) async {
      if (!(await tx.get(ref)).exists) tx.set(ref, badge.toJson());
    });
  }

  @override
  Future<AppSettings> loadSettings(String uid) async {
    final snap = await _user(uid).get();
    final raw = snap.data()?['settings'];
    return raw is Map ? AppSettings.fromJson(Map<String, dynamic>.from(raw)) : const AppSettings();
  }

  @override
  Future<void> saveSettings(String uid, AppSettings settings) =>
      _user(uid).set({'settings': settings.toJson()}, SetOptions(merge: true));
}

/// Uses the "Trigger Email from Firestore" extension: install it in the
/// Firebase console and point it at the `mail` collection.
class FirestoreEmailService implements EmailService {
  FirestoreEmailService({FirebaseFirestore? db, FirebaseAuth? auth})
      : _db = db ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  @override
  Future<void> send({required String to, required String subject, required String body}) async {
    try {
      await _db.collection('mail').add({
        'to': to.trim(),
        'from_uid': _auth.currentUser?.uid,
        'message': {'subject': subject, 'text': body},
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw VerdantException(e.message ?? 'We couldn’t send that email.');
    }
  }
}
