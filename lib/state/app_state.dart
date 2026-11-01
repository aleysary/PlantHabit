import 'package:flutter/material.dart';

import '../core/theme/verdant_colors.dart';
import '../data/catalog/badge_catalog.dart';
import '../data/catalog/habit_catalog.dart';
import '../data/catalog/plant_catalog.dart';
import '../data/models/models.dart';
import '../data/repositories/repositories.dart';
import '../domain/rules.dart';

enum AuthStatus { unknown, signedOut, signedIn }

/// Result of tapping "done" on a habit.
class CompletionOutcome {
  const CompletionOutcome({
    required this.status,
    this.stageBefore = 0,
    this.stageAfter = 0,
    this.newBadges = const [],
  });
  final CompletionStatus status;
  final int stageBefore;
  final int stageAfter;
  final List<BadgeDef> newBadges;
  bool get accepted => status == CompletionStatus.accepted;
  bool get grewStage => stageAfter > stageBefore;
}

/// Single source of truth for the signed-in user's garden.
class AppState extends ChangeNotifier {
  AppState({
    required this.auth,
    required this.garden,
    required this.email,
    required this.updates,
  });

  final AuthRepository auth;
  final GardenRepository garden;
  final EmailService email;
  final UpdateService updates;

  static const _completionRules = CompletionRules();
  static const growth = GrowthRules();

  AuthStatus status = AuthStatus.unknown;
  UserProfile? user;
  List<Habit> _habits = [];
  List<Completion> _completions = [];
  List<EarnedBadge> _badges = [];
  AppSettings settings = const AppSettings();
  bool loading = false;

  // ---------------------------------------------------------------- derived
  List<Habit> get habits => _habits;
  List<Habit> get activeHabits => _habits.where((h) => h.isActive).toList();
  List<Habit> get archivedHabits => _habits.where((h) => !h.isActive).toList();
  List<Completion> get completions => _completions;
  List<EarnedBadge> get earnedBadges => _badges;

  ThemeMode get themeMode => switch (settings.themeMode) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  AccentOption get accent =>
      AccentOption.values.firstWhere((a) => a.name == settings.accent, orElse: () => AccentOption.moss);

  Habit? habitById(String id) {
    for (final h in _habits) {
      if (h.id == id) return h;
    }
    return null;
  }

  List<Completion> completionsFor(String habitId) =>
      _completions.where((c) => c.habitId == habitId).toList()..sort((a, b) => b.day.compareTo(a.day));

  int validCount(String habitId) => _completions.where((c) => c.habitId == habitId).length;
  int stageOf(Habit h) => growth.stageFor(validCount(h.id));

  bool isDoneOn(Habit h, DateTime day) => _completions.any((c) => c.habitId == h.id && Days.same(c.day, day));
  bool isDoneToday(Habit h) => isDoneOn(h, Days.today());

  /// Completions this Mon–Sun week.
  int weekCount(Habit h) {
    final ws = Days.weekStart(Days.today());
    final we = Days.add(ws, 7);
    return _completions.where((c) => c.habitId == h.id && !c.day.isBefore(ws) && c.day.isBefore(we)).length;
  }

  /// Habits that can still be completed today.
  bool isDueToday(Habit h) {
    if (!h.isActive) return false;
    if (h.frequency.type == FrequencyType.daily) return true;
    return isDoneToday(h) || weekCount(h) < h.frequency.timesPerWeek;
  }

  List<Habit> get todayHabits => activeHabits.where(isDueToday).toList();
  int get doneTodayCount => todayHabits.where(isDoneToday).length;

  GardenStats get stats => GardenStats.compute(_habits, _completions);

  bool hasBadge(String id) => _badges.any((b) => b.badgeId == id);

  // ------------------------------------------------------------------- auth
  Future<void> bootstrap() async {
    final u = await auth.currentUser();
    if (u == null) {
      status = AuthStatus.signedOut;
      notifyListeners();
    } else {
      await _loadFor(u);
    }
  }

  Future<void> signIn(String email, String password) async {
    final u = await auth.signIn(email: email, password: password);
    await _loadFor(u);
  }

  Future<void> register(String username, String email, String password) async {
    final u = await auth.register(username: username, email: email, password: password);
    await _loadFor(u);
  }

  Future<void> signOut() async {
    await auth.signOut();
    user = null;
    _habits = [];
    _completions = [];
    _badges = [];
    settings = const AppSettings();
    status = AuthStatus.signedOut;
    notifyListeners();
  }

  Future<void> _loadFor(UserProfile u) async {
    loading = true;
    user = u;
    notifyListeners();
    final results = await Future.wait([
      garden.loadHabits(u.uid),
      garden.loadCompletions(u.uid),
      garden.loadBadges(u.uid),
      garden.loadSettings(u.uid),
    ]);
    _habits = results[0] as List<Habit>;
    _completions = results[1] as List<Completion>;
    _badges = results[2] as List<EarnedBadge>;
    settings = results[3] as AppSettings;
    loading = false;
    status = AuthStatus.signedIn;
    await _awardBadges(silent: true);
    notifyListeners();
  }

  // ----------------------------------------------------------------- habits
  Future<Habit> addHabit({
    required HabitTemplate template,
    required String speciesId,
    required String potId,
    required HabitFrequency frequency,
    String? plantName,
  }) async {
    final uid = user!.uid;
    if (activeHabits.any((h) => h.templateId == template.id)) {
      throw const VerdantException('You’re already tracking this habit.');
    }
    final h = Habit(
      id: 'h${DateTime.now().microsecondsSinceEpoch}',
      templateId: template.id,
      name: template.name,
      description: template.description,
      category: template.category,
      iconKey: template.iconKey,
      speciesId: speciesId,
      potId: potId,
      frequency: frequency,
      createdAt: DateTime.now(),
      plantName: (plantName?.trim().isEmpty ?? true) ? null : plantName!.trim(),
    );
    await garden.saveHabit(uid, h);
    _habits = [..._habits, h];
    await _awardBadges();
    notifyListeners();
    return h;
  }

  Future<void> updateHabit(Habit updated) async {
    await garden.saveHabit(user!.uid, updated);
    _habits = [for (final h in _habits) h.id == updated.id ? updated : h];
    notifyListeners();
  }

  /// Stops tracking but keeps every completion (story 9).
  Future<void> archiveHabit(Habit h) => updateHabit(h.copyWith(archivedAt: DateTime.now()));
  Future<void> restoreHabit(Habit h) => updateHabit(h.copyWith(clearArchived: true));

  // ------------------------------------------------------------ completions
  Future<CompletionOutcome> complete(Habit h, {DateTime? day}) async {
    final d = Days.of(day ?? DateTime.now());
    final status = _completionRules.validate(habit: h, day: d, existing: _completions);
    if (status != CompletionStatus.accepted) return CompletionOutcome(status: status);
    final before = stageOf(h);
    final c = Completion(id: '${h.id}-${Days.key(d)}', habitId: h.id, day: d, recordedAt: DateTime.now());
    // optimistic update
    _completions = [..._completions, c];
    notifyListeners();
    try {
      await garden.addCompletion(user!.uid, c);
    } catch (e) {
      _completions = _completions.where((x) => x.id != c.id).toList();
      notifyListeners();
      rethrow;
    }
    final newBadges = await _awardBadges();
    notifyListeners();
    return CompletionOutcome(status: status, stageBefore: before, stageAfter: stageOf(h), newBadges: newBadges);
  }

  /// Undo today's completion (mis-tap). Growth recalculates automatically.
  Future<void> undoToday(Habit h) async {
    final today = Days.today();
    final match = _completions.where((c) => c.habitId == h.id && Days.same(c.day, today)).toList();
    if (match.isEmpty) return;
    _completions = _completions.where((c) => c.id != match.first.id).toList();
    notifyListeners();
    await garden.removeCompletion(user!.uid, match.first.id);
  }

  // ----------------------------------------------------------------- badges
  Future<List<BadgeDef>> _awardBadges({bool silent = false}) async {
    final s = stats;
    final fresh = <BadgeDef>[];
    for (final b in BadgeCatalog.badges) {
      if (!hasBadge(b.id) && b.isMet(s)) {
        final e = EarnedBadge(badgeId: b.id, earnedAt: DateTime.now());
        _badges = [..._badges, e];
        await garden.saveBadge(user!.uid, e);
        fresh.add(b);
      }
    }
    return silent ? const [] : fresh;
  }

  // --------------------------------------------------------------- settings
  Future<void> saveSettings(AppSettings next) async {
    settings = next;
    notifyListeners();
    if (user != null) await garden.saveSettings(user!.uid, next);
  }

  // ------------------------------------------------------------------ misc
  String plantLabel(Habit h) => h.plantName ?? PlantCatalog.byId(h.speciesId).name;

  @visibleForTesting
  void debugSet({List<Habit>? habits, List<Completion>? completions}) {
    if (habits != null) _habits = habits;
    if (completions != null) _completions = completions;
  }
}
