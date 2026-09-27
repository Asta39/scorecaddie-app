import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/providers/club_feed_provider.dart';
import '../../widgets/top_notification.dart';
import '../onboarding/ob_app.dart';
import '../onboarding/ob_forms.dart';
import '../onboarding/ob_style.dart';

/// My clubs: home club, other memberships, and clubs to ask to join.
class MembershipsScreen extends ConsumerStatefulWidget {
  const MembershipsScreen({super.key});

  @override
  ConsumerState<MembershipsScreen> createState() => _MembershipsScreenState();
}

class _MembershipsScreenState extends ConsumerState<MembershipsScreen> {
  final _requesting = <String>{};

  Future<void> _request(Map<String, dynamic> club, bool first) async {
    final id = club['id'] as String;
    setState(() => _requesting.add(id));
    try {
      final supabase = Supabase.instance.client;
      final me = supabase.auth.currentUser?.id;
      if (me == null) return;
      await supabase.from('player_club_memberships').insert({'player_id': me, 'club_id': id, 'status': 'pending', 'is_home_club': first});
      ref.invalidate(userClubMembershipsProvider);
      if (mounted) TopNotification.showSuccess(context, 'Request sent to ${club['name']}');
    } catch (e) {
      if (mounted) TopNotification.showError(context, 'Couldn\'t send the request: $e');
    } finally {
      if (mounted) setState(() => _requesting.remove(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final mine = ref.watch(userClubMembershipsProvider);
    final all = ref.watch(availableClubsProvider);
    final list = mine.valueOrNull ?? const <UserClubMembership>[];
    final home = list.where((m) => m.isHomeClub).firstOrNull ?? list.where((m) => m.status == 'active').firstOrNull;
    final others = list.where((m) => m != home).toList();
    final joined = {for (final m in list) m.clubId};
    final joinable = (all.valueOrNull ?? const []).where((c) => !joined.contains(c['id'])).toList();

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
              ref.invalidate(userClubMembershipsProvider);
              ref.invalidate(availableClubsProvider);
            },
            child: ListView(
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 60),
              children: [
                ObTopBar('My clubs', onBack: () => context.pop()),
                const SizedBox(height: 18),
                if (mine.isLoading && list.isEmpty)
                  const Padding(padding: EdgeInsets.all(30), child: Center(child: CupertinoActivityIndicator(color: Ob.lime)))
                else ...[
                  const ObEyebrow('Home club'),
                  const SizedBox(height: 10),
                  if (home == null)
                    ObCard(child: Text('No club yet. Ask to join one below.', style: Ob.body(14, color: Ob.creamA(.65))))
                  else
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: Ob.roleFill, borderRadius: BorderRadius.circular(24), border: Border.all(color: Ob.lime, width: 2)),
                      child: Row(children: [
                        ObCrest(home.clubName, size: 56, radius: 16),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(home.clubName, style: Ob.body(16, weight: FontWeight.w800)),
                            Text(
                              [
                                if (home.membershipNumber != null) 'No. ${home.membershipNumber}',
                                if (home.renewalDate != null) 'Renews ${home.renewalDate!.day}/${home.renewalDate!.month}/${home.renewalDate!.year}',
                              ].join(' · ').ifEmpty('Your home course'),
                              style: Ob.body(12, color: Ob.creamA(.6)),
                            ),
                          ]),
                        ),
                        ObChip(home.status == 'active' ? 'Member' : 'Pending', on: true, color: home.status == 'active' ? Ob.lime : const Color(0xFFF5C531)),
                      ]),
                    ),
                  if (others.isNotEmpty) ...[
                    const SizedBox(height: 22),
                    const ObEyebrow('Other memberships'),
                    const SizedBox(height: 10),
                    for (final m in others)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ObCard(
                          padding: const EdgeInsets.all(12),
                          child: Row(children: [
                            ObCrest(m.clubName, size: 48),
                            const SizedBox(width: 12),
                            Expanded(child: Text(m.clubName, style: Ob.body(15, weight: FontWeight.w800))),
                            Text(m.status == 'active' ? 'Active' : 'Pending',
                                style: Ob.body(12, weight: FontWeight.w800, color: m.status == 'active' ? Ob.lime : const Color(0xFFF5C531))),
                          ]),
                        ),
                      ),
                  ],
                  const SizedBox(height: 22),
                  const ObEyebrow('Join a club'),
                  const SizedBox(height: 4),
                  Text('The club confirms you before you\'re in.', style: Ob.body(12, color: Ob.creamA(.55))),
                  const SizedBox(height: 10),
                  if (all.isLoading && joinable.isEmpty)
                    const Center(child: CupertinoActivityIndicator(color: Ob.lime))
                  else if (joinable.isEmpty)
                    ObCard(child: Text('You\'re in every club on ScoreCaddie.', style: Ob.body(14, color: Ob.creamA(.6))))
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: .86),
                      itemCount: joinable.length,
                      itemBuilder: (_, i) {
                        final c = joinable[i];
                        final busy = _requesting.contains(c['id']);
                        return ObCard(
                          padding: const EdgeInsets.fromLTRB(10, 14, 10, 12),
                          child: Column(children: [
                            ObCrest('${c['name']}', size: 56, radius: 14, logoUrl: c['logo_url'] as String?),
                            const SizedBox(height: 8),
                            Expanded(
                              child: Text('${c['name']}', textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: Ob.body(13, weight: FontWeight.w700, height: 1.25)),
                            ),
                            ObButton(
                              height: 36,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              onPressed: busy ? null : () => _request(c, list.isEmpty),
                              child: Text(busy ? 'Sending…' : 'Request to join', style: Ob.label(12, weight: FontWeight.w800)),
                            ),
                          ]),
                        );
                      },
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

extension on String {
  String ifEmpty(String other) => isEmpty ? other : this;
}
