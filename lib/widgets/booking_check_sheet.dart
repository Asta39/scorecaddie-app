import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../screens/onboarding/ob_app.dart';
import '../screens/onboarding/ob_forms.dart';
import '../screens/onboarding/ob_style.dart';
import '../screens/onboarding/ob_widgets.dart';
import 'profile_image.dart';

/// What the player said when asked whether they booked a pro they contacted.
sealed class BookingAnswer {
  const BookingAnswer();
}

class BookedFor extends BookingAnswer {
  const BookedFor(this.when);
  final DateTime when;
}

class NotYet extends BookingAnswer {
  const NotYet();
}

class DidNotBook extends BookingAnswer {
  const DidNotBook();
}

/// Asks, after the player comes back from calling or messaging a caddie or
/// coach, whether they booked; if so, when. Closing the sheet counts as
/// "not yet".
Future<BookingAnswer> askAboutBooking(
  BuildContext context, {
  required String name,
  String? avatarUrl,
  required bool viaCall,
  required DateTime contactedAt,
}) async {
  final answer = await showObSheet<BookingAnswer>(
    context,
    (_) => _BookingCheckSheet(name: name, avatarUrl: avatarUrl, viaCall: viaCall, contactedAt: contactedAt),
  );
  return answer ?? const NotYet();
}

class _BookingCheckSheet extends StatefulWidget {
  const _BookingCheckSheet({required this.name, this.avatarUrl, required this.viaCall, required this.contactedAt});
  final String name;
  final String? avatarUrl;
  final bool viaCall;
  final DateTime contactedAt;

  @override
  State<_BookingCheckSheet> createState() => _BookingCheckSheetState();
}

enum _Step { ask, when }

class _BookingCheckSheetState extends State<_BookingCheckSheet> {
  _Step _step = _Step.ask;
  late DateTime _day = _dateOnly(DateTime.now());
  TimeOfDay? _time;

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
  static const _slots = [('Early', TimeOfDay(hour: 6, minute: 30)), ('Morning', TimeOfDay(hour: 9, minute: 0)), ('Midday', TimeOfDay(hour: 12, minute: 0)), ('Afternoon', TimeOfDay(hour: 14, minute: 30))];

  String get _first => widget.name.split(' ').first;

  String _ago() {
    final m = DateTime.now().difference(widget.contactedAt).inMinutes;
    final how = widget.viaCall ? 'called' : 'messaged';
    if (m < 1) return 'You just $how $_first.';
    if (m < 60) return 'You $how $_first $m min ago.';
    return 'You $how $_first earlier today.';
  }

  DateTime get _when {
    final t = _time ?? const TimeOfDay(hour: 7, minute: 0);
    return DateTime(_day.year, _day.month, _day.day, t.hour, t.minute);
  }

  Future<void> _pickDay() async {
    final today = _dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: _day,
      firstDate: today,
      lastDate: today.add(const Duration(days: 90)),
      builder: obPickerTheme,
    );
    if (picked != null) setState(() => _day = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time ?? const TimeOfDay(hour: 7, minute: 0), builder: obPickerTheme);
    if (picked != null) setState(() => _time = picked);
  }

  @override
  Widget build(BuildContext context) {
    return ObSheet(
      child: AnimatedSize(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: _step == _Step.ask ? _ask() : _whenStep(),
      ),
    );
  }

  Widget _header(String title, String sub) => Row(children: [
        Stack(clipBehavior: Clip.none, children: [
          ProfileImage(url: widget.avatarUrl, name: widget.name, size: 64, isCircle: true),
          Positioned(
            right: -6,
            bottom: -6,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(color: Ob.lime, shape: BoxShape.circle, border: Border.all(color: Ob.bg, width: 3)),
              child: Icon(widget.viaCall ? LucideIcons.phone : LucideIcons.messageCircle, size: 13, color: Ob.ink),
            ),
          ),
        ]),
        const SizedBox(width: 16),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: Ob.display(24, height: 1.1)),
            const SizedBox(height: 4),
            Text(sub, style: Ob.body(14, color: Ob.creamA(.65))),
          ]),
        ),
      ]);

  Widget _ask() => Column(
        key: const ValueKey('ask'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header('Did you book $_first?', _ago()),
          const SizedBox(height: 22),
          ObButton(
            onPressed: () => setState(() => _step = _Step.when),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(LucideIcons.calendarCheck, size: 18, color: Ob.ink),
              const SizedBox(width: 8),
              Text('Yes, I booked', style: Ob.label(16, weight: FontWeight.w800)),
            ]),
          ),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: ObButton(
                tone: ObButtonTone.dark,
                onPressed: () => Navigator.pop(context, const NotYet()),
                child: Text('Not yet', style: Ob.label(15, weight: FontWeight.w800)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ObButton(
                tone: ObButtonTone.dark,
                onPressed: () => Navigator.pop(context, const DidNotBook()),
                child: Text('No', style: Ob.label(15, weight: FontWeight.w800).copyWith(color: Ob.warn)),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          Text('"Not yet" asks again in a while. Your answer helps other golfers find pros who pick up.',
              textAlign: TextAlign.center, style: Ob.body(12, color: Ob.creamA(.45))),
        ],
      );

  Widget _whenStep() {
    final today = _dateOnly(DateTime.now());
    final days = [for (var i = 0; i < 3; i++) today.add(Duration(days: i))];
    String dayLabel(DateTime d) => d == today ? 'Today' : (d == today.add(const Duration(days: 1)) ? 'Tomorrow' : DateFormat('EEE d').format(d));
    final customDay = !days.contains(_day);
    final customTime = _time != null && !_slots.any((s) => s.$2 == _time);

    return Column(
      key: const ValueKey('when'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ObGuideRow(botAsset: ObBot.ball.happy, botLabel: 'Your golf-ball avatar', text: 'Nice. When are you out with $_first?', size: 64, fontSize: 16),
        const SizedBox(height: 18),
        const ObEyebrow('Day'),
        const SizedBox(height: 8),
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (final d in days) GestureDetector(onTap: () => setState(() => _day = d), child: ObChip(dayLabel(d), on: _day == d)),
          GestureDetector(onTap: _pickDay, child: ObChip(customDay ? DateFormat('EEE d MMM').format(_day) : 'Other day…', on: customDay)),
        ]),
        const SizedBox(height: 16),
        const ObEyebrow('Tee off (optional)'),
        const SizedBox(height: 8),
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (final s in _slots)
            GestureDetector(
              onTap: () => setState(() => _time = _time == s.$2 ? null : s.$2),
              child: ObChip('${s.$1} · ${s.$2.format(context)}', on: _time == s.$2),
            ),
          GestureDetector(onTap: _pickTime, child: ObChip(customTime ? _time!.format(context) : 'Pick a time…', on: customTime)),
        ]),
        const SizedBox(height: 22),
        ObButton(
          onPressed: () => Navigator.pop(context, BookedFor(_when)),
          child: Text('Save booking', style: Ob.label(16, weight: FontWeight.w800)),
        ),
        const SizedBox(height: 6),
        TextButton(
          onPressed: () => setState(() => _step = _Step.ask),
          child: Text('Back', style: Ob.body(14, weight: FontWeight.w700, color: Ob.creamA(.6))),
        ),
      ],
    );
  }
}
