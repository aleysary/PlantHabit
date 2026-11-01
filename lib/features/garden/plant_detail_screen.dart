import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/group_plants.dart';
import '../../state/app_state.dart';
import 'group_plant_screen.dart';

/// Existing habit links now open the shared plant for that habit's group.
class PlantDetailScreen extends StatelessWidget {
  const PlantDetailScreen({super.key, required this.habitId});
  final String habitId;
  @override
  Widget build(BuildContext context) {
    final habit = context.watch<AppState>().habitById(habitId);
    if (habit == null) {
      return const Scaffold(
          body: Center(child: Text('This habit is no longer here.')));
    }
    return GroupPlantScreen(group: HabitGroup.of(habit.frequency));
  }
}
