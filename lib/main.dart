import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'app.dart';
import 'core/config/app_config.dart';
import 'core/database/database.dart';
import 'core/database/seed_courses.dart';
import 'providers/app_providers.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('FCM: Background message received: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint('Firebase: Initialization failed. Check config files: $e');
  }
  await dotenv.load(fileName: '.env');

  // Initialize Supabase with deep link auth callback support
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  // Seed courses and drills into local database
  final db = AppDatabase();
  await seedCourses(db);
  await db.syncPrimaryDrills();

  // Initialization logic
  // (Note: Removed temporary admin role override that was forcing ianlove472@gmail.com to Player)

  runApp(
    ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: const ScoreCaddieApp(),
    ),
  );
}
