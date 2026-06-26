import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_providers.dart';
import '../../core/models/coaching_model.dart';
import '../../widgets/top_notification.dart';

class EditSessionScreen extends ConsumerStatefulWidget {
  final CoachingSession session;
  const EditSessionScreen({super.key, required this.session});

  @override
  ConsumerState<EditSessionScreen> createState() => _EditSessionScreenState();
}

class _EditSessionScreenState extends ConsumerState<EditSessionScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _maxPlayersController;
  late TextEditingController _priceController;
  late TextEditingController _locationController;
  late TextEditingController _descriptionController;
  late int _selectedWeeks;
  late DateTime _startDate;
  
  late String _sessionType;
  late String _locationArea;
  late String _targetSkillLevel;
  late TextEditingController _prerequisitesController;
  late TextEditingController _cancellationPolicyController;

  late TimeOfDay _startTime;
  late int _durationMinutes;
  
  late Set<int> _selectedDays;
  bool _isLoading = false;

  final List<int> _durations = [30, 60, 90, 120, 180];
  final List<Map<String, dynamic>> _weekDays = [
    {'name': 'Mon', 'val': 1},
    {'name': 'Tue', 'val': 2},
    {'name': 'Wed', 'val': 3},
    {'name': 'Thu', 'val': 4},
    {'name': 'Fri', 'val': 5},
    {'name': 'Sat', 'val': 6},
    {'name': 'Sun', 'val': 7},
  ];

  late String _paymentTerms;

  final List<Map<String, String>> _termOptions = [
    {'val': 'upfront', 'name': 'Pay Upfront', 'desc': 'Students pay full price when enrolling'},
    {'val': 'post', 'name': 'Post-Session', 'desc': 'Students pay after sessions are complete'},
    {'val': 'split', 'name': '2-Tier Split', 'desc': '50% upfront, 50% upon completion'},
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.session.name);
    _descriptionController = TextEditingController(text: widget.session.description ?? '');
    _maxPlayersController = TextEditingController(text: widget.session.maxPlayers.toString());
    _priceController = TextEditingController(text: widget.session.pricePerSession.toString());
    _locationController = TextEditingController(text: widget.session.location);
    _selectedWeeks = widget.session.weeks;
    _startDate = widget.session.startDate;
    
    final parts = widget.session.startTime.split(':');
    _startTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    _durationMinutes = widget.session.durationMinutes;
    _selectedDays = widget.session.daysOfWeek.toSet();
    _paymentTerms = widget.session.paymentTerms;
    _sessionType = widget.session.sessionType;
    _locationArea = widget.session.locationArea;
    _targetSkillLevel = widget.session.targetSkillLevel;
    _prerequisitesController = TextEditingController(text: widget.session.prerequisites ?? '');
    _cancellationPolicyController = TextEditingController(text: widget.session.cancellationPolicy ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _maxPlayersController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    _prerequisitesController.dispose();
    _cancellationPolicyController.dispose();
    super.dispose();
  }

  Future<void> _updateSession() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDays.isEmpty) {
      TopNotification.showError(context, 'Please select at least one day of the week');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final coachingService = ref.read(coachingServiceProvider);
      await coachingService.updateSession(
        sessionId: widget.session.id,
        name: _nameController.text,
        description: _descriptionController.text,
        maxPlayers: int.tryParse(_maxPlayersController.text) ?? 6,
        price: double.tryParse(_priceController.text) ?? 0.0,
        durationMinutes: _durationMinutes,
        location: _locationController.text,
        daysOfWeek: _selectedDays,
        startTime: _startTime,
        weeks: _selectedWeeks,
        startDate: _startDate,
        paymentTerms: _paymentTerms,
        sessionType: _sessionType,
        locationArea: _locationArea,
        targetSkillLevel: _targetSkillLevel,
        prerequisites: _prerequisitesController.text,
        cancellationPolicy: _cancellationPolicyController.text,
      );

      if (!mounted) return;

      ref.invalidate(coachSessionsProvider);
      ref.invalidate(sessionOccurrencesProvider(widget.session.id));
      ref.invalidate(specificCoachingSessionProvider(widget.session.id));
      
      setState(() => _isLoading = false);
      TopNotification.showSuccess(context, 'Session Updated Successfully!');
      context.pop();
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        TopNotification.showError(context, 'Error updating session: $e');
      }
    }
  }

  Future<void> _cancelSession() async {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Cancel Session?'),
        content: const Text('Are you sure you want to cancel this entire session? All upcoming occurrences will be cancelled and players will be notified. This cannot be undone.'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Go Back'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isLoading = true);
              try {
                await ref.read(coachingServiceProvider).cancelSession(widget.session.id);
                ref.invalidate(coachSessionsProvider);
                if (context.mounted) {
                  setState(() => _isLoading = false);
                  TopNotification.showSuccess(context, 'Session Cancelled Successfully!');
                  context.pop(); // Go back to session detail or list
                }
              } catch (e) {
                if (context.mounted) {
                  setState(() => _isLoading = false);
                  TopNotification.showError(context, 'Error cancelling session: $e');
                }
              }
            },
            child: const Text('Cancel Session'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(context: context, initialTime: _startTime);
    if (picked != null) {
      setState(() => _startTime = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Session', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _updateSession,
            child: _isLoading 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.purple700))
              : const Text('Save', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.purple700)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          physics: const BouncingScrollPhysics(),
          children: [
            const Text('Session Details', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _nameController,
              decoration: _inputDecoration('Session Name (e.g. Morning Swing Clinic)', LucideIcons.flag),
              validator: (val) => val == null || val.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _descriptionController,
              decoration: _inputDecoration('Description', LucideIcons.alignLeft),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _maxPlayersController,
                    keyboardType: TextInputType.number,
                    decoration: _inputDecoration('Max Players', LucideIcons.users),
                    validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    decoration: _inputDecoration('Price (KES)', LucideIcons.creditCard),
                    validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _locationController,
              decoration: _inputDecoration('Club Name (e.g. Karen GC)', LucideIcons.mapPin),
              validator: (val) => val == null || val.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildLocationAreaDropdown(),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSessionTypeDropdown(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            _buildSkillLevelDropdown(),
            const SizedBox(height: 16),

            TextFormField(
              controller: _prerequisitesController,
              decoration: _inputDecoration('Prerequisites', LucideIcons.checkSquare),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _cancellationPolicyController,
              decoration: _inputDecoration('Cancellation Policy', LucideIcons.alertCircle),
              maxLines: 2,
            ),
            
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.grey50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.grey200),
              ),
              child: const Row(
                children: [
                  Icon(LucideIcons.alertTriangle, color: AppColors.grey600, size: 24),
                  SizedBox(width: 16),
                  Expanded(
                    child: Text('Note: Changing the schedule will clear upcoming session occurrences and regenerate new ones based on the new schedule.', 
                      style: TextStyle(color: AppColors.grey800, fontSize: 12, fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('Schedule', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            const SizedBox(height: 16),

            // Start Date Picker
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _startDate,
                  firstDate: DateTime.now().isBefore(_startDate) ? DateTime.now() : _startDate,
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) setState(() => _startDate = picked);
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.grey200),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.calendar, size: 20, color: AppColors.grey500),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Start Date', style: TextStyle(fontSize: 12, color: AppColors.grey500, fontWeight: FontWeight.w600)),
                        Text(DateFormat('EEEE, MMM d, yyyy').format(_startDate), 
                          style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.grey900)),
                      ],
                    ),
                    const Spacer(),
                    const Icon(LucideIcons.chevronRight, size: 16, color: AppColors.grey400),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Day Selector
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.grey100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: _weekDays.map((day) {
                  final isSelected = _selectedDays.contains(day['val']);
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedDays.remove(day['val']);
                            } else {
                              _selectedDays.add(day['val']);
                            }
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: isSelected ? [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))
                            ] : [],
                          ),
                          child: Text(
                            day['name'],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                              color: isSelected ? AppColors.emerald700 : AppColors.grey500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),
            
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _pickStartTime,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.grey200),
                      ),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.clock, size: 20, color: AppColors.grey500),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Start Time', style: TextStyle(fontSize: 12, color: AppColors.grey500, fontWeight: FontWeight.w600)),
                              Text(_startTime.format(context), style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.grey900)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.grey200),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _durationMinutes,
                        isExpanded: true,
                        icon: const Icon(LucideIcons.chevronDown, size: 20, color: AppColors.grey400),
                        items: _durations.map((d) {
                          return DropdownMenuItem<int>(
                            value: d,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('Duration', style: TextStyle(fontSize: 12, color: AppColors.grey500, fontWeight: FontWeight.w600)),
                                Text('$d min', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.grey900)),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _durationMinutes = val);
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Weeks Selector ──────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.grey200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(LucideIcons.calendarDays, size: 18, color: AppColors.grey500),
                      const SizedBox(width: 8),
                      const Text(
                        'Duration (weeks)',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.grey600),
                      ),
                      const Spacer(),
                      Text(
                        '$_selectedWeeks weeks',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.emerald700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [1, 2, 3, 4, 6, 8, 10, 12].map((w) {
                      final isSelected = _selectedWeeks == w;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedWeeks = w),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.emerald700 : AppColors.grey100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '$w',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: isSelected ? Colors.white : AppColors.grey600,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            const Text('Payment Terms', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            const SizedBox(height: 16),
            
            Column(
              children: _termOptions.map((opt) {
                final isSelected = _paymentTerms == opt['val'];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () => setState(() => _paymentTerms = opt['val']!),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? AppColors.purple700 : AppColors.grey200,
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected ? [
                          BoxShadow(color: AppColors.purple700.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))
                        ] : [],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 20, height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: isSelected ? AppColors.purple700 : AppColors.grey400, width: 2),
                              color: isSelected ? AppColors.purple700 : Colors.transparent,
                            ),
                            child: isSelected ? const Icon(Icons.check, size: 12, color: Colors.white) : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(opt['name']!, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                                Text(opt['desc']!, style: const TextStyle(color: AppColors.grey500, fontSize: 11, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            
            const SizedBox(height: 48),
            
            // Cancel Session Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton(
                onPressed: _isLoading ? null : _cancelSession,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.doubleBogey),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  foregroundColor: AppColors.doubleBogey,
                ),
                child: const Text('Cancel Session', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              ),
            ),
            
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }


  Widget _buildLocationAreaDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _locationArea,
          onChanged: (val) => setState(() => _locationArea = val!),
          items: ['Driving Range', 'Putting Green', 'Bunker Area', 'Chipping Green', 'On-Course']
              .map((val) => DropdownMenuItem(value: val, child: Text(val, style: const TextStyle(fontSize: 13))))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildSessionTypeDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _sessionType,
          onChanged: (val) => setState(() => _sessionType = val!),
          items: ['Group', '1-on-1', 'Clinic', 'Camp']
              .map((val) => DropdownMenuItem(value: val, child: Text(val, style: const TextStyle(fontSize: 13))))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildSkillLevelDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _targetSkillLevel,
          onChanged: (val) => setState(() => _targetSkillLevel = val!),
          isExpanded: true,
          items: ['All', 'Beginner', 'Intermediate', 'Advanced']
              .map((val) => DropdownMenuItem(value: val, child: Text(val, style: const TextStyle(fontSize: 13))))
              .toList(),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.grey500, fontWeight: FontWeight.w600, fontSize: 14),
      prefixIcon: Icon(icon, color: AppColors.grey400, size: 20),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.grey200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.grey200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.purple700, width: 2),
      ),
    );
  }
}
