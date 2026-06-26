import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_providers.dart';
import '../../core/database/database.dart' as db;
import '../../core/services/interaction_service.dart';
import '../../core/utils/url_helper.dart';
import '../../widgets/profile_image.dart';
import '../../widgets/loading_spinner.dart';

final marketplaceRoleFilterProvider = StateProvider<String>((ref) => 'all');

class CaddieMarketplaceScreen extends ConsumerStatefulWidget {
  final String initialRole;
  
  const CaddieMarketplaceScreen({super.key, this.initialRole = 'all'});

  @override
  ConsumerState<CaddieMarketplaceScreen> createState() => _CaddieMarketplaceScreenState();
}

class _CaddieMarketplaceScreenState extends ConsumerState<CaddieMarketplaceScreen> {
  late String _selectedRole;
  final _searchController = TextEditingController();
  int? _requiredExperience; // null means any, otherwise 2, 3, 5

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.initialRole;
  }
  
  String? _selectedPersonality;
  String? _selectedCourse;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  TextStyle _getSFStyle({double fontSize = 14, FontWeight fontWeight = FontWeight.w400, Color? color, double? letterSpacing, TextDecoration? decoration}) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      decoration: decoration,
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String>(marketplaceRoleFilterProvider, (prev, next) {
      if (next != _selectedRole) {
        setState(() => _selectedRole = next);
      }
    });

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          scrolledUnderElevation: 0,
          title: Text('Marketplace', 
            style: _getSFStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.grey900)),
          centerTitle: false,
          actions: [
            IconButton(
              icon: const Icon(LucideIcons.sliders, color: AppColors.grey900),
              onPressed: _showFilterSheet,
            ),
            const SizedBox(width: 8),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(50),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: const TabBar(
                isScrollable: false,
                labelColor: AppColors.grey900,
                unselectedLabelColor: AppColors.grey500,
                labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                indicatorColor: AppColors.emerald700,
                indicatorWeight: 3,
                indicatorSize: TabBarIndicatorSize.label,
                dividerColor: Colors.transparent,
                tabs: [
                  Tab(text: 'Discover'),
                  Tab(text: 'Inquiries'),
                  Tab(text: 'Recent'),
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _buildDiscoverTab(),
            _buildInquiriesTab(),
            _buildMyProsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscoverTab() {
    final providersAsync = ref.watch(allProvidersProvider);
    
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSearchBar(),
                const SizedBox(height: 12),
                _buildRoleSwitcher(),
                const SizedBox(height: 24),
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Text('FEATURED PROFESSIONALS', 
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.grey500, letterSpacing: 1.0)),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
        providersAsync.when(
          data: (providers) {
            if (providers.isEmpty) {
              return const SliverFillRemaining(child: _EmptyMarketplace());
            }

            final filtered = providers.where((p) {
              final matchesRole = _selectedRole == 'all' || p.role.toLowerCase() == _selectedRole.toLowerCase();
              
              final nameMatch = p.name.toLowerCase().contains(_searchController.text.toLowerCase());
              final courseMatch = p.coursesJson.toLowerCase().contains(_searchController.text.toLowerCase());
              final matchesSearch = nameMatch || courseMatch;

              bool matchesExp = true;
              if (_requiredExperience != null) {
                matchesExp = p.experience >= _requiredExperience!;
              }

              bool matchesPersonality = true;
              if (_selectedPersonality != null && _selectedPersonality != 'Any') {
                matchesPersonality = p.personalityType == _selectedPersonality;
              }

              bool matchesSpecificCourse = true;
              if (_selectedCourse != null && _selectedCourse != 'Any') {
                matchesSpecificCourse = p.coursesJson.contains(_selectedCourse!);
              }

              return matchesRole && matchesSearch && matchesExp && matchesPersonality && matchesSpecificCourse;
            }).toList();

            if (filtered.isEmpty) {
              return const SliverFillRemaining(
                child: Center(child: Text('No matches found.', style: TextStyle(color: AppColors.grey400))),
              );
            }

            return SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _ProviderCard(provider: filtered[index]),
                  childCount: filtered.length,
                ),
              ),
            );
          },
          loading: () => const SliverFillRemaining(child: LoadingSpinner()),
          error: (err, _) => SliverFillRemaining(child: Center(child: Text('Error: $err'))),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _buildRoleSwitcher() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFE3E3E8),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        children: [
          _buildRoleButton('all', 'All'),
          _buildRoleButton('caddie', 'Caddies'),
          _buildRoleButton('coach', 'Coaches'),
        ],
      ),
    );
  }

  Widget _buildRoleButton(String role, String label) {
    final isSelected = _selectedRole == role;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedRole = role);
          ref.read(marketplaceRoleFilterProvider.notifier).state = role;
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.golfLime : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected ? [
              BoxShadow(color: AppColors.golfLime.withValues(alpha: 0.4), blurRadius: 4, offset: const Offset(0, 2))
            ] : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: _getSFStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
              color: isSelected ? AppColors.grey900 : AppColors.grey600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInquiriesTab() {
    final pendingAsync = ref.watch(pendingInteractionsProvider);

    return pendingAsync.when(
      data: (pending) {
        if (pending.isEmpty) {
          return _buildEmptyTab(
            icon: LucideIcons.messageSquare,
            title: 'No Inquiries',
            subtitle: 'Professionals you contact will appear here.',
          );
        }

        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: pending.length,
          itemBuilder: (context, index) => _InquiryCard(interaction: pending[index]),
        );
      },
      loading: () => const LoadingSpinner(),
      error: (err, _) => Center(child: Text('Error: $err')),
    );
  }

  Widget _buildMyProsTab() {
    final recentProsAsync = ref.watch(recentProsProvider);

    return recentProsAsync.when(
      data: (pros) {
        if (pros.isEmpty) {
          return _buildEmptyTab(
            icon: LucideIcons.users,
            title: 'No Past Pros',
            subtitle: 'Confirmed bookings will show up here.',
          );
        }

        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: pros.length,
          itemBuilder: (context, index) => _ProviderCard(provider: pros[index]),
        );
      },
      loading: () => const LoadingSpinner(),
      error: (err, _) => Center(child: Text('Error: $err')),
    );
  }

  Widget _buildEmptyTab({required IconData icon, required String title, required String subtitle}) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: AppColors.grey200),
          const SizedBox(height: 16),
          Text(title, style: _getSFStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.grey900)),
          const SizedBox(height: 8),
          Text(subtitle, textAlign: TextAlign.center, style: _getSFStyle(color: AppColors.grey500, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final hasActiveFilters = _requiredExperience != null || 
        (_selectedPersonality != null && _selectedPersonality != 'Any') || 
        (_selectedCourse != null && _selectedCourse != 'Any');

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildFilterChip(
            label: _requiredExperience == null ? 'Experience' : '$_requiredExperience+ Yrs',
            isActive: _requiredExperience != null,
            onTap: () => _showExperiencePicker(),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: _selectedPersonality == null || _selectedPersonality == 'Any' ? 'Personality' : _selectedPersonality!,
            isActive: _selectedPersonality != null && _selectedPersonality != 'Any',
            onTap: () => _showPersonalityPicker(),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: _selectedCourse == null || _selectedCourse == 'Any' ? 'Course' : _selectedCourse!,
            isActive: _selectedCourse != null && _selectedCourse != 'Any',
            onTap: () => _showCoursePicker(),
          ),
          if (hasActiveFilters)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  setState(() {
                    _requiredExperience = null;
                    _selectedPersonality = null;
                    _selectedCourse = null;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(color: AppColors.grey200, shape: BoxShape.circle),
                  child: const Icon(LucideIcons.x, size: 14, color: AppColors.grey600),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({required String label, required bool isActive, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.emerald700 : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? AppColors.emerald700 : AppColors.grey200),
          boxShadow: isActive ? [
            BoxShadow(color: AppColors.emerald700.withValues(alpha: 0.2), blurRadius: 4, offset: const Offset(0, 2))
          ] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: _getSFStyle(
              fontSize: 13, 
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w600, 
              color: isActive ? Colors.white : AppColors.grey700
            )),
            const SizedBox(width: 6),
            Icon(CupertinoIcons.chevron_down, size: 12, color: isActive ? Colors.white : AppColors.grey400),
          ],
        ),
      ),
    );
  }

  void _showExperiencePicker() {
    final items = ['Any', '2+ Yrs', '3+ Yrs', '5+ Yrs'];
    final values = [null, 2, 3, 5];
    
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Required Experience', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        actions: items.map((item) => CupertinoActionSheetAction(
          onPressed: () {
            setState(() {
              _requiredExperience = values[items.indexOf(item)];
            });
            Navigator.pop(context);
          },
          child: Text(item, style: const TextStyle(color: AppColors.grey900, fontWeight: FontWeight.w600)),
        )).toList(),
        cancelButton: CupertinoActionSheetAction(
          isDestructiveAction: true,
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  void _showPersonalityPicker() {
    final personalities = ['Any', 'Quiet & Focused', 'Talkative & Fun', 'Strategic', 'Laid-back'];
    
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Personality Type', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        actions: personalities.map((p) => CupertinoActionSheetAction(
          onPressed: () {
            setState(() {
              _selectedPersonality = p;
            });
            Navigator.pop(context);
          },
          child: Text(p, style: const TextStyle(color: AppColors.grey900, fontWeight: FontWeight.w600)),
        )).toList(),
        cancelButton: CupertinoActionSheetAction(
          isDestructiveAction: true,
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  void _showCoursePicker() {
    final allCourses = ref.read(coursesProvider).valueOrNull ?? [];
    final courseNames = {'Any', ...allCourses.map((c) => c.name)}.toList()..sort();
    
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Material(
        color: Colors.transparent,
        child: Container(
          height: MediaQuery.of(context).size.height * 0.6,
          padding: const EdgeInsets.all(32),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select Course', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: courseNames.length,
                  itemBuilder: (context, i) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(color: AppColors.grey50, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.grey100)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      title: Text(courseNames[i], style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      onTap: () {
                        setState(() {
                          _selectedCourse = courseNames[i];
                        });
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE3E3E8),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(CupertinoIcons.search, size: 18, color: AppColors.grey500),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() {}),
              style: _getSFStyle(fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Search by name or course',
                hintStyle: _getSFStyle(color: AppColors.grey500, fontSize: 16),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet() {
    final allCourses = ref.read(coursesProvider).valueOrNull ?? [];
    final courseNames = {'Any', ...allCourses.map((c) => c.name)}.toList()..sort();
    final personalities = [
      'Any', 'Quiet & Focused', 'Talkative & Fun', 'Strategic', 'Laid-back'
    ];
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Material(
        color: Colors.transparent,
        child: Container(
          height: MediaQuery.of(context).size.height * 0.75,
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: StatefulBuilder(
          builder: (context, setModalState) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Filters', style: _getSFStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.grey900)),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: Text('Reset', style: _getSFStyle(color: AppColors.doubleBogey, fontWeight: FontWeight.w600)),
                    onPressed: () {
                      setModalState(() {
                        _requiredExperience = null;
                        _selectedPersonality = null;
                        _selectedCourse = null;
                      });
                      setState(() {});
                    },
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              _buildFilterLabel('EXPERIENCE'),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildExpChip(null, 'Any', setModalState),
                  _buildExpChip(2, '2+ Yrs', setModalState),
                  _buildExpChip(3, '3+ Yrs', setModalState),
                  _buildExpChip(5, '5+ Yrs', setModalState),
                ],
              ),
              
              const SizedBox(height: 32),
              _buildFilterLabel('PERSONALITY'),
              const SizedBox(height: 12),
              _buildiOSSelector(
                context: context,
                value: _selectedPersonality ?? 'Any',
                items: personalities,
                onChanged: (val) {
                  setModalState(() => _selectedPersonality = val);
                  setState(() {});
                },
              ),

              const SizedBox(height: 32),
              _buildFilterLabel('FAMILIAR COURSE'),
              const SizedBox(height: 12),
              _buildiOSSelector(
                context: context,
                value: _selectedCourse ?? 'Any',
                items: courseNames,
                onChanged: (val) {
                  setModalState(() => _selectedCourse = val);
                  setState(() {});
                },
              ),

              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: CupertinoButton(
                  color: AppColors.grey900,
                  onPressed: () => Navigator.pop(context),
                  child: Text('Apply Filters', style: _getSFStyle(fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildFilterLabel(String label) {
    return Text(label, style: _getSFStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.grey500, letterSpacing: 1.0));
  }

  Widget _buildExpChip(int? value, String label, StateSetter setModalState) {
    final isSelected = _requiredExperience == value;
    return GestureDetector(
      onTap: () {
        setModalState(() => _requiredExperience = value);
        setState(() {});
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.emerald700 : AppColors.grey50,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: _getSFStyle(
            color: isSelected ? Colors.white : AppColors.grey700,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildiOSSelector({required BuildContext context, required String value, required List<String> items, required ValueChanged<String?> onChanged}) {
    return GestureDetector(
      onTap: () => _showPicker(context, items, value, onChanged),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.grey50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(value, style: _getSFStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.grey900)),
            const Icon(CupertinoIcons.chevron_down, size: 16, color: AppColors.grey400),
          ],
        ),
      ),
    );
  }

  void _showPicker(BuildContext context, List<String> items, String currentValue, ValueChanged<String?> onChanged) {
    int selectedIndex = items.indexOf(currentValue);
    if (selectedIndex == -1) selectedIndex = 0;

    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 250,
        color: Colors.white,
        child: Column(
          children: [
            Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: const BoxDecoration(
                color: Color(0xFFF9F9F9),
                border: Border(bottom: BorderSide(color: Color(0xFFE5E5E5))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: Text('Cancel', style: _getSFStyle(color: Colors.blue)),
                    onPressed: () => Navigator.pop(context),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: Text('Done', style: _getSFStyle(fontWeight: FontWeight.w600, color: Colors.blue)),
                    onPressed: () {
                      onChanged(items[selectedIndex]);
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoPicker(
                itemExtent: 32,
                scrollController: FixedExtentScrollController(initialItem: selectedIndex),
                onSelectedItemChanged: (index) => selectedIndex = index,
                children: items.map((item) => Center(child: Text(item, style: _getSFStyle(fontSize: 18)))).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProviderCard extends ConsumerWidget {
  final db.Provider provider;

  const _ProviderCard({required this.provider});

  TextStyle _getSFStyle({double fontSize = 14, FontWeight fontWeight = FontWeight.w400, Color? color, double? letterSpacing, TextDecoration? decoration}) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      decoration: decoration,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: CupertinoButton(
        padding: const EdgeInsets.all(16),
        onPressed: () => context.push('/marketplace/provider/${provider.userId}'),
        child: Row(
          children: [
          _ProviderAvatar(userId: provider.userId, avatarUrl: provider.avatarUrl),
          const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(provider.name, style: _getSFStyle(fontWeight: FontWeight.w800, fontSize: 17, color: AppColors.grey900)),
                      const SizedBox(width: 8),
                      Container(
                        width: 6, height: 6,
                        decoration: BoxDecoration(
                          color: provider.isAvailable ? AppColors.emerald500 : AppColors.grey400,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(provider.rating.toStringAsFixed(1), 
                            style: _getSFStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.grey900)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text('${provider.role.toUpperCase()} • ${provider.experience} YRS EXP', 
                    style: _getSFStyle(color: AppColors.emerald700, fontSize: 11, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  _buildCoursesText(provider.coursesJson),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (provider.personalityType != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.golfSand.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            provider.personalityType!,
                            style: _getSFStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.grey700),
                          ),
                        ),
                      const Spacer(),
                      Row(
                        children: [
                          _QuickAction(
                            icon: provider.role == 'caddie' ? LucideIcons.messageSquare : LucideIcons.messageCircle, 
                            color: provider.role == 'caddie' ? AppColors.blue700 : AppColors.emerald700,
                            onTap: () async {
                              if (provider.role == 'caddie') {
                                // Log interaction so AppShell can prompt later if they leave
                                ref.read(interactionServiceProvider).logInteraction(providerId: provider.userId, type: 'chat');
                                if (context.mounted) {
                                  context.push('/chat/${provider.userId}');
                                }
                              } else {
                                final phone = provider.whatsapp ?? provider.phone;
                                await UrlHelper.launchWhatsApp(phone);
                                ref.read(interactionServiceProvider).logInteraction(providerId: provider.userId, type: 'whatsapp');
                              }
                            },
                          ),
                          const SizedBox(width: 10),
                          _QuickAction(
                            icon: LucideIcons.phone, 
                            color: AppColors.blue700,
                            onTap: () async {
                              await UrlHelper.launchCaller(provider.phone);
                              ref.read(interactionServiceProvider).logInteraction(providerId: provider.userId, type: 'call');
                              // AppShell will handle the confirmation prompt when they return to the app
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoursesText(String json) {
    try {
      final List<dynamic> list = jsonDecode(json);
      return Text(list.take(2).join(', '), 
        style: _getSFStyle(color: AppColors.grey500, fontSize: 13), overflow: TextOverflow.ellipsis);
    } catch (_) {
      // Fallback for non-JSON or comma-separated strings
      final text = json.replaceAll('[', '').replaceAll(']', '').replaceAll('"', '');
      return Text(text, style: _getSFStyle(color: AppColors.grey500, fontSize: 13), overflow: TextOverflow.ellipsis);
    }
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}

class _ProviderAvatar extends ConsumerWidget {
  final String userId;
  final String? avatarUrl;
  const _ProviderAvatar({required this.userId, this.avatarUrl});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(specificUserProfileProvider(userId));

    return profileAsync.when(
      data: (profile) => ProfileImage(url: profile?.avatarUrl ?? avatarUrl, size: 70, borderRadius: 14),
      loading: () => ProfileImage(url: avatarUrl, size: 70, borderRadius: 14), // Use fallback immediately
      error: (_, _) => ProfileImage(url: avatarUrl, size: 70, borderRadius: 14),
    );
  }
}

class _EmptyMarketplace extends StatelessWidget {
  const _EmptyMarketplace();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.users, size: 64, color: AppColors.grey200),
          const SizedBox(height: 24),
          const Text('No Professionals Yet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.grey900)),
          const SizedBox(height: 12),
          const Text('Caddies and coaches will appear here soon.', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: AppColors.grey500)),
        ],
      ),
    );
  }
}

class _InquiryCard extends ConsumerWidget {
  final db.Interaction interaction;
  const _InquiryCard({required this.interaction});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final providersAsync = ref.watch(allProvidersProvider);
    final provider = providersAsync.valueOrNull?.firstWhere((p) => p.userId == interaction.providerId);
    
    if (provider == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _ProviderAvatar(userId: provider.userId),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(provider.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.grey900)),
                Text('Contacted via ${interaction.type.toUpperCase()}', style: const TextStyle(color: AppColors.grey500, fontSize: 11, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: CupertinoButton(
                        padding: EdgeInsets.zero,
                        color: AppColors.grey50,
                        onPressed: () => ref.read(interactionServiceProvider).ignoreInteraction(interaction.id),
                        child: const Text('Cancel', style: TextStyle(color: AppColors.grey600, fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: CupertinoButton(
                        padding: EdgeInsets.zero,
                        color: AppColors.emerald700,
                        onPressed: () => ref.read(interactionServiceProvider).confirmBooking(interaction.id, true),
                        child: const Text('Confirm', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
