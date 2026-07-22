import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/restaurant_provider.dart';
import '../../widgets/pill.dart';
import '../../widgets/table_visual.dart';

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
    final bookedAsync = ref.watch(bookedTableIdsProvider(
      ReservationSlotParams(locationId: widget.location.id, date: _selectedDate, time: _selectedTime),
    ));

    return Scaffold(
      backgroundColor: AppColors.grey25,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: Text(widget.location.name, style: const TextStyle(fontSize: AppTypeScale.title, fontWeight: FontWeight.w800, color: AppColors.grey900)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Date', style: TextStyle(fontSize: AppTypeScale.meta, fontWeight: FontWeight.w700, color: AppColors.grey600)),
                const SizedBox(height: 8),
                _DateStrip(
                  selectedDate: _selectedDate,
                  onSelect: (d) => setState(() { _selectedDate = d; _selectedTableId = null; }),
                ),
                const SizedBox(height: 16),
                const Text('Time', style: TextStyle(fontSize: AppTypeScale.meta, fontWeight: FontWeight.w700, color: AppColors.grey600)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _timeSlots.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final slot = _timeSlots[i];
                      final selected = slot == _selectedTime;
                      return GestureDetector(
                        onTap: () => setState(() { _selectedTime = slot; _selectedTableId = null; }),
                        child: Container(
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: selected ? AppColors.emerald600 : AppColors.white,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: selected ? AppColors.emerald600 : AppColors.grey200),
                          ),
                          child: Text(
                            slot,
                            style: TextStyle(
                              fontSize: AppTypeScale.meta,
                              fontWeight: FontWeight.w700,
                              color: selected ? AppColors.white : AppColors.grey700,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Party size', style: TextStyle(fontSize: AppTypeScale.meta, fontWeight: FontWeight.w700, color: AppColors.grey600)),
                    const Spacer(),
                    IconButton(
                      onPressed: _partySize > 1 ? () => setState(() => _partySize--) : null,
                      icon: const Icon(LucideIcons.minus),
                      style: IconButton.styleFrom(minimumSize: const Size(AppTypeScale.minTapTarget, AppTypeScale.minTapTarget)),
                    ),
                    Text('$_partySize', style: const TextStyle(fontSize: AppTypeScale.title, fontWeight: FontWeight.w800)),
                    IconButton(
                      onPressed: () => setState(() => _partySize++),
                      icon: const Icon(LucideIcons.plus),
                      style: IconButton.styleFrom(minimumSize: const Size(AppTypeScale.minTapTarget, AppTypeScale.minTapTarget)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: tablesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => const Center(child: Text('Could not load tables.')),
              data: (tables) {
                if (tables.isEmpty) {
                  return const Center(child: Text('No tables set up here yet.', style: TextStyle(color: AppColors.grey500)));
                }
                final bookedIds = bookedAsync.valueOrNull ?? {};
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: tables.length,
                  itemBuilder: (context, i) {
                    final table = tables[i];
                    final isBooked = bookedIds.contains(table.id);
                    final isSelected = table.id == _selectedTableId;
                    return GestureDetector(
                      onTap: isBooked ? null : () => setState(() => _selectedTableId = table.id),
                      child: Column(
                        children: [
                          Expanded(
                            child: TableVisual(shape: table.shape, seatCount: table.seatCount, isBooked: isBooked, isSelected: isSelected),
                          ),
                          const SizedBox(height: 6),
                          Text('Table ${table.tableNumber}', style: const TextStyle(fontSize: AppTypeScale.meta, fontWeight: FontWeight.w800, color: AppColors.grey900)),
                          if (isBooked)
                            const Pill(label: 'Booked', background: AppColors.grey100, foreground: AppColors.grey500, dense: true)
                          else
                            Text('${table.seatCount} seats', style: const TextStyle(fontSize: AppTypeScale.caption, color: AppColors.grey500, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: AppTypeScale.minTapTarget,
                child: ElevatedButton(
                  onPressed: (_selectedTableId == null || _isBooking) ? null : _confirmReservation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.emerald600,
                    disabledBackgroundColor: AppColors.grey200,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isBooking
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : const Text('Reserve Table', style: TextStyle(fontSize: AppTypeScale.body, fontWeight: FontWeight.w800, color: Colors.white)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

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
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => ReservationConfirmedDialog(
            locationName: widget.location.name,
            tableNumber: tableNumber,
            date: _selectedDate,
            time: _selectedTime,
            partySize: _partySize,
          ),
        );
        if (mounted) Navigator.of(context).pop();
      }
    } on PostgrestException catch (e) {
      if (mounted) {
        final msg = e.message.contains('duplicate') ? 'That table was just booked by someone else — pick another.' : 'Could not complete the reservation.';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } finally {
      if (mounted) setState(() => _isBooking = false);
    }
  }
}

class _DateStrip extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onSelect;

  const _DateStrip({required this.selectedDate, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final days = List.generate(7, (i) => DateTime(today.year, today.month, today.day + i));
    const weekdayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return SizedBox(
      height: 68,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final d = days[i];
          final selected = d.year == selectedDate.year && d.month == selectedDate.month && d.day == selectedDate.day;
          return GestureDetector(
            onTap: () => onSelect(d),
            child: Container(
              width: 56,
              decoration: BoxDecoration(
                color: selected ? AppColors.emerald600 : AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: selected ? AppColors.emerald600 : AppColors.grey200),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(weekdayLabels[d.weekday - 1], style: TextStyle(fontSize: AppTypeScale.caption, fontWeight: FontWeight.w700, color: selected ? AppColors.white : AppColors.grey500)),
                  const SizedBox(height: 4),
                  Text('${d.day}', style: TextStyle(fontSize: AppTypeScale.title, fontWeight: FontWeight.w800, color: selected ? AppColors.white : AppColors.grey900)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Confirmation modal shown after a successful table reservation — replaces
/// the old bottom SnackBar, which was easy to miss and didn't carry the
/// booking details.
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
    const weekdayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final dateLabel = '${weekdayLabels[date.weekday - 1]}, ${date.month}/${date.day}';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(color: AppColors.emerald50, shape: BoxShape.circle),
              child: const Icon(LucideIcons.check, color: AppColors.emerald600, size: 36),
            ),
            const SizedBox(height: 20),
            const Text(
              'Table Reserved',
              style: TextStyle(fontSize: AppTypeScale.headline, fontWeight: FontWeight.w800, color: AppColors.grey900),
            ),
            const SizedBox(height: 6),
            Text(
              locationName,
              style: const TextStyle(fontSize: AppTypeScale.body, fontWeight: FontWeight.w600, color: AppColors.grey600),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.grey25, borderRadius: BorderRadius.circular(18)),
              child: Column(
                children: [
                  _DetailRow(icon: LucideIcons.calendar, label: 'Date', value: dateLabel),
                  const SizedBox(height: 10),
                  _DetailRow(icon: LucideIcons.clock, label: 'Time', value: time),
                  const SizedBox(height: 10),
                  _DetailRow(icon: LucideIcons.armchair, label: 'Table', value: tableNumber),
                  const SizedBox(height: 10),
                  _DetailRow(icon: LucideIcons.users, label: 'Party size', value: '$partySize'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: AppTypeScale.minTapTarget,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.emerald600,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Done', style: TextStyle(fontSize: AppTypeScale.body, fontWeight: FontWeight.w800, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.grey500),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(fontSize: AppTypeScale.meta, color: AppColors.grey500, fontWeight: FontWeight.w600)),
        const Spacer(),
        Text(value, style: const TextStyle(fontSize: AppTypeScale.body, color: AppColors.grey900, fontWeight: FontWeight.w800)),
      ],
    );
  }
}
