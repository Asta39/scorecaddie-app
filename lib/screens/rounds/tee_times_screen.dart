import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/booking_providers.dart';
import '../../core/utils/course_logo_helper.dart';

class TeeTimesScreen extends ConsumerStatefulWidget {
  const TeeTimesScreen({super.key});

  @override
  ConsumerState<TeeTimesScreen> createState() => _TeeTimesScreenState();
}

class _TeeTimesScreenState extends ConsumerState<TeeTimesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey25,
      appBar: AppBar(
        backgroundColor: AppColors.grey25,
        elevation: 0,
        title: const Text('Tee Times', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: AppColors.grey900)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.grey900,
          unselectedLabelColor: AppColors.grey500,
          indicatorColor: AppColors.golfLime,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Past'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _TeeTimesTab(isUpcoming: true),
          _TeeTimesTab(isUpcoming: false),
        ],
      ),
    );
  }
}

class _TeeTimesTab extends ConsumerWidget {
  final bool isUpcoming;

  const _TeeTimesTab({required this.isUpcoming});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teeTimesAsync = ref.watch(casualTeeTimeBookingsProvider);
    
    return teeTimesAsync.when(
      data: (bookings) {
        final filteredBookings = bookings.where((b) {
          final bDate = b.bookingDate;
          final timeParts = b.teeTime.split(':');
          final dt = DateTime(bDate.year, bDate.month, bDate.day, int.parse(timeParts[0]), int.parse(timeParts[1]));
          return isUpcoming ? dt.isAfter(DateTime.now()) : dt.isBefore(DateTime.now());
        }).toList();

        if (filteredBookings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(isUpcoming ? LucideIcons.calendar : LucideIcons.history, size: 64, color: AppColors.grey200),
                const SizedBox(height: 16),
                Text(isUpcoming ? 'No upcoming tee times' : 'No past tee times', 
                  style: const TextStyle(fontSize: 16, color: AppColors.grey500, fontWeight: FontWeight.w500)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: filteredBookings.length,
          itemBuilder: (context, index) {
            final booking = filteredBookings[index];
            return _TeeTimeCard(booking: booking, isUpcoming: isUpcoming);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.golfLime)),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }
}

class _TeeTimeCard extends StatelessWidget {
  final CasualTeeTimeBooking booking;
  final bool isUpcoming;

  const _TeeTimeCard({required this.booking, required this.isUpcoming});

  @override
  Widget build(BuildContext context) {
    final logoPath = CourseLogoHelper.getLogoAssetPath(booking.courseName);
    final timeParts = booking.teeTime.split(':');
    final dt = DateTime(booking.bookingDate.year, booking.bookingDate.month, booking.bookingDate.day, int.parse(timeParts[0]), int.parse(timeParts[1]));

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.grey100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: logoPath != null ? Colors.white : AppColors.emerald50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.grey100),
                ),
                child: logoPath != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(11),
                        child: Image.asset(logoPath, fit: BoxFit.cover, errorBuilder: (c, _, __) => _fallbackIcon()),
                      )
                    : _fallbackIcon(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(booking.courseId.replaceAll('-', ' ').toUpperCase(), 
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.grey900)),
                    const SizedBox(height: 2),
                    Text('${DateFormat('EEE, MMM d, yyyy').format(dt)} at ${DateFormat('h:mm a').format(dt)}', 
                      style: const TextStyle(fontSize: 14, color: AppColors.grey500, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              if (booking.status == 'CANCELLED')
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: const Text('CANCELLED', style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.w900)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _fallbackIcon() {
    return const Center(child: Icon(Icons.golf_course_rounded, color: AppColors.emerald700, size: 20));
  }
}
