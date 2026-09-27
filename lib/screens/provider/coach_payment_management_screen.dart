import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/app_providers.dart';
import '../../core/models/coaching_model.dart';
import '../../widgets/profile_image.dart';
import '../../widgets/top_notification.dart';
import '../onboarding/ob_app.dart';
import '../onboarding/ob_style.dart';
import '../onboarding/ob_widgets.dart';
import 'coach_dashboard_screen.dart' show coachGold;

final _kes = NumberFormat('#,###');

/// An enrollment with the price of the session it belongs to.
class _RE {
  final SessionEnrollment e;
  final CoachingSession session;
  _RE(this.e, this.session);
  double get outstanding => (session.pricePerSession - e.amountPaid).clamp(0, double.infinity).toDouble();
  bool get isPaid => e.paymentStatus == 'fully_paid';
  bool get isOverdue => !isPaid && DateTime.now().difference(e.enrolledAt).inDays > 14;
}

final _allEnrollmentsProvider = FutureProvider<List<_RE>>((ref) async {
  final sessions = await ref.watch(coachSessionsProvider.future);
  final service = ref.watch(coachingServiceProvider);
  final lists = await Future.wait(sessions.map((s) async {
    try {
      return [for (final e in await service.getSessionEnrollments(s.id)) _RE(e, s)];
    } catch (_) {
      return <_RE>[]; // one session failing shouldn't blank the whole screen
    }
  }));
  return lists.expand((l) => l).toList();
});

enum _View { owed, bySession, paid }

class CoachPaymentManagementScreen extends ConsumerStatefulWidget {
  const CoachPaymentManagementScreen({super.key});

  @override
  ConsumerState<CoachPaymentManagementScreen> createState() => _CoachPaymentManagementScreenState();
}

class _CoachPaymentManagementScreenState extends ConsumerState<CoachPaymentManagementScreen> {
  _View _view = _View.owed;
  String? _sessionId;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(_allEnrollmentsProvider);
    final all = async.valueOrNull ?? const <_RE>[];
    final collected = all.fold<double>(0, (a, r) => a + r.e.amountPaid);
    final owed = all.fold<double>(0, (a, r) => a + r.outstanding);
    final sessions = ref.watch(coachSessionsProvider).valueOrNull ?? const <CoachingSession>[];
    final picked = sessions.where((s) => s.id == _sessionId).firstOrNull ?? sessions.firstOrNull;

    final rows = switch (_view) {
      _View.owed => all.where((r) => !r.isPaid).toList()..sort((a, b) => b.outstanding.compareTo(a.outstanding)),
      _View.paid => all.where((r) => r.isPaid).toList(),
      _View.bySession => all.where((r) => r.session.id == picked?.id).toList(),
    };

    return Scaffold(
      backgroundColor: Ob.bg,
      body: DefaultTextStyle(
        style: Ob.textBase,
        child: RefreshIndicator(
          color: Ob.ink,
          backgroundColor: coachGold,
          onRefresh: () async {
            ref.invalidate(coachSessionsProvider);
            ref.invalidate(_allEnrollmentsProvider);
          },
          child: ListView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
            children: [
              const ObTabHeader('Payments').rise(),
              const SizedBox(height: 16),
              ObSplitCards(
                left: ObStat('Collected', 'KES ${_kes.format(collected)}', valueSize: 22, valueColor: Ob.lime),
                right: ObStat('Still owed', 'KES ${_kes.format(owed)}', valueSize: 22, valueColor: coachGold),
              ).rise(1),
              const SizedBox(height: 16),
              ObGooSegmented<_View>(
                options: const [(_View.owed, 'Owe'), (_View.bySession, 'By session'), (_View.paid, 'Paid')],
                selected: _view,
                onChanged: (v) => setState(() => _view = v),
                accent: coachGold,
              ).rise(2),
              const SizedBox(height: 14),
              if (_view == _View.bySession && sessions.isNotEmpty) ...[
                SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: sessions.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (_, i) => GestureDetector(
                      onTap: () => setState(() => _sessionId = sessions[i].id),
                      child: ObChip(sessions[i].name, on: sessions[i].id == picked?.id, color: coachGold),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],
              if (async.isLoading && all.isEmpty)
                const Padding(padding: EdgeInsets.all(40), child: Center(child: CupertinoActivityIndicator(color: coachGold)))
              else if (async.hasError && all.isEmpty)
                ObCard(child: Text('Couldn\'t load payments. Pull down to try again.', style: Ob.body(14, color: Ob.creamA(.7))))
              else if (rows.isEmpty)
                ObCard(
                  padding: const EdgeInsets.all(20),
                  child: ObGuideRow(
                    botAsset: ObBot.star.happy,
                    botLabel: 'Your star avatar',
                    text: switch (_view) {
                      _View.owed => all.isEmpty ? 'Payments show up once players book.' : 'Everyone\'s paid up.',
                      _View.paid => 'Nobody has paid in full yet.',
                      _View.bySession => 'No players in this session yet.',
                    },
                    size: 72,
                    fontSize: 16,
                  ),
                )
              else
                for (final r in rows) Padding(padding: const EdgeInsets.only(bottom: 10), child: _PayRow(r: r, showSession: _view != _View.bySession)),
            ],
          ),
        ),
      ),
    );
  }
}

class _PayRow extends ConsumerWidget {
  const _PayRow({required this.r, required this.showSession});
  final _RE r;
  final bool showSession;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = r.e.playerName ?? 'Student';
    final partial = r.e.paymentStatus == 'partial';
    final price = r.session.pricePerSession;
    final paidShare = price <= 0 ? 1.0 : (r.e.amountPaid / price).clamp(0.0, 1.0);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: r.isPaid ? Ob.roleFill : Ob.cardFill,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: r.isPaid ? Ob.lime.withValues(alpha: .35) : (r.isOverdue ? Ob.warn.withValues(alpha: .5) : Ob.creamA(.06))),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          ProfileImage(url: r.e.playerAvatar, name: name, size: 40, isCircle: true),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: Ob.body(15, weight: FontWeight.w800)),
              Text(
                showSession ? r.session.name : 'Joined ${DateFormat('d MMM').format(r.e.enrolledAt)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Ob.body(12, color: Ob.creamA(.55)),
              ),
            ]),
          ),
          if (r.isPaid)
            ObChip('Paid', on: true)
          else if (r.isOverdue)
            ObChip('${DateTime.now().difference(r.e.enrolledAt).inDays}d late', on: true, color: Ob.warn)
          else
            ObChip(partial ? 'Part paid' : 'Unpaid', on: true, color: coachGold),
        ]),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(value: paidShare, minHeight: 6, backgroundColor: Ob.creamA(.08), color: Ob.lime),
        ),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: Text.rich(TextSpan(children: [
              TextSpan(text: 'KES ${_kes.format(r.e.amountPaid)}', style: Ob.body(13, weight: FontWeight.w800, color: Ob.lime)),
              TextSpan(text: ' of ${_kes.format(price)}', style: Ob.body(13, color: Ob.creamA(.6))),
              if (!r.isPaid) TextSpan(text: '  ·  owes ${_kes.format(r.outstanding)}', style: Ob.body(13, weight: FontWeight.w700, color: coachGold)),
            ])),
          ),
          if (!r.isPaid)
            ObButton(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => _RecordSheet(r: r),
              ),
              child: Text('Record', style: Ob.label(13, weight: FontWeight.w800)),
            ),
        ]),
      ]),
    );
  }
}

class _RecordSheet extends ConsumerStatefulWidget {
  const _RecordSheet({required this.r});
  final _RE r;

  @override
  ConsumerState<_RecordSheet> createState() => _RecordSheetState();
}

class _RecordSheetState extends ConsumerState<_RecordSheet> {
  late final _amount = TextEditingController(text: widget.r.outstanding.toStringAsFixed(0));
  String _method = 'MPESA';
  bool _saving = false;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amount.text.trim());
    if (amount == null || amount <= 0) {
      TopNotification.showError(context, 'Enter an amount');
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(coachingServiceProvider).recordPayment(
            enrollmentId: widget.r.e.id,
            amount: amount,
            method: _method,
            sessionId: widget.r.e.sessionId,
          );
      HapticFeedback.mediumImpact();
      ref.invalidate(sessionEnrollmentsProvider(widget.r.e.sessionId));
      ref.invalidate(_allEnrollmentsProvider);
      ref.invalidate(coachRevenueBreakdownProvider);
      ref.invalidate(coachStudentsProvider);
      if (!mounted) return;
      Navigator.pop(context);
      TopNotification.showSuccess(context, 'KES ${_kes.format(amount)} recorded');
    } catch (e) {
      if (mounted) TopNotification.showError(context, 'Couldn\'t record the payment: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.r;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: EdgeInsets.fromLTRB(22, 12, 22, 22 + MediaQuery.of(context).padding.bottom),
        decoration: const BoxDecoration(color: Ob.bg, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
        child: DefaultTextStyle(
          style: Ob.textBase,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Ob.creamA(.2), borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Row(children: [
              ProfileImage(url: r.e.playerAvatar, name: r.e.playerName, size: 44, isCircle: true),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Record a payment', style: Ob.display(22)),
                  Text('${r.e.playerName ?? 'Student'} · owes KES ${_kes.format(r.outstanding)}', style: Ob.body(13, color: Ob.creamA(.6))),
                ]),
              ),
            ]),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(color: Ob.cardFill, borderRadius: BorderRadius.circular(20)),
              child: Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                Text('KES ', style: Ob.body(16, weight: FontWeight.w700, color: Ob.creamA(.6))),
                Expanded(
                  child: TextField(
                    controller: _amount,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    cursorColor: coachGold,
                    style: Ob.display(40, color: Ob.cream),
                    decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 14),
            ObGooSegmented<String>(
              options: const [('MPESA', 'M-Pesa'), ('CASH', 'Cash'), ('BANK', 'Bank')],
              selected: _method,
              onChanged: (m) => setState(() => _method = m),
              accent: coachGold,
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ObButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Saving…' : 'Save payment', style: Ob.label(16, weight: FontWeight.w800)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
