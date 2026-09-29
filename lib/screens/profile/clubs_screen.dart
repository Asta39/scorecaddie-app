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

/// The player's bag: clubs (the 14 they can hit) and accessories.
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
    final accessories = ref.watch(accessoriesProvider).valueOrNull ?? const <Club>[];
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
                ObIconButton(icon: LucideIcons.plus, label: 'Add a club', onPressed: () => _openItem(context, ref, accessory: false)),
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
              const SizedBox(height: 18),
              const ObEyebrow('Clubs'),
              const SizedBox(height: 10),
              if (clubsAsync.isLoading && clubs.isEmpty)
                const Center(child: CupertinoActivityIndicator(color: Ob.lime))
              else if (clubs.isEmpty) ...[
                ObCard(
                  padding: const EdgeInsets.all(18),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Start with a standard set?', style: Ob.display(20)),
                    const SizedBox(height: 4),
                    Text('Driver to putter, 11 clubs. Tap any of them afterwards to add its details and a photo.', style: Ob.body(13, color: Ob.creamA(.65))),
                    const SizedBox(height: 14),
                    ObButton(onPressed: () => _addStandardSet(context, ref), child: Text('Add the standard set', style: Ob.label(15, weight: FontWeight.w800))),
                  ]),
                ),
                const SizedBox(height: 10),
              ] else
                for (final c in clubs) _ItemRow(item: c, onTap: () => _openItem(context, ref, accessory: false, existing: c), onDelete: () => _delete(ref, c.id)),
              if (!full)
                _AddRow(icon: LucideIcons.camera, text: 'Add a club with a photo', onTap: () => _openItem(context, ref, accessory: false)),
              const SizedBox(height: 24),
              ObEyebrow('Accessories', trailing: Text('Not used for shots', style: Ob.body(12, color: Ob.creamA(.5)))),
              const SizedBox(height: 10),
              for (final a in accessories) _ItemRow(item: a, onTap: () => _openItem(context, ref, accessory: true, existing: a), onDelete: () => _delete(ref, a.id)),
              _AddRow(icon: LucideIcons.backpack, text: 'Add the bag, sticks, rangefinder…', onTap: () => _openItem(context, ref, accessory: true)),
              if (clubs.isNotEmpty || accessories.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text('Tap anything to edit it. Swipe left to remove it.', textAlign: TextAlign.center, style: Ob.body(12, color: Ob.creamA(.4))),
              ],
            ],
          ),
        ),
      ),
    );
  }

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

  /// Opens the add/edit sheet; saving inserts a new item or updates [existing].
  void _openItem(BuildContext context, WidgetRef ref, {required bool accessory, Club? existing}) {
    showObSheet(
      context,
      (_) => _ItemSheet(
        accessory: accessory,
        existing: existing,
        units: ref.read(unitFormatterProvider).units,
        onSave: (values) => _save(ref, accessory: accessory, existing: existing, values: values),
        onDelete: existing == null ? null : () => _delete(ref, existing.id),
      ),
    );
  }

  Future<void> _save(WidgetRef ref, {required bool accessory, Club? existing, required _ItemValues values}) async {
    final db = ref.read(databaseProvider);
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;
    String? blank(String v) => v.trim().isEmpty ? null : v.trim();
    final companion = ClubsCompanion(
      type: drift.Value(values.name),
      brand: drift.Value(blank(values.brand)),
      model: drift.Value(blank(values.model)),
      loft: drift.Value(accessory ? null : values.loft),
      averageDistance: drift.Value(accessory ? null : values.carry),
      notes: drift.Value(blank(values.notes)),
      photoUrl: drift.Value(values.photoPath),
      kind: drift.Value(accessory ? 'accessory' : 'club'),
    );
    if (existing == null) {
      await db.into(db.clubs).insert(companion.copyWith(userId: drift.Value(user.uid)));
      if (!accessory) ref.read(achievementServiceProvider).checkAllAchievements(user.uid);
    } else {
      await (db.update(db.clubs)..where((c) => c.id.equals(existing.id))).write(companion);
    }
  }

  Future<void> _delete(WidgetRef ref, int id) async {
    final db = ref.read(databaseProvider);
    await (db.delete(db.clubs)..where((c) => c.id.equals(id))).go();
  }
}

extension on String {
  String ifBlank(String other) => trim().isEmpty ? other : this;
}

Widget _photoOr(String? path, Widget fallback, {BoxFit fit = BoxFit.cover}) {
  if (path == null) return fallback;
  return path.startsWith('http')
      ? Image.network(path, fit: fit, errorBuilder: (_, _, _) => fallback)
      : Image.file(File(path), fit: fit, errorBuilder: (_, _, _) => fallback);
}

class _ItemRow extends ConsumerWidget {
  const _ItemRow({required this.item, required this.onTap, required this.onDelete});
  final Club item;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessory = item.kind == 'accessory';
    final units = ref.watch(unitFormatterProvider).units;
    final fallback = Center(
      child: accessory ? Icon(LucideIcons.backpack, size: 22, color: Ob.creamA(.75)) : Text(ClubsScreen.short(item.type), style: Ob.display(20)),
    );
    final details = [
      item.brand,
      item.model,
      if (!accessory && item.loft != null) '${item.loft!.toStringAsFixed(item.loft! % 1 == 0 ? 0 : 1)}°',
      if (accessory) item.notes,
    ].whereType<String>().where((x) => x.isNotEmpty).join(' · ').ifBlank('Tap to add details and a photo');

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Dismissible(
        key: ValueKey(item.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(color: Ob.warn.withValues(alpha: .2), borderRadius: BorderRadius.circular(20)),
          child: const Icon(LucideIcons.trash2, color: Ob.warn),
        ),
        onDismissed: (_) => onDelete(),
        child: Semantics(
          button: true,
          label: 'Edit ${item.type}',
          child: GestureDetector(
            onTap: onTap,
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
                  child: _photoOr(item.photoUrl, fallback),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(item.type, style: Ob.body(15, weight: FontWeight.w800)),
                    Text(details, maxLines: 1, overflow: TextOverflow.ellipsis, style: Ob.body(12, color: Ob.creamA(.55))),
                  ]),
                ),
                if (!accessory)
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text(item.averageDistance == null ? '—' : '${item.averageDistance!.round()}', style: Ob.display(18, height: 1)),
                    Text(item.averageDistance == null ? 'carry' : '$units carry', style: Ob.body(11, color: Ob.creamA(.5))),
                  ])
                else
                  Icon(LucideIcons.chevronRight, size: 18, color: Ob.creamA(.4)),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class _AddRow extends StatelessWidget {
  const _AddRow({required this.icon, required this.text, required this.onTap});
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: Ob.creamA(.16), width: 2)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 18, color: Ob.creamA(.75)),
          const SizedBox(width: 8),
          Flexible(child: Text(text, overflow: TextOverflow.ellipsis, style: Ob.body(14, weight: FontWeight.w700, color: Ob.creamA(.75)))),
        ]),
      ),
    );
  }
}

class _ItemValues {
  const _ItemValues({required this.name, required this.brand, required this.model, this.loft, this.carry, required this.notes, this.photoPath});
  final String name, brand, model, notes;
  final double? loft, carry;
  final String? photoPath;
}

/// Add or edit one thing in the bag: a club (loft, carry) or an accessory.
class _ItemSheet extends StatefulWidget {
  const _ItemSheet({required this.accessory, this.existing, required this.units, required this.onSave, this.onDelete});
  final bool accessory;
  final Club? existing;
  final String units;
  final Future<void> Function(_ItemValues values) onSave;
  final VoidCallback? onDelete;

  @override
  State<_ItemSheet> createState() => _ItemSheetState();
}

class _ItemSheetState extends State<_ItemSheet> {
  late final _name = TextEditingController(text: widget.existing?.type ?? '');
  late final _brand = TextEditingController(text: widget.existing?.brand ?? '');
  late final _model = TextEditingController(text: widget.existing?.model ?? '');
  late final _loft = TextEditingController(text: _num(widget.existing?.loft));
  late final _carry = TextEditingController(text: _num(widget.existing?.averageDistance));
  late final _notes = TextEditingController(text: widget.existing?.notes ?? '');
  late String? _photo = widget.existing?.photoUrl;
  File? _newPhoto;
  final _picker = ImagePicker();
  bool _saving = false;
  bool _confirmRemove = false;

  static String _num(double? v) => v == null ? '' : v.toStringAsFixed(v % 1 == 0 ? 0 : 1);

  static const _quickClubs = ['Driver', '3 wood', '5 wood', '4 hybrid', '4 iron', '5 iron', '6 iron', '7 iron', '8 iron', '9 iron', 'Pitching wedge', 'Gap wedge', 'Sand wedge', 'Lob wedge', 'Putter'];
  static const _quickAccessories = ['Golf bag', 'Alignment sticks', 'Rangefinder', 'Umbrella', 'Glove', 'Balls', 'Tees', 'Towel', 'Headcovers', 'Push cart', 'Ball marker', 'Divot tool'];

  @override
  void dispose() {
    for (final c in [_name, _brand, _model, _loft, _carry, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 70);
    if (picked != null) setState(() => _newPhoto = File(picked.path));
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      var path = _photo;
      if (_newPhoto != null) {
        // Keep a copy in app documents so the photo survives cache clears.
        final dir = await getApplicationDocumentsDirectory();
        path = (await _newPhoto!.copy(p.join(dir.path, 'bag_${DateTime.now().millisecondsSinceEpoch}.jpg'))).path;
      }
      await widget.onSave(_ItemValues(
        name: _name.text.trim(),
        brand: _brand.text,
        model: _model.text,
        loft: double.tryParse(_loft.text.trim()),
        carry: double.tryParse(_carry.text.trim()),
        notes: _notes.text,
        photoPath: path,
      ));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        TopNotification.showError(context, 'Couldn\'t save it. Try again.');
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.existing != null;
    final what = widget.accessory ? 'accessory' : 'club';
    final hasPhoto = _newPhoto != null || _photo != null;
    final quick = widget.accessory ? _quickAccessories : _quickClubs;

    return ObSheet(
      title: editing ? 'Edit ${widget.existing!.type}' : 'Add ${widget.accessory ? 'an accessory' : 'a club'}',
      subtitle: widget.accessory ? 'Kept in your bag list. It won\'t show up in practice or scoring.' : null,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * .72),
        child: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            GestureDetector(
              onTap: () => _photoOptions(context, hasPhoto),
              child: Container(
                height: 150,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: Ob.cardFill,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: hasPhoto ? Ob.lime : Ob.creamA(.12), width: 1.5),
                ),
                child: Stack(fit: StackFit.expand, children: [
                  if (_newPhoto != null)
                    Image.file(_newPhoto!, fit: BoxFit.cover)
                  else if (_photo != null)
                    _photoOr(_photo, const SizedBox())
                  else
                    Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(LucideIcons.camera, color: Ob.creamA(.6), size: 26),
                      const SizedBox(height: 6),
                      Text('Add a photo (optional)', style: Ob.body(13, weight: FontWeight.w700, color: Ob.creamA(.7))),
                    ]),
                  if (hasPhoto)
                    Positioned(
                      right: 10,
                      bottom: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: Ob.bg.withValues(alpha: .8), borderRadius: BorderRadius.circular(999)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(LucideIcons.camera, size: 14, color: Ob.cream),
                          const SizedBox(width: 6),
                          Text('Change', style: Ob.body(12, weight: FontWeight.w800)),
                        ]),
                      ),
                    ),
                ]),
              ),
            ),
            const SizedBox(height: 14),
            ObEyebrow(widget.accessory ? 'What is it?' : 'Which club?'),
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 6, children: [
              for (final q in quick)
                GestureDetector(
                  onTap: () => setState(() => _name.text = q),
                  child: ObChip(q, on: _name.text == q),
                ),
            ]),
            const SizedBox(height: 10),
            _field(_name, 'Or type it'),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _field(_brand, 'Brand')),
              const SizedBox(width: 8),
              Expanded(child: _field(_model, 'Model')),
            ]),
            if (!widget.accessory) ...[
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: _field(_loft, 'Loft °', number: true)),
                const SizedBox(width: 8),
                Expanded(child: _field(_carry, 'Carry (${widget.units})', number: true)),
              ]),
            ],
            const SizedBox(height: 10),
            _field(_notes, widget.accessory ? 'Notes, e.g. colour or size' : 'Notes, e.g. shaft, flex, grip', lines: 2),
            const SizedBox(height: 16),
            ObButton(
              onPressed: _name.text.trim().isNotEmpty && !_saving ? _save : null,
              child: Text(_saving ? 'Saving…' : (editing ? 'Save changes' : 'Add to bag'), style: Ob.label(16, weight: FontWeight.w800)),
            ),
            if (editing && widget.onDelete != null) ...[
              const SizedBox(height: 8),
              ObButton(
                tone: ObButtonTone.dark,
                onPressed: () {
                  if (!_confirmRemove) {
                    setState(() => _confirmRemove = true);
                    return;
                  }
                  Navigator.pop(context);
                  widget.onDelete!();
                },
                child: Text(_confirmRemove ? 'Tap again to remove this $what' : 'Remove from bag', style: Ob.label(15, weight: FontWeight.w800).copyWith(color: Ob.warn)),
              ),
            ],
          ]),
        ),
      ),
    );
  }

  void _photoOptions(BuildContext context, bool hasPhoto) {
    Widget tile(IconData icon, String text, VoidCallback onTap, {Color color = Ob.lime}) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: ObSelectTile(
            selected: false,
            onTap: onTap,
            child: Row(children: [Icon(icon, color: color), const SizedBox(width: 12), Text(text, style: Ob.body(15, weight: FontWeight.w700))]),
          ),
        );
    showObSheet(
      context,
      (ctx) => ObSheet(
        title: hasPhoto ? 'Change the photo' : 'Add a photo',
        child: Column(children: [
          tile(LucideIcons.camera, 'Take a photo', () {
            Navigator.pop(ctx);
            _pick(ImageSource.camera);
          }),
          tile(LucideIcons.image, 'Choose from photos', () {
            Navigator.pop(ctx);
            _pick(ImageSource.gallery);
          }),
          if (hasPhoto)
            tile(LucideIcons.trash2, 'Remove the photo', () {
              Navigator.pop(ctx);
              setState(() {
                _newPhoto = null;
                _photo = null;
              });
            }, color: Ob.warn),
        ]),
      ),
    );
  }

  Widget _field(TextEditingController controller, String label, {bool number = false, int lines = 1}) {
    return TextField(
      controller: controller,
      keyboardType: number ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      maxLines: lines,
      cursorColor: Ob.lime,
      onChanged: (_) => setState(() {}),
      style: Ob.body(15, weight: FontWeight.w700),
      decoration: obInput(label),
    );
  }
}
