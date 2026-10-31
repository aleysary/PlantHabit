import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/verdant_theme.dart';
import '../../core/widgets/plant_view.dart';
import '../../core/widgets/ui.dart';
import '../../data/repositories/in_memory.dart';
import '../../data/repositories/repositories.dart';
import '../../state/app_state.dart';

final _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
String? _emailValidator(String? v) => (v == null || !_emailRe.hasMatch(v.trim())) ? 'Enter a valid email' : null;
String? _passwordValidator(String? v) => (v == null || v.length < 8) ? 'At least 8 characters' : null;

/// Shared layout for auth screens: back button, small plant, headline, form.
class _AuthScaffold extends StatelessWidget {
  const _AuthScaffold({required this.title, required this.subtitle, required this.children, this.species = 'echeveria'});
  final String title;
  final String subtitle;
  final List<Widget> children;
  final String species;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const TopBar(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(child: Text(title, style: context.text.displaySmall)),
                      SizedBox(height: 110, child: PlantView(speciesId: species, stage: 4, potId: 'sage', ambient: true)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(subtitle, style: context.text.bodyLarge?.copyWith(color: context.v.muted)),
                  const SizedBox(height: 28),
                  ...children,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner(this.message);
  final String message;
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.colors.error.withAlpha(24),
          borderRadius: BorderRadius.circular(VerdantTheme.radiusMd),
          border: Border.all(color: context.colors.error.withAlpha(80)),
        ),
        child: Row(children: [
          Icon(Icons.error_outline_rounded, color: context.colors.error, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: context.text.bodyMedium?.copyWith(color: context.colors.error))),
        ]),
      );
}

class _PasswordField extends StatefulWidget {
  const _PasswordField({required this.controller, this.label = 'Password', this.validator, this.onSubmitted});
  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onSubmitted;
  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  bool _obscure = true;
  @override
  Widget build(BuildContext context) => TextFormField(
        controller: widget.controller,
        obscureText: _obscure,
        validator: widget.validator,
        onFieldSubmitted: widget.onSubmitted,
        autofillHints: const [AutofillHints.password],
        decoration: InputDecoration(
          labelText: widget.label,
          suffixIcon: IconButton(
            icon: Icon(_obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded),
            onPressed: () => setState(() => _obscure = !_obscure),
          ),
        ),
      );
}

// ---------------------------------------------------------------------------
// Story 2: log in
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController(text: kDebugMode ? kDemoEmail : '');
  final _password = TextEditingController(text: kDebugMode ? kDemoPassword : '');
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await context.read<AppState>().signIn(_email.text, _password.text);
      // AuthGate swaps to the home shell and pops this route.
    } on VerdantException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _AuthScaffold(
      title: 'Welcome\nback.',
      subtitle: 'Your garden missed you.',
      species: 'peace_lily',
      children: [
        Form(
          key: _form,
          child: AutofillGroup(
            child: Column(children: [
              if (_error != null) _ErrorBanner(_error!),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                validator: _emailValidator,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 12),
              _PasswordField(controller: _password, validator: (v) => (v == null || v.isEmpty) ? 'Enter your password' : null, onSubmitted: (_) => _submit()),
            ]),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => ForgotPasswordScreen(initialEmail: _email.text))),
            child: const Text('Forgot password?'),
          ),
        ),
        const SizedBox(height: 8),
        PrimaryButton(label: 'Log in', loading: _busy, onPressed: _submit),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute<void>(builder: (_) => const RegisterScreen())),
            child: const Text('New here? Create an account'),
          ),
        ),
        if (kDebugMode)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('Demo: $kDemoEmail / $kDemoPassword', textAlign: TextAlign.center, style: context.text.bodySmall),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Story 1: register
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_username, _email, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await context.read<AppState>().register(_username.text, _email.text, _password.text);
    } on VerdantException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _AuthScaffold(
      title: 'Plant your\nfirst seed.',
      subtitle: 'Create an account so your garden is saved and private to you.',
      species: 'tulip',
      children: [
        Form(
          key: _form,
          child: AutofillGroup(
            child: Column(children: [
              if (_error != null) _ErrorBanner(_error!),
              TextFormField(
                controller: _username,
                autofillHints: const [AutofillHints.newUsername],
                validator: (v) => (v == null || v.trim().length < 3) ? 'At least 3 characters' : null,
                decoration: const InputDecoration(labelText: 'Username'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                validator: _emailValidator,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 12),
              _PasswordField(controller: _password, validator: _passwordValidator),
              const SizedBox(height: 12),
              _PasswordField(
                controller: _confirm,
                label: 'Confirm password',
                validator: (v) => v != _password.text ? 'Passwords don’t match' : null,
                onSubmitted: (_) => _submit(),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 24),
        PrimaryButton(label: 'Create account', loading: _busy, onPressed: _submit),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute<void>(builder: (_) => const LoginScreen())),
            child: const Text('Already growing? Log in'),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Story 23: reset a forgotten password
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, this.initialEmail = ''});
  final String initialEmail;
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

enum _ResetStep { request, verify, done }

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  late final _email = TextEditingController(text: widget.initialEmail);
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _form = GlobalKey<FormState>();
  _ResetStep _step = _ResetStep.request;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action, _ResetStep next) async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
      if (mounted) setState(() => _step = next);
    } on VerdantException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AppState>().auth;
    final (title, subtitle) = switch (_step) {
      _ResetStep.request => ('Reset your\npassword.', 'Enter the email you signed up with and we’ll send you a verification code.'),
      _ResetStep.verify => ('Check your\ninbox.', 'We sent a 6-digit code to ${_email.text.trim()}. Enter it with your new password.'),
      _ResetStep.done => ('All set.', 'Your password has been reset. Log in with your new password.'),
    };
    return _AuthScaffold(
      title: title,
      subtitle: subtitle,
      species: _step == _ResetStep.done ? 'sunflower' : 'aloe',
      children: [
        Form(
          key: _form,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Column(
              key: ValueKey(_step),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_error != null) _ErrorBanner(_error!),
                if (_step == _ResetStep.request) ...[
                  TextFormField(controller: _email, keyboardType: TextInputType.emailAddress, validator: _emailValidator, decoration: const InputDecoration(labelText: 'Email')),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: 'Send code',
                    loading: _busy,
                    onPressed: () => _run(() => auth.requestPasswordReset(_email.text), _ResetStep.verify),
                  ),
                ],
                if (_step == _ResetStep.verify) ...[
                  TextFormField(
                    controller: _code,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    style: context.text.headlineSmall?.copyWith(letterSpacing: 8),
                    validator: (v) => (v == null || v.trim().length != 6) ? 'Enter the 6-digit code' : null,
                    decoration: const InputDecoration(labelText: 'Verification code', counterText: ''),
                  ),
                  const SizedBox(height: 12),
                  _PasswordField(controller: _password, label: 'New password', validator: _passwordValidator),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: 'Reset password',
                    loading: _busy,
                    onPressed: () => _run(
                      () => auth.confirmPasswordReset(email: _email.text, code: _code.text, newPassword: _password.text),
                      _ResetStep.done,
                    ),
                  ),
                  TextButton(
                    onPressed: _busy ? null : () => _run(() => auth.requestPasswordReset(_email.text), _ResetStep.verify),
                    child: const Text('Resend code'),
                  ),
                  if (kDebugMode) Text('Demo code: $kDemoResetCode', textAlign: TextAlign.center, style: context.text.bodySmall),
                ],
                if (_step == _ResetStep.done) ...[
                  FilledButton(
                    onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute<void>(builder: (_) => const LoginScreen())),
                    child: const Text('Back to log in'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
