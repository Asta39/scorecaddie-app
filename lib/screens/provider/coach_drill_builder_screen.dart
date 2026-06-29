import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
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
  
  List<Map<String, dynamic>> _steps = [
    {'instruction': '', 'balls': 10},
  ];

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
    setState(() => _isLoadingSteps = true);
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.grey900 : const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(widget.drill == null ? 'Create Template' : 'Edit Template', 
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: CupertinoActivityIndicator(),
            )
          else
            TextButton(
              onPressed: _saveDrill,
              child: const Text('Save', style: TextStyle(color: AppColors.emerald700, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: _isLoadingSteps 
        ? const Center(child: CupertinoActivityIndicator())
        : Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionLabel('TEMPLATE INFO'),
              const SizedBox(height: 16),
              _buildCard([
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Drill Name', hintText: 'e.g., Draw Control Drills', border: InputBorder.none),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const Divider(height: 1),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Description', hintText: 'Explain the goal of this drill...', border: InputBorder.none),
                  maxLines: 3,
                ),
              ], isDark),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionLabel('CATEGORY'),
                        const SizedBox(height: 8),
                        _buildDropdownCard(
                          child: DropdownButton<String>(
                            value: _category,
                            isExpanded: true,
                            underline: const SizedBox(),
                            items: ['Swing', 'Short Game', 'Putting', 'Fitness', 'Mental']
                                .map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14))))
                                .toList(),
                            onChanged: (v) => setState(() => _category = v!),
                          ),
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionLabel('DIFFICULTY'),
                        const SizedBox(height: 8),
                        _buildDropdownCard(
                          child: DropdownButton<String>(
                            value: _difficulty,
                            isExpanded: true,
                            underline: const SizedBox(),
                            items: ['Beginner', 'Intermediate', 'Advanced', 'Expert']
                                .map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14))))
                                .toList(),
                            onChanged: (v) => setState(() => _difficulty = v!),
                          ),
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionLabel('DRILL STEPS'),
                  TextButton.icon(
                    onPressed: _addStep,
                    icon: const Icon(LucideIcons.plus, size: 14),
                    label: const Text('Add Step', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _steps.length,
                separatorBuilder: (_, _) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.grey800 : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            CircleAvatar(radius: 12, backgroundColor: AppColors.emerald700, child: Text('${index + 1}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
                            const SizedBox(width: 12),
                            const Text('Step Instructions', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.2)),
                            const Spacer(),
                            if (_steps.length > 1)
                              IconButton(
                                icon: const Icon(LucideIcons.trash2, size: 16, color: AppColors.doubleBogey), 
                                onPressed: () => _removeStep(index),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          decoration: const InputDecoration(hintText: 'e.g., Hit 10 yard pitch shots to target'),
                          onChanged: (v) => _steps[index]['instruction'] = v,
                          maxLines: null,
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            const Text('Balls to hit:', style: TextStyle(fontSize: 13, color: AppColors.grey600, fontWeight: FontWeight.w600)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Slider(
                                value: _steps[index]['balls'].toDouble(),
                                min: 1, max: 50,
                                activeColor: AppColors.emerald700,
                                inactiveColor: AppColors.emerald700.withValues(alpha: 0.1),
                                onChanged: (v) => setState(() => _steps[index]['balls'] = v.round()),
                              ),
                            ),
                            Container(
                              width: 32,
                              alignment: Alignment.center,
                              child: Text('${_steps[index]['balls']}', style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.emerald700)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.grey400, letterSpacing: 1.2));
  }

  Widget _buildCard(List<Widget> children, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.grey800 : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDropdownCard({required Widget child, required bool isDark}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.grey800 : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}
