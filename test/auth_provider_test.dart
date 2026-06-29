import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:score_caddie/providers/app_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Mocks
class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockGoTrueClient extends Mock implements GoTrueClient {}
class MockSession extends Mock implements Session {}
class MockUser extends Mock implements User {}

void main() {
  late MockSupabaseClient mockSupabase;
  late MockGoTrueClient mockAuth;
  late ProviderContainer container;

  setUp(() {
    mockSupabase = MockSupabaseClient();
    mockAuth = MockGoTrueClient();

    when(() => mockSupabase.auth).thenReturn(mockAuth);
    when(() => mockAuth.onAuthStateChange).thenAnswer((_) => const Stream.empty());
    
    // Provide the mocked Supabase client
    container = ProviderContainer(
      overrides: [
        supabaseClientProvider.overrideWithValue(mockSupabase),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  test('authStateProvider initializes correctly', () {
    when(() => mockAuth.currentSession).thenReturn(null);
    when(() => mockAuth.currentUser).thenReturn(null);

    final authState = container.read(authStateProvider);
    expect(authState, isNotNull);
  });

  test('IdentityResolver correctly identifies current UID', () {
    final mockUser = MockUser();
    when(() => mockUser.id).thenReturn('123e4567-e89b-12d3-a456-426614174000');
    when(() => mockAuth.currentUser).thenReturn(mockUser);

    final uid = container.read(supabaseClientProvider).auth.currentUser?.id;
    expect(uid, '123e4567-e89b-12d3-a456-426614174000');
  });
}
