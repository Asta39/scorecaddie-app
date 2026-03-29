import 'dart:io';
import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as drift;
import 'database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = AppDatabase();
  await db.delete(db.reviews).go();
  
  final providers = await db.select(db.providers).get();
  for (var p in providers) {
     await (db.update(db.providers)..where((tbl) => tbl.userId.equals(p.userId))).write(
       const ProvidersCompanion(
         rating: drift.Value(0.0),
         totalReviews: drift.Value(0),
       ),
     );
  }
  
  print('Reviews cleared successfully');
  exit(0);
}
