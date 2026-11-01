import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/verdant_colors.dart';
import '../../core/theme/verdant_theme.dart';
import '../../core/widgets/plant_view.dart';
import '../../core/widgets/ui.dart';
import '../../state/app_state.dart';
import '../badges/badges_screen.dart';
import '../catalog/plant_catalog_screen.dart';
import '../share/share_sheet.dart';
import 'appearance_screen.dart';
import 'updates_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final u = s.user;
    final v = context.v;
    final st = s.stats;
    void push(Widget w) => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => w));

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 130),
        children: [
          const Eyebrow('Account'),
          const SizedBox(height: 8),
          Text('You', style: context.text.displaySmall),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: v.hero, borderRadius: BorderRadius.circular(VerdantTheme.radiusLg)),
            child: Row(children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: v.highlight,
                child: Text(u?.initials ?? '?', style: context.text.headlineMedium?.copyWith(color: VerdantColors.ink)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Flexible(child: Text(u?.username ?? '', style: context.text.headlineSmall?.copyWith(color: v.onHero), overflow: TextOverflow.ellipsis)),
                    if (u?.isAdmin ?? false) ...[const SizedBox(width: 8), Pill('Admin', dense: true, color: v.highlight, textColor: VerdantColors.ink)],
                  ]),
                  const SizedBox(height: 2),
                  Text(u?.email ?? '', style: context.text.bodySmall?.copyWith(color: v.onHero.o(0.6))),
                  if (u != null)
                    Text('Gardening since ${DateFormat('MMMM y').format(u.createdAt)}', style: context.text.bodySmall?.copyWith(color: v.onHero.o(0.6))),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _MiniStat('${st.activeHabits}', 'Plants')),
            const SizedBox(width: 10),
            Expanded(child: _MiniStat('${st.totalCompletions}', 'Waterings')),
            const SizedBox(width: 10),
            Expanded(child: _MiniStat('${s.earnedBadges.length}', 'Badges')),
          ]),
          const SizedBox(height: 24),
          _Group(children: [
            _MenuRow(icon: Icons.workspace_premium_rounded, title: 'Badges & milestones', onTap: () => push(const BadgesScreen())),
            _MenuRow(icon: Icons.local_florist_rounded, title: 'Plant catalogue', onTap: () => push(const PlantCatalogScreen())),
            _MenuRow(icon: Icons.ios_share_rounded, title: 'Share progress', onTap: () => showShareSheet(context)),
          ]),
          const SizedBox(height: 12),
          _Group(children: [
            _MenuRow(icon: Icons.palette_rounded, title: 'Appearance & layout', subtitle: 'Theme, colours, home widgets', onTap: () => push(const AppearanceScreen())),
            if (u?.isAdmin ?? false)
              _MenuRow(icon: Icons.system_update_rounded, title: 'App updates', subtitle: 'Version ${s.updates.currentVersion}', onTap: () => push(const UpdatesScreen())),
          ]),
          const SizedBox(height: 12),
          _Group(children: [
            _MenuRow(
              icon: Icons.logout_rounded,
              title: 'Log out',
              danger: true,
              onTap: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (c) => AlertDialog(
                    title: const Text('Log out?'),
                    content: const Text('Your garden is saved. You’ll need to sign in again to see it.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Stay')),
                      TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Log out')),
                    ],
                  ),
                );
                if (ok == true) await s.signOut();
              },
            ),
          ]),
          const SizedBox(height: 28),
          Center(child: SizedBox(height: 90, child: PlantView(speciesId: 'lucky_bamboo', stage: 3, potId: 'sage', ambient: s.settings.ambientMotion))),
          const SizedBox(height: 6),
          Center(child: Text('Verdant ${s.updates.currentVersion}', style: context.text.bodySmall)),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat(this.value, this.label);
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) => VCard(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: context.text.headlineSmall),
          Text(label, style: context.text.bodySmall),
        ]),
      );
}

class _Group extends StatelessWidget {
  const _Group({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) items.add(Divider(indent: 64, color: context.v.line));
      items.add(children[i]);
    }
    return VCard(padding: EdgeInsets.zero, child: Column(children: items));
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.icon, required this.title, required this.onTap, this.subtitle, this.danger = false});
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool danger;
  @override
  Widget build(BuildContext context) {
    final color = danger ? VerdantColors.danger : context.v.text;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(children: [
          IconSquare(icon, size: 38, iconColor: color, color: danger ? VerdantColors.danger.o(0.1) : null),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: context.text.titleSmall?.copyWith(color: color)),
              if (subtitle != null) Text(subtitle!, style: context.text.bodySmall),
            ]),
          ),
          if (!danger) Icon(Icons.chevron_right_rounded, color: context.v.muted),
        ]),
      ),
    );
  }
}
