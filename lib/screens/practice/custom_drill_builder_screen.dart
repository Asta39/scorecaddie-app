import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:drift/drift.dart' as drift;
import '../../core/theme/app_theme.dart';
import '../../providers/app_providers.dart';
import '../../core/database/database.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/top_notification.dart';

class CustomDrillBuilderScreen extends ConsumerStatefulWidget {
  const CustomDrillBuilderScreen({super.key});

  @override
  ConsumerState<CustomDrillBuilderScreen> createState() => _CustomDrillBuilderScreenState();
}

class _CustomDrillBuilderScreenState extends ConsumerState<CustomDrillBuilderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _difficulty = 'Intermediate';
  int _duration = 20;
  
  final List<Map<String, dynamic>> _steps = [
    {'instruction': '', 'balls': 10},
  ];

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

    final db = ref.read(databaseProvider);
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    final drillId = await db.into(db.drills).insert(
      DrillsCompanion.insert(
        userId: drift.Value(user.uid),
        name: _nameController.text,
        description: _descriptionController.text,
        category: drift.Value('Custom'),
        difficulty: _difficulty,
        durationMinutes: _duration,
        icon: drift.Value('target'),
        isCustom: const drift.Value(true),
      ),
    );

    for (int i = 0; i < _steps.length; i++) {
      await db.into(db.drillSteps).insert(
        DrillStepsCompanion.insert(
          drillId: drillId,
          instruction: _steps[i]['instruction'],
          ballsRequired: _steps[i]['balls'],
          stepOrder: i,
        ),
      );
    }

    if (mounted) {
      TopNotification.showSuccess(context, 'Custom Drill Created!');
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Custom Drill', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: _saveDrill,
            child: const Text('Save', style: TextStyle(color: AppColors.emerald700, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionLabel('BASIC INFO'),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Drill Name', hintText: 'e.g., Short Game Mastery'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description', hintText: 'What are you working on?'),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Difficulty', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.grey500)),
                        DropdownButton<String>(
                          value: _difficulty,
                          isExpanded: true,
                          items: ['Beginner', 'Intermediate', 'Advanced', 'Expert']
                              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                              .toList(),
                          onChanged: (v) => setState(() => _difficulty = v!),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Duration (min)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.grey500)),
                        DropdownButton<int>(
                          value: _duration,
                          isExpanded: true,
                          items: [5, 10, 15, 20, 30, 45, 60]
                              .map((i) => DropdownMenuItem(value: i, child: Text('$i min')))
                              .toList(),
                          onChanged: (v) => setState(() => _duration = v!),
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
                    label: const Text('Add Step', style: TextStyle(fontSize: 12)),
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
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.grey50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.grey200),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            CircleAvatar(radius: 12, backgroundColor: AppColors.grey900, child: Text('${index + 1}', style: const TextStyle(color: Colors.white, fontSize: 10))),
                            const SizedBox(width: 12),
                            const Text('Step Details', style: TextStyle(fontWeight: FontWeight.bold)),
                            const Spacer(),
                            if (_steps.length > 1)
                              IconButton(icon: const Icon(LucideIcons.trash2, size: 16, color: AppColors.doubleBogey), onPressed: () => _removeStep(index)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          decoration: const InputDecoration(labelText: 'Instruction', hintText: 'e.g., Hit 10 yard pitch shots'),
                          onChanged: (v) => _steps[index]['instruction'] = v,
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Text('Balls to hit:', style: TextStyle(fontSize: 13, color: AppColors.grey600)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Slider(
                                value: _steps[index]['balls'].toDouble(),
                                min: 1, max: 50,
                                activeColor: AppColors.emerald700,
                                onChanged: (v) => setState(() => _steps[index]['balls'] = v.round()),
                              ),
                            ),
                            Text('${_steps[index]['balls']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.grey400, letterSpacing: 1.2));
  }
}
