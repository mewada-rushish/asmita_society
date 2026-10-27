import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/design_system.dart';
import '../../../../core/widgets/asmita_toast.dart';
import '../../../../core/widgets/asmita_bottom_sheet.dart';
import '../../../../core/widgets/asmita_loading_indicator.dart';
import '../../../dashboard/widgets/asmita_pre_approve_wizard.dart';

class EmployeeRegistrySheet extends StatefulWidget {
  final int? societyId;

  const EmployeeRegistrySheet({
    super.key,
    this.societyId,
  });

  static Future<void> show(BuildContext context, {int? societyId}) async {
    showAsmitaBottomSheet(
      context: context,
      title: 'Employee Registry',
      subtitle: 'Log on-site attendance & gate movements',
      isScrollControlled: true,
      contentPadding: EdgeInsets.zero,
      child: EmployeeRegistrySheet(societyId: societyId),
    );
  }

  @override
  State<EmployeeRegistrySheet> createState() => _EmployeeRegistrySheetState();
}

class _EmployeeRegistrySheetState extends State<EmployeeRegistrySheet> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _allEmployees = [];
  bool _isLoading = true;
  String _searchQuery = '';

  // In-memory session log for movement: employee_id -> {status: 'IN' | 'OUT', time: DateTime}
  static final Map<int, Map<String, dynamic>> _sessionMovementLog = {};

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadEmployees() async {
    final sId = widget.societyId ?? 114;
    setState(() => _isLoading = true);
    try {
      final list = await AsmitaPreApproveWizard.loadSocietyEmployees(sId);
      if (!mounted) return;
      setState(() {
        _allEmployees = List.from(list);
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredEmployees {
    if (_searchQuery.trim().isEmpty) return _allEmployees;
    final q = _searchQuery.trim().toLowerCase();
    return _allEmployees.where((e) {
      final name = (e['full_name'] ?? e['name'] ?? '').toString().toLowerCase();
      final dept = (e['department_name'] ?? e['department'] ?? '').toString().toLowerCase();
      final role = (e['primary_role'] ?? e['role'] ?? e['designation'] ?? '').toString().toLowerCase();
      final empId = (e['employee_id'] ?? e['id'] ?? '').toString().toLowerCase();
      return name.contains(q) || dept.contains(q) || role.contains(q) || empId.contains(q);
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
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                MediaQuery.of(dialogCtx).viewInsets.bottom + 24,
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
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: actionColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isCheckIn ? Icons.login_rounded : Icons.logout_rounded,
                          color: actionColor,
                          size: 22,
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
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              empName,
                              style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(dialogCtx).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Select Timestamp Method:',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Option 1: Log Current Time
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

                  // Option 2: Add Custom Selected Time
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

                  // Confirm Action Button
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Search Input
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.dividerColor.withValues(alpha: 0.6),
              ),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search employee name, department or role...',
                hintStyle: TextStyle(
                  fontSize: 12,
                  color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                ),
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),
          const SizedBox(height: 14),

          // Count Info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Registered Corporate Staff (${_filteredEmployees.length})',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              if (_sessionMovementLog.isNotEmpty)
                Text(
                  '${_sessionMovementLog.length} active logs today',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AsmitaPalette.successGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Employee List or Loading / Empty States
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: AsmitaLoadingIndicator(
                  color: AsmitaPalette.deepNavy,
                  size: 28,
                ),
              ),
            )
          else if (_filteredEmployees.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.person_off_rounded,
                      size: 40,
                      color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _searchQuery.isNotEmpty
                          ? 'No employees match "$_searchQuery"'
                          : 'No registered employees found in directory',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _filteredEmployees.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, idx) {
                final emp = _filteredEmployees[idx];
                final empId = (emp['user_id'] ?? emp['id'] ?? 0) as int;
                final name = (emp['full_name'] ?? emp['name'] ?? 'Staff Member').toString();
                final dept = (emp['department_name'] ?? emp['department'] ?? 'General').toString();
                final role = (emp['primary_role'] ?? emp['role'] ?? emp['designation'] ?? 'Employee').toString();
                final movement = _sessionMovementLog[empId];
                final isCheckedIn = movement != null && movement['status'] == 'IN';

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isCheckedIn
                          ? AsmitaPalette.successGreen.withValues(alpha: 0.5)
                          : theme.dividerColor.withValues(alpha: 0.6),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Avatar
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AsmitaPalette.deepNavy.withValues(alpha: 0.1),
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : 'E',
                          style: const TextStyle(
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.bold,
                            color: AsmitaPalette.deepNavy,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontFamily: 'Montserrat',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                if (movement != null) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isCheckedIn
                                          ? AsmitaPalette.successGreen.withValues(alpha: 0.15)
                                          : const Color(0xFFDC2626).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      isCheckedIn
                                          ? 'IN • ${DateFormat("hh:mm a").format(movement["time"] as DateTime)}'
                                          : 'OUT • ${DateFormat("hh:mm a").format(movement["time"] as DateTime)}',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: isCheckedIn ? AsmitaPalette.successGreen : const Color(0xFFDC2626),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$dept • $role',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                              ),
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
                          InkWell(
                            onTap: () => _showMovementDialog(emp, isCheckIn: true),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AsmitaPalette.successGreen.withValues(alpha: isCheckedIn ? 0.2 : 0.08),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AsmitaPalette.successGreen.withValues(alpha: isCheckedIn ? 0.8 : 0.3),
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.login_rounded, size: 14, color: AsmitaPalette.successGreen),
                                  SizedBox(width: 4),
                                  Text(
                                    'In',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AsmitaPalette.successGreen,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),

                          // Out Button
                          InkWell(
                            onTap: () => _showMovementDialog(emp, isCheckIn: false),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDC2626).withValues(alpha: !isCheckedIn && movement != null ? 0.2 : 0.08),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFFDC2626).withValues(alpha: !isCheckedIn && movement != null ? 0.8 : 0.3),
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.logout_rounded, size: 14, color: Color(0xFFDC2626)),
                                  SizedBox(width: 4),
                                  Text(
                                    'Out',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFDC2626),
                                    ),
                                  ),
                                ],
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
    );
  }
}
