import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/notification_model.dart';
import '../../providers/app_providers.dart';

class NotificationService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final String? _uid;
  final FlutterLocalNotificationsPlugin _localNotifications;

  static bool _tzInitialized = false;

  NotificationService(this._uid)
    : _localNotifications = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    await _initTimezone();
    await _initLocalNotifications();
  }

  static Future<void> _initTimezone() async {
    if (!_tzInitialized) {
      tz.initializeTimeZones();
      _tzInitialized = true;
    }
  }

  Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      'ic_stat_onesignal_default',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _localNotifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );
  }



  /// Schedule a local notification for a tee time reminder.
  /// [reminderId] is used as the notification ID (for cancellation).
  /// [teeTime] is the actual tee time.
  /// [notifyBeforeMinutes] is how many minutes before the tee time to notify.
  /// [notes] is optional text to include in the notification.
  Future<void> scheduleTeeTimeReminder({
    required int reminderId,
    required DateTime teeTime,
    required int notifyBeforeMinutes,
    String? notes,
  }) async {
    await _initTimezone();

    final notifyAt = teeTime.subtract(Duration(minutes: notifyBeforeMinutes));

    // Don't schedule if the notification time has already passed
    if (notifyAt.isBefore(DateTime.now())) {
      debugPrint('TEE_REMINDER: Notification time already passed, skipping schedule');
      return;
    }

    final scheduledDate = tz.TZDateTime.from(notifyAt, tz.local);

    final body = notes != null && notes.isNotEmpty
        ? 'Note: $notes'
        : 'See you on the first tee!';

    try {
      await _localNotifications.zonedSchedule(
        reminderId, // Use local DB id as notification id
        'Tee off in $notifyBeforeMinutes minutes',
        body,
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'tee_time_reminders',
            'Tee Time Reminders',
            channelDescription: 'Notifications for upcoming tee times',
            importance: Importance.high,
            priority: Priority.high,
            icon: 'ic_stat_onesignal_default',
            largeIcon: DrawableResourceAndroidBitmap('ic_onesignal_large_icon_default'),
            color: Color(0xFFA3E635),
          ),
          iOS: DarwinNotificationDetails(
            sound: 'default',
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
      debugPrint('TEE_REMINDER: Scheduled local notification #$reminderId for $scheduledDate');
    } catch (e) {
      debugPrint('TEE_REMINDER: Failed to schedule notification: $e');
    }
  }

  /// Cancel a previously scheduled tee time reminder notification.
  Future<void> cancelTeeTimeReminder(int reminderId) async {
    try {
      await _localNotifications.cancel(reminderId);
      debugPrint('TEE_REMINDER: Cancelled local notification #$reminderId');
    } catch (e) {
      debugPrint('TEE_REMINDER: Failed to cancel notification: $e');
    }
  }

  /// The user's notifications, newest first.
  ///
  /// Realtime isn't enabled for the Notification table, so a realtime
  /// `.stream()` fails with RealtimeSubscribeException. This polls instead:
  /// once now, then every 30 seconds, and again right after a change here.
  Stream<List<AppNotification>> watchNotifications() {
    if (_uid == null) return Stream.value([]);
    late final StreamController<List<AppNotification>> c;
    Timer? timer;
    Future<void> load() async {
      try {
        final rows = await _supabase.from('Notification').select().eq('userId', _uid).order('createdAt', ascending: false).limit(100);
        if (!c.isClosed) c.add([for (final r in rows) AppNotification.fromSupabase(r)]);
      } catch (e) {
        debugPrint('NOTIFICATIONS: load failed: $e');
        if (!c.isClosed && !_loadedOnce) c.add(const []);
      }
      _loadedOnce = true;
    }

    void onPoke() => load();
    c = StreamController<List<AppNotification>>(
      onListen: () {
        load();
        timer = Timer.periodic(const Duration(seconds: 30), (_) => load());
        _pokes.add(onPoke);
      },
      onCancel: () {
        timer?.cancel();
        _pokes.remove(onPoke);
      },
    );
    return c.stream;
  }

  bool _loadedOnce = false;
  final _pokes = <void Function()>{};
  void _poke() {
    for (final p in [..._pokes]) {
      p();
    }
  }

  /// Whether anything is unread (the dot on the bell).
  Stream<bool> watchHasUnread() => watchNotifications().map((l) => l.any((n) => !n.read));

  Future<void> markAsRead(String notificationId) async {
    if (_uid == null) return;
    await _supabase
        .from('Notification')
        .update({'isRead': true})
        .eq('id', notificationId);
    _poke();
  }

  Future<void> markAllAsRead() async {
    if (_uid == null) return;
    await _supabase
        .from('Notification')
        .update({'isRead': true})
        .eq('userId', _uid)
        .eq('isRead', false);
    _poke();
  }

  Future<void> deleteNotification(String id) async {
    if (_uid == null) return;
    await _supabase.from('Notification').delete().eq('id', id);
    _poke();
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  final auth = ref.watch(authStateProvider).valueOrNull;
  return NotificationService(auth?.uid);
});

final unreadNotificationsProvider = StreamProvider<List<AppNotification>>((
  ref,
) {
  return ref.watch(notificationServiceProvider).watchNotifications();
});

final hasUnreadProvider = StreamProvider<bool>((ref) {
  return ref.watch(notificationServiceProvider).watchHasUnread();
});
