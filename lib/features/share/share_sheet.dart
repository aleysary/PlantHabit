import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/verdant_colors.dart';
import '../../core/theme/verdant_theme.dart';
import '../../core/widgets/plant_view.dart';
import '../../core/widgets/ui.dart';
import '../../data/catalog/badge_catalog.dart';
import '../../data/catalog/plant_catalog.dart';
import '../../data/repositories/repositories.dart';
import '../../state/app_state.dart';
import '../shell/splash_screen.dart';

/// What the user chose to share. Private habit names are excluded unless
/// [includeHabitNames] is switched on (story 22).
class ShareSelection {
  ShareSelection({this.habitId, this.plant = true, this.progress = true, this.badges = false, this.includeHabitNames = false});
  String? habitId;
  bool plant;
  bool progress;
  bool badges;
  bool includeHabitNames;
}

Future<void> showShareSheet(BuildContext context, {String? focusHabitId, bool preselectBadges = false}) {
  final s = context.read<AppState>();
  final sel = ShareSelection(
    habitId: focusHabitId ?? (s.activeHabits.isEmpty ? null : s.activeHabits.first.id),
    plant: s.activeHabits.isNotEmpty,
    badges: preselectBadges,
    progress: !preselectBadges,
  );
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _ShareSheet(selection: sel),
  );
}

class _ShareSheet extends StatefulWidget {
  const _ShareSheet({required this.selection});
  final ShareSelection selection;
  @override
  State<_ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends State<_ShareSheet> {
  final _cardKey = GlobalKey();
  bool _sharing = false;
  ShareSelection get sel => widget.selection;

  bool get _hasSomething => (sel.plant && sel.habitId != null) || sel.progress || sel.badges;

  Future<void> _share(AppState s) async {
    setState(() => _sharing = true);
    final text = buildShareText(s, sel);
    try {
      final boundary = _cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      final image = await boundary?.toImage(pixelRatio: 3);
      final bytes = await image?.toByteData(format: ui.ImageByteFormat.png);
      if (bytes != null) {
        await Share.shareXFiles(
          [XFile.fromData(bytes.buffer.asUint8List(), mimeType: 'image/png', name: 'verdant-garden.png')],
          text: text,
          subject: 'My Verdant garden',
        );
      } else {
        await Share.share(text, subject: 'My Verdant garden');
      }
    } catch (_) {
      await Share.share(text, subject: 'My Verdant garden');
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final v = context.v;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.92,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, scroll) => Column(children: [
        Expanded(
          child: ListView(
            controller: scroll,
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 16),
            children: [
              Text('Share your garden', style: context.text.headlineMedium),
              const SizedBox(height: 4),
              Text('Review exactly what will be shared before it leaves the app.', style: context.text.bodyMedium?.copyWith(color: v.muted)),
              const SizedBox(height: 18),
              Center(
                child: RepaintBoundary(
                  key: _cardKey,
                  child: ShareCard(selection: sel),
                ),
              ),
              const SizedBox(height: 20),
              const Eyebrow('Include'),
              const SizedBox(height: 8),
              _Toggle(
                icon: Icons.spa_rounded,
                title: 'A plant',
                value: sel.plant && sel.habitId != null,
                onChanged: s.activeHabits.isEmpty ? null : (x) => setState(() => sel.plant = x),
              ),
              if (sel.plant && s.activeHabits.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Wrap(spacing: 8, runSpacing: 8, children: [
                    for (final h in s.activeHabits)
                      ChoiceChip(
                        label: Text(s.plantLabel(h)),
                        selected: h.id == sel.habitId,
                        onSelected: (_) => setState(() => sel.habitId = h.id),
                      ),
                  ]),
                ),
              _Toggle(icon: Icons.insights_rounded, title: 'Progress summary', value: sel.progress, onChanged: (x) => setState(() => sel.progress = x)),
              _Toggle(icon: Icons.workspace_premium_rounded, title: 'Earned badges', value: sel.badges, onChanged: (x) => setState(() => sel.badges = x)),
              const SizedBox(height: 14),
              const Eyebrow('Privacy'),
              const SizedBox(height: 8),
              _Toggle(
                icon: Icons.lock_outline_rounded,
                title: 'Include habit names',
                subtitle: sel.includeHabitNames ? 'Habit names will be visible.' : 'Off — only plants and numbers are shared.',
                value: sel.includeHabitNames,
                onChanged: (x) => setState(() => sel.includeHabitNames = x),
              ),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.fromLTRB(22, 12, 22, 12 + MediaQuery.of(context).padding.bottom),
          decoration: BoxDecoration(border: Border(top: BorderSide(color: v.line))),
          child: Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: !_hasSomething
                    ? null
                    : () {
                        final nav = Navigator.of(context);
                        nav.pop();
                        nav.push(MaterialPageRoute<void>(builder: (_) => EmailShareScreen(selection: sel)));
                      },
                icon: const Icon(Icons.mail_outline_rounded),
                label: const Text('Email'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: !_hasSomething || _sharing ? null : () => _share(s),
                icon: const Icon(Icons.ios_share_rounded),
                label: Text(_sharing ? 'Preparing…' : 'Share'),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({required this.icon, required this.title, required this.value, required this.onChanged, this.subtitle});
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          IconSquare(icon, size: 38),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: context.text.titleSmall),
              if (subtitle != null) Text(subtitle!, style: context.text.bodySmall),
            ]),
          ),
          Switch(value: value, onChanged: onChanged),
        ]),
      );
}

/// The visual that gets shared. Fixed size so the exported image is crisp.
class ShareCard extends StatelessWidget {
  const ShareCard({super.key, required this.selection});
  final ShareSelection selection;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final h = selection.habitId == null ? null : s.habitById(selection.habitId!);
    final showPlant = selection.plant && h != null;
    final st = s.stats;
    final badges = BadgeCatalog.badges.where((b) => s.hasBadge(b.id)).toList();
    const fg = VerdantColors.mist;

    return Container(
      width: 320,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: VerdantColors.ink, borderRadius: BorderRadius.circular(28)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          const VerdantWordmark(size: 20, color: fg),
          const Spacer(),
          Text(s.user?.username ?? '', style: context.text.labelMedium?.copyWith(color: fg.o(0.6))),
        ]),
        if (showPlant && h != null) ...[
          const SizedBox(height: 14),
          Container(
            height: 230,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: VerdantColors.potBackdrops[h.potId] ?? [fg, fg]),
            ),
            padding: const EdgeInsets.fromLTRB(10, 14, 10, 4),
            child: Center(child: PlantView(speciesId: h.speciesId, stage: s.stageOf(h), potId: h.potId)),
          ),
          const SizedBox(height: 12),
          Text(
            '${s.plantLabel(h)} · ${PlantCatalog.stageName(PlantCatalog.byId(h.speciesId), s.stageOf(h))}',
            style: context.text.headlineSmall?.copyWith(color: fg, fontSize: 22),
          ),
          Text(
            selection.includeHabitNames ? 'Grown by: ${h.name.toLowerCase()}' : 'Grown by ${s.validCount(h.id)} days of showing up',
            style: context.text.bodySmall?.copyWith(color: fg.o(0.65)),
          ),
        ],
        if (selection.progress) ...[
          const SizedBox(height: 16),
          Row(children: [
            _mini(context, '${st.currentStreak}', 'day streak'),
            _mini(context, '${st.totalCompletions}', 'waterings'),
            _mini(context, '${st.activeHabits}', 'plants'),
          ]),
          if (selection.includeHabitNames && s.activeHabits.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(s.activeHabits.map((x) => x.name).join(' · '), style: context.text.bodySmall?.copyWith(color: fg.o(0.65))),
          ],
        ],
        if (selection.badges) ...[
          const SizedBox(height: 16),
          Text(badges.isEmpty ? 'No badges yet — soon!' : '${badges.length} badges earned',
              style: context.text.labelLarge?.copyWith(color: fg)),
          const SizedBox(height: 8),
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (final b in badges.take(8)) BadgeMedal(icon: b.icon, tier: b.tier, size: 34),
          ]),
        ],
      ]),
    );
  }

  Widget _mini(BuildContext context, String value, String label) => Expanded(
        child: Container(
          margin: const EdgeInsets.only(right: 6),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
          decoration: BoxDecoration(color: Colors.white.o(0.07), borderRadius: BorderRadius.circular(14)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value, style: context.text.titleLarge?.copyWith(color: VerdantColors.lime)),
            Text(label, style: context.text.bodySmall?.copyWith(color: VerdantColors.mist.o(0.6), fontSize: 11)),
          ]),
        ),
      );
}

/// Plain-text version used for share text and email bodies.
String buildShareText(AppState s, ShareSelection sel) {
  final b = StringBuffer('🌱 My Verdant garden\n');
  final h = sel.habitId == null ? null : s.habitById(sel.habitId!);
  if (sel.plant && h != null) {
    final sp = PlantCatalog.byId(h.speciesId);
    b.writeln('\n${s.plantLabel(h)} the ${sp.name.toLowerCase()} is now ${PlantCatalog.stageName(sp, s.stageOf(h)).toLowerCase()}.');
    if (sel.includeHabitNames) b.writeln('It grows every time I: ${h.name.toLowerCase()}.');
  }
  if (sel.progress) {
    final st = s.stats;
    b.writeln('\n${st.currentStreak}-day streak · ${st.totalCompletions} completions · ${st.activeHabits} plants growing.');
    if (sel.includeHabitNames) {
      for (final x in s.activeHabits) {
        b.writeln('• ${x.name} (${x.frequency.label.toLowerCase()})');
      }
    }
  }
  if (sel.badges) {
    final earned = BadgeCatalog.badges.where((x) => s.hasBadge(x.id)).map((x) => x.name).toList();
    if (earned.isNotEmpty) b.writeln('\nBadges: ${earned.join(', ')}');
  }
  b.write('\nGrow your own habits with Verdant.');
  return b.toString();
}

// ---------------------------------------------------------------------------
// Story 24: send habits & plants to someone by email.
class EmailShareScreen extends StatefulWidget {
  const EmailShareScreen({super.key, required this.selection});
  final ShareSelection selection;
  @override
  State<EmailShareScreen> createState() => _EmailShareScreenState();
}

class _EmailShareScreenState extends State<EmailShareScreen> {
  final _form = GlobalKey<FormState>();
  final _to = TextEditingController();
  final _note = TextEditingController();
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _to.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_form.currentState!.validate()) return;
    final s = context.read<AppState>();
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final note = _note.text.trim();
      await s.email.send(
        to: _to.text.trim(),
        subject: '${s.user?.username ?? 'A friend'} shared their Verdant garden 🌱',
        body: '${note.isEmpty ? '' : '$note\n\n'}${buildShareText(s, widget.selection)}',
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (c) => AlertDialog(
          icon: const Icon(Icons.mark_email_read_rounded, size: 36),
          title: const Text('Sent!'),
          content: Text('Your garden is on its way to ${_to.text.trim()}.'),
          actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('Done'))],
        ),
      );
      if (mounted) Navigator.of(context).pop();
    } on VerdantException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Something went wrong sending the email. Please try again.');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final v = context.v;
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          const TopBar(title: 'Email your garden'),
          Expanded(
            child: Form(
              key: _form,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
                children: [
                  if (_error != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: context.colors.error.withAlpha(24), borderRadius: BorderRadius.circular(VerdantTheme.radiusMd)),
                      child: Row(children: [
                        Icon(Icons.error_outline_rounded, color: context.colors.error),
                        const SizedBox(width: 10),
                        Expanded(child: Text(_error!, style: TextStyle(color: context.colors.error))),
                      ]),
                    ),
                  TextFormField(
                    controller: _to,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Recipient email', prefixIcon: Icon(Icons.alternate_email_rounded)),
                    validator: (x) => (x == null || !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(x.trim())) ? 'Enter a valid email' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _note,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Add a note (optional)', alignLabelWithHint: true),
                  ),
                  const SizedBox(height: 22),
                  const Eyebrow('Preview'),
                  const SizedBox(height: 10),
                  Center(child: ShareCard(selection: widget.selection)),
                  const SizedBox(height: 14),
                  VCard(
                    color: v.raised,
                    border: false,
                    child: Text(buildShareText(s, widget.selection), style: context.text.bodyMedium),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 16),
            child: PrimaryButton(label: 'Send email', icon: Icons.send_rounded, loading: _sending, onPressed: _send),
          ),
        ]),
      ),
    );
  }
}
