import 'package:flutter/material.dart';

import '../models/models.dart';

/// A built-in habit the user can browse and add (stories 5 & 6).
@immutable
class HabitTemplate {
  const HabitTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.iconKey,
    required this.suggestedSpecies,
    required this.defaultFrequency,
  });

  final String id;
  final String name;
  final String description;
  final String category;
  final String iconKey;
  final String suggestedSpecies;
  final HabitFrequency defaultFrequency;
}

class HabitCatalog {
  HabitCatalog._();

  static const categories = [
    'All',
    'Wellness',
    'Mind',
    'Fitness',
    'Growth',
    'Home'
  ];

  static const icons = <String, IconData>{
    'water': Icons.water_drop_rounded,
    'meditate': Icons.self_improvement_rounded,
    'walk': Icons.directions_walk_rounded,
    'read': Icons.menu_book_rounded,
    'sleep': Icons.bedtime_rounded,
    'gym': Icons.fitness_center_rounded,
    'journal': Icons.edit_note_rounded,
    'cook': Icons.restaurant_rounded,
    'screen': Icons.phonelink_erase_rounded,
    'music': Icons.music_note_rounded,
    'language': Icons.translate_rounded,
    'gratitude': Icons.favorite_rounded,
    'sun': Icons.wb_sunny_rounded,
    'save': Icons.savings_rounded,
    'stretch': Icons.accessibility_new_rounded,
    'tidy': Icons.cleaning_services_rounded,
    'call': Icons.call_rounded,
    'code': Icons.code_rounded,
    'draw': Icons.brush_rounded,
    'run': Icons.directions_run_rounded,
    'nodrink': Icons.no_drinks_rounded,
    'learn': Icons.psychology_rounded,
    'spa': Icons.spa_rounded,
  };

  static IconData icon(String key) => icons[key] ?? Icons.spa_rounded;

  static const templates = <HabitTemplate>[
    HabitTemplate(
        id: 'weekly-plan',
        name: 'Plan your week',
        description: 'Choose your priorities for the coming week.',
        category: 'Growth',
        iconKey: 'journal',
        suggestedSpecies: 'olive',
        defaultFrequency: HabitFrequency.weekly(1)),
    HabitTemplate(
        id: 'weekly-clean',
        name: 'Clean your room',
        description: 'Give your space a weekly refresh.',
        category: 'Home',
        iconKey: 'tidy',
        suggestedSpecies: 'fern',
        defaultFrequency: HabitFrequency.weekly(1)),
    HabitTemplate(
        id: 'fortnight-budget',
        name: 'Review your budget',
        description: 'Check spending and adjust your plans every two weeks.',
        category: 'Growth',
        iconKey: 'save',
        suggestedSpecies: 'bonsai',
        defaultFrequency: HabitFrequency.biweekly()),
    HabitTemplate(
        id: 'fortnight-declutter',
        name: 'Declutter a space',
        description: 'Sort a drawer, shelf, or cupboard every two weeks.',
        category: 'Home',
        iconKey: 'tidy',
        suggestedSpecies: 'echeveria',
        defaultFrequency: HabitFrequency.biweekly()),
    HabitTemplate(
        id: 'monthly-reflect',
        name: 'Reflect on your month',
        description: 'Celebrate progress and set intentions for next month.',
        category: 'Mind',
        iconKey: 'journal',
        suggestedSpecies: 'cherry_blossom',
        defaultFrequency: HabitFrequency.monthly()),
    HabitTemplate(
        id: 'monthly-connect',
        name: 'Plan a catch-up',
        description: 'Make time each month to reconnect with someone.',
        category: 'Home',
        iconKey: 'call',
        suggestedSpecies: 'tulip',
        defaultFrequency: HabitFrequency.monthly()),
    HabitTemplate(
        id: 'hydrate',
        name: 'Drink 8 glasses of water',
        description: 'Keep a bottle nearby and sip through the day.',
        category: 'Wellness',
        iconKey: 'water',
        suggestedSpecies: 'peace_lily',
        defaultFrequency: HabitFrequency.daily()),
    HabitTemplate(
        id: 'meditate',
        name: 'Meditate 10 minutes',
        description: 'Sit, breathe, and notice. Ten quiet minutes.',
        category: 'Mind',
        iconKey: 'meditate',
        suggestedSpecies: 'bonsai',
        defaultFrequency: HabitFrequency.daily()),
    HabitTemplate(
        id: 'walk',
        name: 'Take a 30-minute walk',
        description: 'Get outside and move at an easy pace.',
        category: 'Fitness',
        iconKey: 'walk',
        suggestedSpecies: 'fern',
        defaultFrequency: HabitFrequency.weekly(5)),
    HabitTemplate(
        id: 'read',
        name: 'Read 20 pages',
        description: 'Fiction, non-fiction — anything that isn’t a feed.',
        category: 'Growth',
        iconKey: 'read',
        suggestedSpecies: 'fiddle_leaf',
        defaultFrequency: HabitFrequency.daily()),
    HabitTemplate(
        id: 'sleep',
        name: 'In bed by 11pm',
        description: 'Protect your sleep window. Screens off first.',
        category: 'Wellness',
        iconKey: 'sleep',
        suggestedSpecies: 'lavender',
        defaultFrequency: HabitFrequency.daily()),
    HabitTemplate(
        id: 'workout',
        name: 'Strength workout',
        description: 'A focused session — weights, bands or bodyweight.',
        category: 'Fitness',
        iconKey: 'gym',
        suggestedSpecies: 'cactus',
        defaultFrequency: HabitFrequency.weekly(3)),
    HabitTemplate(
        id: 'journal',
        name: 'Evening journal',
        description: 'Three lines about today. That’s enough.',
        category: 'Mind',
        iconKey: 'journal',
        suggestedSpecies: 'calathea',
        defaultFrequency: HabitFrequency.daily()),
    HabitTemplate(
        id: 'cook',
        name: 'Cook a home meal',
        description: 'Make something real with your own hands.',
        category: 'Home',
        iconKey: 'cook',
        suggestedSpecies: 'olive',
        defaultFrequency: HabitFrequency.weekly(4)),
    HabitTemplate(
        id: 'screen',
        name: 'No phone first hour',
        description: 'Start the day before the feed does.',
        category: 'Mind',
        iconKey: 'screen',
        suggestedSpecies: 'snake_plant',
        defaultFrequency: HabitFrequency.daily()),
    HabitTemplate(
        id: 'music',
        name: 'Practice an instrument',
        description: 'Fifteen minutes of deliberate practice.',
        category: 'Growth',
        iconKey: 'music',
        suggestedSpecies: 'bird_of_paradise',
        defaultFrequency: HabitFrequency.weekly(4)),
    HabitTemplate(
        id: 'language',
        name: 'Learn a language',
        description: 'One lesson or twenty new words.',
        category: 'Growth',
        iconKey: 'language',
        suggestedSpecies: 'cherry_blossom',
        defaultFrequency: HabitFrequency.daily()),
    HabitTemplate(
        id: 'gratitude',
        name: 'Write 3 gratitudes',
        description: 'Name three good things, however small.',
        category: 'Mind',
        iconKey: 'gratitude',
        suggestedSpecies: 'rose',
        defaultFrequency: HabitFrequency.daily()),
    HabitTemplate(
        id: 'sunlight',
        name: 'Morning sunlight',
        description: 'Ten minutes of daylight soon after waking.',
        category: 'Wellness',
        iconKey: 'sun',
        suggestedSpecies: 'sunflower',
        defaultFrequency: HabitFrequency.daily()),
    HabitTemplate(
        id: 'save',
        name: 'No-spend day',
        description: 'Only essentials today. Watch the savings grow.',
        category: 'Growth',
        iconKey: 'save',
        suggestedSpecies: 'lucky_bamboo',
        defaultFrequency: HabitFrequency.weekly(3)),
    HabitTemplate(
        id: 'stretch',
        name: 'Stretch 10 minutes',
        description: 'Loosen hips, back and shoulders.',
        category: 'Fitness',
        iconKey: 'stretch',
        suggestedSpecies: 'pothos',
        defaultFrequency: HabitFrequency.daily()),
    HabitTemplate(
        id: 'tidy',
        name: 'Ten-minute tidy',
        description: 'Reset one surface or one room.',
        category: 'Home',
        iconKey: 'tidy',
        suggestedSpecies: 'echeveria',
        defaultFrequency: HabitFrequency.daily()),
    HabitTemplate(
        id: 'call',
        name: 'Call someone you love',
        description: 'A real conversation, not a text.',
        category: 'Home',
        iconKey: 'call',
        suggestedSpecies: 'tulip',
        defaultFrequency: HabitFrequency.weekly(2)),
    HabitTemplate(
        id: 'run',
        name: 'Go for a run',
        description: 'Any distance counts. Just lace up.',
        category: 'Fitness',
        iconKey: 'run',
        suggestedSpecies: 'aloe',
        defaultFrequency: HabitFrequency.weekly(3)),
    HabitTemplate(
        id: 'nodrink',
        name: 'Alcohol-free day',
        description: 'Swap in something sparkling.',
        category: 'Wellness',
        iconKey: 'nodrink',
        suggestedSpecies: 'monstera',
        defaultFrequency: HabitFrequency.daily()),
    HabitTemplate(
        id: 'code',
        name: 'Build something',
        description: 'Ship a small piece of a side project.',
        category: 'Growth',
        iconKey: 'code',
        suggestedSpecies: 'cactus',
        defaultFrequency: HabitFrequency.weekly(4)),
    HabitTemplate(
        id: 'draw',
        name: 'Sketch for 15 minutes',
        description: 'Pencil, paper, no pressure.',
        category: 'Growth',
        iconKey: 'draw',
        suggestedSpecies: 'calathea',
        defaultFrequency: HabitFrequency.weekly(3)),
  ];

  static HabitTemplate? byId(String id) {
    for (final t in templates) {
      if (t.id == id) return t;
    }
    return null;
  }

  /// The few starting points shown under "Need ideas?" in the habit screen.
  /// Users are encouraged to write their own; these are just examples, one
  /// or two per rhythm, and open in the editor so they can be personalised.
  static const suggestionIds = [
    'hydrate',
    'read',
    'workout',
    'weekly-plan',
    'fortnight-budget',
    'monthly-reflect',
  ];

  static List<HabitTemplate> get suggestions =>
      [for (final id in suggestionIds) byId(id)!];

  /// A blank template for a habit the user writes from scratch.
  static HabitTemplate blank() => HabitTemplate(
        id: 'custom-${DateTime.now().microsecondsSinceEpoch}',
        name: '',
        description: '',
        category: 'Personal',
        iconKey: 'spa',
        suggestedSpecies: 'sunflower',
        defaultFrequency: const HabitFrequency.daily(),
      );
}
