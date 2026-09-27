import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import '../onboarding/ob_app.dart';
import '../onboarding/ob_style.dart';
import 'coach_dashboard_screen.dart' show coachGold;
import '../../providers/app_providers.dart';
import '../../widgets/top_notification.dart';

class CoachDrillBuilderScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? drill;
  const CoachDrillBuilderScreen({super.key, this.drill});

  @override
  ConsumerState<CoachDrillBuilderScreen> createState() => _CoachDrillBuilderScreenState();
}

class _CoachDrillBuilderScreenState extends ConsumerState<CoachDrillBuilderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _difficulty = 'Intermediate';
  String _category = 'Swing';
  int _duration = 15;
  bool _isSaving = false;
  bool _isLoadingSteps = false;
  // Saving an edited drill deletes its existing steps and re-inserts whatever
  // is on screen. If the original steps failed to load, the screen still holds
  // the default single blank step — saving in that state would silently wipe
  // the real ones, so saving stays blocked until a reload succeeds.
  bool _stepsLoadFailed = false;
  
  List<Map<String, dynamic>> _steps = [
    {'instruction': '', 'balls': 10},
  ];
  // Steps get a stable key so their text fields keep the right text when
  // one above them is removed, and show loaded instructions when editing.
  int _nextKey = 0;
  final _keys = <Map<String, dynamic>, Key>{};
  Key _keyFor(Map<String, dynamic> step) => _keys.putIfAbsent(step, () => ValueKey(_nextKey++));

  @override
  void initState() {
    super.initState();
    if (widget.drill != null) {
      _nameController.text = widget.drill!['name'] ?? '';
      _descriptionController.text = widget.drill!['description'] ?? '';
      _difficulty = widget.drill!['difficulty'] ?? 'Intermediate';
      _category = widget.drill!['category'] ?? 'Swing';
      _duration = (widget.drill!['duration_minutes'] as num?)?.toInt() ?? 15;
      _loadSteps();
    }
  }

  Future<void> _loadSteps() async {
    setState(() {
      _isLoadingSteps = true;
      _stepsLoadFailed = false;
    });
    try {
      final steps = await ref.read(coachingServiceProvider).getDrillSteps(widget.drill!['id']);
      if (steps.isNotEmpty) {
        setState(() {
          _steps = steps.map((s) => {
            'instruction': s['instruction'],
            'balls': (s['balls_required'] as num).toInt(),
          }).toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading steps: $e');
      setState(() => _stepsLoadFailed = true);
    } finally {
      setState(() => _isLoadingSteps = false);
    }
  }

  void _addStep() {
    setState(() {
      _steps.add({'instruction': '', 'balls': 10});
    });
  }

  void _removeStep(int index) {
    if (_steps.length > 1) {
      setState(() => _steps.removeAt(index));
    }
  }

  Future<void> _saveDrill() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);

    try {
      if (widget.drill == null) {
        await ref.read(coachingServiceProvider).createDrillTemplate(
          name: _nameController.text,
          description: _descriptionController.text,
          category: _category,
          difficulty: _difficulty,
          durationMinutes: _duration,
          steps: _steps,
        );
      } else {
        await ref.read(coachingServiceProvider).updateDrillTemplate(
          drillId: widget.drill!['id'],
          name: _nameController.text,
          description: _descriptionController.text,
          category: _category,
          difficulty: _difficulty,
          durationMinutes: _duration,
          steps: _steps,
        );
      }

      ref.invalidate(coachDrillTemplatesProvider);

      if (mounted) {
        TopNotification.showSuccess(context, widget.drill == null ? 'Drill Template Created!' : 'Drill Template Updated!');
        context.pop();
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        TopNotification.showError(context, 'Error: $e');
      }
    }
  }

  static const _categories = ['Swing', 'Short Game', 'Putting', 'Fitness', 'Mental'];
  static const _levels = ['Beginner', 'Intermediate', 'Advanced', 'Expert'];
  static const _durations = [5, 10, 15, 20, 30, 45, 60];

  InputDecoration _input(String label, {String? hint}) => InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: Ob.body(13, color: Ob.creamA(.6)),
        floatingLabelStyle: Ob.body(13, weight: FontWeight.w700, color: coachGold),
        hintStyle: Ob.body(14, color: Ob.creamA(.3)),
        errorStyle: Ob.body(12, color: Ob.warn),
        filled: true,
        fillColor: Ob.cardFill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: coachGold, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: Ob.warn)),
      );

  Widget _chips(String label, List<String> options, String selected, ValueChanged<String> onTap) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ObEyebrow(label),
      const SizedBox(height: 10),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final o in options) GestureDetector(onTap: () => onTap(o), child: ObChip(o, on: o == selected, color: coachGold)),
      ]),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final totalBalls = _steps.fold<int>(0, (a, s) => a + (s['balls'] as int));
    final canSave = !_isSaving && !_isLoadingSteps && !_stepsLoadFailed;

    return Scaffold(
      backgroundColor: Ob.bg,
      body: DefaultTextStyle(
        style: Ob.textBase,
        child: SafeArea(
          bottom: false,
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 20, 0),
              child: Row(children: [
                ObIconButton(icon: LucideIcons.chevronLeft, label: 'Back', onPressed: () => context.pop()),
                const SizedBox(width: 10),
                Text(widget.drill == null ? 'New drill' : 'Edit drill', style: Ob.display(24)),
              ]),
            ),
            Expanded(
              child: _isLoadingSteps
                  ? const Center(child: CupertinoActivityIndicator(color: coachGold))
                  : _stepsLoadFailed
                      ? Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Text('Couldn\'t load this drill\'s steps.', textAlign: TextAlign.center, style: Ob.display(22)),
                            const SizedBox(height: 8),
                            Text('Saving now would wipe them, so it\'s off until they load.', textAlign: TextAlign.center, style: Ob.body(14, color: Ob.creamA(.7))),
                            const SizedBox(height: 20),
                            ObButton(onPressed: _loadSteps, child: Text('Try again', style: Ob.label(15, weight: FontWeight.w800))),
                          ]),
                        )
                      : Form(
                          key: _formKey,
                          child: ListView(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                            children: [
                              TextFormField(
                                controller: _nameController,
                                cursorColor: coachGold,
                                style: Ob.body(15, weight: FontWeight.w700),
                                decoration: _input('Name', hint: 'Gate putting'),
                                validator: (v) => v == null || v.trim().isEmpty ? 'Needed' : null,
                              ),
                              const SizedBox(height: 10),
                              TextFormField(
                                controller: _descriptionController,
                                cursorColor: coachGold,
                                maxLines: 3,
                                style: Ob.body(15, weight: FontWeight.w600),
                                decoration: _input('What it trains'),
                              ),
                              const SizedBox(height: 18),
                              _chips('Area', _categories, _categories.contains(_category) ? _category : '', (v) => setState(() => _category = v)),
                              const SizedBox(height: 18),
                              _chips('Level', _levels, _levels.contains(_difficulty) ? _difficulty : '', (v) => setState(() => _difficulty = v)),
                              const SizedBox(height: 18),
                              _chips('Takes about', [for (final d in {..._durations, _duration}.toList()..sort()) '$d min'], '$_duration min',
                                  (v) => setState(() => _duration = int.parse(v.split(' ').first))),
                              const SizedBox(height: 24),
                              ObEyebrow('Steps · $totalBalls balls'),
                              const SizedBox(height: 10),
                              for (final (i, step) in _steps.indexed)
                                Padding(
                                  key: _keyFor(step),
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: ObCard(
                                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Row(children: [
                                        Container(
                                          width: 28,
                                          height: 28,
                                          alignment: Alignment.center,
                                          decoration: const BoxDecoration(color: coachGold, shape: BoxShape.circle),
                                          child: Text('${i + 1}', style: Ob.body(13, weight: FontWeight.w800, color: Ob.ink)),
                                        ),
                                        const SizedBox(width: 10),
                                        Text('Step ${i + 1}', style: Ob.body(14, weight: FontWeight.w800)),
                                        const Spacer(),
                                        if (_steps.length > 1)
                                          IconButton(
                                            tooltip: 'Remove step',
                                            onPressed: () => _removeStep(i),
                                            icon: Icon(LucideIcons.trash2, size: 18, color: Ob.creamA(.5)),
                                          ),
                                      ]),
                                      const SizedBox(height: 10),
                                      TextFormField(
                                        initialValue: step['instruction'] as String? ?? '',
                                        onChanged: (v) => step['instruction'] = v,
                                        cursorColor: coachGold,
                                        maxLines: null,
                                        style: Ob.body(15, weight: FontWeight.w600),
                                        decoration: _input('What to do', hint: 'Hit 10 pitches to the flag').copyWith(fillColor: Ob.creamA(.05)),
                                        validator: (v) => v == null || v.trim().isEmpty ? 'Needed' : null,
                                      ),
                                      const SizedBox(height: 12),
                                      Row(children: [
                                        Text('Balls', style: Ob.body(13, color: Ob.creamA(.6))),
                                        Expanded(
                                          child: SliderTheme(
                                            data: SliderTheme.of(context).copyWith(
                                              activeTrackColor: coachGold,
                                              inactiveTrackColor: Ob.creamA(.1),
                                              thumbColor: coachGold,
                                              overlayColor: coachGold.withValues(alpha: .15),
                                            ),
                                            child: Slider(
                                              value: (step['balls'] as int).toDouble().clamp(1, 50),
                                              min: 1,
                                              max: 50,
                                              label: 'Balls',
                                              onChanged: (v) => setState(() => step['balls'] = v.round()),
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 30, child: Text('${step['balls']}', textAlign: TextAlign.end, style: Ob.display(18, color: coachGold))),
                                      ]),
                                    ]),
                                  ),
                                ),
                              ObButton(
                                tone: ObButtonTone.dark,
                                onPressed: _addStep,
                                child: Row(mainAxisSize: MainAxisSize.min, children: [
                                  const Icon(LucideIcons.plus, size: 18, color: Ob.cream),
                                  const SizedBox(width: 8),
                                  Text('Add a step', style: Ob.label(15, weight: FontWeight.w800)),
                                ]),
                              ),
                            ],
                          ),
                        ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20, 10, 20, 14 + MediaQuery.of(context).padding.bottom),
              child: SizedBox(
                width: double.infinity,
                child: ObButton(
                  onPressed: canSave ? _saveDrill : null,
                  child: Text(_isSaving ? 'Saving…' : (widget.drill == null ? 'Save drill' : 'Save changes'), style: Ob.label(16, weight: FontWeight.w800)),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
