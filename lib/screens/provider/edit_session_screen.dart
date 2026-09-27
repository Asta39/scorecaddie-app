import 'package:flutter/material.dart';
import '../../core/models/coaching_model.dart';
import 'session_form.dart';

class EditSessionScreen extends StatelessWidget {
  const EditSessionScreen({super.key, required this.session});
  final CoachingSession session;

  @override
  Widget build(BuildContext context) => SessionForm(session: session);
}
