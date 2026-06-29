import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:drift/drift.dart' show Value, OrderingTerm;
import '../../core/theme/app_theme.dart';
import '../../providers/app_providers.dart';
import '../../core/database/database.dart';
import '../../core/services/notification_service.dart';

class TeeTimeRemindersScreen extends ConsumerStatefulWidget {
  const TeeTimeRemindersScreen({super.key});

  @override
  ConsumerState<TeeTimeRemindersScreen> createState() => _TeeTimeRemindersScreenState();
}

class _TeeTimeRemindersScreenState extends ConsumerState<TeeTimeRemindersScreen> with SingleTickerProviderStateMixin {
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
        title: const Text('Tee Time Reminders', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: AppColors.grey900)),
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
          _UpcomingRemindersTab(),
          _PastRemindersTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.golfLime,
        foregroundColor: AppColors.grey900,
        onPressed: () => _showCreateReminderSheet(context),
        icon: const Icon(LucideIcons.plus),
        label: const Text('Add Reminder', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
    );
  }

  void _showCreateReminderSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _CreateReminderSheet(),
    );
  }
}

class _UpcomingRemindersTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remindersAsync = ref.watch(teeTimeRemindersProvider);
    
    return remindersAsync.when(
      data: (reminders) {
        final upcoming = reminders.where((r) => r.reminderDate.isAfter(DateTime.now())).toList();
        if (upcoming.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.bellOff, size: 64, color: AppColors.grey200),
                const SizedBox(height: 16),
                Text('No upcoming reminders', style: TextStyle(fontSize: 16, color: AppColors.grey500, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Text('Tap + to create one', style: TextStyle(fontSize: 14, color: AppColors.grey400)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: upcoming.length,
          itemBuilder: (context, index) {
            final reminder = upcoming[index];
            return Dismissible(
              key: Key('upcoming_reminder_${reminder.id}'),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(LucideIcons.trash2, color: Colors.white),
              ),
              confirmDismiss: (direction) async {
                final confirmed = await _showDeleteConfirmation(context);
                if (confirmed == true) {
                  try {
                    await _deleteReminder(ref, reminder);
                  } catch (e) {
                    debugPrint('TEE_REMINDER: Delete error: $e');
                  }
                  return true;
                }
                return false;
              },
              onDismissed: (direction) {
                ref.invalidate(teeTimeRemindersProvider);
              },
              child: _ReminderCard(reminder: reminder),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }
}

class _PastRemindersTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remindersAsync = ref.watch(teeTimeRemindersProvider);
    
    return remindersAsync.when(
      data: (reminders) {
        final past = reminders.where((r) => r.reminderDate.isBefore(DateTime.now())).toList();
        if (past.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.history, size: 64, color: AppColors.grey200),
                const SizedBox(height: 16),
                Text('No past reminders', style: TextStyle(fontSize: 16, color: AppColors.grey500, fontWeight: FontWeight.w500)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: past.length,
          itemBuilder: (context, index) {
            final reminder = past[index];
            return Dismissible(
              key: Key('past_reminder_${reminder.id}'),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(LucideIcons.trash2, color: Colors.white),
              ),
              confirmDismiss: (direction) async {
                final confirmed = await _showDeleteConfirmation(context);
                if (confirmed == true) {
                  try {
                    await _deleteReminder(ref, reminder);
                  } catch (e) {
                    debugPrint('TEE_REMINDER: Delete error: $e');
                  }
                  return true;
                }
                return false;
              },
              onDismissed: (direction) {
                ref.invalidate(teeTimeRemindersProvider);
              },
              child: _ReminderCard(reminder: reminder),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final TeeTimeReminder reminder;
  const _ReminderCard({required this.reminder});

  @override
  Widget build(BuildContext context) {
    final isPast = reminder.reminderDate.isBefore(DateTime.now());
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isPast ? AppColors.grey100 : AppColors.golfLime.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(LucideIcons.calendar, color: isPast ? AppColors.grey400 : AppColors.grey900, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(DateFormat('EEE, MMM d, yyyy').format(reminder.reminderDate), 
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.grey900)),
                    Text(DateFormat('h:mm a').format(reminder.reminderDate), 
                      style: TextStyle(fontSize: 14, color: AppColors.grey500, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              Text('${reminder.notifyBeforeMinutes} min before', 
                style: TextStyle(fontSize: 12, color: AppColors.grey400, fontWeight: FontWeight.w600)),
            ],
          ),
          if (reminder.notes != null && reminder.notes!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.grey50, borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  const Icon(LucideIcons.stickyNote, size: 16, color: AppColors.grey400),
                  const SizedBox(width: 8),
                  Expanded(child: Text(reminder.notes!, style: TextStyle(fontSize: 14, color: AppColors.grey600))),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CreateReminderSheet extends ConsumerStatefulWidget {
  const _CreateReminderSheet();

  @override
  ConsumerState<_CreateReminderSheet> createState() => _CreateReminderSheetState();
}

class _CreateReminderSheetState extends ConsumerState<_CreateReminderSheet> {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 8, minute: 0);
  int _notifyMinutes = 30;
  final _notesController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                const Text('New Reminder', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                TextButton(
                  onPressed: _saveReminder,
                  child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.emerald700)),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('DATE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.grey400, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) setState(() => _selectedDate = date);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: AppColors.grey50, borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.calendar, color: AppColors.grey400),
                          const SizedBox(width: 12),
                          Text(DateFormat('EEE, MMM d, yyyy').format(_selectedDate), 
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('TIME', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.grey400, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () async {
                      final time = await showTimePicker(context: context, initialTime: _selectedTime);
                      if (time != null) setState(() => _selectedTime = time);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: AppColors.grey50, borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.clock, color: AppColors.grey400),
                          const SizedBox(width: 12),
                          Text(_selectedTime.format(context), 
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('NOTIFY BEFORE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.grey400, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [15, 30, 60, 120].map((mins) => ChoiceChip(
                      label: Text('$mins min'),
                      selected: _notifyMinutes == mins,
                      onSelected: (selected) => setState(() => _notifyMinutes = mins),
                      selectedColor: AppColors.golfLime,
                    )).toList(),
                  ),
                  const SizedBox(height: 24),
                  const Text('NOTES (OPTIONAL)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.grey400, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Add notes for your reminder...',
                      hintStyle: TextStyle(color: AppColors.grey300),
                      filled: true,
                      fillColor: AppColors.grey50,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _saveReminder() async {
    final reminderDate = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, _selectedTime.hour, _selectedTime.minute);
    final db = ref.read(databaseProvider);
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;

    // Save to local Drift database
    final id = await db.into(db.teeTimeReminders).insert(TeeTimeRemindersCompanion.insert(
      userId: user.uid,
      reminderDate: reminderDate,
      notifyBeforeMinutes: Value(_notifyMinutes),
      notes: Value(_notesController.text.isEmpty ? null : _notesController.text),
    ));

    // Schedule a local device notification
    final notificationService = ref.read(notificationServiceProvider);
    await notificationService.scheduleTeeTimeReminder(
      reminderId: id,
      teeTime: reminderDate,
      notifyBeforeMinutes: _notifyMinutes,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
    );

    // Sync to Supabase for cross-device access and push notifications
    try {
      final supabase = Supabase.instance.client;
      await supabase.from('tee_time_reminder').upsert({
        'local_id': id,
        'user_id': user.uid,
        'reminder_date': reminderDate.toUtc().toIso8601String(),
        'notify_before_minutes': _notifyMinutes,
        'notes': _notesController.text.isEmpty ? null : _notesController.text,
        'is_active': true,
      }, onConflict: 'user_id,local_id');
    } catch (e) {
      debugPrint('TEE_REMINDER: Supabase sync failed: $e');
    }

    ref.invalidate(teeTimeRemindersProvider);
    if (mounted) Navigator.pop(context);
  }
}

Future<bool?> _showDeleteConfirmation(BuildContext context) async {
  return showCupertinoDialog<bool>(
    context: context,
    builder: (context) => CupertinoAlertDialog(
      title: const Text('Delete Reminder'),
      content: const Text('Are you sure you want to delete this tee time reminder?'),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        CupertinoDialogAction(
          isDestructiveAction: true,
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
}

Future<void> _deleteReminder(WidgetRef ref, TeeTimeReminder reminder) async {
  final db = ref.read(databaseProvider);
  final user = ref.read(authStateProvider).valueOrNull;

  // 1. Cancel the scheduled local notification
  final notificationService = ref.read(notificationServiceProvider);
  await notificationService.cancelTeeTimeReminder(reminder.id);

  // 2. Delete locally
  await (db.delete(db.teeTimeReminders)..where((t) => t.id.equals(reminder.id))).go();

  // 3. Delete remotely from Supabase
  if (user != null) {
    try {
      final supabase = Supabase.instance.client;
      await supabase
          .from('tee_time_reminder')
          .delete()
          .eq('local_id', reminder.id)
          .eq('user_id', user.uid);
    } catch (e) {
      debugPrint('TEE_REMINDER: Failed to delete remote reminder: $e');
    }
  }
  // Note: invalidation is handled by the caller after the frame completes
}

class TeeTimeReminder {
  final int id;
  final String userId;
  final DateTime reminderDate;
  final int notifyBeforeMinutes;
  final String? notes;

  TeeTimeReminder({required this.id, required this.userId, required this.reminderDate, required this.notifyBeforeMinutes, this.notes});
}

final teeTimeRemindersProvider = FutureProvider<List<TeeTimeReminder>>((ref) async {
  final db = ref.watch(databaseProvider);
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return [];

  // Try to pull and sync reminders from Supabase
  try {
    final supabase = Supabase.instance.client;
    final response = await supabase
        .from('tee_time_reminder')
        .select()
        .eq('user_id', user.uid)
        .eq('is_active', true);

    for (final row in response) {
      final localId = row['local_id'] as int?;
      if (localId == null) continue;

      final reminderDate = DateTime.parse(row['reminder_date'] as String).toLocal();
      final notifyBeforeMinutes = row['notify_before_minutes'] as int;
      final notes = row['notes'] as String?;

      // Check if a local row with this id already belongs to a DIFFERENT user.
      // If so, skip — never overwrite another account's data.
      final existing = await (db.select(db.teeTimeReminders)
            ..where((t) => t.id.equals(localId)))
          .getSingleOrNull();

      if (existing != null && existing.userId != user.uid) {
        // Conflict: same local id, different user — insert as new row instead
        await db.into(db.teeTimeReminders).insertOnConflictUpdate(
          TeeTimeRemindersCompanion(
            userId: Value(user.uid),
            reminderDate: Value(reminderDate),
            notifyBeforeMinutes: Value(notifyBeforeMinutes),
            notes: Value(notes),
          ),
        );
      } else {
        await db.into(db.teeTimeReminders).insertOnConflictUpdate(
          TeeTimeRemindersCompanion(
            id: Value(localId),
            userId: Value(user.uid),
            reminderDate: Value(reminderDate),
            notifyBeforeMinutes: Value(notifyBeforeMinutes),
            notes: Value(notes),
          ),
        );
      }
    }
  } catch (e) {
    debugPrint('TEE_REMINDER: Sync pull failed: $e');
  }

  final reminders = await (db.select(db.teeTimeReminders)
        ..where((t) => t.userId.equals(user.uid))
        ..orderBy([(t) => OrderingTerm.desc(t.reminderDate)]))
      .get();

  return reminders.map((r) => TeeTimeReminder(
    id: r.id,
    userId: r.userId,
    reminderDate: r.reminderDate,
    notifyBeforeMinutes: r.notifyBeforeMinutes,
    notes: r.notes,
  )).toList();
});