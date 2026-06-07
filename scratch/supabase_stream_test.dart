import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  print('Initializing Supabase...');
  await Supabase.initialize(
    url: 'https://qqvzklonfybticckpuvx.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFxdnprbG9uZnlidGljY2twdXZ4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzUyMTgzMTAsImV4cCI6MjA5MDc5NDMxMH0.SwTK7ZSdT1r4RjOBQIlKB6CVN6KUq9mBOpL4zRbMyog',
  );

  final supabase = Supabase.instance.client;

  print('Starting caddies stream...');
  try {
    final stream = supabase.from('caddies').stream(primaryKey: ['id']);
    
    // Listen to the stream for 5 seconds
    final subscription = stream.listen(
      (data) {
        print('STREAM DATA RECEIVED:');
        print('Number of caddies: ${data.length}');
        for (var c in data) {
          print('- ${c['name']} (Visible: ${c['is_marketplace_visible']}, Present: ${c['is_present']})');
        }
      },
      onError: (error) {
        print('STREAM ERROR: $error');
      },
      onDone: () {
        print('STREAM DONE');
      },
    );

    await Future.delayed(Duration(seconds: 5));
    await subscription.cancel();
    print('Stream test finished.');
  } catch (e) {
    print('Caught exception: $e');
  }
}
