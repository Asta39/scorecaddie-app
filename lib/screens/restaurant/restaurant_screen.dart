import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/club_feed_provider.dart';
import '../../core/providers/restaurant_provider.dart';
import '../../widgets/pill.dart';
import '../../widgets/menu_pdf_card.dart';
import 'table_reservation_screen.dart';

/// Player-facing Restaurant tab: browse the club's menu, or reserve a table.
/// Scoped to the player's active club — no payment/delivery yet, reservation
/// only, per current phase.
class RestaurantScreen extends ConsumerStatefulWidget {
  const RestaurantScreen({super.key});

  @override
  ConsumerState<RestaurantScreen> createState() => _RestaurantScreenState();
}

class _RestaurantScreenState extends ConsumerState<RestaurantScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeClub = ref.watch(activeClubProvider);

    return Scaffold(
      backgroundColor: AppColors.grey25,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: Text(
          activeClub?.clubName ?? 'Restaurant',
          style: const TextStyle(fontSize: AppTypeScale.title, fontWeight: FontWeight.w800, color: AppColors.grey900),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.emerald700,
          unselectedLabelColor: AppColors.grey500,
          indicatorColor: AppColors.emerald600,
          labelStyle: const TextStyle(fontSize: AppTypeScale.body, fontWeight: FontWeight.w700),
          tabs: const [
            Tab(text: 'Menu'),
            Tab(text: 'Reserve a Table'),
          ],
        ),
      ),
      body: activeClub == null
          ? const Center(child: Text('Join a club to view its restaurant.'))
          : TabBarView(
              controller: _tabController,
              children: [
                _MenuTab(clubId: activeClub.clubId),
                _ReserveTab(clubId: activeClub.clubId),
              ],
            ),
    );
  }
}

class _MenuTab extends ConsumerWidget {
  final String clubId;
  const _MenuTab({required this.clubId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menuAsync = ref.watch(clubMenuProvider(clubId));
    final docsAsync = ref.watch(clubMenuDocumentsProvider(clubId));

    return menuAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => const Center(child: Text('Could not load the menu.')),
      data: (items) {
        final docs = docsAsync.valueOrNull ?? [];
        if (items.isEmpty && docs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('No menu has been published yet.', style: TextStyle(color: AppColors.grey500, fontSize: AppTypeScale.body)),
            ),
          );
        }
        const categoryOrder = ['starter', 'main', 'special', 'dessert', 'drink'];
        final byCategory = <String, List<MenuItem>>{};
        for (final item in items) {
          byCategory.putIfAbsent(item.category, () => []).add(item);
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (docs.isNotEmpty) ...[
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.62,
                ),
                itemCount: docs.length,
                itemBuilder: (context, i) => MenuPdfCard(document: docs[i]),
              ),
              const SizedBox(height: 12),
            ],
            for (final cat in categoryOrder)
              if (byCategory[cat]?.isNotEmpty == true) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 8, left: 4),
                  child: Text(
                    _categoryLabel(cat),
                    style: const TextStyle(fontSize: AppTypeScale.title, fontWeight: FontWeight.w800, color: AppColors.grey900),
                  ),
                ),
                for (final item in byCategory[cat]!) _MenuItemCard(item: item),
              ],
          ],
        );
      },
    );
  }

  String _categoryLabel(String cat) {
    switch (cat) {
      case 'starter':
        return 'Starters';
      case 'main':
        return 'Mains';
      case 'special':
        return "Chef's Specials";
      case 'dessert':
        return 'Desserts';
      case 'drink':
        return 'Drinks';
      default:
        return cat;
    }
  }
}

class _MenuItemCard extends StatelessWidget {
  final MenuItem item;
  const _MenuItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        item.name,
                        style: const TextStyle(fontSize: AppTypeScale.subtitle, fontWeight: FontWeight.w800, color: AppColors.grey900),
                      ),
                    ),
                    if (item.isNew) ...[
                      const SizedBox(width: 8),
                      const Pill(label: 'New', background: AppColors.emerald100, foreground: AppColors.emerald700, dense: true),
                    ],
                  ],
                ),
                if (item.description != null && item.description!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    item.description!,
                    style: const TextStyle(fontSize: AppTypeScale.meta, color: AppColors.grey600, fontWeight: FontWeight.w500),
                  ),
                ],
                if (item.chefName != null && item.chefName!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(LucideIcons.chefHat, size: 15, color: AppColors.grey500),
                      const SizedBox(width: 5),
                      Text('Chef ${item.chefName}', style: const TextStyle(fontSize: AppTypeScale.caption, color: AppColors.grey500, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (item.priceKes != null) ...[
            const SizedBox(width: 12),
            Text(
              'KES ${item.priceKes!.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: AppTypeScale.body, fontWeight: FontWeight.w800, color: AppColors.emerald700),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReserveTab extends ConsumerWidget {
  final String clubId;
  const _ReserveTab({required this.clubId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationsAsync = ref.watch(restaurantLocationsProvider(clubId));

    return locationsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => const Center(child: Text('Could not load locations.')),
      data: (locations) {
        if (locations.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('No bookable dining areas yet.', style: TextStyle(color: AppColors.grey500, fontSize: AppTypeScale.body)),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: locations.length,
          itemBuilder: (context, i) {
            final loc = locations[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.grey200),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(color: AppColors.emerald50, borderRadius: BorderRadius.circular(14)),
                  child: const Icon(LucideIcons.utensils, color: AppColors.emerald700),
                ),
                title: Text(loc.name, style: const TextStyle(fontSize: AppTypeScale.body, fontWeight: FontWeight.w800, color: AppColors.grey900)),
                trailing: const Icon(LucideIcons.chevronRight, color: AppColors.grey400),
                minVerticalPadding: 16,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => TableReservationScreen(clubId: clubId, location: loc)),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
