import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:drift/drift.dart' as drift;
import 'package:flutter/cupertino.dart';
import '../../core/models/achievement_model.dart';
import '../../widgets/achievement_dialog.dart';
import '../onboarding/ob_app.dart';
import '../onboarding/ob_forms.dart';
import '../onboarding/ob_style.dart';
import '../../providers/app_providers.dart';
import '../../core/database/database.dart';
import '../../widgets/top_notification.dart';

class ClubsScreen extends ConsumerWidget {
  const ClubsScreen({super.key});

  static const _standardSet = ['Driver', '3 wood', '5 hybrid', '5 iron', '6 iron', '7 iron', '8 iron', '9 iron', 'Pitching wedge', 'Sand wedge', 'Putter'];

  static String short(String type) {
    final t = type.toLowerCase();
    if (t.contains('driver')) return 'Dr';
    if (t.contains('putter')) return 'Pt';
    if (t.contains('pitching')) return 'PW';
    if (t.contains('sand')) return 'SW';
    if (t.contains('gap')) return 'GW';
    if (t.contains('lob')) return 'LW';
    final n = RegExp(r'\d+').firstMatch(t)?.group(0);
    if (n != null && t.contains('wood')) return '${n}W';
    if (n != null && t.contains('hybrid')) return '${n}H';
    if (n != null && (t.contains('iron') || t.contains('i'))) return '${n}i';
    if (n != null) return n;
    return type.length <= 2 ? type : type.substring(0, 2);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clubsAsync = ref.watch(clubsProvider);
    final clubs = clubsAsync.valueOrNull ?? const <Club>[];
    final units = ref.watch(unitFormatterProvider).units;
    final full = clubs.length >= 14;
    final loaded = Achievement.allAchievements.where((a) => a.id == 'new_bag').firstOrNull;

    return Scaffold(
      backgroundColor: Ob.bg,
      body: DefaultTextStyle(
        style: Ob.textBase,
        child: SafeArea(
          bottom: false,
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 60),
            children: [
              ObTopBar('My bag', onBack: () => context.pop(), actions: [
                ObIconButton(icon: LucideIcons.plus, label: 'Add a club', onPressed: () => _showAddClubDialog(context, ref)),
              ]),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
                decoration: BoxDecoration(color: Ob.roleFill, borderRadius: BorderRadius.circular(28), border: Border.all(color: Ob.lime.withValues(alpha: .2))),
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('IN THE BAG', style: Ob.eyebrow()),
                      const SizedBox(height: 4),
                      Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                        Text('${clubs.length}', style: Ob.display(52, height: 1)),
                        Text(' of 14 clubs', style: Ob.body(15, weight: FontWeight.w700, color: Ob.creamA(.6))),
                      ]),
                    ]),
                  ),
                  if (loaded != null)
                    Container(
                      width: 76,
                      height: 76,
                      decoration: const BoxDecoration(color: Color(0xFF0D1A12), shape: BoxShape.circle),
                      child: AchievementAvatar(loaded, earned: full, size: 70),
                    ),
                ]),
              ),
              const SizedBox(height: 8),
              Text(full ? 'Fully Loaded unlocked. Nice.' : 'Add ${14 - clubs.length} more to unlock Fully Loaded.', style: Ob.body(13, color: Ob.creamA(.62))),
              const SizedBox(height: 16),
              if (clubsAsync.isLoading && clubs.isEmpty)
                const Center(child: CupertinoActivityIndicator(color: Ob.lime))
              else if (clubs.isEmpty) ...[
                ObCard(
                  padding: const EdgeInsets.all(18),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Start with a standard set?', style: Ob.display(20)),
                    const SizedBox(height: 4),
                    Text('Driver to putter, 11 clubs. Edit or remove any later.', style: Ob.body(13, color: Ob.creamA(.65))),
                    const SizedBox(height: 14),
                    ObButton(onPressed: () => _addStandardSet(context, ref), child: Text('Add the standard set', style: Ob.label(15, weight: FontWeight.w800))),
                  ]),
                ),
                const SizedBox(height: 10),
              ] else
                for (final c in clubs)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Dismissible(
                      key: ValueKey(c.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(color: Ob.warn.withValues(alpha: .2), borderRadius: BorderRadius.circular(20)),
                        child: const Icon(LucideIcons.trash2, color: Ob.warn),
                      ),
                      onDismissed: (_) => _deleteClub(ref, c.id),
                      child: GestureDetector(
                        onTap: () => _showClubDetails(context, c, ref),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Ob.cardFill, borderRadius: BorderRadius.circular(20), border: Border.all(color: Ob.creamA(.06))),
                          child: Row(children: [
                            Container(
                              width: 54,
                              height: 54,
                              clipBehavior: Clip.antiAlias,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF1D3322), Color(0xFF0B160F)]),
                              ),
                              child: c.photoUrl != null
                                  ? (c.photoUrl!.startsWith('http')
                                      ? Image.network(c.photoUrl!, fit: BoxFit.cover, errorBuilder: (_, _, _) => _shortLabel(c.type))
                                      : Image.file(File(c.photoUrl!), fit: BoxFit.cover, errorBuilder: (_, _, _) => _shortLabel(c.type)))
                                  : _shortLabel(c.type),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(c.type, style: Ob.body(15, weight: FontWeight.w800)),
                                Text(
                                  [c.brand, c.model, if (c.loft != null) '${c.loft!.toStringAsFixed(c.loft! % 1 == 0 ? 0 : 1)}°'].whereType<String>().where((x) => x.isNotEmpty).join(' · ').ifBlank('Tap to add details'),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Ob.body(12, color: Ob.creamA(.55)),
                                ),
                              ]),
                            ),
                            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                              Text(c.averageDistance == null ? '—' : '${c.averageDistance!.round()}', style: Ob.display(18, height: 1)),
                              Text(c.averageDistance == null ? 'carry' : '$units carry', style: Ob.body(11, color: Ob.creamA(.5))),
                            ]),
                          ]),
                        ),
                      ),
                    ),
                  ),
              if (!full)
                GestureDetector(
                  onTap: () => _showAddClubDialog(context, ref),
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: Ob.creamA(.16), width: 2)),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(LucideIcons.camera, size: 18, color: Ob.creamA(.75)),
                      const SizedBox(width: 8),
                      Text('Add a club with a photo', style: Ob.body(14, weight: FontWeight.w700, color: Ob.creamA(.75))),
                    ]),
                  ),
                ),
              if (clubs.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text('Swipe a club left to remove it.', textAlign: TextAlign.center, style: Ob.body(12, color: Ob.creamA(.4))),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _shortLabel(String type) => Center(child: Text(short(type), style: Ob.display(20)));

  Future<void> _addStandardSet(BuildContext context, WidgetRef ref) async {
    final db = ref.read(databaseProvider);
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;
    for (final t in _standardSet) {
      await db.into(db.clubs).insert(ClubsCompanion.insert(userId: user.uid, type: t));
    }
    ref.read(achievementServiceProvider).checkAllAchievements(user.uid);
    if (context.mounted) TopNotification.showSuccess(context, '${_standardSet.length} clubs added');
  }

  void _showAddClubDialog(BuildContext context, WidgetRef ref) {
    showObSheet(
      context,
      (_) => _AddClubDialog(onAdd: (type, brand, model, loft, distance, notes, photoPath) {
        _addClub(ref, type, brand, model, loft, distance, notes, photoPath);
      }),
    );
  }

  Future<void> _addClub(WidgetRef ref, String type, String brand, String model, double? loft, double? distance, String? notes, String? photoPath) async {
    final db = ref.read(databaseProvider);
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;

    await db.into(db.clubs).insert(ClubsCompanion.insert(
      userId: user.uid,
      type: type,
      brand: drift.Value(brand.isNotEmpty ? brand : null),
      model: drift.Value(model.isNotEmpty ? model : null),
      loft: drift.Value(loft),
      averageDistance: drift.Value(distance),
      notes: drift.Value(notes?.isNotEmpty == true ? notes : null),
      photoUrl: drift.Value(photoPath),
    ));
    ref.read(achievementServiceProvider).checkAllAchievements(user.uid);
  }

  void _showClubDetails(BuildContext context, Club club, WidgetRef ref) {
    final units = ref.read(unitFormatterProvider).units;
    Widget line(String k, String v) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(children: [
            Expanded(child: Text(k, style: Ob.body(14, color: Ob.creamA(.6)))),
            Text(v, style: Ob.body(14, weight: FontWeight.w700)),
          ]),
        );
    showObSheet(
      context,
      (ctx) => ObSheet(
        title: club.type,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (club.photoUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SizedBox(
                height: 180,
                child: club.photoUrl!.startsWith('http')
                    ? Image.network(club.photoUrl!, fit: BoxFit.cover)
                    : Image.file(File(club.photoUrl!), fit: BoxFit.cover, errorBuilder: (_, _, _) => const SizedBox()),
              ),
            ),
          const SizedBox(height: 8),
          line('Brand', club.brand ?? '—'),
          line('Model', club.model ?? '—'),
          line('Loft', club.loft == null ? '—' : '${club.loft}°'),
          line('Average carry', club.averageDistance == null ? '—' : '${club.averageDistance!.round()} $units'),
          if ((club.notes ?? '').isNotEmpty) line('Notes', club.notes!),
          const SizedBox(height: 12),
          ObButton(
            tone: ObButtonTone.dark,
            onPressed: () {
              Navigator.pop(ctx);
              _deleteClub(ref, club.id);
            },
            child: Text('Remove from bag', style: Ob.label(15, weight: FontWeight.w800).copyWith(color: Ob.warn)),
          ),
        ]),
      ),
    );
  }

  Future<void> _deleteClub(WidgetRef ref, int id) async {
    final db = ref.read(databaseProvider);
    await (db.delete(db.clubs)..where((c) => c.id.equals(id))).go();
  }
}

extension on String {
  String ifBlank(String other) => trim().isEmpty ? other : this;
}

class _AddClubDialog extends StatefulWidget {
  final Function(String type, String brand, String model, double? loft, double? distance, String? notes, String? photoPath) onAdd;
  const _AddClubDialog({required this.onAdd});

  @override
  State<_AddClubDialog> createState() => _AddClubDialogState();
}

class _AddClubDialogState extends State<_AddClubDialog> {
  final _typeController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _loftController = TextEditingController();
  final _distanceController = TextEditingController();
  final _notesController = TextEditingController();
  File? _image;
  final _picker = ImagePicker();
  bool _isSaving = false;

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source, imageQuality: 70);
    if (pickedFile != null) {
      setState(() => _image = File(pickedFile.path));
    }
  }

  Future<void> _handleAdd() async {
    if (_typeController.text.trim().isEmpty) return;
    setState(() => _isSaving = true);
    try {
      String? path;
      if (_image != null) {
        // Keep a copy in app documents so the photo survives cache clears.
        final dir = await getApplicationDocumentsDirectory();
        path = (await _image!.copy(p.join(dir.path, 'club_${DateTime.now().millisecondsSinceEpoch}.jpg'))).path;
      }
      widget.onAdd(_typeController.text.trim(), _brandController.text.trim(), _modelController.text.trim(), double.tryParse(_loftController.text),
          double.tryParse(_distanceController.text), _notesController.text, path);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        TopNotification.showError(context, 'Couldn\'t save the club: $e');
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    for (final c in [_typeController, _brandController, _modelController, _loftController, _distanceController, _notesController]) {
      c.dispose();
    }
    super.dispose();
  }

  static const _quick = ['Driver', '3 wood', '5 wood', '4 hybrid', '4 iron', '5 iron', '6 iron', '7 iron', '8 iron', '9 iron', 'Pitching wedge', 'Gap wedge', 'Sand wedge', 'Lob wedge', 'Putter'];

  @override
  Widget build(BuildContext context) {
    return ObSheet(
      title: 'Add a club',
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * .72),
        child: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            GestureDetector(
              onTap: () => _showImageSourceActionSheet(context),
              child: Container(
                height: 130,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: Ob.cardFill,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _image == null ? Ob.creamA(.12) : Ob.lime, width: 1.5),
                ),
                child: _image == null
                    ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(LucideIcons.camera, color: Ob.creamA(.6), size: 26),
                        const SizedBox(height: 6),
                        Text('Snap the club (optional)', style: Ob.body(13, weight: FontWeight.w700, color: Ob.creamA(.7))),
                      ])
                    : Image.file(_image!, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 14),
            const ObEyebrow('Which club?'),
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 6, children: [
              for (final q in _quick)
                GestureDetector(
                  onTap: () => setState(() => _typeController.text = q),
                  child: ObChip(q, on: _typeController.text == q),
                ),
            ]),
            const SizedBox(height: 10),
            _buildDialogField(_typeController, 'Or type it'),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _buildDialogField(_brandController, 'Brand')),
              const SizedBox(width: 8),
              Expanded(child: _buildDialogField(_modelController, 'Model')),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _buildDialogField(_loftController, 'Loft °', keyboardType: TextInputType.number)),
              const SizedBox(width: 8),
              Expanded(child: _buildDialogField(_distanceController, 'Carry', keyboardType: TextInputType.number)),
            ]),
            const SizedBox(height: 16),
            ObButton(
              onPressed: _typeController.text.trim().isNotEmpty && !_isSaving ? _handleAdd : null,
              child: Text(_isSaving ? 'Saving…' : 'Add to bag', style: Ob.label(16, weight: FontWeight.w800)),
            ),
          ]),
        ),
      ),
    );
  }

  void _showImageSourceActionSheet(BuildContext context) {
    showObSheet(
      context,
      (ctx) => ObSheet(
        title: 'Add a photo',
        child: Column(children: [
          ObSelectTile(
            selected: false,
            onTap: () {
              Navigator.pop(ctx);
              _pickImage(ImageSource.camera);
            },
            child: Row(children: [const Icon(LucideIcons.camera, color: Ob.lime), const SizedBox(width: 12), Text('Take a photo', style: Ob.body(15, weight: FontWeight.w700))]),
          ),
          const SizedBox(height: 8),
          ObSelectTile(
            selected: false,
            onTap: () {
              Navigator.pop(ctx);
              _pickImage(ImageSource.gallery);
            },
            child: Row(children: [const Icon(LucideIcons.image, color: Ob.lime), const SizedBox(width: 12), Text('Choose from photos', style: Ob.body(15, weight: FontWeight.w700))]),
          ),
        ]),
      ),
    );
  }

  Widget _buildDialogField(TextEditingController controller, String label, {TextInputType? keyboardType, int maxLines = 1}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      cursorColor: Ob.lime,
      onChanged: (_) => setState(() {}),
      style: Ob.body(15, weight: FontWeight.w700),
      decoration: obInput(label),
    );
  }
}
