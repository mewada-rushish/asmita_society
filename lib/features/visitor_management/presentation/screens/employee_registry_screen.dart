import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/design_system.dart';
import '../../../../core/widgets/app_skeleton.dart';
import '../../../../core/widgets/app_refresh.dart';
import '../../../../core/widgets/asmita_toast.dart';
import '../../../../core/services/location_geofence_service.dart';
import '../../../../core/widgets/asmita_primary_header.dart';
import '../../../../core/widgets/asmita_bottom_nav_bar.dart';
import '../../../auth/bloc/auth_bloc.dart';
import '../../../auth/bloc/auth_state.dart';
import '../../../dashboard/widgets/asmita_pre_approve_wizard.dart';

/// Full-Page Employee / Staff Registry Screen
/// Featuring:
/// - AsmitaPrimaryHeader with back button & subtitle matching standard app design
/// - AsmitaBottomNavBar
/// - Centered search bar with aligned placeholder
/// - Dropdown filtering for Floor and Department matching BBPS aesthetic
/// - Premium, theme-compliant employee cards with squircle avatar, badge pills, and tactile In/Out actions
class EmployeeRegistryScreen extends StatefulWidget {
  final int? societyId;
  final ValueChanged<int>? onNavigateToTab;
  final bool isEmbedded;

  const EmployeeRegistryScreen({
    super.key,
    this.societyId,
    this.onNavigateToTab,
    this.isEmbedded = false,
  });

  static Future<int?> open(
    BuildContext context, {
    int? societyId,
    ValueChanged<int>? onNavigateToTab,
    bool isEmbedded = false,
  }) {
    return Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (_) => EmployeeRegistryScreen(
          societyId: societyId,
          onNavigateToTab: onNavigateToTab,
          isEmbedded: isEmbedded,
        ),
      ),
    );
  }

  @override
  State<EmployeeRegistryScreen> createState() => EmployeeRegistryScreenState();
}

class EmployeeRegistryScreenState extends State<EmployeeRegistryScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _allEmployees = [];

  Future<void> reload() => _loadData(forceRefresh: true);
  List<Map<String, dynamic>> _allDepartments = [];
  bool _isLoading = true;
  String _searchQuery = '';

  String _selectedFloor = 'All Floors';
  String _selectedDepartment = 'All Departments';
  String _selectedMovementFilter = 'ALL'; // 'OUT' | 'IN' | 'ALL'

  // In-memory session log for movement: employee_id -> {status: 'IN' | 'OUT', time: DateTime}
  static final Map<int, Map<String, dynamic>> _sessionMovementLog = {};

  @override
  void initState() {
    super.initState();
    _loadData(forceRefresh: true);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int _resolveSocietyId() {
    if (widget.societyId != null && widget.societyId! > 0) {
      return widget.societyId!;
    }
    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthAuthenticated && authState.user.societyId != null) {
        return authState.user.societyId!;
      }
    } catch (_) {}
    return 1;
  }

  static DateTime? _parseDateTime(dynamic val) {
    if (val == null) return null;
    if (val is DateTime) return val;
    try {
      return DateTime.parse(val.toString()).toLocal();
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadData({bool forceRefresh = false}) async {
    final sId = _resolveSocietyId();
    setState(() => _isLoading = true);
    if (forceRefresh) {
      _sessionMovementLog.clear();
    }
    try {
      final results = await Future.wait([
        AsmitaPreApproveWizard.loadSocietyEmployees(sId, forceRefresh: forceRefresh),
        AsmitaPreApproveWizard.loadSocietyDepartments(sId),
      ]);
      if (!mounted) return;
      setState(() {
        _allEmployees = List.from(results[0]);
        _allDepartments = List.from(results[1]);
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<String> get _availableFloors {
    final Set<String> floors = {'All Floors'};
    for (final emp in _allEmployees) {
      final f = (emp['floor'] ?? '').toString().trim();
      if (f.isNotEmpty) {
        final clean = f.replaceAll(RegExp(r'^floor\s*', caseSensitive: false), '').trim();
        if (clean.isNotEmpty) floors.add('Floor $clean');
      }
    }
    for (final dept in _allDepartments) {
      final f = (dept['floor'] ?? '').toString().trim();
      if (f.isNotEmpty) {
        final clean = f.replaceAll(RegExp(r'^floor\s*', caseSensitive: false), '').trim();
        if (clean.isNotEmpty) floors.add('Floor $clean');
      }
    }
    final list = floors.toList();
    list.sort((a, b) {
      if (a == 'All Floors') return -1;
      if (b == 'All Floors') return 1;
      return a.compareTo(b);
    });
    return list;
  }

  List<String> get _availableDepartments {
    final Set<String> depts = {'All Departments'};
    for (final emp in _allEmployees) {
      final d = (emp['department_name'] ?? emp['department'] ?? '').toString().trim();
      if (d.isNotEmpty && d != 'General Staff' && d != 'Employee') {
        depts.add(d);
      }
    }
    for (final dept in _allDepartments) {
      final d = (dept['name'] ?? '').toString().trim();
      if (d.isNotEmpty) depts.add(d);
    }
    final list = depts.toList();
    list.sort((a, b) {
      if (a == 'All Departments') return -1;
      if (b == 'All Departments') return 1;
      return a.compareTo(b);
    });
    return list;
  }

  bool _isEmpIn(Map<String, dynamic> emp) {
    final empId = (emp['user_id'] ?? emp['id'] ?? 0) as int;
    final movement = _sessionMovementLog[empId];
    if (movement != null) {
      return movement['status'] == 'IN';
    }
    return emp['is_checked_in'] == true ||
        emp['duty_status'] == 'ON_DUTY' ||
        emp['status'] == 'IN' ||
        emp['attendance_status'] == 'IN';
  }

  bool _isEmpCheckedOutToday(Map<String, dynamic> emp) {
    if (_isEmpIn(emp)) return false;
    final empId = (emp['user_id'] ?? emp['id'] ?? 0) as int;
    final movement = _sessionMovementLog[empId];
    if (movement != null) {
      return movement['status'] == 'OUT';
    }
    if (emp['last_check_out_at'] != null ||
        emp['check_out_at'] != null ||
        emp['check_out_time'] != null) {
      return true;
    }
    final status = (emp['status'] ?? emp['attendance_status'] ?? '').toString().toUpperCase();
    if (status == 'OUT' &&
        (emp['last_movement_at'] != null ||
            emp['last_check_in_at'] != null ||
            emp['recorded_at'] != null)) {
      return true;
    }
    return false;
  }

  bool _isEmpPendingToday(Map<String, dynamic> emp) {
    return !_isEmpIn(emp) && !_isEmpCheckedOutToday(emp);
  }

  List<Map<String, dynamic>> get _baseFilteredEmployees {
    return _allEmployees.where((e) {
      // 1. Search Query Filter
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.trim().toLowerCase();
        final name = (e['full_name'] ?? e['name'] ?? '').toString().toLowerCase();
        final dept = (e['department_name'] ?? e['department'] ?? '').toString().toLowerCase();
        final role = (e['primary_role'] ?? e['role'] ?? e['designation'] ?? '').toString().toLowerCase();
        final empId = (e['employee_id'] ?? e['id'] ?? '').toString().toLowerCase();
        final desk = (e['desk_code'] ?? '').toString().toLowerCase();
        final cabin = (e['cabin_code'] ?? '').toString().toLowerCase();
        final matchesQuery = name.contains(q) ||
            dept.contains(q) ||
            role.contains(q) ||
            empId.contains(q) ||
            desk.contains(q) ||
            cabin.contains(q);
        if (!matchesQuery) return false;
      }

      // 2. Floor Filter
      if (_selectedFloor != 'All Floors') {
        final rawFloor = (e['floor'] ?? '').toString().trim();
        final cleanEmpFloor = rawFloor.replaceAll(RegExp(r'^floor\s*', caseSensitive: false), '').trim();
        final cleanSelectedFloor = _selectedFloor.replaceAll(RegExp(r'^floor\s*', caseSensitive: false), '').trim();
        if (cleanEmpFloor.toLowerCase() != cleanSelectedFloor.toLowerCase()) {
          return false;
        }
      }

      // 3. Department Filter
      if (_selectedDepartment != 'All Departments') {
        final dept = (e['department_name'] ?? e['department'] ?? '').toString().trim().toLowerCase();
        if (dept != _selectedDepartment.toLowerCase()) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  List<Map<String, dynamic>> get _filteredEmployees {
    final base = _baseFilteredEmployees;
    if (_selectedMovementFilter == 'PENDING') {
      return base.where((e) => _isEmpPendingToday(e)).toList();
    } else if (_selectedMovementFilter == 'IN') {
      return base.where((e) => _isEmpIn(e)).toList();
    } else if (_selectedMovementFilter == 'OUT') {
      return base.where((e) => _isEmpCheckedOutToday(e)).toList();
    }
    return base;
  }

  Future<DateTime?> _showIosTimePicker(BuildContext context, DateTime initialDateTime) async {
    DateTime tempTime = initialDateTime;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return showModalBottomSheet<DateTime>(
      context: context,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (pickerCtx) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Centered drag handle
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                // 2. Styled Header Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Cancel Pill
                    InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(pickerCtx);
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF334155).withValues(alpha: 0.5)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF475569).withValues(alpha: 0.4)
                                : const Color(0xFFE2E8F0),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),

                    // Centered Title with Clock Badge
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: (isDark ? const Color(0xFF3B82F6) : AsmitaPalette.deepNavy).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.schedule_rounded,
                            size: 16,
                            color: isDark ? const Color(0xFF60A5FA) : AsmitaPalette.deepNavy,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Select Time',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(pickerCtx).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),

                    // Done Filled Pill
                    InkWell(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        Navigator.pop(pickerCtx, tempTime);
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF3B82F6) : AsmitaPalette.deepNavy,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: (isDark ? const Color(0xFF3B82F6) : AsmitaPalette.deepNavy).withValues(alpha: 0.25),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Text(
                          'Done',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Subtle modern divider
                Divider(
                  height: 1,
                  thickness: 1,
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                ),

                const SizedBox(height: 12),

                // Cupertino Picker
                SizedBox(
                  height: 190,
                  child: CupertinoTheme(
                    data: CupertinoThemeData(
                      brightness: isDark ? Brightness.dark : Brightness.light,
                      textTheme: CupertinoTextThemeData(
                        dateTimePickerTextStyle: TextStyle(
                          color: Theme.of(pickerCtx).colorScheme.onSurface,
                          fontSize: 22,
                          fontFamily: 'Montserrat',
                        ),
                      ),
                    ),
                    child: CupertinoDatePicker(
                      mode: CupertinoDatePickerMode.time,
                      initialDateTime: initialDateTime,
                      use24hFormat: false,
                      onDateTimeChanged: (DateTime newDateTime) {
                        tempTime = newDateTime;
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showMovementDialog(Map<String, dynamic> emp, {required bool isCheckIn}) {
    FocusScope.of(context).unfocus();
    final empId = (emp['user_id'] ?? emp['id'] ?? 0) as int;
    final empName = (emp['full_name'] ?? emp['name'] ?? 'Employee').toString();
    DateTime selectedDateTime = DateTime.now();
    bool useCurrentTime = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            final isDark = Theme.of(dialogCtx).brightness == Brightness.dark;
            final actionColor = isCheckIn ? AsmitaPalette.successGreen : const Color(0xFFDC2626);
            final actionTitle = isCheckIn ? 'Check In Employee' : 'Check Out Employee';

            return SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 18,
                  bottom: MediaQuery.of(dialogCtx).viewInsets.bottom + 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: actionColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            isCheckIn ? Icons.login_rounded : Icons.logout_rounded,
                            color: actionColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                actionTitle,
                                style: const TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                empName,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(dialogCtx).textTheme.bodySmall?.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          onPressed: () => Navigator.pop(sheetContext),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          splashRadius: 20,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Option 1: Real-time
                    InkWell(
                      onTap: () => setDialogState(() => useCurrentTime = true),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: useCurrentTime
                              ? actionColor.withValues(alpha: isDark ? 0.2 : 0.08)
                              : Theme.of(dialogCtx).colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: useCurrentTime ? actionColor : Theme.of(dialogCtx).dividerColor,
                            width: useCurrentTime ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              useCurrentTime ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                              color: useCurrentTime ? actionColor : Colors.grey,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Log Current Time (Real-Time)',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    DateFormat('hh:mm a • dd MMM yyyy').format(DateTime.now()),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: actionColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Option 2: Custom Picked Time (iPhone Style Cupertino Picker)
                    InkWell(
                      onTap: () async {
                        setDialogState(() => useCurrentTime = false);
                        final picked = await _showIosTimePicker(dialogCtx, selectedDateTime);
                        if (picked != null) {
                          final now = DateTime.now();
                          setDialogState(() {
                            useCurrentTime = false;
                            selectedDateTime = DateTime(
                              now.year,
                              now.month,
                              now.day,
                              picked.hour,
                              picked.minute,
                            );
                          });
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: !useCurrentTime
                              ? actionColor.withValues(alpha: isDark ? 0.2 : 0.08)
                              : Theme.of(dialogCtx).colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: !useCurrentTime ? actionColor : Theme.of(dialogCtx).dividerColor,
                            width: !useCurrentTime ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              !useCurrentTime ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                              color: !useCurrentTime ? actionColor : Colors.grey,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Select Custom Time',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    !useCurrentTime
                                        ? DateFormat('hh:mm a • dd MMM yyyy').format(selectedDateTime)
                                        : 'Tap to pick specific hour & minute',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: !useCurrentTime ? actionColor : Colors.grey,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.access_time_rounded,
                              color: !useCurrentTime ? actionColor : Colors.grey,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    ElevatedButton(
                      onPressed: () async {
                        FocusScope.of(context).unfocus();
                        final sId = _resolveSocietyId();

                        // Strict 50m Physical Geofence Verification for Receptionist Actions
                        final geofenceResult = await LocationGeofenceService.verifySocietyProximity(
                          societyId: sId,
                          defaultRadius: 50.0,
                        );

                        if (!mounted) return;
                        if (!geofenceResult.isAllowed) {
                          AsmitaToast.show(
                            context,
                            message: geofenceResult.errorMessage ?? 'You must be physically present at the entrance (within 50m) to record attendance.',
                            type: AsmitaToastType.error,
                            duration: const Duration(seconds: 4),
                          );
                          return;
                        }

                        final recordedTime = useCurrentTime ? DateTime.now() : selectedDateTime;
                        final statusStr = isCheckIn ? 'IN' : 'OUT';
                        final existingSession = _sessionMovementLog[empId];
                        final existingCheckIn = existingSession?['last_check_in_at'] ??
                            _parseDateTime(
                              emp['last_check_in_at'] ??
                              emp['check_in_at'] ??
                              emp['check_in_time'],
                            );
                        setState(() {
                          _sessionMovementLog[empId] = {
                            'status': statusStr,
                            'time': recordedTime,
                            'last_movement_at': recordedTime,
                            if (isCheckIn) 'last_check_in_at': recordedTime,
                            if (!isCheckIn) 'last_check_out_at': recordedTime,
                            if (!isCheckIn && existingCheckIn != null) 'last_check_in_at': existingCheckIn,
                          };
                          final idx = _allEmployees.indexWhere(
                            (e) => ((e['user_id'] ?? e['id'] ?? 0) as int) == empId,
                          );
                          if (idx != -1) {
                            _allEmployees[idx]['is_checked_in'] = isCheckIn;
                            _allEmployees[idx]['status'] = statusStr;
                            _allEmployees[idx]['attendance_status'] = statusStr;
                            _allEmployees[idx]['duty_status'] = isCheckIn ? 'ON_DUTY' : 'OFF_DUTY';
                            _allEmployees[idx]['last_movement_at'] = recordedTime.toIso8601String();
                            if (isCheckIn) {
                              _allEmployees[idx]['last_check_in_at'] = recordedTime.toIso8601String();
                            } else {
                              _allEmployees[idx]['last_check_out_at'] = recordedTime.toIso8601String();
                              if (existingCheckIn != null) {
                                _allEmployees[idx]['last_check_in_at'] = existingCheckIn.toIso8601String();
                              }
                            }
                          }
                        });
                        if (!mounted || !sheetContext.mounted) return;
                        Navigator.pop(sheetContext);
                        HapticFeedback.mediumImpact();
                        AsmitaToast.show(
                          context,
                          message: '${isCheckIn ? "Checked in" : "Checked out"} $empName.',
                          type: AsmitaToastType.success,
                        );

                        // Persist to backend server so other gates/receptionists see it
                        AsmitaPreApproveWizard.recordEmployeeMovement(
                          societyId: sId,
                          employeeId: empId,
                          status: statusStr,
                          recordedAt: recordedTime,
                          gateName: 'Gate Reception',
                          notes: 'Manual check-$statusStr by Receptionist',
                          latitude: geofenceResult.currentLatitude,
                          longitude: geofenceResult.currentLongitude,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark
                            ? const Color(0xFF2563EB)
                            : AsmitaPalette.deepNavy,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Confirm ${isCheckIn ? "Check-in" : "Check-out"}',
                        style: const TextStyle(
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showFilterSheet(BuildContext context) {
    HapticFeedback.lightImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMain = isDark ? Colors.white : const Color(0xFF0F172A);
    final textMuted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    String tempFloor = _selectedFloor;
    String tempDept = _selectedDepartment;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final hasTempFilters = tempFloor != 'All Floors' || tempDept != 'All Departments';

            return Container(
              height: MediaQuery.of(context).size.height * 0.70,
              decoration: BoxDecoration(
                color: isDark ? AsmitaPalette.surfaceDark : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    // Handle Bar
                    Container(
                      margin: const EdgeInsets.only(top: 10, bottom: 6),
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    // Sheet Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.tune_rounded,
                            size: 20,
                            color: isDark ? const Color(0xFF60A5FA) : AsmitaPalette.deepNavy,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Filter Staff',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.w700,
                              fontSize: 17,
                              color: textMain,
                            ),
                          ),
                          const Spacer(),
                          if (hasTempFilters)
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                setModalState(() {
                                  tempFloor = 'All Floors';
                                  tempDept = 'All Departments';
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Reset',
                                  style: TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFEF4444),
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: Icon(Icons.close_rounded, size: 22, color: textMuted),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                    ),

                    // Segmented Tabs: Floors & Department
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                      child: Container(
                        height: 42,
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                            width: 1,
                          ),
                        ),
                        child: TabBar(
                          indicator: BoxDecoration(
                            color: isDark ? const Color(0xFF3B82F6) : AsmitaPalette.deepNavy,
                            borderRadius: BorderRadius.circular(9),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          indicatorSize: TabBarIndicatorSize.tab,
                          dividerColor: Colors.transparent,
                          labelColor: Colors.white,
                          unselectedLabelColor: textMuted,
                          labelStyle: const TextStyle(
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5,
                          ),
                          unselectedLabelStyle: const TextStyle(
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.w600,
                            fontSize: 12.5,
                          ),
                          tabs: [
                            Tab(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.layers_outlined, size: 15),
                                    const SizedBox(width: 6),
                                    const Text('Floors'),
                                    if (tempFloor != 'All Floors') ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF10B981),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            Tab(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.business_outlined, size: 15),
                                    const SizedBox(width: 6),
                                    const Text('Departments'),
                                    if (tempDept != 'All Departments') ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF10B981),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Tab Views
                    Expanded(
                      child: TabBarView(
                        children: [
                          // Tab 1: Floor values in Grid of 5
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            child: GridView.builder(
                              itemCount: _availableFloors.length,
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 5,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                                childAspectRatio: 1.05,
                              ),
                              itemBuilder: (context, i) {
                                final f = _availableFloors[i];
                                final isSelected = tempFloor == f;
                                final isAll = f == 'All Floors';
                                final cleanNum = isAll
                                    ? 'All'
                                    : f.replaceAll(RegExp(r'^floor\s*', caseSensitive: false), '').trim();

                                return InkWell(
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    setModalState(() => tempFloor = f);
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? (isDark ? const Color(0xFF3B82F6) : AsmitaPalette.deepNavy)
                                          : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected
                                            ? (isDark ? const Color(0xFF60A5FA) : AsmitaPalette.deepNavy)
                                            : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                        width: isSelected ? 1.5 : 1,
                                      ),
                                    ),
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          if (!isAll)
                                            Text(
                                              'FL',
                                              style: TextStyle(
                                                fontFamily: 'Montserrat',
                                                fontSize: 8.5,
                                                fontWeight: FontWeight.w600,
                                                color: isSelected
                                                    ? Colors.white70
                                                    : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                                              ),
                                            ),
                                          FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Text(
                                              cleanNum,
                                              style: TextStyle(
                                                fontFamily: 'Montserrat',
                                                fontSize: isAll ? 13 : 15,
                                                fontWeight: FontWeight.w700,
                                                color: isSelected ? Colors.white : textMain,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                          // Tab 2: Departments in List
                          ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            itemCount: _availableDepartments.length,
                            separatorBuilder: (_, _) => Divider(
                              height: 1,
                              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                            ),
                            itemBuilder: (context, i) {
                              final d = _availableDepartments[i];
                              final isSelected = tempDept == d;

                              return InkWell(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setModalState(() => tempDept = d);
                                },
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? (isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF))
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        d == 'All Departments'
                                            ? Icons.dashboard_outlined
                                            : Icons.business_outlined,
                                        size: 18,
                                        color: isSelected
                                            ? (isDark ? const Color(0xFF60A5FA) : AsmitaPalette.deepNavy)
                                            : textMuted,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          d,
                                          style: TextStyle(
                                            fontFamily: 'Montserrat',
                                            fontSize: 13,
                                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                            color: isSelected
                                                ? (isDark ? Colors.white : AsmitaPalette.deepNavy)
                                                : textMain,
                                          ),
                                        ),
                                      ),
                                      if (isSelected)
                                        Icon(
                                          Icons.check_circle_rounded,
                                          size: 18,
                                          color: isDark ? const Color(0xFF60A5FA) : AsmitaPalette.deepNavy,
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    // Apply Button Sticky Footer
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark ? AsmitaPalette.surfaceDark : Colors.white,
                        border: Border(
                          top: BorderSide(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                            width: 1,
                          ),
                        ),
                      ),
                      child: SafeArea(
                        top: false,
                        child: SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: ElevatedButton(
                            key: const Key('apply_staff_filters_btn'),
                            onPressed: () {
                              HapticFeedback.mediumImpact();
                              setState(() {
                                _selectedFloor = tempFloor;
                                _selectedDepartment = tempDept;
                              });
                              Navigator.pop(ctx);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark ? const Color(0xFF3B82F6) : AsmitaPalette.deepNavy,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Apply Filters',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final base = _baseFilteredEmployees;
    final pendingCount = base.where((e) => _isEmpPendingToday(e)).length;
    final inCount = base.where((e) => _isEmpIn(e)).length;
    final outCount = base.where((e) => _isEmpCheckedOutToday(e)).length;
    final allCount = base.length;
    final filtered = _filteredEmployees;
    final hasFloorFilter = _selectedFloor != 'All Floors';
    final hasDeptFilter = _selectedDepartment != 'All Departments';
    final hasFloorOrDeptFilter = hasFloorFilter || hasDeptFilter;
    final hasActiveFilter = hasFloorOrDeptFilter ||
        _searchQuery.isNotEmpty ||
        _selectedMovementFilter != 'ALL';
    final hasFiltersApplied = hasFloorOrDeptFilter || _searchQuery.isNotEmpty;

    String filterLabel = 'Filter';
    if (hasFloorFilter && hasDeptFilter) {
      filterLabel = '2 Filters';
    } else if (hasFloorFilter) {
      final clean = _selectedFloor.replaceAll(RegExp(r'^floor\s*', caseSensitive: false), '').trim();
      filterLabel = clean.isNotEmpty ? 'Floor $clean' : _selectedFloor;
    } else if (hasDeptFilter) {
      filterLabel = _selectedDepartment;
    }

    final bodyContent = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
                    // Search Bar with perfectly aligned icon & placeholder text
                    Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: isDark ? AsmitaPalette.surfaceDark : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? AsmitaPalette.borderGreyDark : AsmitaPalette.borderGrey,
                          width: 1.5,
                        ),
                      ),
                      child: TextField(
                        controller: _searchController,
                        textAlignVertical: TextAlignVertical.center,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: context.responsiveFont(13),
                          color: isDark ? AsmitaPalette.textDarkModeMain : AsmitaPalette.textDark,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: 'Search employee name, department or role...',
                          hintStyle: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: context.responsiveFont(12.5),
                            color: isDark
                                ? AsmitaPalette.textDarkModeMuted
                                : AsmitaPalette.textLight,
                          ),
                          prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 48),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            size: 20,
                            color: isDark ? AsmitaPalette.textDarkModeMuted : AsmitaPalette.textLight,
                          ),
                          suffixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 48),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 18),
                                  padding: EdgeInsets.zero,
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                        ),
                        onChanged: (val) => setState(() => _searchQuery = val),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // KPI Movement Filter Tabs (Pending, In, Out, All)
                    _buildKpiFilterTabs(
                      context,
                      pendingCount: pendingCount,
                      inCount: inCount,
                      outCount: outCount,
                      allCount: allCount,
                    ),

                    const SizedBox(height: 14),

                    // Section Header: Staff Count + Filter Actions
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: SizedBox(
                        height: 34,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Left: Staff count badge
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  'Staff',
                                  style: TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontSize: context.responsiveFont(13.5),
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  height: 22,
                                  padding: const EdgeInsets.symmetric(horizontal: 7),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: (isDark ? const Color(0xFF3B82F6) : AsmitaPalette.deepNavy)
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(11),
                                  ),
                                  child: Text(
                                    '${filtered.length}',
                                    style: TextStyle(
                                      fontFamily: 'Montserrat',
                                      fontSize: context.responsiveFont(10.5),
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? const Color(0xFF60A5FA) : AsmitaPalette.deepNavy,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            // Right: Reset button + Single Filter Button
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerRight,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    if (hasFiltersApplied) ...[
                                      GestureDetector(
                                        onTap: () {
                                          HapticFeedback.lightImpact();
                                          _searchController.clear();
                                          setState(() {
                                            _searchQuery = '';
                                            _selectedFloor = 'All Floors';
                                            _selectedDepartment = 'All Departments';
                                          });
                                        },
                                        child: Container(
                                          height: 32,
                                          padding: const EdgeInsets.symmetric(horizontal: 9),
                                          margin: const EdgeInsets.only(right: 6),
                                          decoration: BoxDecoration(
                                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                              width: 1,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.refresh_rounded,
                                                size: 12,
                                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Reset',
                                                style: TextStyle(
                                                  fontFamily: 'Montserrat',
                                                  fontSize: 10.5,
                                                  fontWeight: FontWeight.w600,
                                                  color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],

                                    // Single Filter Button opening Slideup with Tabs
                                    GestureDetector(
                                      key: const Key('employee_registry_filter_btn'),
                                      onTap: () => _showFilterSheet(context),
                                      child: Container(
                                        height: 32,
                                        padding: const EdgeInsets.symmetric(horizontal: 10),
                                        decoration: BoxDecoration(
                                          color: hasFloorOrDeptFilter
                                              ? (isDark ? const Color(0xFF2563EB) : AsmitaPalette.deepNavy)
                                              : (isDark ? AsmitaPalette.surfaceDark : Colors.white),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: hasFloorOrDeptFilter
                                                ? Colors.transparent
                                                : (isDark ? AsmitaPalette.borderGreyDark : const Color(0xFFCBD5E1)),
                                            width: 1.1,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.03),
                                              blurRadius: 3,
                                              offset: const Offset(0, 1),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.tune_rounded,
                                              size: 13,
                                              color: hasFloorOrDeptFilter
                                                  ? Colors.white
                                                  : (isDark ? AsmitaPalette.deepNavyDark : AsmitaPalette.deepNavy),
                                            ),
                                            const SizedBox(width: 5),
                                            Text(
                                              filterLabel,
                                              style: TextStyle(
                                                fontFamily: 'Montserrat',
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: hasFloorOrDeptFilter
                                                    ? Colors.white
                                                    : (isDark ? AsmitaPalette.textDarkModeMain : AsmitaPalette.textDark),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Active movement count notice
                  if (_sessionMovementLog.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.history_rounded, size: 14, color: AsmitaPalette.successGreen),
                          const SizedBox(width: 5),
                          Text(
                            '${_sessionMovementLog.length} active attendance movements logged today',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AsmitaPalette.successGreen,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Employee List or Loading / Empty States
                  if (_isLoading)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: _buildEmployeeSkeletonList(context),
                    )
                  else if (filtered.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 60),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.person_off_rounded,
                              size: 48,
                              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.3),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'No employees match "$_searchQuery"'
                                  : 'No registered employees found matching filter',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                              ),
                            ),
                            if (hasActiveFilter) ...[
                              const SizedBox(height: 10),
                              OutlinedButton.icon(
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                    _selectedFloor = 'All Floors';
                                    _selectedDepartment = 'All Departments';
                                  });
                                },
                                icon: const Icon(Icons.refresh_rounded, size: 14),
                                label: const Text('Clear Filters', style: TextStyle(fontSize: 12)),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, idx) {
                        final emp = filtered[idx];
                        final empId = (emp['user_id'] ?? emp['id'] ?? 0) as int;
                        final name = (emp['full_name'] ?? emp['name'] ?? 'Staff Member').toString();
                        final dept = (emp['department_name'] ?? emp['department'] ?? 'General').toString();
                        final role = (emp['primary_role'] ?? emp['role'] ?? emp['designation'] ?? 'Employee').toString();
                        final floor = (emp['floor'] ?? '').toString().trim();
                        final desk = (emp['desk_code'] ?? '').toString().trim();
                        final cabin = (emp['cabin_code'] ?? '').toString().trim();
                        final movement = _sessionMovementLog[empId];
                        final isCheckedIn = _isEmpIn(emp);

                        DateTime? parseDateTime(dynamic val) {
                          if (val == null) return null;
                          if (val is DateTime) return val;
                          try {
                            return DateTime.parse(val.toString()).toLocal();
                          } catch (_) {
                            return null;
                          }
                        }

                        DateTime? checkInTime = parseDateTime(
                          emp['last_check_in_at'] ??
                          emp['check_in_at'] ??
                          emp['check_in_time'] ??
                          emp['checked_in_at'],
                        );
                        DateTime? checkOutTime = parseDateTime(
                          emp['last_check_out_at'] ??
                          emp['check_out_at'] ??
                          emp['check_out_time'] ??
                          emp['checked_out_at'],
                        );

                        final lastMovement = parseDateTime(emp['last_movement_at'] ?? emp['recorded_at']);
                        if (lastMovement != null) {
                          if (isCheckedIn && checkInTime == null) {
                            checkInTime = lastMovement;
                          } else if (!isCheckedIn && checkOutTime == null) {
                            checkOutTime = lastMovement;
                          }
                        }

                        if (movement != null) {
                          final status = movement['status'];
                          final time = movement['time'] as DateTime;
                          if (status == 'IN') {
                            checkInTime = time;
                          } else if (status == 'OUT') {
                            checkOutTime = time;
                          }
                          if (movement['last_check_in_at'] != null) {
                            checkInTime = movement['last_check_in_at'] as DateTime;
                          }
                          if (movement['last_check_out_at'] != null) {
                            checkOutTime = movement['last_check_out_at'] as DateTime;
                          }
                        }

                        String cleanFloor = '';
                        if (floor.isNotEmpty) {
                          cleanFloor = floor.replaceAll(RegExp(r'^floor\s*', caseSensitive: false), '').trim();
                        }

                        // Generate smart 2-letter initials
                        String initials = 'S';
                        final nameParts = name.trim().split(RegExp(r'\s+'));
                        if (nameParts.isNotEmpty && nameParts[0].isNotEmpty) {
                          if (nameParts.length == 1) {
                            initials = nameParts[0][0].toUpperCase();
                          } else if (nameParts[1].isNotEmpty) {
                            initials = '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
                          }
                        }

                        final isAllFilter = _selectedMovementFilter == 'ALL';
                        final isPendingFilter = _selectedMovementFilter == 'PENDING';
                        final isInFilter = _selectedMovementFilter == 'IN';
                        final isOutFilter = _selectedMovementFilter == 'OUT';

                        final showFooter = !isAllFilter;
                        final showInButton = isPendingFilter || isOutFilter;
                        final showOutButton = isInFilter;

                        return Container(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isCheckedIn
                                  ? (isDark
                                      ? const Color(0xFF059669).withValues(alpha: 0.45)
                                      : const Color(0xFF10B981).withValues(alpha: 0.35))
                                  : (isDark ? AsmitaPalette.borderGreyDark : const Color(0xFFE2E8F0)),
                              width: isCheckedIn ? 1.4 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // ── UPPER SECTION: Employee Profile & Presence ──
                              Padding(
                                padding: EdgeInsets.fromLTRB(14, 13, 14, isAllFilter ? 13 : 11),
                                child: IntrinsicHeight(
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      // Squircle Avatar with Presence Dot
                                      AspectRatio(
                                        aspectRatio: 1,
                                        child: Stack(
                                          clipBehavior: Clip.none,
                                          children: [
                                            Container(
                                              width: double.infinity,
                                              height: double.infinity,
                                              decoration: BoxDecoration(
                                                color: isCheckedIn
                                                    ? (isDark
                                                        ? const Color(0xFF064E3B).withValues(alpha: 0.35)
                                                        : const Color(0xFFECFDF5))
                                                    : (isDark
                                                        ? AsmitaPalette.deepNavyDark.withValues(alpha: 0.15)
                                                        : const Color(0xFFF1F5F9)),
                                                borderRadius: BorderRadius.circular(14),
                                                border: Border.all(
                                                  color: isCheckedIn
                                                      ? (isDark ? const Color(0xFF059669) : const Color(0xFF10B981).withValues(alpha: 0.4))
                                                      : (isDark ? AsmitaPalette.borderGreyDark : const Color(0xFFCBD5E1)),
                                                  width: 1,
                                                ),
                                              ),
                                              alignment: Alignment.center,
                                              child: Text(
                                                initials,
                                                style: TextStyle(
                                                  fontFamily: 'Montserrat',
                                                  fontWeight: FontWeight.w700,
                                                  color: isCheckedIn
                                                      ? (isDark ? const Color(0xFF34D399) : const Color(0xFF059669))
                                                      : (isDark ? AsmitaPalette.deepNavyDark : AsmitaPalette.deepNavy),
                                                  fontSize: 16,
                                                  letterSpacing: 0.4,
                                                ),
                                              ),
                                            ),
                                            // Presence Status Dot
                                            Positioned(
                                              right: -1,
                                              bottom: -1,
                                              child: Container(
                                                width: 13,
                                                height: 13,
                                                decoration: BoxDecoration(
                                                  color: isCheckedIn ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: theme.colorScheme.surface,
                                                    width: 2,
                                                  ),
                                                  boxShadow: [
                                                    if (isCheckedIn)
                                                      BoxShadow(
                                                        color: const Color(0xFF10B981).withValues(alpha: 0.5),
                                                        blurRadius: 4,
                                                        offset: const Offset(0, 1),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),

                                      // Name, Role & Location
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontFamily: 'Montserrat',
                                                fontWeight: FontWeight.w700,
                                                fontSize: context.responsiveFont(14),
                                                height: 1.15,
                                                color: isDark ? AsmitaPalette.textDarkModeMain : const Color(0xFF0F172A),
                                                letterSpacing: -0.2,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              dept.isNotEmpty && role.isNotEmpty ? '$role • $dept' : (role.isNotEmpty ? role : dept),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontFamily: 'Poppins',
                                                fontSize: context.responsiveFont(11.5),
                                                height: 1.15,
                                                fontWeight: FontWeight.w500,
                                                color: isDark ? AsmitaPalette.textDarkModeMuted : const Color(0xFF64748B),
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            if (cleanFloor.isNotEmpty || desk.isNotEmpty || cabin.isNotEmpty)
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6.5, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                                      borderRadius: BorderRadius.circular(6),
                                                      border: Border.all(
                                                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                                        width: 0.8,
                                                      ),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Icon(
                                                          Icons.layers_rounded,
                                                          size: 11,
                                                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                                        ),
                                                        const SizedBox(width: 3.5),
                                                        Text(
                                                          [
                                                            if (cleanFloor.isNotEmpty) 'Floor $cleanFloor',
                                                            if (desk.isNotEmpty) desk,
                                                            if (cabin.isNotEmpty) cabin,
                                                          ].join(' • '),
                                                          style: TextStyle(
                                                            fontFamily: 'Poppins',
                                                            fontSize: 10,
                                                            fontWeight: FontWeight.w500,
                                                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              )
                                            else
                                              const SizedBox(height: 18),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),

                                      // Presence Badge (Top-Right)
                                      Align(
                                        alignment: Alignment.topRight,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                                          decoration: BoxDecoration(
                                            color: isCheckedIn
                                                ? (isDark ? const Color(0xFF064E3B).withValues(alpha: 0.4) : const Color(0xFFECFDF5))
                                                : (isPendingFilter
                                                    ? (isDark ? const Color(0xFF78350F).withValues(alpha: 0.35) : const Color(0xFFFEF3C7))
                                                    : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9))),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: isCheckedIn
                                                  ? const Color(0xFF10B981).withValues(alpha: 0.4)
                                                  : (isPendingFilter
                                                      ? const Color(0xFFF59E0B).withValues(alpha: 0.4)
                                                      : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
                                              width: 0.8,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                width: 6,
                                                height: 6,
                                                decoration: BoxDecoration(
                                                  color: isCheckedIn
                                                      ? const Color(0xFF10B981)
                                                      : (isPendingFilter
                                                          ? const Color(0xFFF59E0B)
                                                          : const Color(0xFF94A3B8)),
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                isCheckedIn ? 'Inside' : (isPendingFilter ? 'Pending' : 'Out'),
                                                style: TextStyle(
                                                  fontFamily: 'Montserrat',
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w700,
                                                  color: isCheckedIn
                                                      ? (isDark ? const Color(0xFF34D399) : const Color(0xFF059669))
                                                      : (isPendingFilter
                                                          ? (isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309))
                                                          : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // ── INTEGRATED FOOTER: Timestamps + Action Buttons (Hidden on 'ALL' tab) ──
                              if (showFooter)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF0F172A).withValues(alpha: 0.4)
                                        : const Color(0xFFF8FAFC),
                                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(15)),
                                    border: Border(
                                      top: BorderSide(
                                        color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      // Left: Timestamps / Status
                                      Expanded(
                                        child: Builder(
                                          builder: (_) {
                                            if (isOutFilter) {
                                              // "In checked out show check in and out timestamps both."
                                              return Row(
                                                children: [
                                                  if (checkInTime != null) ...[
                                                    Icon(
                                                      Icons.login_rounded,
                                                      size: 12,
                                                      color: isDark ? const Color(0xFF34D399) : const Color(0xFF059669),
                                                    ),
                                                    const SizedBox(width: 3),
                                                    Text(
                                                      'In ${DateFormat("hh:mm a").format(checkInTime)}',
                                                      style: TextStyle(
                                                        fontFamily: 'Poppins',
                                                        fontSize: 10.5,
                                                        fontWeight: FontWeight.w600,
                                                        color: isDark ? const Color(0xFF34D399) : const Color(0xFF047857),
                                                      ),
                                                    ),
                                                  ],
                                                  if (checkInTime != null && checkOutTime != null)
                                                    Padding(
                                                      padding: const EdgeInsets.symmetric(horizontal: 5),
                                                      child: Text(
                                                        '•',
                                                        style: TextStyle(
                                                          color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ),
                                                  if (checkOutTime != null) ...[
                                                    Icon(
                                                      Icons.logout_rounded,
                                                      size: 12,
                                                      color: isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626),
                                                    ),
                                                    const SizedBox(width: 3),
                                                    Text(
                                                      'Out ${DateFormat("hh:mm a").format(checkOutTime)}',
                                                      style: TextStyle(
                                                        fontFamily: 'Poppins',
                                                        fontSize: 10.5,
                                                        fontWeight: FontWeight.w600,
                                                        color: isDark ? const Color(0xFFF87171) : const Color(0xFFB91C1C),
                                                      ),
                                                    ),
                                                  ],
                                                  if (checkInTime == null && checkOutTime == null) ...[
                                                    Icon(
                                                      Icons.logout_rounded,
                                                      size: 12,
                                                      color: isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626),
                                                    ),
                                                    const SizedBox(width: 3),
                                                    Text(
                                                      'Checked out today',
                                                      style: TextStyle(
                                                        fontFamily: 'Poppins',
                                                        fontSize: 10.5,
                                                        fontWeight: FontWeight.w600,
                                                        color: isDark ? const Color(0xFFF87171) : const Color(0xFFB91C1C),
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              );
                                            } else if (isInFilter) {
                                              return Row(
                                                children: [
                                                  Icon(
                                                    Icons.login_rounded,
                                                    size: 12,
                                                    color: isDark ? const Color(0xFF34D399) : const Color(0xFF059669),
                                                  ),
                                                  const SizedBox(width: 3),
                                                  Text(
                                                    checkInTime != null
                                                        ? 'In ${DateFormat("hh:mm a").format(checkInTime)}'
                                                        : 'Inside property',
                                                    style: TextStyle(
                                                      fontFamily: 'Poppins',
                                                      fontSize: 10.5,
                                                      fontWeight: FontWeight.w600,
                                                      color: isDark ? const Color(0xFF34D399) : const Color(0xFF047857),
                                                    ),
                                                  ),
                                                ],
                                              );
                                            } else if (isPendingFilter) {
                                              return Row(
                                                children: [
                                                  Icon(
                                                    Icons.schedule_rounded,
                                                    size: 12,
                                                    color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    'Pending check-in',
                                                    style: TextStyle(
                                                      fontFamily: 'Poppins',
                                                      fontSize: 10.5,
                                                      fontWeight: FontWeight.w500,
                                                      color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309),
                                                    ),
                                                  ),
                                                ],
                                              );
                                            }
                                            return const SizedBox.shrink();
                                          },
                                        ),
                                      ),

                                      const SizedBox(width: 8),

                                      // Right: Action Button
                                      if (showInButton)
                                        _buildMovementActionButton(
                                          emp: emp,
                                          isCheckIn: true,
                                          isDark: isDark,
                                          compact: false,
                                        ),
                                      if (showOutButton)
                                        _buildMovementActionButton(
                                          emp: emp,
                                          isCheckIn: false,
                                          isDark: isDark,
                                          compact: false,
                                        ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              );

    if (widget.isEmbedded) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: bodyContent,
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      bottomNavigationBar: AsmitaBottomNavBar(
        currentIndex: -1,
        onTap: (index) {
          Navigator.pop(context, index);
          if (widget.onNavigateToTab != null) {
            widget.onNavigateToTab!(index);
          }
        },
      ),
      body: Column(
        children: [
          // Standard Primary App Header matching BBPS & Society views
          const AsmitaPrimaryHeader(
            subtitleOverride: 'Staff Registry',
            showBackButton: true,
            allowPropertySwitching: false,
            bottomPadding: 12.0,
          ),

          // Main Content Area with Pull-to-Refresh & Responsive Bounded Canvas
          Expanded(
            child: BoundedCanvas(
              maxWidth: 600,
              child: AppRefresh(
                onRefresh: () async {
                  await _loadData(forceRefresh: true);
                },
                padding: EdgeInsets.fromLTRB(
                  context.responsivePadding(16),
                  8,
                  context.responsivePadding(16),
                  24,
                ),
                child: bodyContent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// KPI Movement Filter Tabs (Pending, In, Out, All)
  Widget _buildKpiFilterTabs(
    BuildContext context, {
    required int pendingCount,
    required int inCount,
    required int outCount,
    required int allCount,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Expanded(
          child: _buildKpiCard(
            context,
            label: 'Pending',
            count: pendingCount,
            icon: Icons.hourglass_top_rounded,
            accentColor: isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706),
            filterKey: 'PENDING',
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _buildKpiCard(
            context,
            label: 'In',
            count: inCount,
            icon: Icons.login_rounded,
            accentColor: isDark ? const Color(0xFF34D399) : AsmitaPalette.successGreen,
            filterKey: 'IN',
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _buildKpiCard(
            context,
            label: 'Out',
            count: outCount,
            icon: Icons.logout_rounded,
            accentColor: isDark ? const Color(0xFFF87171) : const Color(0xFFEF4444),
            filterKey: 'OUT',
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _buildKpiCard(
            context,
            label: 'All',
            count: allCount,
            icon: Icons.groups_rounded,
            accentColor: isDark ? const Color(0xFF60A5FA) : AsmitaPalette.deepNavy,
            filterKey: 'ALL',
          ),
        ),
      ],
    );
  }

  Widget _buildKpiCard(
    BuildContext context, {
    required String label,
    required int count,
    required IconData icon,
    required Color accentColor,
    required String filterKey,
  }) {
    final isSelected = _selectedMovementFilter == filterKey;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedMovementFilter = filterKey;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          vertical: context.responsiveScale(10),
          horizontal: 2,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                  ? accentColor.withValues(alpha: 0.18)
                  : accentColor.withValues(alpha: 0.08))
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? accentColor
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? accentColor.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.02),
              blurRadius: isSelected ? 8 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Squircle Icon Container
            Container(
              width: context.responsiveScale(30),
              height: context.responsiveScale(30),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: isDark ? 0.22 : 0.10),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                  color: accentColor.withValues(
                    alpha: isSelected ? 0.45 : 0.18,
                  ),
                  width: 1.0,
                ),
              ),
              child: Center(
                child: Icon(
                  icon,
                  color: accentColor,
                  size: context.responsiveScale(16),
                ),
              ),
            ),
            SizedBox(height: context.responsiveScale(5)),
            // KPI Count Number
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '$count',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: context.responsiveFont(16.5),
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(height: 2),
            // KPI Label
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: context.responsiveFont(10.5),
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isDark
                      ? (isSelected ? Colors.white : const Color(0xFF94A3B8))
                      : (isSelected ? const Color(0xFF0F172A) : const Color(0xFF64748B)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMovementActionButton({
    required Map<String, dynamic> emp,
    required bool isCheckIn,
    required bool isDark,
    bool compact = false,
  }) {
    final bgColor = isCheckIn ? const Color(0xFF059669) : const Color(0xFFDC2626);
    final icon = isCheckIn ? Icons.login_rounded : Icons.logout_rounded;
    final label = compact ? (isCheckIn ? 'In' : 'Out') : (isCheckIn ? 'Check In' : 'Check Out');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showMovementDialog(emp, isCheckIn: isCheckIn),
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          height: 32,
          padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 13),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: bgColor.withValues(alpha: 0.25),
                blurRadius: 4,
                offset: const Offset(0, 1.5),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 13, color: Colors.white),
              const SizedBox(width: 4.5),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmployeeSkeletonList(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AsmitaSkeleton(
      isLoading: true,
      child: Column(
        children: List.generate(
          4,
          (index) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: isDark ? AsmitaPalette.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AsmitaPalette.borderGreyDark : const Color(0xFFE2E8F0),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.35)
                      : const Color(0xFF0F172A).withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 13, 14, 11),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AsmitaSkeleton.bone(width: 58, height: 58, borderRadius: 14),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AsmitaSkeleton.text(width: 120, height: 14, borderRadius: 3),
                            const SizedBox(height: 5),
                            AsmitaSkeleton.text(width: 160, height: 12, borderRadius: 3),
                            const SizedBox(height: 6),
                            AsmitaSkeleton.bone(width: 65, height: 18, borderRadius: 6),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      AsmitaSkeleton.pill(width: 55, height: 22),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0F172A).withValues(alpha: 0.4)
                        : const Color(0xFFF8FAFC),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(15)),
                    border: Border(
                      top: BorderSide(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AsmitaSkeleton.text(width: 100, height: 12, borderRadius: 3),
                      AsmitaSkeleton.bone(width: 70, height: 30, borderRadius: 8),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
