import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:drift/drift.dart' as drift;
import '../../core/theme/app_theme.dart';
import '../../providers/app_providers.dart';
import '../../core/database/database.dart';

class ClubsScreen extends ConsumerWidget {
  const ClubsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clubsAsync = ref.watch(clubsProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: AppColors.grey900),
          onPressed: () => context.pop(),
        ),
        title: const Text('My Bag', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.grey900)),
      ),
      body: clubsAsync.when(
        data: (clubs) => clubs.isEmpty ? _buildEmptyState(context) : _buildList(context, clubs, ref),
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.emerald700)),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddClubDialog(context, ref),
        backgroundColor: AppColors.emerald700,
        icon: const Icon(LucideIcons.plus, color: Colors.white),
        label: const Text('Add Club', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.briefcase, size: 64, color: AppColors.grey200),
          const SizedBox(height: 16),
          const Text('Your bag is empty', style: TextStyle(color: AppColors.grey500, fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('Add your clubs to track your equipment', style: TextStyle(color: AppColors.grey400)),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context, List<Club> clubs, WidgetRef ref) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: clubs.length,
      itemBuilder: (context, i) {
        final club = clubs[i];
        return Card(
          color: AppColors.white,
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.grey100)),
          child: ListTile(
            onTap: () => _showClubDetails(context, club),
            contentPadding: const EdgeInsets.all(12),
            leading: Container(
              width: 60, height: 60,
              decoration: BoxDecoration(
                color: AppColors.grey50, 
                borderRadius: BorderRadius.circular(12),
                image: club.photoUrl != null ? DecorationImage(
                  image: club.photoUrl!.startsWith('http') 
                      ? NetworkImage(club.photoUrl!) as ImageProvider
                      : FileImage(File(club.photoUrl!)), 
                  fit: BoxFit.cover
                ) : null,
              ),
              child: club.photoUrl == null ? Center(child: Icon(LucideIcons.camera, color: AppColors.grey300)) : null,
            ),
            title: Text('${club.brand ?? ""} ${club.model ?? ""}'.trim().isEmpty ? club.type : '${club.brand ?? ""} ${club.model ?? ""}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            subtitle: Text(club.type, style: const TextStyle(color: AppColors.grey500, fontSize: 12)),
            trailing: IconButton(
              icon: const Icon(LucideIcons.trash2, color: AppColors.doubleBogey, size: 20),
              onPressed: () => _deleteClub(ref, club.id),
            ),
          ),
        );
      },
    );
  }

  void _showAddClubDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _AddClubDialog(onAdd: (type, brand, model, loft, notes, photoPath) {
        _addClub(ref, type, brand, model, loft, notes, photoPath);
      }),
    );
  }

  Future<void> _addClub(WidgetRef ref, String type, String brand, String model, double? loft, String? notes, String photoPath) async {
    final db = ref.read(databaseProvider);
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;

    await db.into(db.clubs).insert(ClubsCompanion.insert(
      userId: user.uid,
      type: type,
      brand: drift.Value(brand.isNotEmpty ? brand : null),
      model: drift.Value(model.isNotEmpty ? model : null),
      loft: drift.Value(loft),
      notes: drift.Value(notes?.isNotEmpty == true ? notes : null),
      photoUrl: drift.Value(photoPath),
    ));

    // Trigger Achievement Check
    ref.read(achievementServiceProvider).checkAllAchievements(user.uid);
  }

  void _showClubDetails(BuildContext context, Club club) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40, height: 4,
              decoration: BoxDecoration(color: AppColors.grey200, borderRadius: BorderRadius.circular(2)),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (club.photoUrl != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: club.photoUrl!.startsWith('http')
                          ? Image.network(
                              club.photoUrl!,
                              width: double.infinity,
                              height: 300,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  height: 300,
                                  color: AppColors.grey50,
                                  child: const Center(child: CircularProgressIndicator(color: AppColors.emerald500)),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) => Container(
                                height: 300,
                                color: AppColors.grey50,
                                child: const Center(child: Icon(LucideIcons.imageOff, color: AppColors.grey300, size: 48)),
                              ),
                            )
                          : Image.file(
                              File(club.photoUrl!),
                              width: double.infinity,
                              height: 300,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                height: 300,
                                color: AppColors.grey50,
                                child: const Center(child: Icon(LucideIcons.imageOff, color: AppColors.grey300, size: 48)),
                              ),
                            ),
                      ),
                    const SizedBox(height: 24),
                    Text(club.type.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.emerald700, letterSpacing: 1.5)),
                    const SizedBox(height: 8),
                    Text('${club.brand ?? ""} ${club.model ?? ""}'.trim().isEmpty ? 'Generic Club' : '${club.brand ?? ""} ${club.model ?? ""}', 
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.grey900)),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 24),
                    _buildDetailRow('Brand', club.brand ?? '—'),
                    _buildDetailRow('Model', club.model ?? '—'),
                    _buildDetailRow('Loft', club.loft != null ? '${club.loft}°' : '—'),
                    if (club.notes != null && club.notes!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text('NOTES', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.grey400, letterSpacing: 1)),
                      const SizedBox(height: 8),
                      Text(club.notes!, style: const TextStyle(fontSize: 16, color: AppColors.grey700, height: 1.5)),
                    ],
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => Navigator.pop(context),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.grey900,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.grey400)),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.grey900)),
        ],
      ),
    );
  }

  Future<void> _deleteClub(WidgetRef ref, int id) async {
    final db = ref.read(databaseProvider);
    await (db.delete(db.clubs)..where((c) => c.id.equals(id))).go();
  }
}

class _AddClubDialog extends StatefulWidget {
  final Function(String type, String brand, String model, double? loft, String? notes, String photoPath) onAdd;
  const _AddClubDialog({required this.onAdd});

  @override
  State<_AddClubDialog> createState() => _AddClubDialogState();
}

class _AddClubDialogState extends State<_AddClubDialog> {
  final _typeController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _loftController = TextEditingController();
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
    if (_typeController.text.isEmpty || _image == null) return;
    
    setState(() => _isSaving = true);
    
    try {
      // Save image to local documents directory for persistence
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'club_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedImage = await _image!.copy(p.join(directory.path, fileName));
      
      widget.onAdd(
        _typeController.text,
        _brandController.text,
        _modelController.text,
        double.tryParse(_loftController.text),
        _notesController.text,
        savedImage.path,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving club: $e')));
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text('Add New Club', style: TextStyle(fontWeight: FontWeight.w800)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () => _showImageSourceActionSheet(context),
              child: Container(
                width: double.infinity,
                height: 150,
                decoration: BoxDecoration(
                  color: AppColors.grey50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _image == null ? AppColors.grey200 : AppColors.emerald700, width: 2),
                  image: _image != null ? DecorationImage(image: FileImage(_image!), fit: BoxFit.cover) : null,
                ),
                child: _image == null 
                  ? const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.camera, color: AppColors.grey400, size: 32),
                        SizedBox(height: 8),
                        Text('Add Club Photo*', style: TextStyle(color: AppColors.grey400, fontWeight: FontWeight.bold, fontSize: 12)),
                        Text('Required for Identification', style: TextStyle(color: AppColors.grey300, fontSize: 10)),
                      ],
                    )
                  : const SizedBox.shrink(),
              ),
            ),
            const SizedBox(height: 20),
            _buildDialogField(_typeController, 'Type (e.g. Driver, 7-Iron)*'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildDialogField(_brandController, 'Brand')),
                const SizedBox(width: 8),
                Expanded(child: _buildDialogField(_loftController, 'Loft', keyboardType: TextInputType.number)),
              ],
            ),
            const SizedBox(height: 12),
            _buildDialogField(_modelController, 'Model'),
            const SizedBox(height: 12),
            _buildDialogField(_notesController, 'Notes/Serial #', maxLines: 3),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: (_typeController.text.isNotEmpty && _image != null && !_isSaving) ? _handleAdd : null,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.emerald700,
            disabledBackgroundColor: AppColors.grey200,
          ),
          child: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Add to Bag'),
        ),
      ],
    );
  }

  void _showImageSourceActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(LucideIcons.camera),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.image),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogField(TextEditingController controller, String label, {TextInputType? keyboardType, int maxLines = 1}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 12),
        filled: true,
        fillColor: AppColors.grey50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}
