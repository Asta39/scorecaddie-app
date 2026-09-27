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
import 'coach_dashboard_screen.dart' show coachGold;

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
    final ok = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.fromLTRB(22, 22, 22, 22 + MediaQuery.of(ctx).padding.bottom),
        decoration: const BoxDecoration(color: Ob.cardFill, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
        child: DefaultTextStyle(
          style: Ob.textBase,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Cancel the whole session?', style: Ob.display(24)),
            const SizedBox(height: 8),
            Text('Every upcoming date is cancelled and your players are told. This can\'t be undone.', style: Ob.body(14, color: Ob.creamA(.7))),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ObButton(tone: ObButtonTone.dark, onPressed: () => Navigator.pop(ctx, false), child: Text('Keep it', style: Ob.label(15, weight: FontWeight.w800)))),
              const SizedBox(width: 10),
              Expanded(child: ObButton(tone: ObButtonTone.light, onPressed: () => Navigator.pop(ctx, true), child: Text('Cancel session', style: Ob.label(15, weight: FontWeight.w800).copyWith(color: Ob.warn)))),
            ]),
          ]),
        ),
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
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate.isBefore(now) ? now : _startDate,
      firstDate: _editing && _startDate.isBefore(now) ? _startDate : now,
      lastDate: now.add(const Duration(days: 365)),
      builder: _pickerTheme,
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _startTime, builder: _pickerTheme);
    if (picked != null) setState(() => _startTime = picked);
  }

  Widget _pickerTheme(BuildContext context, Widget? child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: coachGold, onPrimary: Ob.ink, surface: Ob.cardFill, onSurface: Ob.cream),
          dialogTheme: const DialogThemeData(backgroundColor: Ob.cardFill),
        ),
        child: child!,
      );

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
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 20, 0),
                  child: Row(children: [
                    ObIconButton(icon: LucideIcons.chevronLeft, label: 'Back', onPressed: () => context.pop()),
                    const SizedBox(width: 10),
                    Text(_editing ? 'Edit session' : 'New session', style: Ob.display(24)),
                  ]),
                ),
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    children: [
                      _field(_name, 'Name', hint: 'Short game in 6 weeks', required: true),
                      const SizedBox(height: 10),
                      _field(_description, 'What you\'ll cover', maxLines: 3),
                      const SizedBox(height: 18),
                      const ObEyebrow('Kind'),
                      const SizedBox(height: 10),
                      ObGooSegmented<String>(
                        options: [for (final t in _types) (t, t)],
                        selected: _type,
                        onChanged: (v) => setState(() {
                          _type = v;
                          if (v == '1-on-1') _maxPlayers = 1;
                        }),
                        accent: coachGold,
                        fontSize: 13,
                      ),
                      const SizedBox(height: 18),
                      Row(children: [
                        Expanded(child: _stepper('Players', _maxPlayers, 1, 40, (v) => setState(() => _maxPlayers = v))),
                        const SizedBox(width: 10),
                        Expanded(child: _field(_price, 'KES a session', keyboard: TextInputType.number, required: true, onChanged: (_) => setState(() {}))),
                      ]),
                      const SizedBox(height: 18),
                      _field(_location, 'Club', hint: 'Karen Country Club', required: true),
                      const SizedBox(height: 10),
                      _chips('Where at the club', _areas, _area, (v) => setState(() => _area = v)),
                      const SizedBox(height: 18),
                      _chips('Level', _levels, _level, (v) => setState(() => _level = v)),
                      const SizedBox(height: 18),
                      const ObEyebrow('Days'),
                      const SizedBox(height: 10),
                      Row(children: [
                        for (var d = 1; d <= 7; d++) ...[
                          if (d > 1) const SizedBox(width: 6),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _days.contains(d) ? _days.remove(d) : _days.add(d)),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                height: 44,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: _days.contains(d) ? coachGold : Ob.cardFill,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Text(_dayNames[d - 1], style: Ob.body(12, weight: FontWeight.w800, color: _days.contains(d) ? Ob.ink : Ob.creamA(.7))),
                              ),
                            ),
                          ),
                        ],
                      ]),
                      const SizedBox(height: 14),
                      Row(children: [
                        Expanded(child: _pickerTile('Starts', DateFormat('EEE d MMM').format(_startDate), LucideIcons.calendar, _pickDate)),
                        const SizedBox(width: 10),
                        Expanded(child: _pickerTile('At', _startTime.format(context), LucideIcons.clock, _pickTime)),
                      ]),
                      const SizedBox(height: 18),
                      _chips('Each session', [for (final d in _durations) '$d min'], '$_duration min', (v) => setState(() => _duration = int.parse(v.split(' ').first))),
                      const SizedBox(height: 18),
                      _chips('Runs for', [for (final w in _weekOptions) '$w wk'], '$_weeks wk', (v) => setState(() => _weeks = int.parse(v.split(' ').first))),
                      const SizedBox(height: 18),
                      const ObEyebrow('Payment'),
                      const SizedBox(height: 10),
                      for (final (val, title, sub) in _terms)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: GestureDetector(
                            onTap: () => setState(() => _paymentTerms = val),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: _paymentTerms == val ? const Color(0xFF2A2410) : Ob.cardFill,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: _paymentTerms == val ? coachGold : Colors.transparent, width: 1.5),
                              ),
                              child: Row(children: [
                                Expanded(
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text(title, style: Ob.body(15, weight: FontWeight.w800)),
                                    Text(sub, style: Ob.body(12, color: Ob.creamA(.6))),
                                  ]),
                                ),
                                Icon(_paymentTerms == val ? LucideIcons.circleCheck : LucideIcons.circle, color: _paymentTerms == val ? coachGold : Ob.creamA(.3)),
                              ]),
                            ),
                          ),
                        ),
                      const SizedBox(height: 10),
                      _field(_prerequisites, 'Bring or know beforehand', hint: 'Own wedge, basic grip'),
                      const SizedBox(height: 10),
                      _field(_cancellation, 'Cancellation policy', hint: '24h notice required'),
                      if (_editing) ...[
                        const SizedBox(height: 24),
                        Center(
                          child: TextButton.icon(
                            onPressed: _busy || widget.session!.status == 'cancelled' ? null : _cancelSession,
                            icon: const Icon(LucideIcons.calendarX2, color: Ob.warn, size: 18),
                            label: Text('Cancel this session', style: Ob.body(14, weight: FontWeight.w800, color: Ob.warn)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.fromLTRB(20, 12, 20, 14 + MediaQuery.of(context).padding.bottom),
                  decoration: BoxDecoration(color: Ob.bg, border: Border(top: BorderSide(color: Ob.creamA(.06)))),
                  child: Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                        Text('IF IT FILLS', style: Ob.eyebrow()),
                        Text('KES ${kes.format(full)}', style: Ob.display(22, color: coachGold)),
                      ]),
                    ),
                    ObButton(
                      onPressed: _busy ? null : _save,
                      child: Text(_busy ? 'Saving…' : (_editing ? 'Save changes' : 'Publish'), style: Ob.label(16, weight: FontWeight.w800)),
                    ),
                  ]),
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
    return TextFormField(
      controller: c,
      maxLines: maxLines,
      keyboardType: keyboard,
      onChanged: onChanged,
      cursorColor: coachGold,
      style: Ob.body(15, weight: FontWeight.w700),
      validator: required ? (v) => (v == null || v.trim().isEmpty) ? 'Needed' : null : null,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: Ob.body(13, color: Ob.creamA(.6)),
        floatingLabelStyle: Ob.body(13, weight: FontWeight.w700, color: coachGold),
        hintStyle: Ob.body(14, color: Ob.creamA(.3)),
        errorStyle: Ob.body(12, color: Ob.warn),
        filled: true,
        fillColor: Ob.cardFill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: coachGold, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: Ob.warn)),
      ),
    );
  }

  Widget _stepper(String label, int value, int min, int max, ValueChanged<int> onChanged) {
    Widget btn(IconData icon, int next) => GestureDetector(
          onTap: next < min || next > max ? null : () => onChanged(next),
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: Ob.creamA(.08), shape: BoxShape.circle),
            child: Icon(icon, size: 16, color: Ob.cream),
          ),
        );
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(color: Ob.cardFill, borderRadius: BorderRadius.circular(18)),
      child: Row(children: [
        btn(LucideIcons.minus, value - 1),
        Expanded(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(label, style: Ob.body(11, color: Ob.creamA(.55))),
            Text('$value', style: Ob.display(20, height: 1.1)),
          ]),
        ),
        btn(LucideIcons.plus, value + 1),
      ]),
    );
  }

  Widget _chips(String label, List<String> options, String selected, ValueChanged<String> onTap) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ObEyebrow(label),
      const SizedBox(height: 10),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final o in options) GestureDetector(onTap: () => onTap(o), child: ObChip(o, on: o == selected, color: coachGold)),
      ]),
    ]);
  }

  Widget _pickerTile(String label, String value, IconData icon, VoidCallback onTap) {
    return ObCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      radius: 18,
      child: Row(children: [
        Icon(icon, size: 18, color: coachGold),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: Ob.body(11, color: Ob.creamA(.55))),
            Text(value, style: Ob.body(15, weight: FontWeight.w800)),
          ]),
        ),
      ]),
    );
  }
}
