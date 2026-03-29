import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' as drift;
import '../../core/theme/app_theme.dart';
import '../../providers/app_providers.dart';
import '../../core/database/database.dart';
import '../../core/cloud/sync_service.dart';

class AddCourseScreen extends ConsumerStatefulWidget {
  const AddCourseScreen({super.key});

  @override
  ConsumerState<AddCourseScreen> createState() => _AddCourseScreenState();
}

class _AddCourseScreenState extends ConsumerState<AddCourseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  
  int _totalHoles = 18;
  late List<int> _holePars;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _holePars = List.filled(18, 4);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _updateHoleCount(int count) {
    setState(() {
      _totalHoles = count;
      if (count == 9 && _holePars.length == 18) {
        _holePars = _holePars.sublist(0, 9);
      } else if (count == 18 && _holePars.length == 9) {
        _holePars = [..._holePars, ...List.filled(9, 4)];
      }
    });
  }

  Future<void> _saveCourse() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    
    try {
      final db = ref.read(databaseProvider);
      final firestoreId = const Uuid().v4();
      
      final int front9Par = _holePars.sublist(0, _totalHoles == 18 ? 9 : _totalHoles).reduce((a, b) => a + b);
      int? back9Par;
      if (_totalHoles == 18) {
        back9Par = _holePars.sublist(9, 18).reduce((a, b) => a + b);
      }
      
      final totalPar = front9Par + (back9Par ?? 0);

      await db.into(db.courses).insert(
        CoursesCompanion.insert(
          firestoreId: drift.Value(firestoreId),
          name: _nameController.text.trim(),
          location: drift.Value(_locationController.text.trim()),
          totalHoles: drift.Value(_totalHoles),
          par18: drift.Value(totalPar),
          par9front: drift.Value(front9Par),
          par9back: drift.Value(back9Par),
          holePars: drift.Value(jsonEncode(_holePars)),
          userId: drift.Value(ref.read(authStateProvider).valueOrNull?.uid),
        ),
      );

      // Sync to Firestore
      try {
        final savedCourse = await db.getCourseByFirestoreId(firestoreId);
        if (savedCourse != null) {
          await ref.read(syncServiceProvider).syncCourse(savedCourse);
        }
      } catch (e) {
        debugPrint('Error syncing custom course: $e');
      }

      ref.invalidate(coursesProvider);
      
      if (!mounted) return;
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Course added successfully!'), backgroundColor: AppColors.emerald700),
      );
    } catch (e) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding course: $e'), backgroundColor: AppColors.doubleBogey),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey50,
      appBar: AppBar(
        backgroundColor: AppColors.grey50,
        elevation: 0,
        title: const Text('Add Custom Course', style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('General Info'),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _nameController,
                label: 'Course Name',
                hint: 'e.g. Windsor Golf Club',
                validator: (v) => v == null || v.isEmpty ? 'Please enter a name' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _locationController,
                label: 'Location',
                hint: 'e.g. Nairobi, Kenya',
              ),
              
              const SizedBox(height: 32),
              _buildSectionTitle('Format'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _SegmentButton(
                      label: '18 Holes',
                      isSelected: _totalHoles == 18,
                      onTap: () => _updateHoleCount(18),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SegmentButton(
                      label: '9 Holes',
                      isSelected: _totalHoles == 9,
                      onTap: () => _updateHoleCount(9),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              _buildSectionTitle('Hole Pars'),
              const SizedBox(height: 12),
              const Text('Tap a hole to adjust its par value.', style: TextStyle(color: AppColors.grey500)),
              const SizedBox(height: 16),
              
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: List.generate(_totalHoles, (index) {
                  return GestureDetector(
                    onTap: () => _showParPicker(index),
                    child: Container(
                      width: 55,
                      height: 55,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.grey200),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('H${index + 1}', style: const TextStyle(fontSize: 10, color: AppColors.grey400, fontWeight: FontWeight.bold)),
                          Text('${_holePars[index]}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.grey800)),
                        ],
                      ),
                    ),
                  );
                }),
              ),
              
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: _isSaving ? null : _saveCourse,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.emerald700,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isSaving 
                      ? const CircularProgressIndicator(color: AppColors.white)
                      : const Text('Save Course', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.grey900));
  }

  Widget _buildTextField({required TextEditingController controller, required String label, String? hint, String? Function(String?)? validator}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.grey600)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: AppColors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.grey200)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.grey200)),
          ),
        ),
      ],
    );
  }

  void _showParPicker(int index) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Hole ${index + 1} Par', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [3, 4, 5, 6].map((p) => GestureDetector(
                onTap: () {
                  setState(() => _holePars[index] = p);
                  Navigator.pop(ctx);
                },
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: _holePars[index] == p ? AppColors.emerald700 : AppColors.grey100,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text('$p', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _holePars[index] == p ? AppColors.white : AppColors.grey800)),
                ),
              )).toList(),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _SegmentButton({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.grey900 : AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSelected ? AppColors.grey900 : AppColors.grey200),
        ),
        alignment: Alignment.center,
        child: Text(label, style: TextStyle(color: isSelected ? AppColors.white : AppColors.grey600, fontWeight: FontWeight.w700)),
      ),
    );
  }
}
