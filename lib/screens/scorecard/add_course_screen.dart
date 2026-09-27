import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/services.dart';
import '../onboarding/ob_app.dart';
import '../onboarding/ob_forms.dart';
import '../onboarding/ob_style.dart';
import '../../providers/app_providers.dart';
import '../../core/database/database.dart';
import '../../widgets/top_notification.dart';

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
      final supabaseId = const Uuid().v4();
      
      final int front9Par = _holePars.sublist(0, _totalHoles == 18 ? 9 : _totalHoles).reduce((a, b) => a + b);
      int? back9Par;
      if (_totalHoles == 18) {
        back9Par = _holePars.sublist(9, 18).reduce((a, b) => a + b);
      }
      
      final totalPar = front9Par + (back9Par ?? 0);

      await db.into(db.courses).insert(
        CoursesCompanion.insert(
          supabaseId: drift.Value(supabaseId),
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

      // Sync to Supabase
      try {
        final savedCourse = await db.getCourseBySupabaseId(supabaseId);
        if (savedCourse != null) {
          await ref.read(syncServiceProvider).syncCourse(savedCourse);
        }
      } catch (e) {
        debugPrint('Error syncing custom course: $e');
      }

      ref.invalidate(coursesProvider);
      
      if (!mounted) return;
      context.pop();
      TopNotification.showSuccess(context, 'Course added successfully!');
    } catch (e) {
      setState(() => _isSaving = false);
      TopNotification.showError(context, 'Error adding course: $e');
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    final par = _holePars.fold(0, (a, b) => a + b);
    return Scaffold(
      backgroundColor: Ob.bg,
      body: DefaultTextStyle(
        style: Ob.textBase,
        child: SafeArea(
          bottom: false,
          child: Form(
            key: _formKey,
            child: Column(children: [
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: [
                    ObTopBar('Add a course', onBack: () => context.pop()),
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: _nameController,
                      cursorColor: Ob.lime,
                      textCapitalization: TextCapitalization.words,
                      style: Ob.body(15, weight: FontWeight.w700),
                      decoration: obInput('Course name', hint: 'Windsor Golf Club'),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Needs a name' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _locationController,
                      cursorColor: Ob.lime,
                      textCapitalization: TextCapitalization.words,
                      style: Ob.body(15, weight: FontWeight.w700),
                      decoration: obInput('Where', hint: 'Nairobi'),
                    ),
                    const SizedBox(height: 20),
                    const ObEyebrow('Holes'),
                    const SizedBox(height: 10),
                    ObGooSegmented<int>(options: const [(18, '18 holes'), (9, '9 holes')], selected: _totalHoles, onChanged: _updateHoleCount),
                    const SizedBox(height: 20),
                    ObEyebrow('Par for each hole · $par total'),
                    const SizedBox(height: 4),
                    Text('Tap a hole to change it: 3, 4, 5, then back to 3.', style: Ob.body(12, color: Ob.creamA(.55))),
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 6, mainAxisSpacing: 8, crossAxisSpacing: 8),
                      itemCount: _totalHoles,
                      itemBuilder: (_, i) {
                        final p = _holePars[i];
                        final c = p == 3 ? const Color(0xFF7DD3FC) : (p == 5 ? const Color(0xFFF5C531) : Ob.lime);
                        return Semantics(
                          button: true,
                          label: 'Hole ${i + 1}, par $p',
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _holePars[i] = p >= 5 ? 3 : p + 1);
                            },
                            onLongPress: () => _showParPicker(i),
                            child: Container(
                              decoration: BoxDecoration(color: Ob.cardFill, borderRadius: BorderRadius.circular(14), border: Border.all(color: c.withValues(alpha: .35))),
                              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                Text('${i + 1}', style: Ob.body(10, color: Ob.creamA(.5))),
                                Text('$p', style: Ob.display(20, color: c, height: 1.1)),
                              ]),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(20, 10, 20, 14 + MediaQuery.of(context).padding.bottom),
                child: SizedBox(
                  width: double.infinity,
                  child: ObButton(
                    onPressed: _isSaving ? null : _saveCourse,
                    child: Text(_isSaving ? 'Saving…' : 'Save course', style: Ob.label(17, weight: FontWeight.w800)),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  void _showParPicker(int index) {
    showObSheet(
      context,
      (ctx) => ObSheet(
        title: 'Hole ${index + 1}',
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          for (final p in const [3, 4, 5, 6])
            GestureDetector(
              onTap: () {
                setState(() => _holePars[index] = p);
                Navigator.pop(ctx);
              },
              child: Container(
                width: 62,
                height: 62,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: _holePars[index] == p ? Ob.lime : Ob.cardFill, shape: BoxShape.circle),
                child: Text('$p', style: Ob.display(26, color: _holePars[index] == p ? Ob.ink : Ob.cream)),
              ),
            ),
        ]),
      ),
    );
  }
}
