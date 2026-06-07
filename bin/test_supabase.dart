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
    print('Missing environment variables. Check .env file');
    exit(1);
  }

  print('Initializing Supabase...');
  final client = SupabaseClient(supabaseUrl, supabaseKey);

  print('Authenticating as test user (player1@example.com)...');
  try {
    final authRes = await client.auth.signInWithPassword(
      email: 'player1@example.com',
      password: 'password123'
    );
    print('Logged in successfully as: ${authRes.user?.email}');
    
    print('\nTesting FriendCode query (unquoted)...');
    try {
      final res1 = await client.from('User').select('id, name, friendCode').eq('friendCode', 'SC-TEST-1234').limit(1);
      print('Unquoted query result: $res1');
    } catch(e) {
      print('Unquoted query failed: $e');
    }

    print('\nTesting FriendCode query (quoted)...');
    try {
      final res2 = await client.from('User').select('id, name, friendCode').eq('"friendCode"', 'SC-TEST-1234').limit(1);
      print('Quoted query result: $res2');
    } catch(e) {
      print('Quoted query failed: $e');
    }

    print('\nTesting all users...');
    final allUsers = await client.from('User').select('id, name, friendCode').limit(3);
    print('All users result: $allUsers');

  } catch(e) {
    print('Auth or query failed: $e');
  }

  exit(0);
}
