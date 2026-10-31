import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/verdant_colors.dart';
import '../../core/theme/verdant_theme.dart';
import '../../core/widgets/ui.dart';
import '../../data/repositories/repositories.dart';
import '../../state/app_state.dart';

enum _UpdatePhase { checking, upToDate, available, installing, failed, installed }

/// Story 25 (admin): see, install or postpone updates; retry on failure.
class UpdatesScreen extends StatefulWidget {
  const UpdatesScreen({super.key});
  @override
  State<UpdatesScreen> createState() => _UpdatesScreenState();
}

class _UpdatesScreenState extends State<UpdatesScreen> {
  _UpdatePhase _phase = _UpdatePhase.checking;
  AppUpdate? _update;
  double _progress = 0;
  String? _error;
  StreamSubscription<double>? _sub;

  UpdateService get _svc => context.read<AppState>().updates;

  @override
  void initState() {
    super.initState();
    _check();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _check() async {
    setState(() => _phase = _UpdatePhase.checking);
    final u = await _svc.checkForUpdate();
    if (!mounted) return;
    setState(() {
      _update = u;
      _phase = u == null ? _UpdatePhase.upToDate : _UpdatePhase.available;
    });
  }

  void _install() {
    final u = _update;
    if (u == null) return;
    setState(() {
      _phase = _UpdatePhase.installing;
      _progress = 0;
      _error = null;
    });
    _sub = _svc.install(u).listen(
      (p) => setState(() => _progress = p),
      onError: (Object e) => setState(() {
        _phase = _UpdatePhase.failed;
        _error = e is VerdantException ? e.message : 'The update couldn’t be installed.';
      }),
      onDone: () {
        if (_phase == _UpdatePhase.installing && mounted) {
          setState(() => _phase = _UpdatePhase.installed);
          showToast(context, 'Updated to ${u.version}.', icon: Icons.check_circle_rounded);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final v = context.v;
    final u = _update;
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          const TopBar(title: 'App updates'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
              children: [
                VCard(
                  child: Row(children: [
                    IconSquare(Icons.verified_rounded, color: v.highlight, iconColor: VerdantColors.ink),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Installed version', style: context.text.bodySmall),
                        Text(_svc.currentVersion, style: context.text.headlineSmall),
                      ]),
                    ),
                    if (_phase == _UpdatePhase.upToDate || _phase == _UpdatePhase.installed)
                      TextButton(onPressed: _check, child: const Text('Check again')),
                  ]),
                ),
                const SizedBox(height: 16),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  child: switch (_phase) {
                    _UpdatePhase.checking => const Padding(
                        key: ValueKey('c'),
                        padding: EdgeInsets.all(40),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    _UpdatePhase.upToDate || _UpdatePhase.installed => Padding(
                        key: const ValueKey('ok'),
                        padding: const EdgeInsets.all(24),
                        child: Column(children: [
                          Icon(Icons.check_circle_rounded, size: 44, color: context.colors.primary),
                          const SizedBox(height: 10),
                          Text('You’re up to date', style: context.text.titleLarge),
                          Text('Verdant ${_svc.currentVersion} is the latest version.', style: context.text.bodySmall),
                        ]),
                      ),
                    _ => VCard(
                        key: const ValueKey('u'),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Pill('New', color: v.highlight, textColor: VerdantColors.ink, dense: true),
                            const SizedBox(width: 8),
                            Text('Version ${u?.version ?? ''}', style: context.text.titleLarge),
                          ]),
                          const SizedBox(height: 4),
                          if (u != null)
                            Text('Released ${DateFormat('MMM d').format(u.releasedAt)} · ${u.sizeMb.toStringAsFixed(1)} MB', style: context.text.bodySmall),
                          const SizedBox(height: 14),
                          if (u != null)
                            for (final entry in u.notes.entries) ...[
                              Eyebrow(entry.key),
                              const SizedBox(height: 6),
                              for (final line in entry.value)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Padding(
                                      padding: const EdgeInsets.only(top: 7, right: 10),
                                      child: Container(width: 5, height: 5, decoration: BoxDecoration(color: context.colors.primary, shape: BoxShape.circle)),
                                    ),
                                    Expanded(child: Text(line, style: context.text.bodyMedium)),
                                  ]),
                                ),
                              const SizedBox(height: 8),
                            ],
                          if (_phase == _UpdatePhase.installing) ...[
                            const SizedBox(height: 6),
                            ProgressBar(value: _progress, height: 8),
                            const SizedBox(height: 6),
                            Text('Installing… ${(_progress * 100).round()}%', style: context.text.bodySmall),
                          ],
                          if (_phase == _UpdatePhase.failed) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: context.colors.error.withAlpha(24), borderRadius: BorderRadius.circular(VerdantTheme.radiusSm)),
                              child: Row(children: [
                                Icon(Icons.error_outline_rounded, color: context.colors.error),
                                const SizedBox(width: 8),
                                Expanded(child: Text(_error ?? 'Update failed.', style: TextStyle(color: context.colors.error))),
                              ]),
                            ),
                            const SizedBox(height: 12),
                          ],
                          if (_phase != _UpdatePhase.installing)
                            Row(children: [
                              Expanded(child: OutlinedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Later'))),
                              const SizedBox(width: 10),
                              Expanded(child: FilledButton(onPressed: _install, child: Text(_phase == _UpdatePhase.failed ? 'Retry' : 'Install'))),
                            ]),
                        ]),
                      ),
                  },
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}
