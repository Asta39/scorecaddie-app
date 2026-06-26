import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';
import '../core/database/database.dart' as db;
import '../core/services/caddie_service.dart';
import '../core/models/booking_model.dart';
import 'auth_providers.dart';
import 'database_providers.dart';

final caddieServiceProvider = Provider<CaddieService>((ref) {
  return CaddieService();
});

final upcomingBookingsProvider = StreamProvider<List<BookingModel>>((ref) {
  return ref.watch(caddieServiceProvider).watchUpcomingBookings();
});

final caddieAllBookingsProvider = StreamProvider<List<BookingModel>>((ref) {
  return ref.watch(caddieServiceProvider).watchAllBookings();
});

final allProvidersProvider = StreamProvider<List<db.Provider>>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  
  final usersStream = supabase
      .from('User')
      .stream(primaryKey: ['id'])
      .inFilter('role', ['COACH', 'CADDIE']);

  final caddiesStream = Stream.fromFuture(
    supabase
        .from('caddies')
        .select('*, caddie_attendance(time_in, time_out, is_absent, date), clubs(name, caddies_about)')
        .then((data) => List<Map<String, dynamic>>.from(data as List))
  ).handleError((error) {
    print('SUPABASE ERROR fetching caddies: $error');
    return <Map<String, dynamic>>[];
  });

  return Rx.combineLatest2(
    usersStream,
    caddiesStream,
    (List<Map<String, dynamic>> usersList, List<Map<String, dynamic>> caddiesList) {
      final userProviders = usersList.map((data) {
        return db.Provider(
          id: 0,
          userId: data['id'],
          role: (data['role'] ?? 'COACH').toString().toUpperCase(),
          name: data['name'] ?? 'Provider',
          avatarUrl: data['avatarUrl'],
          phone: data['phone'] ?? '',
          whatsapp: data['whatsapp'],
          experience: data['experience'] ?? 0,
          coursesJson: data['coursesJson'] ?? '[]',
          specializationsJson: data['specializations'] ?? '[]',
          availabilityJson: data['availabilityJson'] ?? '{}',
          price: data['price'] != null ? (data['price'] is int ? (data['price'] as int).toDouble() : data['price']) : null,
          rating: data['rating'] != null ? (data['rating'] is int ? (data['rating'] as int).toDouble() : data['rating']) : 5.0,
          totalReviews: data['totalReviews'] ?? 0,
          totalBookings: data['totalBookings'] ?? 0,
          totalCalls: data['totalCalls'] ?? 0,
          isAvailable: data['isAvailable'] ?? true,
          profileComplete: data['profileComplete'] ?? false,
          certificationUrl: data['certificationUrl'],
          certificatesJson: data['certificatesJson'] ?? '[]',
          bio: data['bio'],
          personalityType: data['personalityType'],
          coachingLocation: data['coachingLocation'],
          coachingStylesJson: data['coachingStylesJson'],
          sessionTypesJson: data['sessionTypesJson'],
          hasCertification: data['hasCertification'] ?? false,
          certificationName: data['certificationName'],
          targetAudienceJson: data['targetAudienceJson'],
          views: data['views'] ?? 0,
          streak: data['streak'] ?? 0,
          createdAt: data['createdAt'] != null ? DateTime.tryParse(data['createdAt']) ?? DateTime.now() : DateTime.now(),
        );
      }).toList();

      final caddieProviders = caddiesList.map((data) {
        int experienceLvl = 0;
        if (data['experience_level'] == 'intermediate') experienceLvl = 5;
        if (data['experience_level'] == 'expert') experienceLvl = 10;
        
        bool isAvailable = false;
        if (data['caddie_attendance'] != null) {
          final attendanceList = List<dynamic>.from(data['caddie_attendance'] as List);
          final todayStr = DateTime.now().toIso8601String().substring(0, 10);
          final todayRecord = attendanceList.firstWhere(
            (a) => a['date'] == todayStr,
            orElse: () => null,
          );
          if (todayRecord != null) {
            isAvailable = todayRecord['time_in'] != null &&
                todayRecord['time_out'] == null &&
                todayRecord['is_absent'] != true;
          }
        }
        
        return db.Provider(
          id: 0,
          userId: data['id'],
          role: 'CADDIE',
          name: data['name'] ?? 'Caddie',
          avatarUrl: data['photo_url'],
          phone: data['phone'] ?? '',
          whatsapp: null,
          experience: experienceLvl,
          coursesJson: data['clubs'] != null && data['clubs']['name'] != null ? '["${data['clubs']['name']}"]' : '[]',
          specializationsJson: '[]',
          availabilityJson: '{}',
          price: null,
          rating: 5.0,
          totalReviews: 0,
          totalBookings: 0,
          totalCalls: 0,
          isAvailable: isAvailable,
          profileComplete: true,
          certificationUrl: null,
          certificatesJson: '[]',
          bio: data['clubs'] != null ? data['clubs']['caddies_about'] : null,
          personalityType: null,
          coachingLocation: null,
          coachingStylesJson: null,
          sessionTypesJson: null,
          hasCertification: false,
          certificationName: null,
          targetAudienceJson: null,
          views: data['views'] ?? 0,
          streak: 0,
          createdAt: data['created_at'] != null ? DateTime.tryParse(data['created_at']) ?? DateTime.now() : DateTime.now(),
        );
      }).toList();

      return [...userProviders, ...caddieProviders];
    }
  );
});

final specificProviderProvider = StreamProvider.family<db.Provider?, String>((ref, userId) {
  final supabase = ref.watch(supabaseClientProvider);
  
  final userStream = Stream.fromFuture(
    supabase
        .from('User')
        .select()
        .eq('id', userId)
  ).handleError((error) {
    return <dynamic>[];
  });

  final caddieStream = Stream.fromFuture(
    supabase
        .from('caddies')
        .select('*, caddie_attendance(time_in, time_out, is_absent, date), clubs(name, caddies_about)')
        .eq('id', userId)
  ).handleError((error) {
    print('SUPABASE ERROR fetching specific caddie: $error');
    return <dynamic>[];
  });

  return Rx.combineLatest2(
    userStream,
    caddieStream,
    (List<dynamic> usersRaw, List<dynamic> caddiesRaw) {
      final users = List<Map<String, dynamic>>.from(usersRaw);
      final caddies = List<Map<String, dynamic>>.from(caddiesRaw);
      
      if (users.isEmpty && caddies.isEmpty) return null;
      
      bool isUser = users.isNotEmpty;
      final data = isUser ? users.first : caddies.first;
      
      // We can't await inside this sync function directly, so we use a simplified count or 0 
      // The previous code used asyncMap which was messy with combineLatest. 
      // We'll leave totalBookings as 0 for now since this is primarily for displaying basic info
      
      if (isUser) {
        return db.Provider(
          id: 0,
          userId: data['id'],
          role: (data['role'] ?? 'COACH').toString().toUpperCase(),
          name: data['name'] ?? 'Provider',
          avatarUrl: data['avatarUrl'],
          phone: data['phone'] ?? '',
          whatsapp: data['whatsapp'],
          experience: int.tryParse(data['experience']?.toString() ?? '') ?? 0,
          coursesJson: data['coursesJson'] ?? '[]',
          specializationsJson: data['specializations'] ?? '[]',
          availabilityJson: data['availabilityJson'] ?? '{}',
          price: data['price'] != null ? (data['price'] is int ? (data['price'] as int).toDouble() : data['price']) : null,
          rating: data['rating'] != null ? (data['rating'] is int ? (data['rating'] as int).toDouble() : data['rating']) : 5.0,
          totalReviews: int.tryParse(data['totalReviews']?.toString() ?? '') ?? 0,
          totalBookings: int.tryParse(data['totalBookings']?.toString() ?? '') ?? 0, 
          totalCalls: int.tryParse(data['totalCalls']?.toString() ?? '') ?? 0,
          isAvailable: data['isAvailable'] ?? true,
          profileComplete: data['profileComplete'] ?? false,
          certificationUrl: data['certificationUrl'],
          certificatesJson: data['certificatesJson'] ?? '[]',
          bio: data['bio'],
          personalityType: data['personalityType'],
          coachingLocation: data['coachingLocation'],
          coachingStylesJson: data['coachingStylesJson'],
          sessionTypesJson: data['sessionTypesJson'],
          hasCertification: data['hasCertification'] ?? false,
          certificationName: data['certificationName'],
          targetAudienceJson: data['targetAudienceJson'],
          views: int.tryParse(data['views']?.toString() ?? '') ?? 0,
          streak: int.tryParse(data['streak']?.toString() ?? '') ?? 0,
          createdAt: data['createdAt'] != null ? DateTime.tryParse(data['createdAt']) ?? DateTime.now() : DateTime.now(),
        );
      } else {
        int experienceLvl = 0;
        if (data['experience_level'] == 'intermediate') experienceLvl = 5;
        if (data['experience_level'] == 'expert') experienceLvl = 10;
        
        bool isAvailable = false;
        if (data['caddie_attendance'] != null) {
          final attendanceList = List<dynamic>.from(data['caddie_attendance'] as List);
          final todayStr = DateTime.now().toIso8601String().substring(0, 10);
          final todayRecord = attendanceList.firstWhere(
            (a) => a['date'] == todayStr,
            orElse: () => null,
          );
          if (todayRecord != null) {
            isAvailable = todayRecord['time_in'] != null &&
                todayRecord['time_out'] == null &&
                todayRecord['is_absent'] != true;
          }
        }
        
        return db.Provider(
          id: 0,
          userId: data['id'],
          role: 'CADDIE',
          name: data['name'] ?? 'Caddie',
          avatarUrl: data['photo_url'],
          phone: data['phone'] ?? '',
          whatsapp: null,
          experience: experienceLvl,
          coursesJson: data['clubs'] != null && data['clubs']['name'] != null ? '["${data['clubs']['name']}"]' : '[]',
          specializationsJson: '[]',
          availabilityJson: '{}',
          price: null,
          rating: 5.0,
          totalReviews: 0,
          totalBookings: 0,
          totalCalls: 0,
          isAvailable: isAvailable,
          profileComplete: true,
          certificationUrl: null,
          certificatesJson: '[]',
          bio: data['clubs'] != null ? data['clubs']['caddies_about'] : null,
          personalityType: null,
          coachingLocation: null,
          coachingStylesJson: null,
          sessionTypesJson: null,
          hasCertification: false,
          certificationName: null,
          targetAudienceJson: null,
          views: data['views'] ?? 0,
          streak: 0,
          createdAt: data['created_at'] != null ? DateTime.tryParse(data['created_at']) ?? DateTime.now() : DateTime.now(),
        );
      }
    }
  );
});

final interactionsProvider = StreamProvider<List<db.Interaction>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value([]);
  return ref.watch(supabaseClientProvider)
      .from('interactions')
      .stream(primaryKey: ['id'])
      .eq('player_id', user.id)
      .order('timestamp', ascending: true)
      .map((list) {
        return list.map((data) => db.Interaction(
          id: data['id'] is int ? data['id'] : int.tryParse(data['id']?.toString() ?? '') ?? 0,
          playerId: data['player_id'],
          providerId: data['provider_id'],
          type: data['type'],
          status: data['status'] ?? 'pending',
          lastPromptedAt: data['lastPromptedAt'] != null ? DateTime.tryParse(data['lastPromptedAt']) : null,
          timestamp: data['timestamp'] != null ? DateTime.tryParse(data['timestamp']) ?? DateTime.now() : DateTime.now(),
        )).toList();
      });
});

final pendingInteractionsProvider = Provider<AsyncValue<List<db.Interaction>>>((ref) {
  final interactions = ref.watch(interactionsProvider);
  return interactions.whenData((list) => list.where((i) => i.status == 'pending').toList());
});

final recentProsProvider = StreamProvider<List<db.Provider>>((ref) {
  final interactions = ref.watch(interactionsProvider).valueOrNull ?? [];
  final bookedProviderIds = interactions
      .where((i) => i.status == 'booked')
      .map((i) => i.providerId)
      .toSet()
      .toList();
  
  if (bookedProviderIds.isEmpty) return Stream.value([]);
  
  final database = ref.watch(databaseProvider);
  return (database.select(database.providers)
        ..where((p) => p.userId.isIn(bookedProviderIds)))
      .watch();
});

final providerInteractionsProvider = StreamProvider<List<db.Interaction>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value([]);
  return ref.watch(supabaseClientProvider)
      .from('interactions')
      .stream(primaryKey: ['id'])
      .eq('provider_id', user.id)
      .order('timestamp', ascending: false)
      .map((list) {
        return list.map((data) => db.Interaction(
          id: data['id'] ?? 0,
          playerId: data['player_id'],
          providerId: data['provider_id'],
          type: data['type'],
          status: data['status'] ?? 'pending',
          lastPromptedAt: data['lastPromptedAt'] != null ? DateTime.tryParse(data['lastPromptedAt']) : null,
          timestamp: data['timestamp'] != null ? DateTime.tryParse(data['timestamp']) ?? DateTime.now() : DateTime.now(),
        )).toList();
      });
});

final providerReviewsProvider = StreamProvider.family<List<db.Review>, String>((ref, providerId) {
  return ref.watch(supabaseClientProvider)
      .from('Review')
      .stream(primaryKey: ['id'])
      .eq('provider_id', providerId)
      .order('createdAt', ascending: false)
      .map((list) {
        return list.map((data) => db.Review(
          id: data['id'] ?? 0,
          providerId: data['provider_id'],
          playerId: data['player_id'],
          playerName: data['player_name'] ?? 'Golfer',
          playerAvatar: data['player_avatar'],
          rating: data['rating'] ?? 5,
          comment: data['comment'] ?? '',
          createdAt: data['createdAt'] != null ? DateTime.tryParse(data['createdAt']) ?? DateTime.now() : DateTime.now(),
        )).toList();
      });
});

final currentProviderProvider = StreamProvider<db.Provider?>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value(null);
  
  return ref.watch(specificProviderProvider(user.id).stream);
});
