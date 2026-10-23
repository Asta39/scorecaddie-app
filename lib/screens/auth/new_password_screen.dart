import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/app_providers.dart';
import '../../widgets/top_notification.dart';
import '../onboarding/ob_forms.dart';
import '../onboarding/ob_style.dart';

/// Opened from a password-reset email: the link signs the golfer in for
/// this one step, and they choose a new password.
class NewPasswordScreen extends ConsumerStatefulWidget {
  const NewPasswordScreen({super.key});

  @override
  ConsumerState<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends ConsumerState<NewPasswordScreen> {
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;
  bool _saving = false;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final p = _password.text;
    if (p.length < 6) {
      TopNotification.showError(context, 'Use at least 6 characters');
      return;
    }
    if (p != _confirm.text) {
      TopNotification.showError(context, 'The two passwords don’t match');
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(supabaseAuthServiceProvider).updatePassword(p);
      if (!mounted) return;
      TopNotification.showSuccess(context, 'Password changed');
      context.go('/');
    } catch (e) {
      if (mounted) TopNotification.showError(context, '$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget field(TextEditingController c, String label, List<String> hints) => TextField(
          controller: c,
          obscureText: _obscure,
          autofillHints: hints,
          cursorColor: Ob.lime,
          style: Ob.body(17),
          decoration: obInput(label, hint: 'At least 6 characters'),
        );
    return Scaffold(
      backgroundColor: Ob.bg,
      body: DefaultTextStyle(
        style: Ob.textBase,
        child: SafeArea(
          child: ListView(padding: const EdgeInsets.fromLTRB(16, 24, 16, 24), children: [
            Semantics(header: true, child: Text('Set a new password', style: Ob.display(32, height: 1.1))),
            const SizedBox(height: 6),
            Text('You’ll use it next time you sign in with your email.', style: Ob.body(17, color: Ob.creamA(.6))),
            const SizedBox(height: 24),
            AutofillGroup(
              child: Column(children: [
                field(_password, 'New password', const [AutofillHints.newPassword]),
                const SizedBox(height: 12),
                field(_confirm, 'Type it again', const [AutofillHints.newPassword]),
              ]),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => setState(() => _obscure = !_obscure),
                child: Text(_obscure ? 'Show passwords' : 'Hide passwords', style: Ob.body(15, color: Ob.lime)),
              ),
            ),
            const SizedBox(height: 12),
            ObButton(
              height: 54,
              radius: 14,
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Saving…' : 'Save password', style: Ob.label(17)),
            ),
          ]),
        ),
      ),
    );
  }
}
