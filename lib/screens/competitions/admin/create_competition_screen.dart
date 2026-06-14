import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/competition_providers.dart';
import '../../../widgets/loading_spinner.dart';

class CreateCompetitionScreen extends ConsumerStatefulWidget {
  const CreateCompetitionScreen({super.key});

  @override
  ConsumerState<CreateCompetitionScreen> createState() =>
      _CreateCompetitionScreenState();
}

class _CreateCompetitionScreenState
    extends ConsumerState<CreateCompetitionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _feeController = TextEditingController(text: '0');

  String _selectedType = 'stableford';
  DateTime _startDate = DateTime.now().add(const Duration(days: 7));
  DateTime? _entryDeadline;
  int _handicapAllowance = 100;
  int _maxHandicap = 36;
  String _tiebreaker = 'countback';

  static const _formats = [
    ('stableford', 'Stableford'),
    ('strokeplay', 'Stroke Play'),
    ('matchplay', 'Match Play'),
    ('betterball', 'Better Ball'),
    ('foursome', 'Foursome'),
    ('bogey', 'Bogey'),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _feeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final actionState = ref.watch(competitionActionsProvider);
    final clubIdAsync = ref.watch(playerHomeClubIdProvider);

    return Scaffold(
      backgroundColor: AppColors.grey50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Create Competition',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 18,
            color: AppColors.grey900,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Section(
                title: 'Basic Details',
                children: [
                  _Field(
                    label: 'Competition Name *',
                    child: TextFormField(
                      controller: _nameController,
                      decoration: _inputDecoration(
                          'e.g. Club Championship 2025'),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _Field(
                    label: 'Description (optional)',
                    child: TextFormField(
                      controller: _descController,
                      maxLines: 3,
                      decoration: _inputDecoration(
                          'Rules, notes, sponsor info...'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              _Section(
                title: 'Format',
                children: [
                  ...(_formats.map((f) {
                    final selected = _selectedType == f.$1;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedType = f.$1),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: selected ? AppColors.grey900 : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected
                                ? AppColors.grey900
                                : AppColors.grey200,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              selected
                                  ? LucideIcons.checkCircle2
                                  : LucideIcons.circle,
                              size: 18,
                              color: selected
                                  ? Colors.white
                                  : AppColors.grey300,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              f.$2,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: selected
                                    ? Colors.white
                                    : AppColors.grey700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  })),
                ],
              ),
              const SizedBox(height: 20),

              _Section(
                title: 'Schedule',
                children: [
                  _DatePickerRow(
                    label: 'Competition Date *',
                    date: _startDate,
                    onPick: () => _pickDate(context, isDeadline: false),
                  ),
                  const SizedBox(height: 12),
                  _DatePickerRow(
                    label: 'Entry Deadline',
                    date: _entryDeadline,
                    onPick: () => _pickDate(context, isDeadline: true),
                    optional: true,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              _Section(
                title: 'Entry Fee',
                children: [
                  TextFormField(
                    controller: _feeController,
                    keyboardType: TextInputType.number,
                    decoration: _inputDecoration('0').copyWith(
                      prefixText: 'KES  ',
                      prefixStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.grey500,
                      ),
                    ),
                    validator: (v) {
                      if (v != null && v.isNotEmpty) {
                        final parsed = double.tryParse(v);
                        if (parsed == null || parsed < 0) {
                          return 'Enter a valid amount';
                        }
                      }
                      return null;
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),

              _Section(
                title: 'Rules',
                children: [
                  _SliderRow(
                    label: 'Handicap Allowance',
                    value: _handicapAllowance.toDouble(),
                    min: 50,
                    max: 100,
                    divisions: 10,
                    format: '$_handicapAllowance%',
                    onChanged: (v) =>
                        setState(() => _handicapAllowance = v.round()),
                  ),
                  const SizedBox(height: 12),
                  _SliderRow(
                    label: 'Max Handicap',
                    value: _maxHandicap.toDouble(),
                    min: 18,
                    max: 54,
                    divisions: 36,
                    format: '$_maxHandicap',
                    onChanged: (v) =>
                        setState(() => _maxHandicap = v.round()),
                  ),
                  const SizedBox(height: 12),
                  _Field(
                    label: 'Tiebreaker',
                    child: DropdownButtonFormField<String>(
                      value: _tiebreaker,
                      decoration: _inputDecoration(''),
                      items: const [
                        DropdownMenuItem(
                            value: 'countback', child: Text('Countback')),
                        DropdownMenuItem(
                            value: 'sudden_death',
                            child: Text('Sudden Death')),
                        DropdownMenuItem(
                            value: 'match_of_cards',
                            child: Text('Match of Cards')),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => _tiebreaker = v);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              if (actionState.errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(actionState.errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 13)),
                ),
                const SizedBox(height: 16),
              ],

              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: actionState.isLoading
                      ? null
                      : () => _submit(context, clubIdAsync.valueOrNull),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.emerald700,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: actionState.isLoading
                      ? const LoadingSpinner(size: 24)
                      : const Text(
                          'Create Competition',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate(BuildContext context,
      {required bool isDeadline}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isDeadline
          ? (_entryDeadline ?? _startDate.subtract(const Duration(days: 2)))
          : _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() {
        if (isDeadline) {
          _entryDeadline = picked;
        } else {
          _startDate = picked;
        }
      });
    }
  }

  Future<void> _submit(BuildContext context, String? clubId) async {
    if (!_formKey.currentState!.validate()) return;
    if (clubId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No club found. Are you a club admin?'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    final profile = ref.read(userProfileProvider).valueOrNull;
    if (profile == null) return;

    final id = await ref
        .read(competitionActionsProvider.notifier)
        .createCompetition(
          clubId: clubId,
          name: _nameController.text.trim(),
          description: _descController.text.trim().isEmpty
              ? null
              : _descController.text.trim(),
          competitionType: _selectedType,
          startDate: _startDate,
          entryDeadline: _entryDeadline,
          entryFee:
              double.tryParse(_feeController.text.trim()) ?? 0,
          rulesConfig: {
            'handicap_allowance_pct': _handicapAllowance,
            'max_handicap': _maxHandicap,
            'flights': [],
            'tiebreaker': _tiebreaker,
          },
          createdBy: profile.uid ?? '',
        );

    if (id != null && context.mounted) {
      context.pushReplacement('/competitions/$id');
    }
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.grey300),
      filled: true,
      fillColor: Colors.white,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.grey200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.grey200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            const BorderSide(color: AppColors.emerald700, width: 1.5),
      ),
    );
  }
}

// ─── Helper widgets ───────────────────────────────────────────────────────────
class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppColors.grey400,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        ...children,
      ],
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final Widget child;

  const _Field({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.grey600)),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _DatePickerRow extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onPick;
  final bool optional;

  const _DatePickerRow({
    required this.label,
    required this.date,
    required this.onPick,
    this.optional = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPick,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.grey200),
        ),
        child: Row(
          children: [
            const Icon(LucideIcons.calendar,
                size: 16, color: AppColors.grey400),
            const SizedBox(width: 10),
            Text(label,
                style: const TextStyle(
                    color: AppColors.grey500,
                    fontWeight: FontWeight.w500,
                    fontSize: 13)),
            const Spacer(),
            Text(
              date != null
                  ? DateFormat('d MMM y').format(date!)
                  : optional
                      ? 'Optional'
                      : 'Select',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: date != null
                    ? AppColors.grey900
                    : AppColors.grey300,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String format;
  final ValueChanged<double> onChanged;

  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.format,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.grey600)),
            Text(format,
                style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.grey900)),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          activeColor: AppColors.emerald700,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
