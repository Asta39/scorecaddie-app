import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/providers/club_feed_provider.dart';
import '../../core/providers/restaurant_provider.dart';
import '../onboarding/ob_app.dart';
import '../onboarding/ob_forms.dart';
import '../onboarding/ob_style.dart';
import '../onboarding/ob_widgets.dart';
import 'menu_pdf_viewer_screen.dart';
import 'table_reservation_screen.dart';

enum _View { menu, book }

/// The clubhouse: browse the active club's menu, or reserve a table.
class RestaurantScreen extends ConsumerStatefulWidget {
  const RestaurantScreen({super.key});

  @override
  ConsumerState<RestaurantScreen> createState() => _RestaurantScreenState();
}

class _RestaurantScreenState extends ConsumerState<RestaurantScreen> {
  _View _view = _View.menu;
  String _course = 'all';

  static const _order = ['starter', 'main', 'special', 'dessert', 'drink'];
  static String _label(String c) => switch (c) {
        'all' => 'All',
        'starter' => 'Starters',
        'main' => 'Mains',
        'special' => 'Specials',
        'dessert' => 'Desserts',
        'drink' => 'Drinks',
        _ => c[0].toUpperCase() + c.substring(1),
      };

  // A warm tint per course where a dish has no photo.
  static Color _tint(String c) => switch (c) {
        'starter' => const Color(0xFF2E3B1C),
        'main' => const Color(0xFF3B2A18),
        'special' => const Color(0xFF3A3212),
        'dessert' => const Color(0xFF3A1E2A),
        'drink' => const Color(0xFF16323A),
        _ => Ob.roleFill,
      };

  @override
  Widget build(BuildContext context) {
    final club = ref.watch(activeClubProvider);

    return Scaffold(
      backgroundColor: Ob.bg,
      body: DefaultTextStyle(
        style: Ob.textBase,
        child: SafeArea(
          bottom: false,
          child: club == null
              ? Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    ObTopBar('Clubhouse', onBack: () => context.pop()),
                    const SizedBox(height: 20),
                    ObGuideRow(botAsset: ObBot.ball.idle, botLabel: 'Your golf-ball avatar', text: 'Join a club to see its menu and book a table.', size: 76, fontSize: 16),
                  ]),
                )
              : _content(club.clubId, club.clubName),
        ),
      ),
    );
  }

  Widget _content(String clubId, String clubName) {
    final menuAsync = ref.watch(clubMenuProvider(clubId));
    final docs = ref.watch(clubMenuDocumentsProvider(clubId)).valueOrNull ?? const <MenuDocument>[];
    final items = menuAsync.valueOrNull ?? const <MenuItem>[];
    final courses = ['all', ..._order.where((c) => items.any((i) => i.category == c))];
    final shown = items.where((i) => _course == 'all' || i.category == _course).toList()
      ..sort((a, b) => _order.indexOf(a.category).compareTo(_order.indexOf(b.category)));

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 60),
      children: [
        ObTopBar('Clubhouse', onBack: () => context.pop(), actions: [
          if (docs.isNotEmpty)
            ObIconButton(
              icon: LucideIcons.fileText,
              label: 'Full menu (PDF)',
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => MenuPdfViewerScreen(title: docs.first.name, pdfUrl: docs.first.pdfUrl))),
            ),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          ObCrest(clubName, size: 40, radius: 12),
          const SizedBox(width: 12),
          Expanded(child: Text(clubName, style: Ob.body(14, weight: FontWeight.w800))),
        ]).rise(),
        const SizedBox(height: 14),
        ObGooSegmented<_View>(
          options: const [(_View.menu, 'Menu'), (_View.book, 'Book a table')],
          selected: _view,
          onChanged: (v) => setState(() => _view = v),
        ).rise(1),
        const SizedBox(height: 14),
        if (_view == _View.book)
          _BookList(clubId: clubId)
        else if (menuAsync.isLoading && items.isEmpty)
          const Padding(padding: EdgeInsets.all(40), child: Center(child: CupertinoActivityIndicator(color: Ob.lime)))
        else if (items.isEmpty && docs.isEmpty)
          ObCard(child: Text('The kitchen hasn\'t put its menu up yet.', style: Ob.body(14, color: Ob.creamA(.65))))
        else ...[
          if (items.isNotEmpty) ...[
            SizedBox(
              height: 34,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: courses.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, i) => GestureDetector(onTap: () => setState(() => _course = courses[i]), child: ObChip(_label(courses[i]), on: _course == courses[i])),
              ),
            ),
            const SizedBox(height: 12),
            for (final d in shown) Padding(padding: const EdgeInsets.only(bottom: 10), child: _dish(d)),
          ],
          if (docs.isNotEmpty) ...[
            const SizedBox(height: 12),
            const ObEyebrow('Menus to download'),
            const SizedBox(height: 10),
            for (final doc in docs)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ObCard(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => MenuPdfViewerScreen(title: doc.name, pdfUrl: doc.pdfUrl))),
                  child: Row(children: [
                    const Icon(LucideIcons.fileText, color: Ob.lime),
                    const SizedBox(width: 12),
                    Expanded(child: Text(doc.name, style: Ob.body(15, weight: FontWeight.w700))),
                    Icon(LucideIcons.chevronRight, size: 18, color: Ob.creamA(.4)),
                  ]),
                ),
              ),
          ],
        ],
      ],
    );
  }

  Widget _dish(MenuItem d) {
    return ObCard(
      padding: const EdgeInsets.all(12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 88,
          height: 88,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(color: _tint(d.category), borderRadius: BorderRadius.circular(18)),
          child: Stack(children: [
            if ((d.photoUrl ?? '').isNotEmpty) Positioned.fill(child: Image.network(d.photoUrl!, fit: BoxFit.cover, errorBuilder: (_, _, _) => const SizedBox())),
            if (d.isNew) const Positioned(left: 8, bottom: 8, child: ObChip('New', on: true)),
          ]),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 88,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(d.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: Ob.body(15, weight: FontWeight.w800)),
              if ((d.description ?? '').isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(d.description!, maxLines: 2, overflow: TextOverflow.ellipsis, style: Ob.body(12, height: 1.4, color: Ob.creamA(.62))),
              ],
              const Spacer(),
              Row(children: [
                Expanded(child: Text((d.chefName ?? '').isEmpty ? '' : 'Chef ${d.chefName}', style: Ob.body(11, color: Ob.creamA(.5)))),
                if (d.priceKes != null) Text('KES ${NumberFormat('#,###').format(d.priceKes)}', style: Ob.display(18)),
              ]),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _BookList extends ConsumerWidget {
  const _BookList({required this.clubId});
  final String clubId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(restaurantLocationsProvider(clubId));
    final list = async.valueOrNull ?? const <RestaurantLocation>[];
    if (async.isLoading && list.isEmpty) return const Padding(padding: EdgeInsets.all(40), child: Center(child: CupertinoActivityIndicator(color: Ob.lime)));
    if (list.isEmpty) return ObCard(child: Text('No tables to book here yet.', style: Ob.body(14, color: Ob.creamA(.65))));
    const tints = [Color(0xFF2E3B1C), Color(0xFF16323A), Color(0xFF3B2A18), Color(0xFF3A1E2A)];
    return Column(children: [
      for (final (i, loc) in list.indexed)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: ObCard(
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => TableReservationScreen(clubId: clubId, location: loc))),
            child: Row(children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(color: tints[i % tints.length], borderRadius: BorderRadius.circular(16)),
                child: const Icon(LucideIcons.utensils, color: Ob.cream, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(loc.name, style: Ob.body(16, weight: FontWeight.w800)),
                  Text('Pick a day, a time and your table', style: Ob.body(12, color: Ob.creamA(.58))),
                ]),
              ),
              Icon(LucideIcons.chevronRight, size: 18, color: Ob.creamA(.4)),
            ]),
          ),
        ),
    ]);
  }
}
