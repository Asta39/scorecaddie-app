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

class TeeTimesScreen extends ConsumerWidget {
  const TeeTimesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(casualTeeTimeBookingsProvider);
    final now = DateTime.now();
    final all = async.valueOrNull ?? const <CasualTeeTimeBooking>[];
    final upcoming = all.where((b) => teeDateTime(b).isAfter(now) && b.status != 'CANCELLED').toList()..sort((a, b) => teeDateTime(a).compareTo(teeDateTime(b)));
    final past = all.where((b) => !upcoming.contains(b)).toList()..sort((a, b) => teeDateTime(b).compareTo(teeDateTime(a)));

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
                ObTopBar('My tee times', onBack: () => context.pop(), actions: [
                  ObIconButton(icon: LucideIcons.plus, label: 'Book a tee time', onPressed: () => context.push('/book-tee-time')),
                ]),
                const SizedBox(height: 18),
                const ObEyebrow('Coming up'),
                const SizedBox(height: 10),
                if (async.isLoading && all.isEmpty)
                  const Padding(padding: EdgeInsets.all(40), child: Center(child: CupertinoActivityIndicator(color: Ob.lime)))
                else if (async.hasError && all.isEmpty)
                  ObCard(child: Text('Couldn\'t load your tee times. Pull down to try again.', style: Ob.body(14, color: Ob.creamA(.7))))
                else if (upcoming.isEmpty)
                  ObCard(
                    padding: const EdgeInsets.all(18),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      ObGuideRow(botAsset: ObBot.ball.idle, botLabel: 'Your golf-ball avatar', text: 'Nothing booked. Grab a slot?', size: 72, fontSize: 16),
                      const SizedBox(height: 14),
                      ObButton(onPressed: () => context.push('/book-tee-time'), child: Text('Book a tee time', style: Ob.label(15, weight: FontWeight.w800))),
                    ]),
                  )
                else
                  for (final b in upcoming) Padding(padding: const EdgeInsets.only(bottom: 10), child: _Upcoming(booking: b).rise()),
                if (past.isNotEmpty) ...[
                  const SizedBox(height: 22),
                  const ObEyebrow('Past and cancelled'),
                  const SizedBox(height: 10),
                  ObCard(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(children: [
                      for (final (i, b) in past.indexed) ...[
                        if (i > 0) const ObHair(),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(children: [
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(
                                  DateFormat('EEE d MMM · HH:mm').format(teeDateTime(b)),
                                  style: Ob.body(14, weight: FontWeight.w700, color: b.status == 'CANCELLED' ? Ob.creamA(.45) : Ob.cream).copyWith(
                                    decoration: b.status == 'CANCELLED' ? TextDecoration.lineThrough : null,
                                  ),
                                ),
                                Text(b.courseName, style: Ob.body(12, color: Ob.creamA(.55))),
                              ]),
                            ),
                            Text(
                              b.status == 'CANCELLED' ? 'Cancelled' : 'Played',
                              style: Ob.body(12, weight: FontWeight.w800, color: b.status == 'CANCELLED' ? Ob.warn : Ob.creamA(.55)),
                            ),
                          ]),
                        ),
                      ],
                    ]),
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

class _Upcoming extends StatelessWidget {
  const _Upcoming({required this.booking});
  final CasualTeeTimeBooking booking;

  @override
  Widget build(BuildContext context) {
    final at = teeDateTime(booking);
    return ObCard(
      padding: const EdgeInsets.all(14),
      child: Row(children: [
        Container(
          width: 56,
          height: 62,
          decoration: BoxDecoration(color: Ob.lime.withValues(alpha: .12), borderRadius: BorderRadius.circular(16)),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(DateFormat('EEE').format(at).toUpperCase(), style: Ob.body(11, weight: FontWeight.w800, color: Ob.lime)),
            Text('${at.day}', style: Ob.display(26, height: 1, color: Ob.lime)),
          ]),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(DateFormat.Hm().format(at), style: Ob.display(22, height: 1)),
            const SizedBox(height: 3),
            Text(booking.courseName, maxLines: 1, overflow: TextOverflow.ellipsis, style: Ob.body(13, weight: FontWeight.w700)),
            Text(booking.paymentStatus.toUpperCase() == 'PAID' ? 'Paid' : 'Pay at the pro shop', style: Ob.body(12, color: Ob.creamA(.55))),
          ]),
        ),
        ObCrest(booking.courseName, size: 40),
      ]),
    );
  }
}
