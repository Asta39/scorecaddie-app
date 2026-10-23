import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/models/coaching_model.dart';
import '../../providers/app_providers.dart';
import '../../widgets/top_notification.dart';
import '../onboarding/ob_app.dart';
import '../onboarding/ob_style.dart';
import '../onboarding/ob_forms.dart';

/// Create a coaching session, or edit one when [session] is given.
class SessionForm extends ConsumerStatefulWidget {
  const SessionForm({super.key, this.session});
  final CoachingSession? session;

  @override
  ConsumerState<SessionForm> createState() => _SessionFormState();
}

class _SessionFormState extends ConsumerState<SessionForm> {
  static const _types = ['Group', '1-on-1', 'Clinic', 'Camp'];
  static const _areas = ['Driving Range', 'Putting Green', 'Bunker Area', 'Chipping Green', 'On-Course'];
  static const _levels = ['All', 'Beginner', 'Intermediate', 'Advanced'];
  static const _durations = [30, 60, 90, 120, 180];
  static const _weekOptions = [1, 2, 3, 4, 6, 8, 10, 12];
  static const _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _terms = [
    ('upfront', 'Pay upfront', 'Players pay the full price when they book'),
    ('post', 'Pay after', 'Players pay once the sessions are done'),
    ('split', 'Half and half', '50% when they book, 50% at the end'),
  ];

  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.session?.name ?? '');
  late final _description = TextEditingController(text: widget.session?.description ?? '');
  late final _price = TextEditingController(text: widget.session == null ? '' : widget.session!.pricePerSession.toStringAsFixed(0));
  late final _location = TextEditingController(text: widget.session?.location ?? '');
  late final _prerequisites = TextEditingController(text: widget.session?.prerequisites ?? '');
  late final _cancellation = TextEditingController(text: widget.session?.cancellationPolicy ?? '');

  late int _maxPlayers = widget.session?.maxPlayers ?? 6;
  late int _weeks = widget.session?.weeks ?? 4;
  late DateTime _startDate = widget.session?.startDate ?? DateTime.now().add(const Duration(days: 1));
  late TimeOfDay _startTime = _parseTime(widget.session?.startTime) ?? const TimeOfDay(hour: 7, minute: 0);
  late int _duration = widget.session?.durationMinutes ?? 120;
  late String _type = _pick(widget.session?.sessionType, _types);
  late String _area = _pick(widget.session?.locationArea, _areas);
  late String _level = _pick(widget.session?.targetSkillLevel, _levels);
  late String _paymentTerms = widget.session?.paymentTerms ?? 'upfront';
  late final Set<int> _days = {...?widget.session?.daysOfWeek};
  bool _busy = false;

  bool get _editing => widget.session != null;

  static String _pick(String? v, List<String> options) => options.contains(v) ? v! : options.first;

  static TimeOfDay? _parseTime(String? t) {
    if (t == null) return null;
    final p = t.split(':');
    final h = int.tryParse(p.first), m = p.length > 1 ? int.tryParse(p[1]) : 0;
    return h == null || m == null ? null : TimeOfDay(hour: h, minute: m);
  }

  @override
  void dispose() {
    for (final c in [_name, _description, _price, _location, _prerequisites, _cancellation]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_days.isEmpty) {
      TopNotification.showError(context, 'Pick at least one day of the week');
      return;
    }
    setState(() => _busy = true);
    final service = ref.read(coachingServiceProvider);
    try {
      if (_editing) {
        await service.updateSession(
          sessionId: widget.session!.id,
          name: _name.text.trim(),
          description: _description.text.trim(),
          maxPlayers: _maxPlayers,
          price: double.tryParse(_price.text) ?? 0,
          durationMinutes: _duration,
          location: _location.text.trim(),
          daysOfWeek: _days,
          startTime: _startTime,
          weeks: _weeks,
          startDate: _startDate,
          paymentTerms: _paymentTerms,
          sessionType: _type,
          locationArea: _area,
          targetSkillLevel: _level,
          prerequisites: _prerequisites.text,
          cancellationPolicy: _cancellation.text,
        );
        ref.invalidate(sessionOccurrencesProvider(widget.session!.id));
        ref.invalidate(specificCoachingSessionProvider(widget.session!.id));
      } else {
        await service.createSession(
          name: _name.text.trim(),
          description: _description.text.trim(),
          maxPlayers: _maxPlayers,
          price: double.tryParse(_price.text) ?? 0,
          durationMinutes: _duration,
          location: _location.text.trim(),
          daysOfWeek: _days,
          startTime: _startTime,
          weeks: _weeks,
          startDate: _startDate,
          paymentTerms: _paymentTerms,
          sessionType: _type,
          locationArea: _area,
          targetSkillLevel: _level,
          prerequisites: _prerequisites.text,
          cancellationPolicy: _cancellation.text,
        );
        final me = ref.read(authStateProvider).valueOrNull;
        if (me != null) ref.invalidate(providerSessionsProvider(me.id));
      }
      ref.invalidate(coachSessionsProvider);
      if (!mounted) return;
      TopNotification.showSuccess(context, _editing ? 'Session updated' : 'Session published');
      context.pop();
    } catch (e) {
      if (mounted) TopNotification.showError(context, 'Couldn\'t save the session: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancelSession() async {
    final ok = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Cancel the whole session?'),
        content: const Text('Every upcoming date is cancelled and your players are told. This can’t be undone.'),
        actions: [
          CupertinoDialogAction(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep it')),
          CupertinoDialogAction(isDestructiveAction: true, onPressed: () => Navigator.pop(ctx, true), child: const Text('Cancel session')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref.read(coachingServiceProvider).cancelSession(widget.session!.id);
      ref.invalidate(coachSessionsProvider);
      if (!mounted) return;
      TopNotification.showSuccess(context, 'Session cancelled');
      context.pop();
    } catch (e) {
      if (mounted) TopNotification.showError(context, 'Couldn\'t cancel the session: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final first = _editing && _startDate.isBefore(now) ? _startDate : DateTime(now.year, now.month, now.day);
    var picked = _startDate.isBefore(first) ? first : _startDate;
    await _wheel(CupertinoDatePicker(
      mode: CupertinoDatePickerMode.date,
      initialDateTime: picked,
      minimumDate: first,
      maximumDate: now.add(const Duration(days: 365)),
      onDateTimeChanged: (d) => picked = d,
    ));
    setState(() => _startDate = picked);
  }

  Future<void> _pickTime() async {
    final n = DateTime.now();
    var picked = DateTime(n.year, n.month, n.day, _startTime.hour, _startTime.minute);
    await _wheel(CupertinoDatePicker(
      mode: CupertinoDatePickerMode.time,
      use24hFormat: true,
      minuteInterval: 5,
      initialDateTime: picked.subtract(Duration(minutes: picked.minute % 5)),
      onDateTimeChanged: (d) => picked = d,
    ));
    setState(() => _startTime = TimeOfDay(hour: picked.hour, minute: picked.minute));
  }

  Future<void> _wheel(Widget picker) => showObSheet<void>(
        context,
        (ctx) => ObSheet(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            SizedBox(height: 216, child: picker),
            const SizedBox(height: 8),
            ObButton(height: 50, radius: 14, onPressed: () => Navigator.pop(ctx), child: Text('Done', style: Ob.label(17))),
          ]),
        ),
      );

  Future<void> _choose(String title, List<String> options, String selected, ValueChanged<String> onPick) async {
    final v = await showCupertinoModalPopup<String>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(title),
        actions: [
          for (final o in options)
            CupertinoActionSheetAction(isDefaultAction: o == selected, onPressed: () => Navigator.pop(ctx, o), child: Text(o)),
        ],
        cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
      ),
    );
    if (v != null) setState(() => onPick(v));
  }

  @override
  Widget build(BuildContext context) {
    final price = double.tryParse(_price.text) ?? 0;
    final full = price * _maxPlayers * _days.length * _weeks;
    final kes = NumberFormat('#,###');

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: Ob.overlay,
      child: Scaffold(
        backgroundColor: Ob.bg,
        body: DefaultTextStyle(
          style: Ob.textBase,
          child: SafeArea(
            bottom: false,
            child: Form(
              key: _formKey,
              child: Column(children: [
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      ObTopBar(_editing ? 'Edit session' : 'New session', onBack: () => context.pop()),
                      const SizedBox(height: 14),
                      ObGroup(children: [
                        _field(_name, 'Name', hint: 'Short game in 6 weeks', required: true),
                        _field(_description, 'What you’ll cover', hint: 'Optional', maxLines: 3),
                      ]),
                      const SizedBox(height: 22),
                      ObGooSegmented<String>(
                        options: [for (final t in _types) (t, t)],
                        selected: _type,
                        onChanged: (v) => setState(() {
                          _type = v;
                          if (v == '1-on-1') _maxPlayers = 1;
                        }),
                      ),
                      const SizedBox(height: 22),
                      ObGroup(header: 'Size and price', footer: 'If every seat fills: KES ${kes.format(full)}.', children: [
                        ObRow('Players', trailing: _stepper(_maxPlayers, 1, 40, (v) => setState(() => _maxPlayers = v))),
                        _field(_price, 'KES a session', hint: '1500', keyboard: TextInputType.number, required: true, onChanged: (_) => setState(() {})),
                      ]),
                      const SizedBox(height: 22),
                      ObGroup(header: 'Where', children: [
                        _field(_location, 'Club', hint: 'Karen Country Club', required: true),
                        ObRow('Area', value: _area, onTap: () => _choose('Where at the club', _areas, _area, (v) => _area = v)),
                        ObRow('Level', value: _level, onTap: () => _choose('Level', _levels, _level, (v) => _level = v)),
                      ]),
                      const SizedBox(height: 22),
                      ObGroup(header: 'When', children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                          child: Row(children: [
                            for (var d = 1; d <= 7; d++) ...[
                              if (d > 1) const SizedBox(width: 6),
                              Expanded(
                                child: Semantics(
                                  button: true,
                                  selected: _days.contains(d),
                                  label: _dayNames[d - 1],
                                  child: GestureDetector(
                                    onTap: () => setState(() => _days.contains(d) ? _days.remove(d) : _days.add(d)),
                                    child: Container(
                                      height: 40,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(color: _days.contains(d) ? Ob.lime : Ob.field, borderRadius: BorderRadius.circular(10)),
                                      child: Text(_dayNames[d - 1], style: Ob.body(13, weight: FontWeight.w600, color: _days.contains(d) ? Ob.ink : Ob.cream)),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ]),
                        ),
                        ObRow('Starts', value: DateFormat('EEE d MMM').format(_startDate), onTap: _pickDate),
                        ObRow('Time', value: _startTime.format(context), onTap: _pickTime),
                        ObRow('Length', value: '$_duration min',
                            onTap: () => _choose('Each session', [for (final d in _durations) '$d min'], '$_duration min', (v) => _duration = int.parse(v.split(' ').first))),
                        ObRow('Runs for', value: '$_weeks ${_weeks == 1 ? 'week' : 'weeks'}',
                            onTap: () => _choose('Runs for', [for (final w in _weekOptions) '$w wk'], '$_weeks wk', (v) => _weeks = int.parse(v.split(' ').first))),
                      ]),
                      const SizedBox(height: 22),
                      ObGroup(header: 'Payment', children: [
                        for (final (val, title, sub) in _terms)
                          ObRow(title,
                              subtitle: sub,
                              trailing: _paymentTerms == val ? const Icon(CupertinoIcons.checkmark_alt, color: Ob.lime, size: 22) : const SizedBox(width: 22),
                              onTap: () => setState(() => _paymentTerms = val)),
                      ]),
                      const SizedBox(height: 22),
                      ObGroup(header: 'Good to know', children: [
                        _field(_prerequisites, 'Bring', hint: 'Own wedge, basic grip'),
                        _field(_cancellation, 'Cancelling', hint: '24h notice required'),
                      ]),
                      if (_editing) ...[
                        const SizedBox(height: 22),
                        ObGroup(children: [
                          ObRow('Cancel this session',
                              titleColor: Ob.warn,
                              onTap: _busy || widget.session!.status == 'cancelled' ? null : _cancelSession),
                        ]),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 10 + MediaQuery.of(context).padding.bottom),
                  child: SizedBox(
                    width: double.infinity,
                    child: ObButton(
                      height: 54,
                      radius: 14,
                      onPressed: _busy ? null : _save,
                      child: Text(_busy ? 'Saving…' : (_editing ? 'Save changes' : 'Publish session'), style: Ob.label(17)),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label,
      {String? hint, int maxLines = 1, bool required = false, TextInputType? keyboard, ValueChanged<String>? onChanged}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Row(crossAxisAlignment: maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center, children: [
        SizedBox(width: 118, child: Padding(padding: EdgeInsets.only(top: maxLines > 1 ? 12 : 0), child: Text(label, style: Ob.body(17)))),
        Expanded(
          child: TextFormField(
            controller: c,
            maxLines: maxLines,
            minLines: 1,
            keyboardType: keyboard,
            onChanged: onChanged,
            cursorColor: Ob.lime,
            style: Ob.body(17),
            validator: required ? (v) => (v == null || v.trim().isEmpty) ? 'Needed' : null : null,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: Ob.body(17, color: Ob.creamA(.3)),
              errorStyle: Ob.body(12, color: Ob.warn),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _stepper(int value, int min, int max, ValueChanged<int> onChanged) {
    Widget btn(IconData icon, String label, int next) => Semantics(
          button: true,
          label: label,
          child: GestureDetector(
            onTap: next < min || next > max ? null : () => onChanged(next),
            child: SizedBox(width: 44, height: 32, child: Icon(icon, size: 18, color: next < min || next > max ? Ob.creamA(.3) : Ob.cream)),
          ),
        );
    return Row(mainAxisSize: MainAxisSize.min, children: [
      SizedBox(width: 36, child: Text('$value', textAlign: TextAlign.center, style: Ob.body(17, color: Ob.creamA(.6)))),
      const SizedBox(width: 8),
      Container(
        decoration: BoxDecoration(color: Ob.field, borderRadius: BorderRadius.circular(8)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          btn(LucideIcons.minus, 'Fewer players', value - 1),
          Container(width: 1, height: 18, color: Ob.creamA(.2)),
          btn(LucideIcons.plus, 'More players', value + 1),
        ]),
      ),
    ]);
  }
}
