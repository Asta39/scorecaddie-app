import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/database/database.dart' as db;
import '../../core/utils/whs_engine.dart';
import '../../providers/app_providers.dart';

class RoundSetupModal extends ConsumerStatefulWidget {
  final int courseId;
  const RoundSetupModal({super.key, required this.courseId});

  static Future<void> show(BuildContext context, db.Course course, {bool isGroup = false}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RoundSetupModal(courseId: course.id),
    );
  }

  @override
  ConsumerState<RoundSetupModal> createState() => _RoundSetupModalState();
}

class _RoundSetupModalState extends ConsumerState<RoundSetupModal> {
  String _format = '18 Holes';
  db.Tee? _selectedTee;
  List<db.Tee> _tees = [];
  bool _loading = true;
  
  // Marker state
  db.Friend? _selectedMarker;
  String _manualMarkerName = '';
  final TextEditingController _markerNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTees();
  }

  Future<void> _loadTees() async {
    final database = ref.read(databaseProvider);
    final tees = await database.getTeesForCourse(widget.courseId);
    setState(() {
      _tees = tees;
      if (tees.isNotEmpty) _selectedTee = tees.first;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _markerNameController.dispose();
    super.dispose();
  }

  int _calculateCH(double handicapIndex) {
    if (_selectedTee == null) return 0;
    return WHSEngine.calculateCourseHandicap(
      handicapIndex: handicapIndex,
      slopeRating: _selectedTee!.slopeRating,
      courseRating: _selectedTee!.courseRating,
      par: _selectedTee!.par ?? 72,
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final hIndex = profile?.handicap ?? 0.0;

    if (_loading) return const SizedBox(height: 300, child: Center(child: CupertinoActivityIndicator()));

    return Container(
        padding: EdgeInsets.fromLTRB(24, 12, 24, MediaQuery.of(context).padding.bottom + 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.grey100, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 32),
              const Text('ROUND SETUP', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.grey900)),
              const SizedBox(height: 32),

              // ── Format Selection ─────────────────────────────────────
              const Text('FORMAT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.grey400, letterSpacing: 1.5)),
              const SizedBox(height: 12),
              _buildSegmentedControl(['18 Holes', 'Front 9', 'Back 9'], _format, (val) => setState(() => _format = val)),
              
              const SizedBox(height: 32),

              // ── Tee Selection ────────────────────────────────────────
              const Text('SELECT YOUR TEE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.grey400, letterSpacing: 1.5)),
              const SizedBox(height: 12),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _tees.length,
                  itemBuilder: (context, i) {
                    final t = _tees[i];
                    final isSelected = _selectedTee?.id == t.id;
                    return _buildTeeOption(t, isSelected);
                  },
                ),
              ),

              const SizedBox(height: 32),

              // ── Course Handicap Card ────────────────────────────────
              _buildCHCard(hIndex),

              const SizedBox(height: 32),

              // ── Marker Selection ────────────────────────────────────
              const Text('ASSIGN A MARKER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.grey400, letterSpacing: 1.5)),
              const SizedBox(height: 12),
              ref.watch(friendsProvider).when(
                data: (friends) {
                  final showManual = _selectedMarker == null;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppColors.grey50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.grey200),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<db.Friend?>(
                            value: _selectedMarker,
                            hint: const Text('Select a Marker (Friend)', style: TextStyle(color: AppColors.grey400, fontSize: 14)),
                            isExpanded: true,
                            dropdownColor: Colors.white,
                            items: [
                              const DropdownMenuItem<db.Friend?>(
                                value: null,
                                child: Text('Enter Marker Manually...', style: TextStyle(color: AppColors.grey900, fontWeight: FontWeight.w500, fontSize: 14)),
                              ),
                              ...friends.map((f) => DropdownMenuItem<db.Friend?>(
                                value: f,
                                child: Text(f.friendName ?? 'Unknown Friend', style: const TextStyle(color: AppColors.grey900, fontSize: 14)),
                              )),
                            ],
                            onChanged: (val) {
                              setState(() {
                                _selectedMarker = val;
                                if (val != null) {
                                  _manualMarkerName = '';
                                  _markerNameController.text = '';
                                }
                              });
                            },
                          ),
                        ),
                      ),
                      if (showManual) ...[
                        const SizedBox(height: 12),
                        TextField(
                          controller: _markerNameController,
                          style: const TextStyle(color: AppColors.grey900, fontSize: 14, fontWeight: FontWeight.w600),
                          decoration: InputDecoration(
                            hintText: 'Enter Marker\'s Name',
                            hintStyle: const TextStyle(color: AppColors.grey400, fontSize: 14, fontWeight: FontWeight.normal),
                            filled: true,
                            fillColor: AppColors.grey50,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: AppColors.grey200),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: AppColors.golfLime, width: 2),
                            ),
                          ),
                          onChanged: (val) => _manualMarkerName = val,
                        ),
                      ],
                    ],
                  );
                },
                loading: () => const Center(child: CupertinoActivityIndicator()),
                error: (_, __) => const Text('Error loading friends'),
              ),

              const SizedBox(height: 40),
              
              SizedBox(
                width: double.infinity,
                height: 64,
                child: FilledButton(
                  onPressed: () {
                    final markerName = _selectedMarker?.friendName ?? _manualMarkerName.trim();
                    if (markerName.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please assign a marker for WHS/KGU round certification.')),
                      );
                      return;
                    }

                    final ch = _calculateCH(hIndex);
                    Navigator.pop(context); // Close Modal
                    context.push('/scoring', extra: {
                      'courseId': widget.courseId,
                      'holesPlayed': _format == '18 Holes' ? 18 : (_format == 'Front 9' ? 9 : -9),
                      'teeId': _selectedTee?.id,
                      'courseHandicap': ch,
                      'markerName': markerName,
                      'markerId': _selectedMarker?.friendId,
                    });
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.grey900,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Text('LET\'S PLAY', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                ),
              ),
            ],
        ),
      ),
    );
  }

  Widget _buildSegmentedControl(List<String> options, String selected, Function(String) onChanged) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: AppColors.grey50, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: options.map((opt) {
          final isSelected = selected == opt;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(opt),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: isSelected ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)] : null,
                ),
                child: Text(opt, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600, color: isSelected ? AppColors.grey900 : AppColors.grey400)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTeeOption(db.Tee tee, bool isSelected) {
    final color = _getTeeColor(tee.name);
    return GestureDetector(
      onTap: () => setState(() => _selectedTee = tee),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.grey900 : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.grey900 : AppColors.grey100, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Text(tee.name.toUpperCase(), style: TextStyle(color: isSelected ? Colors.white : AppColors.grey900, fontWeight: FontWeight.w900, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 4),
            Text('${tee.yardage}y', style: TextStyle(color: isSelected ? Colors.white54 : AppColors.grey400, fontSize: 11, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  Widget _buildCHCard(double hIndex) {
    final ch = _calculateCH(hIndex);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.golfLime.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.golfLime.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(color: AppColors.golfLime, shape: BoxShape.circle),
            child: const Icon(LucideIcons.calculator, color: Colors.black, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('COURSE HANDICAP', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.grey500, letterSpacing: 1)),
                Text('$ch STROKES', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.grey900, letterSpacing: -0.5)),
              ],
            ),
          ),
          Text('${hIndex.toStringAsFixed(1)} HI', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.grey400)),
        ],
      ),
    );
  }

  Color _getTeeColor(String name) {
    final n = name.toLowerCase();
    if (n.contains('white')) return Colors.grey[300]!;
    if (n.contains('yellow')) return Colors.yellow[600]!;
    if (n.contains('red')) return Colors.red[600]!;
    if (n.contains('blue')) return Colors.blue[600]!;
    if (n.contains('green')) return Colors.green[600]!;
    return Colors.black;
  }
}
