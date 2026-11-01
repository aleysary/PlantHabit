import 'dart:async';
import 'dart:math';

import '../../domain/rules.dart';
import '../models/models.dart';
import 'repositories.dart';

/// In-memory backends so the app runs out of the box with no Firebase
/// project. Swap them for the Firebase versions in docs/FIREBASE.md.
///
/// Demo login: demo@verdant.app / garden123
const kDemoEmail = 'demo@verdant.app';
const kDemoPassword = 'garden123';

/// Code the fake reset email "sends".
const kDemoResetCode = '123456';

Future<void> _latency([int ms = 380]) => Future<void>.delayed(Duration(milliseconds: ms));

final _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

class InMemoryAuthRepository implements AuthRepository {
  InMemoryAuthRepository() {
    final demo = UserProfile(
      uid: 'demo-user',
      username: 'Aley',
      email: kDemoEmail,
      createdAt: DateTime.now().subtract(const Duration(days: 60)),
      isAdmin: true,
    );
    _users[kDemoEmail] = _Account(demo, kDemoPassword);
  }

  final Map<String, _Account> _users = {};
  UserProfile? _current;

  @override
  Future<UserProfile?> currentUser() async => _current;

  @override
  Future<UserProfile> register({required String username, required String email, required String password}) async {
    await _latency();
    final e = email.trim().toLowerCase();
    final u = username.trim();
    if (u.length < 3) throw const VerdantException('Username must be at least 3 characters.');
    if (!_emailRe.hasMatch(e)) throw const VerdantException('That email doesn’t look right.');
    if (password.length < 8) throw const VerdantException('Password must be at least 8 characters.');
    if (_users.containsKey(e)) throw const VerdantException('An account with this email already exists.');
    if (_users.values.any((a) => a.profile.username.toLowerCase() == u.toLowerCase())) {
      throw const VerdantException('That username is taken. Try another.');
    }
    final profile = UserProfile(uid: 'u${DateTime.now().microsecondsSinceEpoch}', username: u, email: e, createdAt: DateTime.now());
    _users[e] = _Account(profile, password);
    _current = profile;
    return profile;
  }

  @override
  Future<UserProfile> signIn({required String email, required String password}) async {
    await _latency();
    final acc = _users[email.trim().toLowerCase()];
    if (acc == null || acc.password != password) {
      throw const VerdantException('Email or password is incorrect.');
    }
    _current = acc.profile;
    return acc.profile;
  }

  @override
  Future<void> signOut() async {
    await _latency(200);
    _current = null;
  }

  @override
  Future<void> requestPasswordReset(String email) async {
    await _latency();
    final e = email.trim().toLowerCase();
    if (!_emailRe.hasMatch(e)) throw const VerdantException('Enter a valid email address.');
    // Don't reveal whether the account exists — always "succeed".
  }

  @override
  Future<void> confirmPasswordReset({required String email, required String code, required String newPassword}) async {
    await _latency();
    final acc = _users[email.trim().toLowerCase()];
    if (code.trim() != kDemoResetCode || acc == null) throw const VerdantException('That code is invalid or has expired.');
    if (newPassword.length < 8) throw const VerdantException('Password must be at least 8 characters.');
    acc.password = newPassword;
  }
}

class _Account {
  _Account(this.profile, this.password);
  final UserProfile profile;
  String password;
}

class InMemoryGardenRepository implements GardenRepository {
  final Map<String, Map<String, Habit>> _habits = {};
  final Map<String, Map<String, Completion>> _completions = {};
  final Map<String, Map<String, EarnedBadge>> _badges = {};
  final Map<String, AppSettings> _settings = {};

  void _ensureSeeded(String uid) {
    if (uid != 'demo-user' || _habits.containsKey(uid)) return;
    final seed = DemoSeed.build();
    _habits[uid] = {for (final h in seed.habits) h.id: h};
    _completions[uid] = {for (final c in seed.completions) c.id: c};
  }

  @override
  Future<List<Habit>> loadHabits(String uid) async {
    await _latency(250);
    _ensureSeeded(uid);
    return (_habits[uid] ?? {}).values.toList()..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  @override
  Future<void> saveHabit(String uid, Habit habit) async {
    await _latency(150);
    (_habits[uid] ??= {})[habit.id] = habit;
  }

  @override
  Future<List<Completion>> loadCompletions(String uid) async {
    _ensureSeeded(uid);
    return (_completions[uid] ?? {}).values.toList();
  }

  @override
  Future<void> addCompletion(String uid, Completion completion) async {
    await _latency(120);
    (_completions[uid] ??= {})[completion.id] = completion;
  }

  @override
  Future<void> removeCompletion(String uid, String completionId) async {
    _completions[uid]?.remove(completionId);
  }

  @override
  Future<List<EarnedBadge>> loadBadges(String uid) async => (_badges[uid] ?? {}).values.toList();

  @override
  Future<void> saveBadge(String uid, EarnedBadge badge) async {
    // keyed by badge id -> a badge can never be stored twice
    (_badges[uid] ??= {}).putIfAbsent(badge.badgeId, () => badge);
  }

  @override
  Future<AppSettings> loadSettings(String uid) async => _settings[uid] ?? const AppSettings();

  @override
  Future<void> saveSettings(String uid, AppSettings settings) async {
    await _latency(200);
    _settings[uid] = settings;
  }
}

class FakeEmailService implements EmailService {
  @override
  Future<void> send({required String to, required String subject, required String body}) async {
    await _latency(900);
    if (!_emailRe.hasMatch(to.trim())) throw const VerdantException('Enter a valid recipient email.');
    if (to.trim().toLowerCase().endsWith('@fail.test')) {
      throw const VerdantException('We couldn’t send that email. Check your connection and try again.');
    }
  }
}

class FakeUpdateService implements UpdateService {
  int _attempts = 0;
  bool _installed = false;

  @override
  String get currentVersion => _installed ? '1.1.0' : '1.0.0';

  @override
  Future<AppUpdate?> checkForUpdate() async {
    await _latency(700);
    if (_installed) return null;
    return AppUpdate(
      version: '1.1.0',
      releasedAt: DateTime.now().subtract(const Duration(days: 2)),
      sizeMb: 18.4,
      notes: const {
        'New': ['Olive Tree and Lucky Bamboo join the catalogue', 'Share cards for badges'],
        'Improved': ['Smoother plant animations', 'Faster garden loading'],
        'Fixed': ['Streak could reset at midnight in some time zones'],
      },
    );
  }

  @override
  Stream<double> install(AppUpdate update) async* {
    _attempts++;
    for (var i = 1; i <= 20; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 90));
      // First attempt fails part-way so the retry path can be demoed.
      if (_attempts == 1 && i == 13) {
        throw const VerdantException('Update failed: download interrupted.');
      }
      yield i / 20;
    }
    _installed = true;
  }
}

/// Deterministic demo garden so screens look alive on first launch.
class DemoSeed {
  DemoSeed._(this.habits, this.completions);
  final List<Habit> habits;
  final List<Completion> completions;

  static DemoSeed build() {
    final today = Days.today();
    final rnd = Random(42);
    final habits = <Habit>[];
    final comps = <Completion>[];

    void add(String id, String template, String name, String desc, String cat, String icon, String species, String pot,
        HabitFrequency freq, int count, int ageDays, {String? nick}) {
      final h = Habit(
        id: id,
        templateId: template,
        name: name,
        description: desc,
        category: cat,
        iconKey: icon,
        speciesId: species,
        potId: pot,
        frequency: freq,
        createdAt: Days.add(today, -ageDays),
        plantName: nick,
      );
      habits.add(h);
      var made = 0;
      var d = Days.add(today, -1);
      final perWeek = <int, int>{};
      while (made < count && d.isAfter(h.createdAt)) {
        final wk = Days.key(Days.weekStart(d));
        final skip = rnd.nextDouble() < 0.18;
        final weeklyFull = freq.type == FrequencyType.weekly && (perWeek[wk] ?? 0) >= freq.timesPerWeek;
        if (!skip && !weeklyFull) {
          comps.add(Completion(id: '$id-${Days.key(d)}', habitId: id, day: d, recordedAt: d.add(const Duration(hours: 19))));
          perWeek[wk] = (perWeek[wk] ?? 0) + 1;
          made++;
        }
        d = Days.add(d, -1);
      }
    }

    add('h-meditate', 'meditate', 'Meditate 10 minutes', 'Sit, breathe, and notice.', 'Mind', 'meditate', 'bonsai', 'sage', const HabitFrequency.daily(), 27, 40, nick: 'Kenji');
    add('h-sun', 'sunlight', 'Morning sunlight', 'Ten minutes of daylight after waking.', 'Wellness', 'sun', 'sunflower', 'blush', const HabitFrequency.daily(), 25, 36);
    add('h-water', 'hydrate', 'Drink 8 glasses of water', 'Keep a bottle nearby.', 'Wellness', 'water', 'peace_lily', 'ivory', const HabitFrequency.daily(), 16, 26);
    add('h-read', 'read', 'Read 20 pages', 'Anything that isn’t a feed.', 'Growth', 'read', 'monstera', 'terracotta', const HabitFrequency.daily(), 9, 14, nick: 'Monty');
    add('h-gym', 'workout', 'Strength workout', 'Weights, bands or bodyweight.', 'Fitness', 'gym', 'cactus', 'stone', const HabitFrequency.weekly(3), 4, 16);
    add('h-lang', 'language', 'Learn a language', 'One lesson or twenty new words.', 'Growth', 'language', 'cherry_blossom', 'midnight', const HabitFrequency.daily(), 2, 4);
    return DemoSeed._(habits, comps);
  }
}
