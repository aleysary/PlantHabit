import 'package:flutter/material.dart';

import '../../domain/rules.dart';

enum BadgeTier {
  bronze(Color(0xFFD08A5A), Color(0xFF8C4E2A)),
  silver(Color(0xFFD9DDE0), Color(0xFF7D868C)),
  gold(Color(0xFFF7D774), Color(0xFFB8861C)),
  emerald(Color(0xFFA8F0C0), Color(0xFF1F7A4A));

  const BadgeTier(this.light, this.dark);
  final Color light;
  final Color dark;
}

/// Milestone badge (stories 19–21). [progress] reads the current value from
/// stats; the badge is earned once progress >= target, and only once.
@immutable
class BadgeDef {
  const BadgeDef({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.tier,
    required this.target,
    required this.progress,
  });

  final String id;
  final String name;
  final String description;
  final IconData icon;
  final BadgeTier tier;
  final int target;
  final int Function(GardenStats s) progress;

  bool isMet(GardenStats s) => progress(s) >= target;
}

class BadgeCatalog {
  BadgeCatalog._();

  static final badges = <BadgeDef>[
    BadgeDef(id: 'first_sprout', name: 'First Sprout', description: 'Log your very first habit.', icon: Icons.grass_rounded, tier: BadgeTier.bronze, target: 1, progress: (s) => s.totalCompletions),
    BadgeDef(id: 'streak_3', name: 'Taking Root', description: 'Keep a 3-day streak.', icon: Icons.local_fire_department_rounded, tier: BadgeTier.bronze, target: 3, progress: (s) => s.longestStreak),
    BadgeDef(id: 'garden_3', name: 'Little Garden', description: 'Track 3 habits at once.', icon: Icons.yard_rounded, tier: BadgeTier.bronze, target: 3, progress: (s) => s.activeHabits),
    BadgeDef(id: 'streak_7', name: 'Week of Green', description: 'Keep a 7-day streak.', icon: Icons.calendar_view_week_rounded, tier: BadgeTier.silver, target: 7, progress: (s) => s.longestStreak),
    BadgeDef(id: 'completions_25', name: 'Green Thumb', description: 'Log 25 completions.', icon: Icons.back_hand_rounded, tier: BadgeTier.silver, target: 25, progress: (s) => s.totalCompletions),
    BadgeDef(id: 'first_bloom', name: 'First Bloom', description: 'Grow a plant to its final stage.', icon: Icons.local_florist_rounded, tier: BadgeTier.gold, target: 1, progress: (s) => s.plantsAtFinalStage),
    BadgeDef(id: 'botanist', name: 'Botanist', description: 'Grow 5 different species.', icon: Icons.science_rounded, tier: BadgeTier.silver, target: 5, progress: (s) => s.distinctSpecies),
    BadgeDef(id: 'perfect_week', name: 'Perfect Week', description: 'Hit every target for a full week.', icon: Icons.verified_rounded, tier: BadgeTier.gold, target: 1, progress: (s) => s.perfectWeeks),
    BadgeDef(id: 'streak_30', name: 'Evergreen', description: 'Keep a 30-day streak.', icon: Icons.forest_rounded, tier: BadgeTier.gold, target: 30, progress: (s) => s.longestStreak),
    BadgeDef(id: 'completions_100', name: 'Master Gardener', description: 'Log 100 completions.', icon: Icons.workspace_premium_rounded, tier: BadgeTier.emerald, target: 100, progress: (s) => s.totalCompletions),
    BadgeDef(id: 'greenhouse', name: 'Greenhouse', description: 'Track 6 habits at once.', icon: Icons.house_siding_rounded, tier: BadgeTier.silver, target: 6, progress: (s) => s.activeHabits),
    BadgeDef(id: 'bouquet', name: 'Bouquet', description: 'Have 3 plants at their final stage.', icon: Icons.filter_vintage_rounded, tier: BadgeTier.emerald, target: 3, progress: (s) => s.plantsAtFinalStage),
  ];

  static BadgeDef? byId(String id) {
    for (final b in badges) {
      if (b.id == id) return b;
    }
    return null;
  }
}
