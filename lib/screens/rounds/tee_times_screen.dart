import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../providers/booking_providers.dart';
import '../onboarding/ob_app.dart';
import '../onboarding/ob_forms.dart';
import '../onboarding/ob_style.dart';
import '../onboarding/ob_widgets.dart';

/// When a booking tees off; tolerates "7:30", "07:30" and "07:30:00".
DateTime teeDateTime(CasualTeeTimeBooking b) {
  final p = b.teeTime.split(':');
  final h = int.tryParse(p.first) ?? 0;
  final m = p.length > 1 ? int.tryParse(p[1]) ?? 0 : 0;
  return DateTime(b.bookingDate.year, b.bookingDate.month, b.bookingDate.day, h, m);
}

enum _When { upcoming, past }

class TeeTimesScreen extends ConsumerStatefulWidget {
  const TeeTimesScreen({super.key});

  @override
  ConsumerState<TeeTimesScreen> createState() => _TeeTimesScreenState();
}

class _TeeTimesScreenState extends ConsumerState<TeeTimesScreen> {
  _When _when = _When.upcoming;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(casualTeeTimeBookingsProvider);
    final now = DateTime.now();
    final all = async.valueOrNull ?? const <CasualTeeTimeBooking>[];
    final upcoming = all.where((b) => teeDateTime(b).isAfter(now) && b.status != 'CANCELLED').toList()..sort((a, b) => teeDateTime(a).compareTo(teeDateTime(b)));
    final past = all.where((b) => !upcoming.contains(b)).toList()..sort((a, b) => teeDateTime(b).compareTo(teeDateTime(a)));
    final shown = _when == _When.upcoming ? upcoming : past;
    final next = upcoming.firstOrNull;

    return Scaffold(
      backgroundColor: Ob.bg,
      body: DefaultTextStyle(
        style: Ob.textBase,
        child: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            color: Ob.ink,
            backgroundColor: Ob.lime,
            onRefresh: () async => ref.invalidate(casualTeeTimeBookingsProvider),
            child: ListView(
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 60),
              children: [
                ObTopBar('Tee times', onBack: () => context.pop(), actions: [
                  ObIconButton(icon: LucideIcons.plus, label: 'Book a tee time', onPressed: () => context.push('/book-tee-time')),
                ]),
                const SizedBox(height: 16),
                if (next != null) ...[
                  _NextCard(booking: next).rise(),
                  const SizedBox(height: 16),
                ],
                ObGooSegmented<_When>(
                  options: [(_When.upcoming, 'Upcoming · ${upcoming.length}'), (_When.past, 'Past · ${past.length}')],
                  selected: _when,
                  onChanged: (v) => setState(() => _when = v),
                ),
                const SizedBox(height: 14),
                if (async.isLoading && all.isEmpty)
                  const Padding(padding: EdgeInsets.all(40), child: Center(child: CupertinoActivityIndicator(color: Ob.lime)))
                else if (async.hasError && all.isEmpty)
                  ObCard(child: Text('Couldn\'t load your tee times. Pull down to try again.', style: Ob.body(14, color: Ob.creamA(.7))))
                else if (shown.isEmpty)
                  ObCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      ObGuideRow(
                        botAsset: ObBot.ball.idle,
                        botLabel: 'Your golf-ball avatar',
                        text: _when == _When.upcoming ? 'Nothing booked. Grab a slot?' : 'Tee times you\'ve played show up here.',
                        size: 72,
                        fontSize: 16,
                      ),
                      if (_when == _When.upcoming) ...[
                        const SizedBox(height: 16),
                        ObButton(
                          onPressed: () => context.push('/book-tee-time'),
                          child: Text('Book a tee time', style: Ob.label(15, weight: FontWeight.w800)),
                        ),
                      ],
                    ]),
                  )
                else
                  for (final b in shown.where((b) => b != next || _when == _When.past))
                    Padding(padding: const EdgeInsets.only(bottom: 10), child: _Row(booking: b)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NextCard extends StatelessWidget {
  const _NextCard({required this.booking});
  final CasualTeeTimeBooking booking;

  @override
  Widget build(BuildContext context) {
    final at = teeDateTime(booking);
    final days = DateUtils.dateOnly(at).difference(DateUtils.dateOnly(DateTime.now())).inDays;
    final when = days == 0 ? 'TODAY' : (days == 1 ? 'TOMORROW' : 'IN $days DAYS');
    return ObHeroCard(
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('NEXT UP · $when', style: Ob.eyebrow()),
            const SizedBox(height: 6),
            Text(DateFormat.Hm().format(at), style: Ob.display(48, color: Ob.lime, height: 1)),
            const SizedBox(height: 4),
            Text(DateFormat('EEEE d MMMM').format(at), style: Ob.body(14, weight: FontWeight.w700)),
            Text(booking.courseName, style: Ob.body(13, color: Ob.creamA(.6))),
          ]),
        ),
        ObCrest(booking.courseName, size: 64, radius: 18),
      ]),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.booking});
  final CasualTeeTimeBooking booking;

  @override
  Widget build(BuildContext context) {
    final at = teeDateTime(booking);
    final cancelled = booking.status == 'CANCELLED';
    return ObCard(
      padding: const EdgeInsets.all(14),
      child: Row(children: [
        ObCrest(booking.courseName, size: 46),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(booking.courseName, maxLines: 1, overflow: TextOverflow.ellipsis, style: Ob.body(15, weight: FontWeight.w800, color: cancelled ? Ob.creamA(.5) : Ob.cream)),
            Text(DateFormat('EEE d MMM · HH:mm').format(at), style: Ob.body(12, color: Ob.creamA(.55))),
          ]),
        ),
        if (cancelled)
          const ObChip('Cancelled', on: true, color: Ob.warn)
        else if (booking.paymentStatus.toUpperCase() == 'PAID')
          const ObChip('Paid', on: true)
        else
          ObChip(booking.status.isEmpty ? 'Booked' : booking.status[0] + booking.status.substring(1).toLowerCase()),
      ]),
    );
  }
}
