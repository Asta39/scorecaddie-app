import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'app.dart';
import 'core/database/database.dart';
import 'core/database/seed_courses.dart';
import 'firebase_options.dart';
import 'providers/app_providers.dart';
import 'core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Seed courses and drills into local database
  final db = AppDatabase();
  await seedCourses(db);
  await db.syncPrimaryDrills();

  // Initialize Notifications
  final notificationService = NotificationService();
  await notificationService.init();

  // --- Temporary Admin/Cleanup Block ---
  try {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      if (currentUser.email == 'ianlove472@gmail.com') {
        print('ADMIN: Found primary user. Forcing role to Player and completing profile.');
        await db.upsertProfile(UserProfilesCompanion(
          firebaseUid: drift.Value(currentUser.uid),
          name: drift.Value(currentUser.displayName ?? 'Ian'),
          role: const drift.Value('player'),
          profileComplete: const drift.Value(true),
          updatedAt: drift.Value(DateTime.now()),
        ));
      }
      // Note: Removed the "else" branch that was deleting all non-admin profiles.
      // That was preventing new users from keeping their profiles across restarts.
    }
  } catch (e) {
    print('ADMIN: Cleanup error: $e');
  }
  // -------------------------------------

  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
      ],
      child: const ScoreCaddieApp(),
    ),
  );
}
