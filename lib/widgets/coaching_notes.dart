import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/app_providers.dart';
import '../screens/onboarding/ob_app.dart';
import '../screens/onboarding/ob_forms.dart';
import '../screens/onboarding/ob_style.dart';
import 'top_notification.dart';

/// Notes a coach and a player leave each other. There's no chat in the app:
/// they call to talk, and write here what should be remembered. Only the two
/// of them see these.
class CoachingNotes extends ConsumerWidget {
  const CoachingNotes({super.key, required this.coachId, required this.playerId, required this.otherName});
  final String coachId;
  final String playerId;

  /// The other person's first name, for "Coach" or the player's name on their notes.
  final String otherName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ids = (coachId, playerId);
    final async = ref.watch(coachingNotesProvider(ids));
    final me = ref.watch(authStateProvider).valueOrNull?.id;
    final notes = async.valueOrNull ?? const <Map<String, dynamic>>[];

    return ObGroup(
      header: 'Notes',
      footer: 'Only you and $otherName see these.',
      children: [
        if (async.isLoading && notes.isEmpty)
          const Padding(padding: EdgeInsets.all(16), child: Center(child: CupertinoActivityIndicator(color: Ob.lime)))
        else if (async.hasError && notes.isEmpty)
          ObRow('Couldn’t load notes', subtitle: 'Tap to try again', onTap: () => ref.invalidate(coachingNotesProvider(ids)))
        else
          for (final n in notes)
            ObRow(
              '${n['body']}',
              subtitle: '${n['author_id'] == me ? 'You' : otherName} · ${_when(n['created_at'])}',
              onTap: n['author_id'] == me ? () => _delete(context, ref, n) : null,
            ),
        ObRow('Add a note', titleColor: Ob.lime, onTap: () => _add(context, ref)),
      ],
    );
  }

  static String _when(dynamic iso) {
    final d = DateTime.tryParse('$iso')?.toLocal();
    return d == null ? '' : DateFormat('d MMM, HH:mm').format(d);
  }

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final c = TextEditingController();
    final text = await showObSheet<String>(
      context,
      (ctx) => ObSheet(
        title: 'New note',
        subtitle: '$otherName will see it',
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          TextField(
            controller: c,
            autofocus: true,
            minLines: 3,
            maxLines: 6,
            maxLength: 1000,
            cursorColor: Ob.lime,
            style: Ob.body(17),
            decoration: obInput(null, hint: 'e.g. Work on weight transfer before Saturday'),
          ),
          const SizedBox(height: 12),
          ObButton(height: 50, radius: 14, onPressed: () => Navigator.pop(ctx, c.text.trim()), child: Text('Save note', style: Ob.label(17))),
        ]),
      ),
    ).whenComplete(c.dispose);
    if (text == null || text.isEmpty) return;
    try {
      await ref.read(coachingServiceProvider).addNote(coachId: coachId, playerId: playerId, body: text);
      ref.invalidate(coachingNotesProvider((coachId, playerId)));
    } catch (e) {
      if (context.mounted) TopNotification.showError(context, 'Couldn’t save the note: $e');
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, Map<String, dynamic> n) async {
    final ok = await showCupertinoModalPopup<bool>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        message: Text('${n['body']}', maxLines: 3, overflow: TextOverflow.ellipsis),
        actions: [
          CupertinoActionSheetAction(isDestructiveAction: true, onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete note')),
        ],
        cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(coachingServiceProvider).deleteNote('${n['id']}');
      ref.invalidate(coachingNotesProvider((coachId, playerId)));
    } catch (e) {
      if (context.mounted) TopNotification.showError(context, 'Couldn’t delete the note: $e');
    }
  }
}
