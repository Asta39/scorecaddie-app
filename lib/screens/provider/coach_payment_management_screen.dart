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
import '../onboarding/ob_forms.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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

    final revenue = ref.watch(coachRevenueBreakdownProvider).valueOrNull;

    return Scaffold(
      backgroundColor: Ob.bg,
      body: DefaultTextStyle(
        style: Ob.textBase,
        child: RefreshIndicator(
          color: Ob.ink,
          backgroundColor: Ob.lime,
          onRefresh: () async {
            ref.invalidate(coachSessionsProvider);
            ref.invalidate(_allEnrollmentsProvider);
            ref.invalidate(coachRevenueBreakdownProvider);
          },
          child: ListView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
            children: [
              const ObTabHeader('Money'),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Ob.cardFill, borderRadius: BorderRadius.circular(16)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Collected', style: Ob.body(13, weight: FontWeight.w600, color: Ob.creamA(.6))),
                  Text(_kes.format(collected), style: Ob.display(48, height: 1.1)),
                  Text('KES · ${owed > 0 ? 'KES ${_kes.format(owed)} still owed' : 'nothing owed'}',
                      style: Ob.body(15, color: owed > 0 ? Ob.warn : Ob.creamA(.6))),
                ]),
              ),
              if (revenue != null) ...[
                const SizedBox(height: 22),
                ObGroup(header: 'By method', children: [
                  ObRow('M-Pesa', leading: const ObRowIcon(LucideIcons.smartphone, Ob.lime), value: _kes.format(revenue['MPESA'] ?? 0)),
                  ObRow('Cash', leading: const ObRowIcon(LucideIcons.banknote, Color(0xFFB7791F)), value: _kes.format(revenue['CASH'] ?? 0)),
                  ObRow('Bank', leading: const ObRowIcon(LucideIcons.landmark, Color(0xFF2563EB)), value: _kes.format(revenue['BANK'] ?? 0)),
                ]),
              ],
              const SizedBox(height: 22),
              ObGooSegmented<_View>(
                options: const [(_View.owed, 'Owe'), (_View.bySession, 'By session'), (_View.paid, 'Paid')],
                selected: _view,
                onChanged: (v) => setState(() => _view = v),
              ),
              if (_view == _View.bySession && sessions.isNotEmpty) ...[
                const SizedBox(height: 12),
                ObGroup(children: [
                  ObRow('Session', value: picked?.name ?? '', onTap: () async {
                    final id = await showCupertinoModalPopup<String>(
                      context: context,
                      builder: (ctx) => CupertinoActionSheet(
                        actions: [
                          for (final s in sessions)
                            CupertinoActionSheetAction(isDefaultAction: s.id == picked?.id, onPressed: () => Navigator.pop(ctx, s.id), child: Text(s.name)),
                        ],
                        cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                      ),
                    );
                    if (id != null) setState(() => _sessionId = id);
                  }),
                ]),
              ],
              const SizedBox(height: 16),
              if (async.isLoading && all.isEmpty)
                const Padding(padding: EdgeInsets.all(40), child: Center(child: CupertinoActivityIndicator(color: Ob.lime)))
              else if (async.hasError && all.isEmpty)
                const ObGroup(children: [ObRow('Couldn’t load payments', subtitle: 'Pull down to try again')])
              else if (rows.isEmpty)
                ObGroup(children: [
                  ObRow(switch (_view) {
                    _View.owed => all.isEmpty ? 'Payments show up once players book' : 'Everyone’s paid up',
                    _View.paid => 'Nobody has paid in full yet',
                    _View.bySession => 'No players in this session yet',
                  }),
                ])
              else
                ObGroup(
                  footer: _view == _View.paid ? null : 'Tap a player to record a payment.',
                  children: [for (final r in rows) _payRow(context, r, showSession: _view != _View.bySession)],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _payRow(BuildContext context, _RE r, {required bool showSession}) {
    final late = r.isOverdue ? ' · ${DateTime.now().difference(r.e.enrolledAt).inDays} days late' : '';
    return ObRow(
      r.e.playerName ?? 'Student',
      subtitle: '${showSession ? r.session.name : 'Joined ${DateFormat('d MMM').format(r.e.enrolledAt)}'} · paid ${_kes.format(r.e.amountPaid)} of ${_kes.format(r.session.pricePerSession)}$late',
      leading: ProfileImage(url: r.e.playerAvatar, name: r.e.playerName, size: 36, isCircle: true),
      value: r.isPaid ? 'Paid' : _kes.format(r.outstanding),
      valueColor: r.isPaid ? null : Ob.warn,
      onTap: r.isPaid
          ? null
          : () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => _RecordSheet(r: r),
              ),
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
    return ObSheet(
      title: 'Record a payment',
      subtitle: '${r.e.playerName ?? 'Student'} · owes KES ${_kes.format(r.outstanding)}',
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(color: Ob.cardFill, borderRadius: BorderRadius.circular(12)),
          child: Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
            Text('KES ', style: Ob.body(17, color: Ob.creamA(.6))),
            Expanded(
              child: TextField(
                controller: _amount,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                cursorColor: Ob.lime,
                style: Ob.display(36, color: Ob.cream),
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
        ),
        const SizedBox(height: 18),
        ObButton(
          height: 54,
          radius: 14,
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Saving…' : 'Record', style: Ob.label(17)),
        ),
      ]),
    );
  }
}
