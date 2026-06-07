// lib/core/services/fcm_token_service.dart

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class FCMTokenService {
  static Future<void> initialize() async {
    try {
      final fcm = FirebaseMessaging.instance;
      
      // Request permission for iOS/macOS
      NotificationSettings settings = await fcm.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('FCM: User granted notification permission');
      }

      final token = await fcm.getToken();
      if (token != null) {
        await _saveTokenToSupabase(token);
      }

      // Listen to token refresh
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        _saveTokenToSupabase(newToken);
      });
    } catch (e) {
      debugPrint('FCM: Failed to get token (Firebase may not be initialized yet): $e');
    }
  }

  static Future<void> _saveTokenToSupabase(String token) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      await Supabase.instance.client
        .from('User')
        .update({'fcmToken': token})
        .eq('id', user.id);
      debugPrint('FCM: Token saved successfully to User profile');
    } catch (e) {
      debugPrint('FCM: Failed to save token: $e');
    }
  }

  // Call this when user logs in
  static Future<void> onUserLogin() async {
    await initialize();
  }

  // Call this when user logs out
  static Future<void> onUserLogout() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      await Supabase.instance.client
        .from('User')
        .update({'fcmToken': null})
        .eq('id', user.id);
      debugPrint('FCM: Token cleared successfully');
    } catch (e) {
      debugPrint('FCM: Failed to clear token: $e');
    }
  }
}