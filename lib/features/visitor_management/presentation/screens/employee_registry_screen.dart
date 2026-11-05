import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/design_system.dart';
import '../../../../core/widgets/asmita_toast.dart';
import '../../../../core/widgets/asmita_loading_indicator.dart';
import '../../../../core/widgets/asmita_animated_refresh.dart';
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

  const EmployeeRegistryScreen({
    super.key,
    this.societyId,
    this.onNavigateToTab,
  });

  static Future<int?> open(
    BuildContext context, {
    int? societyId,
    ValueChanged<int>? onNavigateToTab,
  }) {
    return Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (_) => EmployeeRegistryScreen(
          societyId: societyId,
          onNavigateToTab: onNavigateToTab,
        ),
      ),
    );
  }

  @override
  State<EmployeeRegistryScreen> createState() => _EmployeeRegistryScreenState();
}

class _EmployeeRegistryScreenState extends State<EmployeeRegistryScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _allEmployees = [];
  List<Map<String, dynamic>> _allDepartments = [];
  bool _isLoading = true;
  String _searchQuery = '';

  String _selectedFloor = 'All Floors';
  String _selectedDepartment = 'All Departments';

  // In-memory session log for movement: employee_id -> {status: 'IN' | 'OUT', time: DateTime}
  static final Map<int, Map<String, dynamic>> _sessionMovementLog = {};

  @override
  void initState() {
    super.initState();
    _loadData();
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
    return 115;
  }

  Future<void> _loadData({bool forceRefresh = false}) async {
    final sId = _resolveSocietyId();
    setState(() => _isLoading = true);
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

  List<Map<String, dynamic>> get _filteredEmployees {
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

  void _showMovementDialog(Map<String, dynamic> emp, {required bool isCheckIn}) {
    final empId = (emp['user_id'] ?? emp['id'] ?? 0) as int;
    final empName = (emp['full_name'] ?? emp['name'] ?? 'Employee').toString();
    DateTime selectedDateTime = DateTime.now();
    bool useCurrentTime = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 18,
                bottom: MediaQuery.of(dialogCtx).viewInsets.bottom + 24,
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

                  // Option 2: Custom Picked Time
                  InkWell(
                    onTap: () async {
                      setDialogState(() => useCurrentTime = false);
                      final pickedTime = await showTimePicker(
                        context: dialogCtx,
                        initialTime: TimeOfDay.fromDateTime(selectedDateTime),
                      );
                      if (pickedTime != null) {
                        final now = DateTime.now();
                        setDialogState(() {
                          useCurrentTime = false;
                          selectedDateTime = DateTime(
                            now.year,
                            now.month,
                            now.day,
                            pickedTime.hour,
                            pickedTime.minute,
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
                                      ? DateFormat('hh:mm a (Selected)').format(selectedDateTime)
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
                    onPressed: () {
                      final recordedTime = useCurrentTime ? DateTime.now() : selectedDateTime;
                      setState(() {
                        _sessionMovementLog[empId] = {
                          'status': isCheckIn ? 'IN' : 'OUT',
                          'time': recordedTime,
                        };
                      });
                      Navigator.pop(sheetContext);
                      HapticFeedback.mediumImpact();
                      AsmitaToast.show(
                        context,
                        message: '${isCheckIn ? "Checked in" : "Checked out"} $empName.',
                        type: AsmitaToastType.success,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: actionColor,
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
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDropdownPill({
    required BuildContext context,
    required bool isDark,
    required String selectedValue,
    required List<String> items,
    required IconData icon,
    required String tooltip,
    required ValueChanged<String> onSelected,
  }) {
    final theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(
        hoverColor: Colors.transparent,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      child: PopupMenuButton<String>(
        initialValue: selectedValue,
        tooltip: tooltip,
        offset: const Offset(0, 36),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
          ),
        ),
        color: isDark ? AsmitaPalette.surfaceElevatedDark : Colors.white,
        elevation: 4,
        onSelected: onSelected,
        itemBuilder: (BuildContext ctx) {
          return items.map((val) {
            final isSelected = val == selectedValue;
            return PopupMenuItem<String>(
              value: val,
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 15,
                    color: isSelected
                        ? (isDark ? AsmitaPalette.deepNavyDark : AsmitaPalette.deepNavy)
                        : (isDark ? AsmitaPalette.textDarkModeMuted : AsmitaPalette.textLight),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      val,
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? (isDark ? AsmitaPalette.deepNavyDark : AsmitaPalette.deepNavy)
                            : (isDark ? AsmitaPalette.textDarkModeMain : AsmitaPalette.textDark),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: isDark ? AsmitaPalette.deepNavyDark : AsmitaPalette.deepNavy,
                    ),
                ],
              ),
            );
          }).toList();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isDark ? AsmitaPalette.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark ? AsmitaPalette.borderGreyDark : AsmitaPalette.borderGrey,
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 13,
                color: isDark ? AsmitaPalette.deepNavyDark : AsmitaPalette.deepNavy,
              ),
              const SizedBox(width: 5),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 110),
                child: Text(
                  selectedValue,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AsmitaPalette.textDarkModeMain : AsmitaPalette.textDark,
                  ),
                ),
              ),
              const SizedBox(width: 3),
              Icon(
                Icons.arrow_drop_down_rounded,
                size: 18,
                color: isDark ? AsmitaPalette.textDarkModeMuted : AsmitaPalette.textLight,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final filtered = _filteredEmployees;
    final hasActiveFilter = _selectedFloor != 'All Floors' ||
        _selectedDepartment != 'All Departments' ||
        _searchQuery.isNotEmpty;

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
          AsmitaPrimaryHeader(
            subtitleOverride: 'Staff Registry',
            showBackButton: true,
            allowPropertySwitching: false,
            bottomPadding: 12.0,
            trailingExtraAction: IconButton(
              icon: const Icon(Icons.refresh_rounded, size: 20, color: Colors.white),
              tooltip: 'Refresh Registry',
              onPressed: () {
                HapticFeedback.lightImpact();
                _loadData(forceRefresh: true);
              },
            ),
          ),

          // Main Content Area with Pull-to-Refresh
          Expanded(
            child: AsmitaPullToRefresh(
              onRefresh: () async {
                await _loadData(forceRefresh: true);
              },
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(
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
                        fontSize: 13,
                        color: isDark ? AsmitaPalette.textDarkModeMain : AsmitaPalette.textDark,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: 'Search employee name, department or role...',
                        hintStyle: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12.5,
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

                  const SizedBox(height: 14),

                  // Section Header with BBPS-Style Filter Dropdowns
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
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
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: (isDark ? const Color(0xFF3B82F6) : AsmitaPalette.deepNavy)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${filtered.length}',
                                style: TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? const Color(0xFF60A5FA) : AsmitaPalette.deepNavy,
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Right: Reset button + Floor Dropdown + Department Dropdown
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              if (hasActiveFilter) ...[
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
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4.5),
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
                                      children: [
                                        Icon(
                                          Icons.refresh_rounded,
                                          size: 11,
                                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          'Reset',
                                          style: TextStyle(
                                            fontFamily: 'Montserrat',
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],

                              // Floor Dropdown
                              _buildDropdownPill(
                                context: context,
                                isDark: isDark,
                                selectedValue: _selectedFloor,
                                items: _availableFloors,
                                icon: Icons.layers_outlined,
                                tooltip: 'Filter by Floor',
                                onSelected: (val) {
                                  HapticFeedback.selectionClick();
                                  setState(() => _selectedFloor = val);
                                },
                              ),

                              const SizedBox(width: 6),

                              // Department Dropdown
                              _buildDropdownPill(
                                context: context,
                                isDark: isDark,
                                selectedValue: _selectedDepartment,
                                items: _availableDepartments,
                                icon: Icons.business_outlined,
                                tooltip: 'Filter by Department',
                                onSelected: (val) {
                                  HapticFeedback.selectionClick();
                                  setState(() => _selectedDepartment = val);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Active movement count notice
                  if (_sessionMovementLog.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
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
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: Center(
                        child: AsmitaLoadingIndicator(
                          color: AsmitaPalette.deepNavy,
                          size: 32,
                        ),
                      ),
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
                        final isCheckedIn = movement != null && movement['status'] == 'IN';

                        String cleanFloor = '';
                        if (floor.isNotEmpty) {
                          cleanFloor = floor.replaceAll(RegExp(r'^floor\s*', caseSensitive: false), '').trim();
                        }

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isCheckedIn
                                  ? AsmitaPalette.successGreen
                                  : (isDark ? AsmitaPalette.borderGreyDark : AsmitaPalette.borderGrey),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Squircle Avatar in Asmita Deep Navy
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AsmitaPalette.deepNavyDark.withValues(alpha: 0.15)
                                      : AsmitaPalette.deepNavy.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isDark
                                        ? AsmitaPalette.deepNavyDark.withValues(alpha: 0.3)
                                        : AsmitaPalette.deepNavy.withValues(alpha: 0.15),
                                    width: 1,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : 'S',
                                  style: TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? AsmitaPalette.deepNavyDark : AsmitaPalette.deepNavy,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Info Column
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Row 1: Name and optional movement status tag
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontFamily: 'Montserrat',
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13.5,
                                              color: isDark ? AsmitaPalette.textDarkModeMain : AsmitaPalette.textDark,
                                              letterSpacing: -0.2,
                                            ),
                                          ),
                                        ),
                                        if (movement != null) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: isCheckedIn
                                                  ? AsmitaPalette.successGreen.withValues(alpha: 0.12)
                                                  : AsmitaPalette.actionRed.withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(
                                                color: isCheckedIn
                                                    ? AsmitaPalette.successGreen.withValues(alpha: 0.4)
                                                    : AsmitaPalette.actionRed.withValues(alpha: 0.4),
                                                width: 0.8,
                                              ),
                                            ),
                                            child: Text(
                                              isCheckedIn
                                                  ? 'IN • ${DateFormat("hh:mm a").format(movement["time"] as DateTime)}'
                                                  : 'OUT • ${DateFormat("hh:mm a").format(movement["time"] as DateTime)}',
                                              style: TextStyle(
                                                fontSize: 9.5,
                                                fontWeight: FontWeight.bold,
                                                color: isCheckedIn
                                                    ? AsmitaPalette.successGreen
                                                    : AsmitaPalette.actionRed,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 3),

                                    // Row 2: Department & Designation
                                    Text(
                                      '$dept • $role',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w500,
                                        color: isDark
                                            ? AsmitaPalette.textDarkModeMuted
                                            : AsmitaPalette.textLight,
                                      ),
                                    ),
                                    const SizedBox(height: 5),

                                    // Row 3: Meta Badges (Floor, Desk, Cabin)
                                    Wrap(
                                      spacing: 5,
                                      runSpacing: 4,
                                      children: [
                                        if (cleanFloor.isNotEmpty)
                                          _buildBadge(
                                            icon: Icons.layers_rounded,
                                            label: 'Floor $cleanFloor',
                                            isDark: isDark,
                                          ),
                                        if (desk.isNotEmpty)
                                          _buildBadge(
                                            icon: Icons.desk_rounded,
                                            label: desk,
                                            isDark: isDark,
                                          ),
                                        if (cabin.isNotEmpty)
                                          _buildBadge(
                                            icon: Icons.meeting_room_rounded,
                                            label: cabin,
                                            isDark: isDark,
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 8),

                              // Quick Action Buttons (Check In / Check Out)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // In Button
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () => _showMovementDialog(emp, isCheckIn: true),
                                      borderRadius: BorderRadius.circular(10),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                        decoration: BoxDecoration(
                                          color: isCheckedIn
                                              ? AsmitaPalette.successGreen
                                              : (isDark
                                                  ? AsmitaPalette.successGreen.withValues(alpha: 0.15)
                                                  : AsmitaPalette.successGreen.withValues(alpha: 0.1)),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                            color: isCheckedIn
                                                ? AsmitaPalette.successGreen
                                                : AsmitaPalette.successGreen.withValues(alpha: 0.4),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.login_rounded,
                                              size: 13,
                                              color: isCheckedIn ? Colors.white : AsmitaPalette.successGreen,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'In',
                                              style: TextStyle(
                                                fontFamily: 'Montserrat',
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: isCheckedIn ? Colors.white : AsmitaPalette.successGreen,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),

                                  // Out Button
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () => _showMovementDialog(emp, isCheckIn: false),
                                      borderRadius: BorderRadius.circular(10),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                        decoration: BoxDecoration(
                                          color: !isCheckedIn && movement != null
                                              ? AsmitaPalette.actionRed
                                              : (isDark
                                                  ? AsmitaPalette.actionRed.withValues(alpha: 0.15)
                                                  : AsmitaPalette.actionRed.withValues(alpha: 0.08)),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                            color: !isCheckedIn && movement != null
                                                ? AsmitaPalette.actionRed
                                                : AsmitaPalette.actionRed.withValues(alpha: 0.4),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.logout_rounded,
                                              size: 13,
                                              color: !isCheckedIn && movement != null
                                                  ? Colors.white
                                                  : AsmitaPalette.actionRed,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Out',
                                              style: TextStyle(
                                                fontFamily: 'Montserrat',
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: !isCheckedIn && movement != null
                                                    ? Colors.white
                                                    : AsmitaPalette.actionRed,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge({
    required IconData icon,
    required String label,
    required bool isDark,
  }) {
    final badgeColor = isDark ? AsmitaPalette.deepNavyDark : AsmitaPalette.deepNavy;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: isDark
            ? AsmitaPalette.deepNavyDark.withValues(alpha: 0.12)
            : AsmitaPalette.deepNavy.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isDark
              ? AsmitaPalette.deepNavyDark.withValues(alpha: 0.25)
              : AsmitaPalette.deepNavy.withValues(alpha: 0.15),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10.5, color: badgeColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: badgeColor,
            ),
          ),
        ],
      ),
    );
  }
}
