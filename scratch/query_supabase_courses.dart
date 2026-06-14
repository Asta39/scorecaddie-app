import 'dart:io';
import 'package:supabase/supabase.dart';

void main() async {
  final envFile = File('.env');
  final lines = await envFile.readAsLines();
  final env = <String, String>{};
  for (final line in lines) {
    if (line.trim().isEmpty || line.startsWith('#')) continue;
    final parts = line.split('=');
    if (parts.length >= 2) {
      env[parts[0].trim()] = parts.sublist(1).join('=').trim();
    }
  }

  final supabaseUrl = env['SUPABASE_URL'];
  final supabaseKey = env['SUPABASE_ANON_KEY'];
  
  if (supabaseUrl == null || supabaseKey == null) {
    print('Missing environment variables.');
    exit(1);
  }

  print('Connecting to Supabase at $supabaseUrl...');
  final client = SupabaseClient(supabaseUrl, supabaseKey);

  try {
    // 1. Fetch courses
    print('\n--- Supabase Courses ---');
    final List<dynamic> courses = await client.from('Course').select('id, name, location, par18, holesCount');
    for (var c in courses) {
      final courseId = c['id'] as String;
      final name = c['name'] as String;
      
      // Count tees for this course
      final tees = await client.from('Tee').select('id, name').eq('courseId', courseId);
      final holes = await client.from('CourseHole').select('id, holeNumber').eq('courseId', courseId);
      
      print('Course: $name (id: $courseId, par18: ${c['par18']}, holesCount: ${c['holesCount']})');
      print('  Tees (${tees.length}): ${tees.map((t) => t['name']).toList()}');
      print('  Holes count: ${holes.length}');
    }
  } catch (e) {
    print('Error: $e');
  }
  exit(0);
}
