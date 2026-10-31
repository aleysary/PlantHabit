import 'package:flutter/material.dart';

/// A plant species the user can grow. Art lives in assets/plants/<id>/.
/// Regenerate the art with `node tool/plant_art/generate.mjs`.
@immutable
class PlantSpecies {
  const PlantSpecies({
    required this.id,
    required this.name,
    required this.latin,
    required this.finalStageName,
    required this.care,
    required this.vibe,
    required this.tint,
    this.frontLayerFromStage,
    this.rarity = PlantRarity.common,
  });

  final String id;
  final String name;
  final String latin;

  /// Name of the last growth stage ("Blooming", "Thriving"...).
  final String finalStageName;
  final String care;
  final String vibe;

  /// Representative colour used for chips and accents.
  final Color tint;

  /// Some plants (trailing pothos) have a layer drawn in front of the pot.
  final int? frontLayerFromStage;
  final PlantRarity rarity;

  String asset(int stage) => 'assets/plants/$id/stage_$stage.svg';
  String? frontAsset(int stage) =>
      frontLayerFromStage != null && stage >= frontLayerFromStage! ? 'assets/plants/$id/stage_${stage}_front.svg' : null;
}

enum PlantRarity {
  common('Common'),
  uncommon('Uncommon'),
  rare('Rare');

  const PlantRarity(this.label);
  final String label;
}

@immutable
class PotStyle {
  const PotStyle(this.id, this.name, this.swatch);
  final String id;
  final String name;
  final Color swatch;
  String get back => 'assets/pots/${id}_back.svg';
  String get front => 'assets/pots/${id}_front.svg';
}

/// Growth stages shared by every species. Index == stage number.
@immutable
class GrowthStage {
  const GrowthStage(this.index, this.name, this.threshold, this.blurb);
  final int index;
  final String name;

  /// Valid completions needed to reach this stage.
  final int threshold;
  final String blurb;
}

class PlantCatalog {
  PlantCatalog._();

  static const stages = <GrowthStage>[
    GrowthStage(0, 'Seed', 0, 'Planted and full of potential.'),
    GrowthStage(1, 'Sprout', 1, 'The first green shoot breaks through.'),
    GrowthStage(2, 'Seedling', 3, 'Roots are settling in.'),
    GrowthStage(3, 'Growing', 7, 'A week of care shows.'),
    GrowthStage(4, 'Mature', 14, 'Strong, steady, established.'),
    GrowthStage(5, 'Final', 24, 'Your consistency in full bloom.'),
  ];

  static String stageName(PlantSpecies s, int stage) => stage == 5 ? s.finalStageName : stages[stage].name;

  static const species = <PlantSpecies>[
    PlantSpecies(id: 'monstera', name: 'Monstera', latin: 'Monstera deliciosa', finalStageName: 'Thriving', care: 'Bright, indirect light', vibe: 'Bold & tropical', tint: Color(0xFF2F7D47)),
    PlantSpecies(id: 'snake_plant', name: 'Snake Plant', latin: 'Dracaena trifasciata', finalStageName: 'Flowering', care: 'Thrives on neglect', vibe: 'Sharp & architectural', tint: Color(0xFF2A5B36)),
    PlantSpecies(id: 'fiddle_leaf', name: 'Fiddle Leaf Fig', latin: 'Ficus lyrata', finalStageName: 'Thriving', care: 'Steady light, no drafts', vibe: 'Statement tree', tint: Color(0xFF2D6C36), rarity: PlantRarity.uncommon),
    PlantSpecies(id: 'echeveria', name: 'Echeveria', latin: 'Echeveria elegans', finalStageName: 'Flowering', care: 'Sun & sparse water', vibe: 'Soft geometry', tint: Color(0xFF6FA59A)),
    PlantSpecies(id: 'cactus', name: 'Saguaro Cactus', latin: 'Carnegiea gigantea', finalStageName: 'Flowering', care: 'Full sun, very dry', vibe: 'Desert icon', tint: Color(0xFF4E8B51)),
    PlantSpecies(id: 'fern', name: 'Boston Fern', latin: 'Nephrolepis exaltata', finalStageName: 'Lush', care: 'Humid & shaded', vibe: 'Feathery & lush', tint: Color(0xFF62AA40)),
    PlantSpecies(id: 'bonsai', name: 'Juniper Bonsai', latin: 'Juniperus procumbens', finalStageName: 'Thriving', care: 'Patience, daily care', vibe: 'Calm & ancient', tint: Color(0xFF5C9A3F), rarity: PlantRarity.rare),
    PlantSpecies(id: 'sunflower', name: 'Sunflower', latin: 'Helianthus annuus', finalStageName: 'Blooming', care: 'All the sun', vibe: 'Pure optimism', tint: Color(0xFFF5B322)),
    PlantSpecies(id: 'tulip', name: 'Tulip', latin: 'Tulipa gesneriana', finalStageName: 'Blooming', care: 'Cool spring light', vibe: 'Bright & cheerful', tint: Color(0xFFE03A4A)),
    PlantSpecies(id: 'lavender', name: 'Lavender', latin: 'Lavandula angustifolia', finalStageName: 'Blooming', care: 'Sun & good drainage', vibe: 'Calm & fragrant', tint: Color(0xFF8A68D4)),
    PlantSpecies(id: 'cherry_blossom', name: 'Cherry Blossom', latin: 'Prunus serrulata', finalStageName: 'Blooming', care: 'Seasonal rhythm', vibe: 'Fleeting beauty', tint: Color(0xFFF08BB0), rarity: PlantRarity.rare),
    PlantSpecies(id: 'peace_lily', name: 'Peace Lily', latin: 'Spathiphyllum wallisii', finalStageName: 'Blooming', care: 'Low light friendly', vibe: 'Serene & glossy', tint: Color(0xFF1F5E35)),
    PlantSpecies(id: 'aloe', name: 'Aloe Vera', latin: 'Aloe barbadensis', finalStageName: 'Flowering', care: 'Bright & dry', vibe: 'Healing spikes', tint: Color(0xFF73A970)),
    PlantSpecies(id: 'rose', name: 'Garden Rose', latin: 'Rosa × hybrida', finalStageName: 'Blooming', care: 'Sun & attention', vibe: 'Romantic classic', tint: Color(0xFFD9203F), rarity: PlantRarity.uncommon),
    PlantSpecies(id: 'bird_of_paradise', name: 'Bird of Paradise', latin: 'Strelitzia reginae', finalStageName: 'Blooming', care: 'Bright light, warmth', vibe: 'Exotic flair', tint: Color(0xFFF07C11), rarity: PlantRarity.rare),
    PlantSpecies(id: 'calathea', name: 'Calathea', latin: 'Goeppertia roseopicta', finalStageName: 'Thriving', care: 'Humidity & shade', vibe: 'Painted leaves', tint: Color(0xFF6B3D5E), rarity: PlantRarity.uncommon),
    PlantSpecies(id: 'pothos', name: 'Golden Pothos', latin: 'Epipremnum aureum', finalStageName: 'Cascading', care: 'Any light, easy', vibe: 'Easygoing trailer', tint: Color(0xFF4F9A3A), frontLayerFromStage: 3),
    PlantSpecies(id: 'lucky_bamboo', name: 'Lucky Bamboo', latin: 'Dracaena sanderiana', finalStageName: 'Flourishing', care: 'Indirect light', vibe: 'Good fortune', tint: Color(0xFF8AB84E)),
    PlantSpecies(id: 'olive', name: 'Olive Tree', latin: 'Olea europaea', finalStageName: 'Fruiting', care: 'Sun & warmth', vibe: 'Mediterranean calm', tint: Color(0xFF8FAA72), rarity: PlantRarity.uncommon),
  ];

  static const pots = <PotStyle>[
    PotStyle('terracotta', 'Terracotta', Color(0xFFC96A3C)),
    PotStyle('ivory', 'Ivory Ceramic', Color(0xFFEDE7DA)),
    PotStyle('stone', 'Concrete', Color(0xFFA9A59D)),
    PotStyle('sage', 'Sage Glaze', Color(0xFF93AD8D)),
    PotStyle('midnight', 'Midnight', Color(0xFF2A3348)),
    PotStyle('blush', 'Blush', Color(0xFFDFA999)),
  ];

  static PlantSpecies byId(String id) => species.firstWhere((s) => s.id == id, orElse: () => species.first);
  static PotStyle potById(String id) => pots.firstWhere((p) => p.id == id, orElse: () => pots.first);

  /// Every asset path — handy for precaching.
  static Iterable<String> allAssets() sync* {
    for (final s in species) {
      for (var i = 0; i < stages.length; i++) {
        yield s.asset(i);
        final f = s.frontAsset(i);
        if (f != null) yield f;
      }
    }
    for (final p in pots) {
      yield p.back;
      yield p.front;
    }
  }
}
