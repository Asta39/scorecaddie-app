import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../widgets/profile_image.dart';
import '../onboarding/ob_app.dart';
import '../onboarding/ob_forms.dart';
import '../onboarding/ob_style.dart';
import '../onboarding/ob_widgets.dart';
import 'friend_code.dart';
import '../../providers/app_providers.dart';
import '../../core/database/database.dart';

class FriendsScreen extends ConsumerWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friendsAsync = ref.watch(friendsProvider);
    final requestsAsync = ref.watch(friendRequestsProvider);

    // AUTO-SYNC ACCEPTED REQUESTS (For the Sender)
    ref.listen(acceptedSentRequestsProvider, (prev, next) {
      if (next.hasValue && next.value!.isNotEmpty) {
        for (var req in next.value!) {
          ref.read(friendServiceProvider).finalizeHandshake(req['id']);
        }
      }
    });

    final requests = requestsAsync.valueOrNull ?? const <Map<String, dynamic>>[];
    final friends = friendsAsync.valueOrNull ?? const <Friend>[];
    final me = ref.watch(userProfileProvider).valueOrNull;

    return Scaffold(
      backgroundColor: Ob.bg,
      body: DefaultTextStyle(
        style: Ob.textBase,
        child: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            color: Ob.ink,
            backgroundColor: Ob.lime,
            onRefresh: () async {
              ref.invalidate(friendsProvider);
              ref.invalidate(friendRequestsProvider);
            },
            child: ListView(
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 60),
              children: [
                ObTopBar('Friends', onBack: () => context.pop(), actions: [
                  ObIconButton(icon: LucideIcons.scanLine, label: 'Scan a friend\'s code', onPressed: () => scanFriendCode(context, ref)),
                  ObIconButton(icon: LucideIcons.userPlus, label: 'Add by code', onPressed: () => _showAddFriendDialog(context, ref)),
                ]),
                const SizedBox(height: 18),
                ObEyebrow('Wants to connect', trailing: Text(requests.isEmpty ? '' : '${requests.length} new', style: Ob.body(12, weight: FontWeight.w700, color: Ob.creamA(.55)))),
                const SizedBox(height: 10),
                if (requests.isEmpty)
                  Text('All caught up.', style: Ob.body(13, color: Ob.creamA(.55)))
                else
                  for (final r in requests)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ObCard(
                        padding: const EdgeInsets.all(12),
                        child: Row(children: [
                          ProfileImage(url: r['fromAvatar'], name: r['fromName'], size: 44, isCircle: true),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('${r['fromName'] ?? 'Golfer'}', style: Ob.body(15, weight: FontWeight.w800)),
                              Text('Wants to be friends', style: Ob.body(12, color: Ob.creamA(.58))),
                            ]),
                          ),
                          _circle(LucideIcons.x, 'Decline', false, () => ref.read(friendServiceProvider).respondToRequest(r['id'], false)),
                          const SizedBox(width: 8),
                          _circle(LucideIcons.check, 'Accept', true, () async {
                            await ref.read(friendServiceProvider).respondToRequest(r['id'], true);
                            ref.invalidate(friendsProvider);
                            final user = ref.read(authStateProvider).valueOrNull;
                            if (user != null) ref.read(achievementServiceProvider).checkAllAchievements(user.id);
                          }),
                        ]),
                      ),
                    ),
                const SizedBox(height: 22),
                ObEyebrow('Your friends', trailing: Text('${friends.length}', style: Ob.body(12, weight: FontWeight.w700, color: Ob.creamA(.55)))),
                const SizedBox(height: 10),
                if (friendsAsync.isLoading && friends.isEmpty)
                  const Center(child: CupertinoActivityIndicator(color: Ob.lime))
                else if (friends.isEmpty)
                  ObCard(
                    padding: const EdgeInsets.all(18),
                    child: ObGuideRow(botAsset: ObBot.ball.idle, botLabel: 'Your golf-ball avatar', text: 'No friends yet. Scan someone\'s code or share yours.', size: 72, fontSize: 16),
                  )
                else
                  ObCard(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(children: [
                      for (final (i, f) in friends.indexed) ...[
                        if (i > 0) const ObHair(),
                        Dismissible(
                          key: ValueKey(f.id),
                          direction: DismissDirection.endToStart,
                          background: Container(alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), color: Ob.warn.withValues(alpha: .2), child: const Icon(LucideIcons.trash2, color: Ob.warn)),
                          confirmDismiss: (_) => _showRemoveFriendDialog(context, f, ref),
                          child: InkWell(
                            onTap: () => context.push('/player/${f.friendId}?name=${Uri.encodeComponent(f.friendName ?? 'Golfer')}'),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              child: Row(children: [
                                ProfileImage(url: f.friendAvatar, name: f.friendName, size: 42, isCircle: true),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Row(children: [
                                    Flexible(child: Text(f.friendName ?? 'Golfer', maxLines: 1, overflow: TextOverflow.ellipsis, style: Ob.body(15, weight: FontWeight.w700))),
                                    if (f.isCoach) ...[const SizedBox(width: 6), const ObChip('Coach', on: true, color: Color(0xFFF5C531))],
                                    if (f.isStudent) ...[const SizedBox(width: 6), const ObChip('Student', on: true, color: Color(0xFF7DD3FC))],
                                  ]),
                                ),
                                Icon(LucideIcons.chevronRight, size: 18, color: Ob.creamA(.4)),
                              ]),
                            ),
                          ),
                        ),
                      ],
                    ]),
                  ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () => showMyFriendCode(context, ref),
                  child: ObCard(
                    child: Row(children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Ob.cream, borderRadius: BorderRadius.circular(14)),
                        child: me?.friendCode == null
                            ? const SizedBox(width: 56, height: 56, child: Icon(LucideIcons.qrCode, color: Ob.ink, size: 36))
                            : QrImageView(data: 'scorecaddie://friend/add/${me!.friendCode}', size: 56, padding: EdgeInsets.zero),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Your code: ${me?.friendCode ?? 'tap to make one'}', style: Ob.body(15, weight: FontWeight.w800)),
                          const SizedBox(height: 2),
                          Text('Friends scan this on the 1st tee to add you.', style: Ob.body(12, height: 1.4, color: Ob.creamA(.6))),
                        ]),
                      ),
                    ]),
                  ),
                ),
                const SizedBox(height: 10),
                if (friends.isNotEmpty) Text('Swipe a friend left to remove them.', textAlign: TextAlign.center, style: Ob.body(12, color: Ob.creamA(.4))),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _circle(IconData icon, String label, bool primary, VoidCallback onTap) => Semantics(
        button: true,
        label: label,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: primary ? Ob.lime : Ob.creamA(.08), shape: BoxShape.circle),
            child: Icon(icon, size: 17, color: primary ? Ob.ink : Ob.cream),
          ),
        ),
      );

  Future<bool> _showRemoveFriendDialog(BuildContext context, Friend friend, WidgetRef ref) async {
    final ok = await showObSheet<bool>(
      context,
      (ctx) => ObSheet(
        title: 'Remove ${friend.friendName ?? 'this friend'}?',
        child: Row(children: [
          Expanded(child: ObButton(tone: ObButtonTone.dark, onPressed: () => Navigator.pop(ctx, false), child: Text('Keep', style: Ob.label(15, weight: FontWeight.w800)))),
          const SizedBox(width: 10),
          Expanded(
            child: ObButton(
              tone: ObButtonTone.light,
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Remove', style: Ob.label(15, weight: FontWeight.w800).copyWith(color: Ob.warn)),
            ),
          ),
        ]),
      ),
    );
    if (ok != true) return false;
    await ref.read(friendServiceProvider).removeFriend(friend.friendId);
    ref.invalidate(friendsProvider);
    return true;
  }

  void _showAddFriendDialog(BuildContext context, WidgetRef ref) {
    final c = TextEditingController();
    showObSheet(
      context,
      (ctx) => ObSheet(
        title: 'Add by code',
        subtitle: 'Their code is on their profile, like SC-A3B9-X7K1.',
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          TextField(
            controller: c,
            autofocus: true,
            autocorrect: false,
            textCapitalization: TextCapitalization.characters,
            cursorColor: Ob.lime,
            style: Ob.display(22).copyWith(letterSpacing: 2),
            decoration: obInput(null, hint: 'SC-XXXX-XXXX'),
          ),
          const SizedBox(height: 16),
          ObButton(
            onPressed: () {
              final code = c.text.trim();
              if (code.isEmpty) return;
              Navigator.pop(ctx);
              addFriendByCode(context, ref, code);
            },
            child: Text('Find them', style: Ob.label(16, weight: FontWeight.w800)),
          ),
        ]),
      ),
    ).whenComplete(c.dispose);
  }
}
