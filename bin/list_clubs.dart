import 'package:supabase/supabase.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  await dotenv.load(fileName: ".env");
  final supabase = SupabaseClient(
    dotenv.env['SUPABASE_URL']!,
    dotenv.env['SUPABASE_ANON_KEY']!,
  );

  final res = await supabase.from('clubs').select('*');
  print('Total clubs: ${res.length}');
  for (var club in res) {
    print('${club['name']}');
  }
}
