import 'package:flutter/foundation.dart';

/// How often a habit should be completed.
enum FrequencyType { daily, weekly }

@immutable
class HabitFrequency {
  const HabitFrequency.daily()
      : type = FrequencyType.daily,
        timesPerWeek = 7;
  const HabitFrequency.weekly(this.timesPerWeek) : type = FrequencyType.weekly;

  final FrequencyType type;

  /// For weekly habits: how many completions per (Mon–Sun) week.
  final int timesPerWeek;

  String get label => type == FrequencyType.daily
      ? 'Every day'
      : timesPerWeek == 1
          ? 'Once a week'
          : '$timesPerWeek× a week';

  Map<String, dynamic> toJson() => {'type': type.name, 'timesPerWeek': timesPerWeek};

  factory HabitFrequency.fromJson(Map<String, dynamic> j) => j['type'] == 'daily'
      ? const HabitFrequency.daily()
      : HabitFrequency.weekly((j['timesPerWeek'] as num?)?.toInt() ?? 3);

  @override
  bool operator ==(Object other) =>
      other is HabitFrequency && other.type == type && other.timesPerWeek == timesPerWeek;

  @override
  int get hashCode => Object.hash(type, timesPerWeek);
}

/// A habit the user is tracking. Each habit owns exactly one plant.
@immutable
class Habit {
  const Habit({
    required this.id,
    required this.templateId,
    required this.name,
    required this.description,
    required this.category,
    required this.iconKey,
    required this.speciesId,
    required this.potId,
    required this.frequency,
    required this.createdAt,
    this.plantName,
    this.archivedAt,
  });

  final String id;
  final String templateId;
  final String name;
  final String description;
  final String category;
  final String iconKey;
  final String speciesId;
  final String potId;
  final HabitFrequency frequency;
  final DateTime createdAt;

  /// Optional nickname for the plant ("Fernando").
  final String? plantName;

  /// Set when the habit is removed from active tracking (history is kept).
  final DateTime? archivedAt;

  bool get isActive => archivedAt == null;

  Habit copyWith({
    String? name,
    String? description,
    String? speciesId,
    String? potId,
    HabitFrequency? frequency,
    String? plantName,
    DateTime? archivedAt,
    bool clearArchived = false,
  }) {
    return Habit(
      id: id,
      templateId: templateId,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category,
      iconKey: iconKey,
      speciesId: speciesId ?? this.speciesId,
      potId: potId ?? this.potId,
      frequency: frequency ?? this.frequency,
      createdAt: createdAt,
      plantName: plantName ?? this.plantName,
      archivedAt: clearArchived ? null : (archivedAt ?? this.archivedAt),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'templateId': templateId,
        'name': name,
        'description': description,
        'category': category,
        'iconKey': iconKey,
        'speciesId': speciesId,
        'potId': potId,
        'frequency': frequency.toJson(),
        'createdAt': createdAt.toIso8601String(),
        'plantName': plantName,
        'archivedAt': archivedAt?.toIso8601String(),
      };

  factory Habit.fromJson(Map<String, dynamic> j) => Habit(
        id: j['id'] as String,
        templateId: j['templateId'] as String,
        name: j['name'] as String,
        description: (j['description'] as String?) ?? '',
        category: (j['category'] as String?) ?? 'Wellness',
        iconKey: (j['iconKey'] as String?) ?? 'spa',
        speciesId: j['speciesId'] as String,
        potId: (j['potId'] as String?) ?? 'terracotta',
        frequency: HabitFrequency.fromJson(Map<String, dynamic>.from(j['frequency'] as Map)),
        createdAt: DateTime.parse(j['createdAt'] as String),
        plantName: j['plantName'] as String?,
        archivedAt: j['archivedAt'] == null ? null : DateTime.parse(j['archivedAt'] as String),
      );
}

/// One recorded completion. Stored as its own document so history survives
/// edits and removal of the habit.
@immutable
class Completion {
  const Completion({required this.id, required this.habitId, required this.day, required this.recordedAt});

  final String id;
  final String habitId;

  /// Calendar day (local, time stripped) the completion counts for.
  final DateTime day;
  final DateTime recordedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'habitId': habitId,
        'day': day.toIso8601String(),
        'recordedAt': recordedAt.toIso8601String(),
      };

  factory Completion.fromJson(Map<String, dynamic> j) => Completion(
        id: j['id'] as String,
        habitId: j['habitId'] as String,
        day: DateTime.parse(j['day'] as String),
        recordedAt: DateTime.parse(j['recordedAt'] as String),
      );
}

@immutable
class EarnedBadge {
  const EarnedBadge({required this.badgeId, required this.earnedAt});
  final String badgeId;
  final DateTime earnedAt;

  Map<String, dynamic> toJson() => {'badgeId': badgeId, 'earnedAt': earnedAt.toIso8601String()};
  factory EarnedBadge.fromJson(Map<String, dynamic> j) =>
      EarnedBadge(badgeId: j['badgeId'] as String, earnedAt: DateTime.parse(j['earnedAt'] as String));
}

@immutable
class UserProfile {
  const UserProfile({
    required this.uid,
    required this.username,
    required this.email,
    required this.createdAt,
    this.isAdmin = false,
  });

  final String uid;
  final String username;
  final String email;
  final DateTime createdAt;
  final bool isAdmin;

  String get initials => username.isEmpty ? '?' : username.substring(0, 1).toUpperCase();

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'username': username,
        'email': email,
        'createdAt': createdAt.toIso8601String(),
        'isAdmin': isAdmin,
      };

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
        uid: j['uid'] as String,
        username: j['username'] as String,
        email: j['email'] as String,
        createdAt: DateTime.parse(j['createdAt'] as String),
        isAdmin: (j['isAdmin'] as bool?) ?? false,
      );
}

enum GardenLayout { grid, list }

/// Appearance + home layout preferences (stories 25/26). Saved per user so
/// they survive logout/login.
@immutable
class AppSettings {
  const AppSettings({
    this.themeMode = 'system',
    this.accent = 'moss',
    this.compact = false,
    this.gardenLayout = GardenLayout.grid,
    this.showDailyQuote = true,
    this.showStreakCard = true,
    this.showWeekStrip = true,
    this.ambientMotion = true,
  });

  /// 'system' | 'light' | 'dark'
  final String themeMode;
  final String accent;
  final bool compact;
  final GardenLayout gardenLayout;
  final bool showDailyQuote;
  final bool showStreakCard;
  final bool showWeekStrip;

  /// Gentle idle sway on plants.
  final bool ambientMotion;

  AppSettings copyWith({
    String? themeMode,
    String? accent,
    bool? compact,
    GardenLayout? gardenLayout,
    bool? showDailyQuote,
    bool? showStreakCard,
    bool? showWeekStrip,
    bool? ambientMotion,
  }) =>
      AppSettings(
        themeMode: themeMode ?? this.themeMode,
        accent: accent ?? this.accent,
        compact: compact ?? this.compact,
        gardenLayout: gardenLayout ?? this.gardenLayout,
        showDailyQuote: showDailyQuote ?? this.showDailyQuote,
        showStreakCard: showStreakCard ?? this.showStreakCard,
        showWeekStrip: showWeekStrip ?? this.showWeekStrip,
        ambientMotion: ambientMotion ?? this.ambientMotion,
      );

  Map<String, dynamic> toJson() => {
        'themeMode': themeMode,
        'accent': accent,
        'compact': compact,
        'gardenLayout': gardenLayout.name,
        'showDailyQuote': showDailyQuote,
        'showStreakCard': showStreakCard,
        'showWeekStrip': showWeekStrip,
        'ambientMotion': ambientMotion,
      };

  factory AppSettings.fromJson(Map<String, dynamic> j) => AppSettings(
        themeMode: (j['themeMode'] as String?) ?? 'system',
        accent: (j['accent'] as String?) ?? 'moss',
        compact: (j['compact'] as bool?) ?? false,
        gardenLayout: j['gardenLayout'] == 'list' ? GardenLayout.list : GardenLayout.grid,
        showDailyQuote: (j['showDailyQuote'] as bool?) ?? true,
        showStreakCard: (j['showStreakCard'] as bool?) ?? true,
        showWeekStrip: (j['showWeekStrip'] as bool?) ?? true,
        ambientMotion: (j['ambientMotion'] as bool?) ?? true,
      );
}
