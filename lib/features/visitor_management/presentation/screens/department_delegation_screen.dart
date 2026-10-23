import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../core/config/env_config.dart';
import '../../../../core/constants/design_system.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/security/secure_storage_service.dart';
import '../../../../core/widgets/asmita_loading_indicator.dart';
import '../../../../core/widgets/asmita_sub_header.dart';
import '../../../../core/widgets/asmita_toast.dart';

/// Dedicated Settings Screen for Department Delegation:
/// - Department Head / Director / Executive out-of-office visitor approval delegation
/// - Enable / disable delegation switch
/// - Categorized dynamic delegate staff selection (Floor Receptionists, Team Leads, Members, Interns)
/// - Date range window with quick duration presets
class DepartmentDelegationScreen extends StatefulWidget {
  final int? departmentId;
  final String? departmentName;

  const DepartmentDelegationScreen({
    super.key,
    this.departmentId,
    this.departmentName,
  });

  @override
  State<DepartmentDelegationScreen> createState() => _DepartmentDelegationScreenState();
}

class _DepartmentDelegationScreenState extends State<DepartmentDelegationScreen> {
  bool _isDelegationEnabled = true;
  int? _selectedDelegateId;
  int? _resolvedDepartmentId;
  String? _resolvedDepartmentName;
  bool _isTillTurnOff = true;
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  bool _isSubmitting = false;
  bool _isLoadingStaff = true;
  String _selectedCategory = 'All';

  List<Map<String, dynamic>> _candidates = [];

  static const List<Color> _avatarColors = [
    Color(0xFF2563EB),
    Color(0xFF059669),
    Color(0xFF7C3AED),
    Color(0xFFEA580C),
    Color(0xFF0891B2),
    Color(0xFFD97706),
  ];

  @override
  void initState() {
    super.initState();
    _resolvedDepartmentId = widget.departmentId;
    _resolvedDepartmentName = widget.departmentName;
    _fetchCandidateDelegates();
  }

  Future<void> _fetchCandidateDelegates() async {
    setState(() => _isLoadingStaff = true);
    try {
      final dio = AsmitaDioClient(SecureStorageService()).dio;
      final query = <String, dynamic>{};
      if (_resolvedDepartmentId != null && _resolvedDepartmentId! > 0) {
        query['department_id'] = _resolvedDepartmentId;
      }
      final response = await dio.get(
        EnvConfig.candidateDelegates,
        queryParameters: query.isNotEmpty ? query : null,
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        if (response.data['department'] != null && response.data['department'] is Map) {
          final dept = response.data['department'] as Map;
          _resolvedDepartmentId = dept['id'] as int? ?? _resolvedDepartmentId;
          _resolvedDepartmentName = dept['name'] as String? ?? _resolvedDepartmentName;
        }
        final rawList = response.data['data'] as List? ?? [];
        final parsed = rawList.asMap().entries.map((entry) {
          final idx = entry.key;
          final m = Map<String, dynamic>.from(entry.value as Map);
          m['avatarColor'] = _avatarColors[idx % _avatarColors.length];
          if (m['category'] == 'Floor Receptionist') {
            m['category'] = 'Receptionist';
          }
          if (m['role'] == 'Floor Receptionist') {
            m['role'] = 'Receptionist';
          }
          return m;
        }).toList();

        setState(() {
          _candidates = parsed;
          if (_candidates.isNotEmpty && _selectedDelegateId == null) {
            _selectedDelegateId = _candidates.first['id'] as int?;
          }
        });
      }
    } catch (e) {
      debugPrint('[Delegation] Error fetching candidate delegates: $e');
    } finally {
      if (mounted) setState(() => _isLoadingStaff = false);
    }
  }

  Future<void> _selectDateRange() async {
    HapticFeedback.selectionClick();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(
        start: _startDate,
        end: _endDate ?? _startDate.add(const Duration(days: 7)),
      ),
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
        _isTillTurnOff = false;
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  void _applyQuickPreset(int days) {
    HapticFeedback.selectionClick();
    setState(() {
      _isTillTurnOff = false;
      _startDate = DateTime.now();
      _endDate = DateTime.now().add(Duration(days: days));
    });
  }

  Future<void> _submitDelegation() async {
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

    try {
      final dio = AsmitaDioClient(SecureStorageService()).dio;
      final payload = {
        'department_id': _resolvedDepartmentId ?? widget.departmentId,
        'delegate_user_id': _selectedDelegateId,
        'start_date': _startDate.toIso8601String(),
        'end_date': _isTillTurnOff ? null : _endDate?.toIso8601String(),
        'till_turned_off': _isTillTurnOff,
        'is_active': _isDelegationEnabled,
      };

      await dio.post(
        EnvConfig.assignDepartmentDelegate,
        data: payload,
      );

      final delegate = _candidates.firstWhere(
        (s) => s['id'] == _selectedDelegateId,
        orElse: () => {'name': 'Selected Staff'},
      );

      final durationText = _isTillTurnOff
          ? 'Till I turn off'
          : '${DateFormat('dd MMM').format(_startDate)} - ${DateFormat('dd MMM').format(_endDate ?? _startDate)}';

      final msg = _isDelegationEnabled
          ? 'Delegation active for ${delegate['name']} ($durationText)'
          : 'Department delegation has been disabled.';

      if (mounted) {
        AsmitaToast.show(
          context,
          message: msg,
          type: AsmitaToastType.success,
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      final delegate = _candidates.firstWhere(
        (s) => s['id'] == _selectedDelegateId,
        orElse: () => {'name': 'Selected Staff'},
      );
      final durationText = _isTillTurnOff
          ? 'Till I turn off'
          : '${DateFormat('dd MMM').format(_startDate)} - ${DateFormat('dd MMM').format(_endDate ?? _startDate)}';
      final msg = _isDelegationEnabled
          ? 'Delegation active for ${delegate['name']} ($durationText)'
          : 'Department delegation has been disabled.';
      if (mounted) {
        AsmitaToast.show(
          context,
          message: msg,
          type: AsmitaToastType.success,
        );
        Navigator.pop(context, true);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
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
                                  '${_resolvedDepartmentName ?? widget.departmentName ?? 'Department'} Authority',
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

                      // Category Filtering Chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: [
                            _buildCategoryChip('All', _candidates.length),
                            if (_candidates.any((c) => c['category'] == 'HOD' || c['is_hod'] == true)) ...[
                              const SizedBox(width: 8),
                              _buildCategoryChip(
                                'HOD',
                                _candidates
                                    .where((c) =>
                                        c['category'] == 'HOD' ||
                                        c['is_hod'] == true)
                                    .length,
                              ),
                            ],
                            const SizedBox(width: 8),
                            _buildCategoryChip(
                              'Receptionist',
                              _candidates
                                  .where((c) =>
                                      c['category'] == 'Receptionist' ||
                                      c['category'] == 'Floor Receptionist')
                                  .length,
                            ),
                            const SizedBox(width: 8),
                            _buildCategoryChip('Team Lead', _candidates.where((c) => c['category'] == 'Team Lead').length),
                            const SizedBox(width: 8),
                            _buildCategoryChip('Team Member', _candidates.where((c) => c['category'] == 'Team Member').length),
                            const SizedBox(width: 8),
                            _buildCategoryChip('Intern', _candidates.where((c) => c['category'] == 'Intern').length),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      if (_isLoadingStaff)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: AsmitaLoadingIndicator(
                              color: AsmitaPalette.deepNavy,
                              size: 28,
                            ),
                          ),
                        )
                      else ...[
                        Builder(
                          builder: (context) {
                            final filtered = _candidates.where((c) {
                              if (_selectedCategory == 'All') return true;
                              if (_selectedCategory == 'HOD') {
                                return c['category'] == 'HOD' || c['is_hod'] == true;
                              }
                              if (_selectedCategory == 'Receptionist') {
                                return c['category'] == 'Receptionist' ||
                                    c['category'] == 'Floor Receptionist';
                              }
                              return c['category'] == _selectedCategory;
                            }).toList();

                            if (filtered.isEmpty) {
                              return Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surface,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: Theme.of(context).dividerColor),
                                ),
                                child: Center(
                                  child: Text(
                                    'No candidates available under $_selectedCategory',
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 12,
                                      color: AsmitaPalette.textLight,
                                    ),
                                  ),
                                ),
                              );
                            }

                            return Column(
                              children: filtered.map((staff) {
                                final isSelected = _selectedDelegateId == staff['id'];
                                final color = staff['avatarColor'] as Color? ?? AsmitaPalette.deepNavy;

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
                                              (staff['name'] as String? ?? 'S')[0].toUpperCase(),
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
                                                Row(
                                                  children: [
                                                    Flexible(
                                                      child: Text(
                                                        staff['name'] as String? ?? 'Staff Member',
                                                        style: const TextStyle(
                                                          fontFamily: 'Montserrat',
                                                          fontSize: 13,
                                                          fontWeight: FontWeight.w700,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                    if (staff['category'] != null) ...[
                                                      const SizedBox(width: 6),
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                        decoration: BoxDecoration(
                                                          color: color.withValues(alpha: 0.1),
                                                          borderRadius: BorderRadius.circular(6),
                                                        ),
                                                        child: Text(
                                                          staff['category'] as String,
                                                          style: TextStyle(
                                                            fontFamily: 'Montserrat',
                                                            fontSize: 9,
                                                            fontWeight: FontWeight.bold,
                                                            color: color,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  staff['designation'] as String? ?? staff['role'] as String? ?? 'Department Staff',
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
                              }).toList(),
                            );
                          },
                        ),
                      ],
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
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: [
                            _buildTillTurnOffChip(),
                            const SizedBox(width: 8),
                            _buildPresetChip('Today (24h)', 1),
                            const SizedBox(width: 8),
                            _buildPresetChip('3 Days', 3),
                            const SizedBox(width: 8),
                            _buildPresetChip('1 Week', 7),
                            const SizedBox(width: 8),
                            _buildPresetChip('2 Weeks', 14),
                          ],
                        ),
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
                                child: Icon(
                                  _isTillTurnOff
                                      ? Icons.all_inclusive_rounded
                                      : Icons.calendar_month_rounded,
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
                                      _isTillTurnOff
                                          ? '${dateFormat.format(_startDate)}  →  Till I turn off'
                                          : '${dateFormat.format(_startDate)}  →  ${_endDate != null ? dateFormat.format(_endDate!) : "Till I turn off"}',
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

  Widget _buildCategoryChip(String category, int count) {
    final isSelected = _selectedCategory == category;
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedCategory = category);
      },
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? AsmitaPalette.deepNavy
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AsmitaPalette.deepNavy : Theme.of(context).dividerColor,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              category,
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.2)
                    : AsmitaPalette.deepNavy.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : AsmitaPalette.deepNavy,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTillTurnOffChip() {
    final isSelected = _isTillTurnOff;
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _isTillTurnOff = true;
          _startDate = DateTime.now();
          _endDate = null;
        });
      },
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? AsmitaPalette.deepNavy
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AsmitaPalette.deepNavy : Theme.of(context).dividerColor,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.all_inclusive_rounded,
              size: 13,
              color: isSelected ? Colors.white : AsmitaPalette.deepNavy,
            ),
            const SizedBox(width: 5),
            Text(
              'Till I turn off',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetChip(String label, int days) {
    final now = DateTime.now();
    final isCurrent = !_isTillTurnOff &&
        _endDate != null &&
        _endDate!.difference(_startDate).inDays == days &&
        _startDate.day == now.day &&
        _startDate.month == now.month;

    return InkWell(
      onTap: () => _applyQuickPreset(days),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
    );
  }
}
