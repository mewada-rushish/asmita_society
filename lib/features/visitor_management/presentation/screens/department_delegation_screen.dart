import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/bloc/auth_bloc.dart';
import '../../../auth/bloc/auth_state.dart';
import 'package:intl/intl.dart';

import '../../../../core/config/env_config.dart';
import '../../../../core/constants/design_system.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/security/secure_storage_service.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/widgets/asmita_animated_refresh.dart';
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
  bool _isDelegationEnabled = false;
  bool _hasUserManuallyToggled = false;
  int? _selectedDelegateId;
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

  Map<String, dynamic>? _activeOutgoing;
  List<Map<String, dynamic>> _incomingDelegations = [];

  @override
  void initState() {
    super.initState();
    _fetchCandidateDelegates();
  }

  Future<void> _fetchCandidateDelegates({bool isSilent = false}) async {
    if (!isSilent) {
      setState(() => _isLoadingStaff = true);
    }
    try {
      final dio = AsmitaDioClient(SecureStorageService()).dio;

      final authState = context.read<AuthBloc>().state;
      final currentUser = authState is AuthAuthenticated ? authState.user : null;
      final currentUserId = currentUser?.userId;
      final userPower = currentUser?.rolePower ?? 100;
      final userFloor = (currentUser?.roleDetails?['floor']?.toString() ?? '')
          .toLowerCase()
          .replaceAll('floor', '')
          .replaceAll(RegExp(r'th|st|nd|rd'), '')
          .trim();

      final propertyId = currentUser?.societyId ?? 115;

      // 1. Fetch current user delegation status
      try {
        final statusRes = await dio.get(
          EnvConfig.employeeDelegationStatus,
          queryParameters: {'property_id': propertyId},
        );
        if (statusRes.statusCode == 200 && statusRes.data['success'] == true) {
          final dData = statusRes.data['data'] as Map<String, dynamic>?;
          if (dData != null) {
            _activeOutgoing = dData['outgoingDelegation'] as Map<String, dynamic>?;
            _incomingDelegations = (dData['incomingDelegations'] as List? ?? [])
                .map((x) => Map<String, dynamic>.from(x as Map))
                .toList();
            if (_activeOutgoing != null) {
              _isDelegationEnabled = true;
              _selectedDelegateId = _activeOutgoing!['delegate_user_id'] as int?;
              _isTillTurnOff = _activeOutgoing!['end_date'] == null;
              if (_activeOutgoing!['start_date'] != null) {
                _startDate = DateTime.tryParse(_activeOutgoing!['start_date'].toString()) ?? DateTime.now();
              }
              if (_activeOutgoing!['end_date'] != null) {
                _endDate = DateTime.tryParse(_activeOutgoing!['end_date'].toString());
              }
            } else if (!_hasUserManuallyToggled) {
              _isDelegationEnabled = false;
            }
          }
        }
      } catch (stErr) {
        debugPrint('[Delegation] Note: status endpoint fallback: $stErr');
      }

      // 2. Fetch eligible colleagues for personal delegation
      List<dynamic> rawList = [];
      try {
        final queryParams = <String, dynamic>{};
        if (currentUserId != null) {
          queryParams['userId'] = currentUserId;
        }
        if (widget.departmentId != null) {
          queryParams['department_id'] = widget.departmentId;
        }
        queryParams['property_id'] = propertyId;
        queryParams['societyId'] = propertyId;

        final response = await dio.get(
          EnvConfig.employeeDelegationColleagues,
          queryParameters: queryParams.isNotEmpty ? queryParams : null,
        );
        if (response.statusCode == 200 && response.data['success'] == true) {
          rawList = response.data['data'] as List? ?? [];
        }
      } catch (colleagueErr) {
        debugPrint('[Delegation] Note: colleagues endpoint error, falling back: $colleagueErr');
      }

      // If colleagues list is empty, query the candidateDelegates endpoint
      if (rawList.isEmpty) {
        try {
          final queryParams = <String, dynamic>{};
          if (currentUserId != null) {
            queryParams['userId'] = currentUserId;
          }
          if (widget.departmentId != null) {
            queryParams['departmentId'] = widget.departmentId;
          }
          queryParams['property_id'] = propertyId;
          queryParams['propertyId'] = propertyId;

          final legacyRes = await dio.get(
            EnvConfig.candidateDelegates,
            queryParameters: queryParams.isNotEmpty ? queryParams : null,
          );
          if (legacyRes.statusCode == 200 && legacyRes.data['success'] == true) {
            rawList = legacyRes.data['data'] as List? ?? [];
          }
        } catch (legacyErr) {
          debugPrint('[Delegation] Legacy candidate delegates error: $legacyErr');
        }
      }

      // Filter rawList strictly to delegatees, subordinates under the actor with lower power, or matching floor receptionist
      final filteredRaw = rawList.where((rawItem) {
        if (rawItem is! Map) return false;
        final m = Map<String, dynamic>.from(rawItem);
        final id = m['user_id'] ?? m['id'];
        if (currentUserId != null && id == currentUserId) return false;

        final role = (m['role'] ?? m['designation'] ?? '').toString().toLowerCase();
        final desig = (m['designation'] ?? '').toString().toLowerCase();
        final name = (m['name'] ?? m['full_name'] ?? '').toString().toLowerCase();

        // 1. Gate receptionists are NEVER eligible as delegates
        if (role.contains('gate') || desig.contains('gate') || name.contains('gate')) return false;

        // 2. Floor receptionist check: allowed only if assigned to actor's exact floor
        final isReceptionist = role.contains('reception') || desig.contains('reception') || name.contains('reception');
        if (isReceptionist) {
          final candFloor = (m['floor']?.toString() ?? '')
              .toLowerCase()
              .replaceAll('floor', '')
              .replaceAll(RegExp(r'th|st|nd|rd'), '')
              .trim();
          if (userFloor.isNotEmpty && candFloor.isNotEmpty && candFloor == userFloor) {
            return true;
          }
          if (m['category'] == 'Receptionist' && !name.contains('gate') && !desig.contains('gate')) {
            return true;
          }
          return false;
        }

        // 3. For ALL other colleagues: MUST BE EXPLICITLY AN ENABLED DELEGATEE
        final isExplicitlyDisabled = m['is_delegatee'] == false ||
            (m['role_details'] is Map && m['role_details']['is_delegatee'] == false);
        if (isExplicitlyDisabled) return false;

        // 4. Candidate role power MUST NOT be greater than delegator (peers with equal power are allowed)
        final candidatePower = m['power'] is int
            ? m['power'] as int
            : int.tryParse(m['power']?.toString() ?? '') ?? 100;

        if (userPower < 500 && candidatePower > userPower) {
          return false;
        }

        // 5. Must be an employee under the delegator:
        final reportsTo = m['reports_to_user_id'] ?? m['reports_to_id'] ??
            (m['role_details'] is Map ? (m['role_details']['reports_to_user_id'] ?? m['role_details']['reports_to_id']) : null);
        if (currentUserId != null && reportsTo != null && reportsTo.toString() == currentUserId.toString()) {
          return true;
        }

        // Director (power 500)
        if (userPower >= 500) {
          return true;
        }

        // Department matching
        final userDept = (currentUser?.roleDetails?['department'] ?? currentUser?.roleDetails?['department_name'] ?? '').toString().toLowerCase();
        final candDept = (m['department'] ?? (m['role_details'] is Map ? m['role_details']['department'] : '')).toString().toLowerCase();
        if (userDept.isNotEmpty && candDept.isNotEmpty && (userDept == candDept || userDept.contains(candDept) || candDept.contains(userDept))) {
          return true;
        }

        if (reportsTo != null && currentUserId != null && reportsTo.toString() != currentUserId.toString()) {
          return false;
        }

        return true;
      }).toList();

      final parsed = filteredRaw.asMap().entries.map((entry) {
        final idx = entry.key;
        final m = Map<String, dynamic>.from(entry.value as Map);
        m['id'] = m['user_id'] ?? m['id'];
        m['avatarColor'] = _avatarColors[idx % _avatarColors.length];

        // Determine role and designation
        final desig = m['designation']?.toString() ?? m['role']?.toString() ?? 'Colleague';
        final dept = m['department']?.toString() ?? 'General';
        m['role'] = desig;

        // Categorize correctly for filter chips
        String category = m['category']?.toString() ?? '';
        if (category.isEmpty || category == 'General' || category == 'All') {
          final lower = desig.toLowerCase();
          final lowerDept = dept.toLowerCase();
          if (m['is_hod'] == true || lower.contains('hod') || lower.contains('head')) {
            category = 'HOD';
          } else if (lower.contains('reception') || lowerDept.contains('reception')) {
            category = 'Receptionist';
          } else if (lower.contains('lead') || lower.contains('manager') || lower.contains('tl')) {
            category = 'Team Lead';
          } else if (lower.contains('intern') || lower.contains('trainee')) {
            category = 'Intern';
          } else {
            category = 'Team Member';
          }
        }
        m['category'] = category;
        return m;
      }).toList();

      if (mounted) {
        setState(() {
          _candidates = parsed;
          if (_candidates.isNotEmpty) {
            if (_selectedDelegateId == null || !_candidates.any((c) => c['id'] == _selectedDelegateId)) {
              _selectedDelegateId = _candidates.first['id'] as int?;
            }
          } else {
            _selectedDelegateId = null;
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
      final authState = context.read<AuthBloc>().state;
      final currentUser = authState is AuthAuthenticated ? authState.user : null;
      final propertyId = currentUser?.societyId ?? 115;

      if (!_isDelegationEnabled) {
        // Revoke active delegation
        await dio.delete(
          EnvConfig.employeeDelegation,
          queryParameters: {'property_id': propertyId},
        );
        if (mounted) {
          AsmitaToast.show(
            context,
            message: 'Visitor delegation has been deactivated. Approvals will route directly to you.',
            type: AsmitaToastType.success,
          );
          Navigator.pop(context, true);
        }
        return;
      }

      final payload = {
        'delegate_user_id': _selectedDelegateId,
        'start_date': _startDate.toIso8601String(),
        'end_date': _isTillTurnOff ? null : _endDate?.toIso8601String(),
        'property_id': propertyId,
      };

      final response = await dio.post(
        EnvConfig.employeeDelegation,
        data: payload,
      );

      final delegate = _candidates.firstWhere(
        (s) => s['id'] == _selectedDelegateId,
        orElse: () => {'name': 'Selected Colleague'},
      );

      final msg = 'Approvals sent to ${delegate['name']}.';

      if (mounted) {
        AsmitaToast.show(
          context,
          message: response.data?['message'] ?? msg,
          type: AsmitaToastType.success,
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('[Delegation] Submit error: $e');
      String errMsg = 'Failed to update delegation.';
      if (e is DioException && e.response?.data is Map) {
        errMsg = e.response!.data['message'] ?? errMsg;
      }
      if (mounted) {
        AsmitaToast.show(
          context,
          message: errMsg,
          type: AsmitaToastType.error,
        );
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
            const AsmitaSubHeader(title: 'Visitor Approval Delegation'),

            // Scrollable Settings Content with Pull to Refresh
            Expanded(
              child: AsmitaPullToRefresh(
                onRefresh: () async {
                  await _fetchCandidateDelegates();
                },
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
                              Icons.sync_alt_rounded,
                              color: AsmitaPalette.deepNavy,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Visitor Approval Hand-off',
                                  style: TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 3),
                                Text(
                                  'When delegated, your chosen colleague will receive live visitor alerts on your behalf. Deliveries, cabs, and history remain direct to you.',
                                  style: TextStyle(fontSize: 12, height: 1.4, color: AsmitaPalette.textLight),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Incoming Delegations Card (if colleagues have delegated to this user)
                    if (_incomingDelegations.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.15 : 0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.35 : 0.25),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.assignment_ind_rounded, color: Color(0xFF059669), size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  'Handling Approvals For (${_incomingDelegations.length})',
                                  style: const TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF065F46),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ..._incomingDelegations.map((inc) {
                              final delegator = inc['delegator'] as Map?;
                              final name = delegator?['full_name'] ?? 'Colleague';
                              final role = delegator?['primary_role'] ?? 'Employee';
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Text(
                                  '• $name ($role)',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

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
                              _hasUserManuallyToggled = true;
                              setState(() => _isDelegationEnabled = val);
                              if (val && _candidates.isEmpty && !_isLoadingStaff) {
                                _fetchCandidateDelegates(isSilent: false);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    if (_isDelegationEnabled) ...[
                      // Section Header: Select Delegate & BBPS-style Category Dropdown
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 8),
                        child: Row(
                          children: [
                            const Expanded(
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
                            _buildStaffCategoryDropdown(context),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (_isLoadingStaff) ...[
                        _buildSkeletalDelegateList(context),
                      ] else ...[
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

                      // Section Header: Delegation Window & BBPS-style Presets Dropdown
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 8),
                        child: Row(
                          children: [
                            const Expanded(
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
                            _buildDelegationWindowDropdown(context),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
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
                                  : (_activeOutgoing != null ? 'Deactivate Delegation' : 'Save Preferences'),
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

  Widget _buildSkeletalDelegateList(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[200]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Skeletal Staff Cards
        ...List.generate(3, (index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Shimmer.fromColors(
              baseColor: baseColor,
              highlightColor: highlightColor,
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 120,
                              height: 14,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              width: 60,
                              height: 14,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: 100,
                          height: 11,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  List<Map<String, dynamic>> _getAvailableStaffCategories() {
    final List<Map<String, dynamic>> categories = [
      {
        'label': 'All',
        'count': _candidates.length,
        'icon': Icons.grid_view_rounded,
      },
    ];
    if (_candidates.any((c) => c['category'] == 'HOD' || c['is_hod'] == true)) {
      categories.add({
        'label': 'HOD',
        'count': _candidates.where((c) => c['category'] == 'HOD' || c['is_hod'] == true).length,
        'icon': Icons.badge_outlined,
      });
    }
    if (_candidates.any((c) =>
        c['category'] == 'Receptionist' || c['category'] == 'Floor Receptionist')) {
      categories.add({
        'label': 'Receptionist',
        'count': _candidates
            .where((c) =>
                c['category'] == 'Receptionist' ||
                c['category'] == 'Floor Receptionist')
            .length,
        'icon': Icons.support_agent_rounded,
      });
    }
    if (_candidates.any((c) => c['category'] == 'Team Lead')) {
      categories.add({
        'label': 'Team Lead',
        'count': _candidates.where((c) => c['category'] == 'Team Lead').length,
        'icon': Icons.supervisor_account_outlined,
      });
    }
    if (_candidates.any((c) => c['category'] == 'Team Member')) {
      categories.add({
        'label': 'Team Member',
        'count': _candidates.where((c) => c['category'] == 'Team Member').length,
        'icon': Icons.person_outline_rounded,
      });
    }
    if (_candidates.any((c) => c['category'] == 'Intern')) {
      categories.add({
        'label': 'Intern',
        'count': _candidates.where((c) => c['category'] == 'Intern').length,
        'icon': Icons.school_outlined,
      });
    }
    return categories;
  }

  Widget _buildStaffCategoryDropdown(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categories = _getAvailableStaffCategories();
    final currentItem = categories.firstWhere(
      (c) => c['label'] == _selectedCategory,
      orElse: () => categories.first,
    );

    return PopupMenuButton<String>(
      initialValue: _selectedCategory,
      tooltip: 'Filter Staff Category',
      offset: const Offset(0, 32),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
        ),
      ),
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      elevation: 6,
      onSelected: (String cat) {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedCategory = cat;
        });
      },
      itemBuilder: (BuildContext context) {
        return categories.map((item) {
          final label = item['label'] as String;
          final count = item['count'] as int;
          final icon = item['icon'] as IconData;
          final isSelected = label == _selectedCategory;
          return PopupMenuItem<String>(
            value: label,
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 15,
                  color: isSelected
                      ? (isDark ? const Color(0xFF60A5FA) : AsmitaPalette.deepNavy)
                      : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    count > 0 ? '$label ($count)' : label,
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? (isDark ? const Color(0xFF60A5FA) : AsmitaPalette.deepNavy)
                          : (isDark ? Colors.white : const Color(0xFF0F172A)),
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_rounded,
                    size: 16,
                    color: isDark ? const Color(0xFF60A5FA) : AsmitaPalette.deepNavy,
                  ),
              ],
            ),
          );
        }).toList();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              currentItem['icon'] as IconData,
              size: 13,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
            ),
            const SizedBox(width: 5),
            Text(
              '${currentItem['label']} (${currentItem['count']})',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(width: 3),
            Icon(
              Icons.arrow_drop_down_rounded,
              size: 18,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ],
        ),
      ),
    );
  }

  String _getActiveWindowLabel() {
    if (_isTillTurnOff || _endDate == null) return 'Till I turn off';
    final diffDays = _endDate!.difference(_startDate).inDays;
    final diffHours = _endDate!.difference(_startDate).inHours;
    if (diffHours <= 26 && diffDays <= 1) return 'Today (24h)';
    if (diffDays == 3) return '3 Days';
    if (diffDays == 7) return '1 Week';
    if (diffDays == 14) return '2 Weeks';
    return 'Custom';
  }

  IconData _getActiveWindowIcon(String label) {
    switch (label) {
      case 'Till I turn off':
        return Icons.all_inclusive_rounded;
      case 'Today (24h)':
        return Icons.today_rounded;
      case '3 Days':
        return Icons.date_range_rounded;
      case '1 Week':
        return Icons.calendar_view_week_rounded;
      case '2 Weeks':
        return Icons.calendar_month_rounded;
      default:
        return Icons.edit_calendar_rounded;
    }
  }

  Widget _buildDelegationWindowDropdown(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentLabel = _getActiveWindowLabel();
    final currentIcon = _getActiveWindowIcon(currentLabel);

    final List<Map<String, dynamic>> presets = [
      {'label': 'Till I turn off', 'icon': Icons.all_inclusive_rounded},
      {'label': 'Today (24h)', 'icon': Icons.today_rounded, 'days': 1},
      {'label': '3 Days', 'icon': Icons.date_range_rounded, 'days': 3},
      {'label': '1 Week', 'icon': Icons.calendar_view_week_rounded, 'days': 7},
      {'label': '2 Weeks', 'icon': Icons.calendar_month_rounded, 'days': 14},
      {'label': 'Custom Date', 'icon': Icons.edit_calendar_rounded, 'custom': true},
    ];

    return PopupMenuButton<String>(
      initialValue: currentLabel,
      tooltip: 'Select Delegation Window',
      offset: const Offset(0, 32),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
        ),
      ),
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      elevation: 6,
      onSelected: (String label) {
        if (label == 'Till I turn off') {
          HapticFeedback.selectionClick();
          setState(() {
            _isTillTurnOff = true;
            _startDate = DateTime.now();
            _endDate = null;
          });
        } else if (label == 'Custom Date') {
          _selectDateRange();
        } else {
          final match = presets.firstWhere((p) => p['label'] == label, orElse: () => {});
          final days = match['days'] as int? ?? 1;
          _applyQuickPreset(days);
        }
      },
      itemBuilder: (BuildContext context) {
        return presets.map((preset) {
          final label = preset['label'] as String;
          final icon = preset['icon'] as IconData;
          final isSelected = label == currentLabel;
          return PopupMenuItem<String>(
            value: label,
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 15,
                  color: isSelected
                      ? (isDark ? const Color(0xFF60A5FA) : AsmitaPalette.deepNavy)
                      : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? (isDark ? const Color(0xFF60A5FA) : AsmitaPalette.deepNavy)
                          : (isDark ? Colors.white : const Color(0xFF0F172A)),
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_rounded,
                    size: 16,
                    color: isDark ? const Color(0xFF60A5FA) : AsmitaPalette.deepNavy,
                  ),
              ],
            ),
          );
        }).toList();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              currentIcon,
              size: 13,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
            ),
            const SizedBox(width: 5),
            Text(
              currentLabel,
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(width: 3),
            Icon(
              Icons.arrow_drop_down_rounded,
              size: 18,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ],
        ),
      ),
    );
  }
}
