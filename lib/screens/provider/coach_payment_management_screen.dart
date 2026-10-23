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
import '../../core/utils/mpesa_message.dart';
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
  List<_RE> _allRows = const [];

  /// Players who still owe come first in the picker.
  static List<_RE> _owedFirst(List<_RE> all) => [...all.where((r) => !r.isPaid), ...all.where((r) => r.isPaid)];

  void _record([_RE? r]) => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _RecordSheet(r: r, all: _owedFirst(_allRows)),
      );
  String? _sessionId;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(_allEnrollmentsProvider);
    final all = async.valueOrNull ?? const <_RE>[];
    _allRows = all;
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
              ObTabHeader('Money', actions: [
                ObIconButton(icon: LucideIcons.plus, label: 'Record a payment', onPressed: all.isEmpty ? null : () => _record()),
              ]),
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
                builder: (_) => _RecordSheet(r: r, all: _owedFirst(_allRows)),
              ),
    );
  }
}

/// Records a payment. Paste the M-Pesa confirmation and the amount, code and
/// sender fill themselves in; pick (or confirm) the player it's from.
class _RecordSheet extends ConsumerStatefulWidget {
  const _RecordSheet({this.r, required this.all});

  /// The player tapped on, if any.
  final _RE? r;

  /// Everyone who can be paid for, to pick from.
  final List<_RE> all;

  @override
  ConsumerState<_RecordSheet> createState() => _RecordSheetState();
}

class _RecordSheetState extends ConsumerState<_RecordSheet> {
  late _RE? _for = widget.r;
  late final _amount = TextEditingController(text: widget.r?.outstanding.toStringAsFixed(0) ?? '');
  final _message = TextEditingController();
  final _code = TextEditingController();
  String _method = 'MPESA';
  String? _sender;
  bool _saving = false;

  @override
  void dispose() {
    _amount.dispose();
    _message.dispose();
    _code.dispose();
    super.dispose();
  }

  void _read(String text) {
    final m = MpesaMessage.parse(text);
    if (m.isEmpty) return;
    setState(() {
      _method = 'MPESA';
      if (m.amount != null) _amount.text = m.amount!.toStringAsFixed(0);
      if (m.code != null) _code.text = m.code!;
      _sender = m.sender;
      // Match the sender's name to a player, if nobody's picked yet.
      if (_for == null && m.sender != null) {
        final words = m.sender!.toLowerCase().split(' ').where((w) => w.length > 2).toSet();
        final hits = widget.all.where((r) {
          final name = (r.e.playerName ?? '').toLowerCase();
          return words.any(name.contains);
        }).toList();
        if (hits.length == 1) _for = hits.first;
      }
    });
  }

  Future<void> _pickPlayer() async {
    final picked = await showCupertinoModalPopup<_RE>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('Who is this payment from?'),
        actions: [
          for (final r in widget.all)
            CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(ctx, r),
              child: Text('${r.e.playerName ?? 'Student'} · ${r.session.name}', maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
      ),
    );
    if (picked != null) setState(() => _for = picked);
  }

  Future<void> _save() async {
    final r = _for;
    final amount = double.tryParse(_amount.text.trim());
    if (r == null) {
      TopNotification.showError(context, 'Pick who the payment is from');
      return;
    }
    if (amount == null || amount <= 0) {
      TopNotification.showError(context, 'Enter an amount');
      return;
    }
    if (_method == 'MPESA' && _code.text.trim().length < 8) {
      TopNotification.showError(context, 'Paste the M-Pesa message or enter its code');
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(coachingServiceProvider).recordPayment(
            enrollmentId: r.e.id,
            amount: amount,
            method: _method,
            sessionId: r.e.sessionId,
            playerId: r.e.playerId,
            reference: _method == 'MPESA' ? _code.text.trim() : null,
            message: _message.text.trim(),
          );
      HapticFeedback.mediumImpact();
      ref.invalidate(sessionEnrollmentsProvider(r.e.sessionId));
      ref.invalidate(_allEnrollmentsProvider);
      ref.invalidate(coachRevenueBreakdownProvider);
      ref.invalidate(coachStudentsProvider);
      if (!mounted) return;
      Navigator.pop(context);
      TopNotification.showSuccess(context, 'KES ${_kes.format(amount)} from ${r.e.playerName ?? 'student'} recorded');
    } catch (e) {
      final dup = '$e'.contains('duplicate') || '$e'.contains('23505');
      if (mounted) TopNotification.showError(context, dup ? 'That M-Pesa code is already recorded' : 'Couldn’t record the payment: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = _for;
    return ObSheet(
      title: 'Record a payment',
      height: MediaQuery.of(context).size.height * .85,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: ListView(children: [
        ObGooSegmented<String>(
          options: const [('MPESA', 'M-Pesa'), ('CASH', 'Cash'), ('BANK', 'Bank')],
          selected: _method,
          onChanged: (m) => setState(() => _method = m),
        ),
        const SizedBox(height: 16),
        if (_method == 'MPESA') ...[
          Container(
            decoration: BoxDecoration(color: Ob.cardFill, borderRadius: BorderRadius.circular(12)),
            child: TextField(
              controller: _message,
              onChanged: _read,
              minLines: 3,
              maxLines: 6,
              cursorColor: Ob.lime,
              style: Ob.body(15),
              decoration: InputDecoration(
                hintText: 'Paste the M-Pesa message here',
                hintStyle: Ob.body(15, color: Ob.creamA(.4)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
          ),
          if (_sender != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
              child: Text('From $_sender', style: Ob.body(13, color: Ob.creamA(.6))),
            ),
          const SizedBox(height: 16),
        ],
        ObGroup(children: [
          ObRow('From', value: r == null ? 'Pick a player' : (r.e.playerName ?? 'Student'), valueColor: r == null ? Ob.lime : null, onTap: _pickPlayer),
          if (r != null) ObRow('Session', value: r.session.name),
          if (r != null) ObRow('Still owes', value: 'KES ${_kes.format(r.outstanding)}'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(children: [
              Text('Amount', style: Ob.body(17)),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _amount,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textAlign: TextAlign.end,
                  cursorColor: Ob.lime,
                  style: Ob.body(17),
                  decoration: InputDecoration(border: InputBorder.none, hintText: '0', prefixText: 'KES ', prefixStyle: Ob.body(17, color: Ob.creamA(.6))),
                ),
              ),
            ]),
          ),
          if (_method == 'MPESA')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(children: [
                Text('M-Pesa code', style: Ob.body(17)),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _code,
                    textAlign: TextAlign.end,
                    textCapitalization: TextCapitalization.characters,
                    cursorColor: Ob.lime,
                    style: Ob.body(17),
                    decoration: const InputDecoration(border: InputBorder.none, hintText: 'SKL4ABC123'),
                  ),
                ),
              ]),
            ),
        ]),
        const SizedBox(height: 18),
        ObButton(
          height: 54,
          radius: 14,
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Saving…' : 'Record', style: Ob.label(17)),
        ),
        const SizedBox(height: 24),
      ]),
    );
  }
}
