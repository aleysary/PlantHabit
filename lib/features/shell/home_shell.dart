import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/verdant_colors.dart';
import '../../core/theme/verdant_theme.dart';
import '../../core/widgets/ui.dart';
import '../garden/garden_screen.dart';
import '../habits/habit_library_screen.dart';
import '../profile/profile_screen.dart';
import '../progress/progress_screen.dart';
import '../today/today_screen.dart';

/// Story 3: after login the user lands here, on their dashboard.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  void _go(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _index,
        children: [
          TodayScreen(onOpenGarden: () => _go(1)),
          const GardenScreen(),
          const ProgressScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: _NavBar(
        index: _index,
        onTap: _go,
        onAdd: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const HabitLibraryScreen())),
      ),
    );
  }
}

class _NavBar extends StatelessWidget {
  const _NavBar({required this.index, required this.onTap, required this.onAdd});
  final int index;
  final ValueChanged<int> onTap;
  final VoidCallback onAdd;

  static const _items = [
    (Icons.wb_twilight_rounded, 'Today'),
    (Icons.yard_rounded, 'Garden'),
    (Icons.insights_rounded, 'Progress'),
    (Icons.person_rounded, 'You'),
  ];

  @override
  Widget build(BuildContext context) {
    final v = context.v;
    final bottom = MediaQuery.of(context).padding.bottom;
    Widget item(int i) {
      final (icon, label) = _items[i];
      final selected = i == index;
      return Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            HapticFeedback.selectionClick();
            onTap(i);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: selected ? v.highlight : Colors.transparent,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Icon(icon, size: 22, color: selected ? VerdantColors.ink : v.onHero.o(0.6)),
              ),
              const SizedBox(height: 4),
              Text(label,
                  style: context.text.labelMedium?.copyWith(fontSize: 11, color: selected ? v.onHero : v.onHero.o(0.55))),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(14, 0, 14, bottom > 0 ? bottom : 14),
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: v.hero,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [BoxShadow(color: Colors.black.o(0.22), blurRadius: 24, offset: const Offset(0, 10))],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Row(
          children: [
            item(0),
            item(1),
            Pressable(
              onTap: onAdd,
              child: Container(
                width: 52,
                height: 52,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(color: v.highlight, borderRadius: BorderRadius.circular(18)),
                child: const Icon(Icons.add_rounded, color: VerdantColors.ink, size: 28),
              ),
            ),
            item(2),
            item(3),
          ],
        ),
      ),
    );
  }
}
