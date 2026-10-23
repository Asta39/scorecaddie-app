import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/coaching_model.dart';
import '../../providers/app_providers.dart';
import '../onboarding/ob_style.dart';
import 'session_form.dart';

class EditSessionScreen extends ConsumerWidget {
  const EditSessionScreen({super.key, required this.sessionId, this.session});
  final String sessionId;
  final CoachingSession? session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = session ?? ref.watch(coachSessionsProvider).valueOrNull?.where((x) => x.id == sessionId).firstOrNull;
    if (s == null) {
      return const Scaffold(backgroundColor: Ob.bg, body: Center(child: CupertinoActivityIndicator(color: Ob.lime)));
    }
    return SessionForm(key: ValueKey(s.id), session: s);
  }
}
