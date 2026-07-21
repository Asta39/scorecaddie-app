import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RestaurantLocation {
  final String id;
  final String name;
  final bool isBookable;

  RestaurantLocation({required this.id, required this.name, required this.isBookable});

  factory RestaurantLocation.fromJson(Map<String, dynamic> json) => RestaurantLocation(
        id: json['id'],
        name: json['name'],
        isBookable: json['is_bookable'] ?? true,
      );
}

class RestaurantTable {
  final String id;
  final String locationId;
  final String tableNumber;
  final String shape;
  final int seatCount;

  RestaurantTable({
    required this.id,
    required this.locationId,
    required this.tableNumber,
    required this.shape,
    required this.seatCount,
  });

  factory RestaurantTable.fromJson(Map<String, dynamic> json) => RestaurantTable(
        id: json['id'],
        locationId: json['location_id'],
        tableNumber: json['table_number'],
        shape: json['shape'],
        seatCount: json['seat_count'],
      );
}

class MenuItem {
  final String id;
  final String name;
  final String? description;
  final String category;
  final double? priceKes;
  final String? chefName;
  final String? photoUrl;
  final bool isNew;

  MenuItem({
    required this.id,
    required this.name,
    this.description,
    required this.category,
    this.priceKes,
    this.chefName,
    this.photoUrl,
    required this.isNew,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) => MenuItem(
        id: json['id'],
        name: json['name'],
        description: json['description'],
        category: json['category'],
        priceKes: (json['price_kes'] as num?)?.toDouble(),
        chefName: json['chef_name'],
        photoUrl: json['photo_url'],
        isNew: json['is_new'] ?? false,
      );
}

final restaurantLocationsProvider =
    FutureProvider.autoDispose.family<List<RestaurantLocation>, String>((ref, clubId) async {
  final supabase = Supabase.instance.client;
  final response = await supabase
      .from('club_restaurant_locations')
      .select('id, name, is_bookable')
      .eq('club_id', clubId)
      .eq('is_bookable', true)
      .order('sort_order');
  return (response as List).map((r) => RestaurantLocation.fromJson(r)).toList();
});

final restaurantTablesProvider =
    FutureProvider.autoDispose.family<List<RestaurantTable>, String>((ref, locationId) async {
  final supabase = Supabase.instance.client;
  final response = await supabase
      .from('club_restaurant_tables')
      .select('id, location_id, table_number, shape, seat_count')
      .eq('location_id', locationId)
      .eq('is_active', true)
      .order('table_number');
  return (response as List).map((r) => RestaurantTable.fromJson(r)).toList();
});

class MenuDocument {
  final String id;
  final String name;
  final String pdfUrl;

  MenuDocument({required this.id, required this.name, required this.pdfUrl});

  factory MenuDocument.fromJson(Map<String, dynamic> json) {
    final path = json['pdf_path'] as String;
    final url = Supabase.instance.client.storage.from('menu-pdfs').getPublicUrl(path);
    return MenuDocument(id: json['id'], name: json['name'], pdfUrl: url);
  }
}

final clubMenuDocumentsProvider =
    FutureProvider.autoDispose.family<List<MenuDocument>, String>((ref, clubId) async {
  final supabase = Supabase.instance.client;
  final response = await supabase
      .from('club_menu_documents')
      .select('id, name, pdf_path')
      .eq('club_id', clubId)
      .order('sort_order');
  return (response as List).map((r) => MenuDocument.fromJson(r)).toList();
});

final clubMenuProvider = FutureProvider.autoDispose.family<List<MenuItem>, String>((ref, clubId) async {
  final supabase = Supabase.instance.client;
  final response = await supabase
      .from('club_menu_items')
      .select('id, name, description, category, price_kes, chef_name, photo_url, is_new')
      .eq('club_id', clubId)
      .eq('is_available', true)
      .order('sort_order');
  return (response as List).map((r) => MenuItem.fromJson(r)).toList();
});

class ReservationSlotParams {
  final String locationId;
  final DateTime date;
  final String time;

  ReservationSlotParams({required this.locationId, required this.date, required this.time});

  @override
  bool operator ==(Object other) =>
      other is ReservationSlotParams &&
      other.locationId == locationId &&
      other.date.year == date.year &&
      other.date.month == date.month &&
      other.date.day == date.day &&
      other.time == time;

  @override
  int get hashCode => Object.hash(locationId, date.year, date.month, date.day, time);
}

/// Table ids already confirmed-booked for a given location/date/time slot.
final bookedTableIdsProvider =
    FutureProvider.autoDispose.family<Set<String>, ReservationSlotParams>((ref, params) async {
  final supabase = Supabase.instance.client;
  final dateStr =
      '${params.date.year}-${params.date.month.toString().padLeft(2, '0')}-${params.date.day.toString().padLeft(2, '0')}';
  final response = await supabase
      .from('club_restaurant_reservations')
      .select('table_id, club_restaurant_tables!inner(location_id)')
      .eq('club_restaurant_tables.location_id', params.locationId)
      .eq('reservation_date', dateStr)
      .eq('reservation_time', params.time)
      .eq('status', 'confirmed');
  return (response as List).map((r) => r['table_id'] as String).toSet();
});
