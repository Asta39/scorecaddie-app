import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import '../../widgets/top_notification.dart';
import '../onboarding/ob_app.dart';
import '../onboarding/ob_forms.dart';
import '../onboarding/ob_style.dart';
import '../onboarding/ob_widgets.dart';
import '../../core/providers/restaurant_provider.dart';

const _timeSlots = ['12:00', '12:30', '13:00', '13:30', '18:00', '18:30', '19:00', '19:30', '20:00'];

class TableReservationScreen extends ConsumerStatefulWidget {
  final String clubId;
  final RestaurantLocation location;

  const TableReservationScreen({super.key, required this.clubId, required this.location});

  @override
  ConsumerState<TableReservationScreen> createState() => _TableReservationScreenState();
}

class _TableReservationScreenState extends ConsumerState<TableReservationScreen> {
  DateTime _selectedDate = DateTime.now();
  String _selectedTime = _timeSlots.first;
  String? _selectedTableId;
  int _partySize = 2;
  bool _isBooking = false;

  @override
  Widget build(BuildContext context) {
    final tablesAsync = ref.watch(restaurantTablesProvider(widget.location.id));
    final booked = ref.watch(bookedTableIdsProvider(ReservationSlotParams(locationId: widget.location.id, date: _selectedDate, time: _selectedTime))).valueOrNull ?? const <String>{};
    final tables = tablesAsync.valueOrNull ?? const <RestaurantTable>[];
    final today = DateUtils.dateOnly(DateTime.now());
    final picked = tables.where((t) => t.id == _selectedTableId).firstOrNull;

    return Scaffold(
      backgroundColor: Ob.bg,
      body: DefaultTextStyle(
        style: Ob.textBase,
        child: SafeArea(
          bottom: false,
          child: Column(children: [
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  ObTopBar(widget.location.name, onBack: () => Navigator.of(context).maybePop()),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 70,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: 7,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final d = today.add(Duration(days: i));
                        final on = DateUtils.isSameDay(d, _selectedDate);
                        return ObSelectTile(
                          selected: on,
                          width: 58,
                          padding: EdgeInsets.zero,
                          onTap: () => setState(() {
                            _selectedDate = d;
                            _selectedTableId = null;
                          }),
                          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Text(i == 0 ? 'Today' : DateFormat('EEE').format(d), style: Ob.body(11, weight: FontWeight.w800, color: on ? Ob.lime : Ob.creamA(.6))),
                            Text('${d.day}', style: Ob.display(22, height: 1.1)),
                          ]),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 34,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _timeSlots.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (_, i) => GestureDetector(
                        onTap: () => setState(() {
                          _selectedTime = _timeSlots[i];
                          _selectedTableId = null;
                        }),
                        child: ObChip(_timeSlots[i], on: _timeSlots[i] == _selectedTime),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ObCard(
                    child: Row(children: [
                      Expanded(child: Text('How many?', style: Ob.body(15, weight: FontWeight.w700))),
                      _step(LucideIcons.minus, _partySize > 1 ? () => setState(() => _partySize--) : null),
                      SizedBox(width: 64, child: Column(children: [Text('$_partySize', style: Ob.display(26, height: 1)), Text('people', style: Ob.body(10, color: Ob.creamA(.5)))])),
                      _step(LucideIcons.plus, _partySize < 20 ? () => setState(() => _partySize++) : null),
                    ]),
                  ),
                  const SizedBox(height: 12),
                  ObCard(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const ObEyebrow('Pick a table'),
                      const SizedBox(height: 12),
                      if (tablesAsync.isLoading && tables.isEmpty)
                        const Center(child: CupertinoActivityIndicator(color: Ob.lime))
                      else if (tables.isEmpty)
                        Text('No tables set up here yet.', style: Ob.body(13, color: Ob.creamA(.6)))
                      else
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Ob.bg.withValues(alpha: .5), borderRadius: BorderRadius.circular(20)),
                          child: Wrap(spacing: 10, runSpacing: 10, alignment: WrapAlignment.center, children: [
                            for (final t in tables) _table(t, booked.contains(t.id) || t.seatCount < _partySize),
                          ]),
                        ),
                      const SizedBox(height: 12),
                      Wrap(spacing: 14, runSpacing: 6, children: [
                        _legend(Ob.lime, 'Yours', filled: true),
                        _legend(Ob.creamA(.3), 'Free'),
                        _legend(Ob.creamA(.08), 'Taken or too small', filled: true),
                      ]),
                    ]),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20, 10, 20, 14 + MediaQuery.of(context).padding.bottom),
              child: SizedBox(
                width: double.infinity,
                child: ObButton(
                  onPressed: picked == null || _isBooking ? null : _confirmReservation,
                  child: Text(
                    _isBooking ? 'Booking…' : (picked == null ? 'Pick a table' : 'Book table ${picked.tableNumber} · $_selectedTime'),
                    style: Ob.label(16, weight: FontWeight.w800),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _step(IconData icon, VoidCallback? onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(color: Ob.creamA(onTap == null ? .03 : .08), shape: BoxShape.circle),
          child: Icon(icon, size: 16, color: onTap == null ? Ob.creamA(.25) : Ob.cream),
        ),
      );

  Widget _table(RestaurantTable t, bool unavailable) {
    final on = t.id == _selectedTableId;
    final round = t.shape == 'round';
    return Semantics(
      button: true,
      selected: on,
      label: 'Table ${t.tableNumber}, ${t.seatCount} seats${unavailable ? ', unavailable' : ''}',
      child: GestureDetector(
        onTap: unavailable ? null : () => setState(() => _selectedTableId = t.id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: round ? 64 : 84,
          height: 64,
          decoration: BoxDecoration(
            color: on ? Ob.lime : (unavailable ? Ob.creamA(.08) : Colors.transparent),
            borderRadius: BorderRadius.circular(round ? 32 : 16),
            border: Border.all(color: on ? Ob.lime : (unavailable ? Colors.transparent : Ob.creamA(.3)), width: 1.5),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(t.tableNumber, style: Ob.display(18, height: 1, color: on ? Ob.ink : (unavailable ? Ob.creamA(.35) : Ob.cream))),
            Text('${t.seatCount} seats', style: Ob.body(10, weight: FontWeight.w700, color: on ? Ob.ink : Ob.creamA(unavailable ? .3 : .6))),
          ]),
        ),
      ),
    );
  }

  Widget _legend(Color c, String label, {bool filled = false}) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: filled ? c : null, borderRadius: BorderRadius.circular(4), border: filled ? null : Border.all(color: c))),
        const SizedBox(width: 6),
        Text(label, style: Ob.body(12, color: Ob.creamA(.6))),
      ]);

  Future<void> _confirmReservation() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null || _selectedTableId == null) return;
    setState(() => _isBooking = true);
    try {
      final dateStr =
          '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
      await Supabase.instance.client.from('club_restaurant_reservations').insert({
        'table_id': _selectedTableId,
        'club_id': widget.clubId,
        'player_id': userId,
        'party_size': _partySize,
        'reservation_date': dateStr,
        'reservation_time': '$_selectedTime:00',
      });
      ref.invalidate(bookedTableIdsProvider);
      if (mounted) {
        final tables = ref.read(restaurantTablesProvider(widget.location.id)).valueOrNull ?? [];
        final matchingTable = tables.where((t) => t.id == _selectedTableId);
        final tableNumber = matchingTable.isNotEmpty ? matchingTable.first.tableNumber : '—';
        await Navigator.of(context).push(MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => ReservationConfirmedDialog(
            locationName: widget.location.name,
            tableNumber: tableNumber,
            date: _selectedDate,
            time: _selectedTime,
            partySize: _partySize,
          ),
        ));
        if (mounted) Navigator.of(context).pop();
      }
    } on PostgrestException catch (e) {
      if (mounted) {
        final msg = e.message.contains('duplicate') ? 'That table was just booked by someone else — pick another.' : 'Could not complete the reservation.';
        TopNotification.showError(context, msg);
      }
    } finally {
      if (mounted) setState(() => _isBooking = false);
    }
  }
}

/// Shown after a table is booked.
class ReservationConfirmedDialog extends StatelessWidget {
  final String locationName;
  final String tableNumber;
  final DateTime date;
  final String time;
  final int partySize;

  const ReservationConfirmedDialog({
    super.key,
    required this.locationName,
    required this.tableNumber,
    required this.date,
    required this.time,
    required this.partySize,
  });

  @override
  Widget build(BuildContext context) {
    final when = DateUtils.isSameDay(date, DateTime.now()) ? 'Tonight' : DateFormat('EEEE d MMM').format(date);
    return Scaffold(
      backgroundColor: Ob.bg,
      body: DefaultTextStyle(
        style: Ob.textBase,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(children: [
              const Spacer(),
              SizedBox(
                width: 220,
                height: 200,
                child: Stack(alignment: Alignment.center, children: [
                  Container(width: 140, height: 140, decoration: const BoxDecoration(color: Ob.roleFill, shape: BoxShape.circle)),
                  Image.asset(ObBot.ball.happy, width: 160, height: 160),
                ]),
              ),
              Text('TABLE BOOKED', style: Ob.eyebrow()),
              const SizedBox(height: 8),
              Text('$when at $time', textAlign: TextAlign.center, style: Ob.display(34, height: 1.05)),
              const SizedBox(height: 10),
              Text('Table $tableNumber at $locationName, for $partySize. The clubhouse has your name.', textAlign: TextAlign.center, style: Ob.body(15, height: 1.5, color: Ob.creamA(.7))),
              const Spacer(),
              SizedBox(width: double.infinity, child: ObButton(onPressed: () => Navigator.of(context).pop(), child: Text('Done', style: Ob.label(16, weight: FontWeight.w800)))),
              const SizedBox(height: 16),
            ]),
          ),
        ),
      ),
    );
  }
}
