import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import '../onboarding/ob_app.dart';
import '../onboarding/ob_style.dart';
import '../onboarding/ob_forms.dart';
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
        TopNotification.showSuccess(context, widget.drill == null ? 'Drill saved' : 'Drill updated');
        context.pop();
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        TopNotification.showError(context, 'Couldn’t save the drill: $e');
      }
    }
  }

  static const _categories = ['Swing', 'Short Game', 'Putting', 'Fitness', 'Mental'];
  static const _levels = ['Beginner', 'Intermediate', 'Advanced', 'Expert'];
  static const _durations = [5, 10, 15, 20, 30, 45, 60];

  InputDecoration _input(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: Ob.body(17, color: Ob.creamA(.3)),
        errorStyle: Ob.body(12, color: Ob.warn),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      );

  Future<void> _choose(String title, List<String> options, String selected, ValueChanged<String> onPick) async {
    final v = await showCupertinoModalPopup<String>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(title),
        actions: [
          for (final o in options)
            CupertinoActionSheetAction(isDefaultAction: o == selected, onPressed: () => Navigator.pop(ctx, o), child: Text(o)),
        ],
        cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
      ),
    );
    if (v != null) setState(() => onPick(v));
  }

  Widget _balls(Map<String, dynamic> step) {
    final n = step['balls'] as int;
    Widget btn(IconData icon, String label, int next) => Semantics(
          button: true,
          label: label,
          child: GestureDetector(
            onTap: next < 1 || next > 50 ? null : () => setState(() => step['balls'] = next),
            child: SizedBox(width: 44, height: 32, child: Icon(icon, size: 18, color: next < 1 || next > 50 ? Ob.creamA(.3) : Ob.cream)),
          ),
        );
    return Row(mainAxisSize: MainAxisSize.min, children: [
      SizedBox(width: 32, child: Text('$n', textAlign: TextAlign.center, style: Ob.body(17, color: Ob.creamA(.6)))),
      const SizedBox(width: 8),
      Container(
        decoration: BoxDecoration(color: Ob.field, borderRadius: BorderRadius.circular(8)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          btn(LucideIcons.minus, 'Fewer balls', n - 1),
          Container(width: 1, height: 18, color: Ob.creamA(.2)),
          btn(LucideIcons.plus, 'More balls', n + 1),
        ]),
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final totalBalls = _steps.fold<int>(0, (a, s) => a + (s['balls'] as int));
    final canSave = !_isSaving && !_isLoadingSteps && !_stepsLoadFailed;
    final title = widget.drill == null ? 'New drill' : 'Edit drill';

    return Scaffold(
      backgroundColor: Ob.bg,
      body: DefaultTextStyle(
        style: Ob.textBase,
        child: SafeArea(
          bottom: false,
          child: Column(children: [
            Expanded(
              child: _isLoadingSteps
                  ? const Center(child: CupertinoActivityIndicator(color: Ob.lime))
                  : _stepsLoadFailed
                      ? Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          child: Column(children: [
                            ObTopBar(title, onBack: () => context.pop()),
                            const Spacer(),
                            Text('Couldn’t load this drill’s steps', textAlign: TextAlign.center, style: Ob.display(22)),
                            const SizedBox(height: 8),
                            Text('Saving now would wipe them, so it’s off until they load.', textAlign: TextAlign.center, style: Ob.body(15, color: Ob.creamA(.6))),
                            const SizedBox(height: 20),
                            ObButton(height: 50, radius: 14, onPressed: _loadSteps, child: Text('Try again', style: Ob.label(17))),
                            const Spacer(),
                          ]),
                        )
                      : Form(
                          key: _formKey,
                          child: ListView(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                            children: [
                              ObTopBar(title, onBack: () => context.pop()),
                              const SizedBox(height: 14),
                              ObGroup(children: [
                                TextFormField(
                                  controller: _nameController,
                                  cursorColor: Ob.lime,
                                  style: Ob.body(17),
                                  decoration: _input('Name, e.g. Gate putting'),
                                  validator: (v) => v == null || v.trim().isEmpty ? 'Needed' : null,
                                ),
                                TextFormField(
                                  controller: _descriptionController,
                                  cursorColor: Ob.lime,
                                  minLines: 1,
                                  maxLines: 3,
                                  style: Ob.body(17),
                                  decoration: _input('What it trains (optional)'),
                                ),
                              ]),
                              const SizedBox(height: 22),
                              ObGroup(children: [
                                ObRow('Area', value: _category, onTap: () => _choose('Area', _categories, _category, (v) => _category = v)),
                                ObRow('Level', value: _difficulty, onTap: () => _choose('Level', _levels, _difficulty, (v) => _difficulty = v)),
                                ObRow('Takes about', value: '$_duration min',
                                    onTap: () => _choose('Takes about', [for (final d in {..._durations, _duration}.toList()..sort()) '$d min'], '$_duration min',
                                        (v) => _duration = int.parse(v.split(' ').first))),
                              ]),
                              for (final (i, step) in _steps.indexed) ...[
                                const SizedBox(height: 22),
                                ObGroup(
                                  key: _keyFor(step),
                                  header: 'Step ${i + 1}',
                                  children: [
                                    TextFormField(
                                      initialValue: step['instruction'] as String? ?? '',
                                      onChanged: (v) => step['instruction'] = v,
                                      cursorColor: Ob.lime,
                                      minLines: 1,
                                      maxLines: null,
                                      style: Ob.body(17),
                                      decoration: _input('What to do, e.g. 10 pitches to the flag'),
                                      validator: (v) => v == null || v.trim().isEmpty ? 'Needed' : null,
                                    ),
                                    ObRow('Balls', trailing: _balls(step)),
                                    if (_steps.length > 1) ObRow('Remove step', titleColor: Ob.warn, onTap: () => _removeStep(i)),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 22),
                              ObGroup(footer: '$totalBalls balls in total.', children: [
                                ObRow('Add a step', titleColor: Ob.lime, onTap: _addStep),
                              ]),
                            ],
                          ),
                        ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 10 + MediaQuery.of(context).padding.bottom),
              child: SizedBox(
                width: double.infinity,
                child: ObButton(
                  height: 54,
                  radius: 14,
                  onPressed: canSave ? _saveDrill : null,
                  child: Text(_isSaving ? 'Saving…' : (widget.drill == null ? 'Save drill' : 'Save changes'), style: Ob.label(17)),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
