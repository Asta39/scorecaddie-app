import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'app.dart';
import 'core/config/app_config.dart';
import 'core/database/database.dart';
import 'core/database/seed_courses.dart';
import 'providers/app_providers.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  await dotenv.load(fileName: '.env');

  if (dotenv.env['ONESIGNAL_APP_ID'] != null) {
    OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
    OneSignal.initialize(dotenv.env['ONESIGNAL_APP_ID']!);
    OneSignal.Notifications.requestPermission(true);
  }

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
