import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/design_system.dart';
import '../../../../core/widgets/asmita_sub_header.dart';
import '../../../../core/widgets/asmita_toast.dart';

/// Dedicated Settings Screen for Department Delegation:
/// - Department Head / Director / Executive out-of-office visitor approval delegation
/// - Enable / disable delegation switch
/// - Delegate staff member selection with designations
/// - Date range window with quick duration presets
class DepartmentDelegationScreen extends StatefulWidget {
  final int departmentId;
  final String departmentName;

  const DepartmentDelegationScreen({
    super.key,
    this.departmentId = 1,
    this.departmentName = 'General HQ',
  });

  @override
  State<DepartmentDelegationScreen> createState() => _DepartmentDelegationScreenState();
}

class _DepartmentDelegationScreenState extends State<DepartmentDelegationScreen> {
  bool _isDelegationEnabled = true;
  int? _selectedDelegateId = 102;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 7));
  bool _isSubmitting = false;

  final List<Map<String, dynamic>> _departmentStaff = [
    {
      'id': 102,
      'name': 'Aditi Sharma',
      'designation': 'Executive Assistant & Desk Officer',
      'email': 'aditi.sharma@asmita.com',
      'avatarColor': Color(0xFF2563EB),
    },
    {
      'id': 103,
      'name': 'Rahul Verma',
      'designation': 'Operations & Floor Supervisor',
      'email': 'rahul.verma@asmita.com',
      'avatarColor': Color(0xFF059669),
    },
    {
      'id': 104,
      'name': 'Pooja Iyer',
      'designation': 'Senior Workplace Administrator',
      'email': 'pooja.iyer@asmita.com',
      'avatarColor': Color(0xFF7C3AED),
    },
  ];

  Future<void> _selectDateRange() async {
    HapticFeedback.selectionClick();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AsmitaPalette.deepNavy,
              onPrimary: Colors.white,
              onSurface: AsmitaPalette.textDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  void _applyQuickPreset(int days) {
    HapticFeedback.selectionClick();
    setState(() {
      _startDate = DateTime.now();
      _endDate = DateTime.now().add(Duration(days: days));
    });
  }

  void _submitDelegation() {
    HapticFeedback.mediumImpact();
    if (_isDelegationEnabled && _selectedDelegateId == null) {
      AsmitaToast.show(
        context,
        message: 'Please select a delegate staff member before activating.',
        type: AsmitaToastType.error,
      );
      return;
    }

    setState(() => _isSubmitting = true);

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() => _isSubmitting = false);

      final delegate = _departmentStaff.firstWhere(
        (s) => s['id'] == _selectedDelegateId,
        orElse: () => _departmentStaff.first,
      );

      final msg = _isDelegationEnabled
          ? 'Delegation active for ${delegate['name']} (${DateFormat('dd MMM').format(_startDate)} - ${DateFormat('dd MMM').format(_endDate)})'
          : 'Department delegation has been disabled.';

      AsmitaToast.show(
        context,
        message: msg,
        type: AsmitaToastType.success,
      );
      Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateFormat = DateFormat('dd MMM yyyy');

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Standard Unified SubHeader
            const AsmitaSubHeader(title: 'Department Delegation'),

            // Scrollable Settings Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Info Banner
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AsmitaPalette.deepNavy.withValues(alpha: isDark ? 0.2 : 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AsmitaPalette.deepNavy.withValues(alpha: isDark ? 0.35 : 0.18),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AsmitaPalette.deepNavy.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.admin_panel_settings_rounded,
                              color: AsmitaPalette.deepNavy,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${widget.departmentName} Authority',
                                  style: const TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                const Text(
                                  'When you are away or out of office, your chosen delegate will receive visitor pass approval notifications on your behalf.',
                                  style: TextStyle(fontSize: 12, height: 1.4, color: AsmitaPalette.textLight),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Master Toggle Card
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Theme.of(context).dividerColor),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Enable Out-of-Office Delegation',
                                  style: TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  _isDelegationEnabled
                                      ? 'Delegation is currently ACTIVE'
                                      : 'Delegation is turned OFF',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: _isDelegationEnabled
                                        ? AsmitaPalette.successGreen
                                        : AsmitaPalette.textLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch.adaptive(
                            value: _isDelegationEnabled,
                            activeTrackColor: AsmitaPalette.deepNavy,
                            onChanged: (val) {
                              HapticFeedback.selectionClick();
                              setState(() => _isDelegationEnabled = val);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    if (_isDelegationEnabled) ...[
                      // Section Title: Select Delegate
                      const Padding(
                        padding: EdgeInsets.only(left: 4, bottom: 8),
                        child: Text(
                          'SELECT DELEGATE STAFF MEMBER',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                            color: AsmitaPalette.textLight,
                          ),
                        ),
                      ),

                      // Staff Members List
                      ...List.generate(_departmentStaff.length, (index) {
                        final staff = _departmentStaff[index];
                        final isSelected = _selectedDelegateId == staff['id'];
                        final color = staff['avatarColor'] as Color;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? AsmitaPalette.deepNavy
                                  : Theme.of(context).dividerColor,
                              width: isSelected ? 1.5 : 1.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: InkWell(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _selectedDelegateId = staff['id'] as int);
                            },
                            borderRadius: BorderRadius.circular(14),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: color.withValues(alpha: 0.14),
                                    child: Text(
                                      (staff['name'] as String)[0],
                                      style: TextStyle(
                                        fontFamily: 'Montserrat',
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: color,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          staff['name'] as String,
                                          style: const TextStyle(
                                            fontFamily: 'Montserrat',
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          staff['designation'] as String,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AsmitaPalette.textLight,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    width: 22,
                                    height: 22,
                                    margin: const EdgeInsets.only(right: 4),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected
                                            ? AsmitaPalette.deepNavy
                                            : Theme.of(context).dividerColor,
                                        width: isSelected ? 6.5 : 1.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 16),

                      // Section Title: Delegation Window
                      const Padding(
                        padding: EdgeInsets.only(left: 4, bottom: 8),
                        child: Text(
                          'ACTIVE DELEGATION WINDOW',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                            color: AsmitaPalette.textLight,
                          ),
                        ),
                      ),

                      // Quick Presets Row
                      Row(
                        children: [
                          _buildPresetChip('Today (24h)', 1),
                          const SizedBox(width: 8),
                          _buildPresetChip('3 Days', 3),
                          const SizedBox(width: 8),
                          _buildPresetChip('1 Week', 7),
                          const SizedBox(width: 8),
                          _buildPresetChip('2 Weeks', 14),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Calendar Date Range Picker Card
                      InkWell(
                        onTap: _selectDateRange,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Theme.of(context).dividerColor),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AsmitaPalette.deepNavy.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.calendar_month_rounded,
                                  color: AsmitaPalette.deepNavy,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Delegation Duration',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AsmitaPalette.textLight,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${dateFormat.format(_startDate)}  →  ${dateFormat.format(_endDate)}',
                                      style: const TextStyle(
                                        fontFamily: 'Montserrat',
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.edit_calendar_rounded,
                                size: 18,
                                color: AsmitaPalette.deepNavy,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                    ],

                    // Save Button
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitDelegation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AsmitaPalette.deepNavy,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 2,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _isDelegationEnabled
                                  ? 'Save & Activate Delegation'
                                  : 'Save Preferences',
                              style: const TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetChip(String label, int days) {
    final now = DateTime.now();
    final isCurrent = _endDate.difference(_startDate).inDays == days &&
        _startDate.day == now.day &&
        _startDate.month == now.month;

    return Expanded(
      child: InkWell(
        onTap: () => _applyQuickPreset(days),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isCurrent
                ? AsmitaPalette.deepNavy
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isCurrent ? AsmitaPalette.deepNavy : Theme.of(context).dividerColor,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 10,
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
              color: isCurrent
                  ? Colors.white
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
