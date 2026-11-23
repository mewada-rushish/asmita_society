import 'package:flutter/material.dart';
import '../../../../core/widgets/app_skeleton.dart';
import '../../../../core/widgets/app_refresh.dart';
import '../../../../core/widgets/app_button.dart';
import 'package:asmita_society/core/widgets/asmita_primary_header.dart';
import 'package:asmita_society/core/widgets/asmita_bottom_sheet.dart';
import 'package:asmita_society/core/constants/design_system.dart';
import 'package:asmita_society/core/widgets/asmita_visitor_card.dart';
import 'package:asmita_society/core/widgets/asmita_bottom_nav_bar.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/visitor_bloc.dart';
import '../../bloc/visitor_event.dart';
import '../../bloc/visitor_state.dart';
import '../../data/models/visitor_history_item.dart';
import '../../../../features/auth/bloc/auth_bloc.dart';
import '../../../../features/auth/bloc/auth_state.dart';
import 'package:intl/intl.dart';
import '../../../dashboard/widgets/asmita_pre_approve_wizard.dart';
import 'package:asmita_society/core/widgets/asmita_toast.dart';
import '../../../../core/utils/property_role_resolver.dart';

class VisitorHistoryScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final String? filterCategory;
  const VisitorHistoryScreen({super.key, this.onBack, this.filterCategory});

  @override
  State<VisitorHistoryScreen> createState() => _VisitorHistoryScreenState();
}

class _VisitorHistoryScreenState extends State<VisitorHistoryScreen> {
  String? _selectedStatus;
  DateTime? _startDate;
  DateTime? _endDate;
  String _datePreset = 'ALL';
  String _selectedRecordType = 'ALL';
  String _selectedCategory = 'ALL';
  String _selectedFrequency = 'ALL';
  bool _onlyWithVehicle = false;
  String _sortOrder = 'NEWEST';

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory({bool isRefresh = false}) {
    final authState = context.read<AuthBloc>().state;
    int residentId = 1;
    if (authState is AuthAuthenticated) {
      residentId = authState.user.userId;
    }
    context.read<VisitorBloc>().add(
      LoadMyHistory(
        residentId: residentId,
        isRefresh: isRefresh,
        status: (_selectedStatus == null || _selectedStatus == 'ALL') ? null : _selectedStatus,
        startDate: _startDate,
        endDate: _endDate,
      ),
    );
  }

  int get _activeFilterCount {
    int count = 0;
    if (_selectedStatus != null && _selectedStatus != 'ALL') count++;
    if (_datePreset != 'ALL' || _startDate != null || _endDate != null) count++;
    if (_selectedRecordType != 'ALL') count++;
    if (_selectedCategory != 'ALL') count++;
    if (_selectedFrequency != 'ALL') count++;
    if (_onlyWithVehicle) count++;
    if (_sortOrder != 'NEWEST') count++;
    return count;
  }

  void _clearAllFilters() {
    setState(() {
      _selectedStatus = null;
      _startDate = null;
      _endDate = null;
      _datePreset = 'ALL';
      _selectedRecordType = 'ALL';
      _selectedCategory = 'ALL';
      _selectedFrequency = 'ALL';
      _onlyWithVehicle = false;
      _sortOrder = 'NEWEST';
    });
    _loadHistory();
  }

  void _applyDatePreset(String preset, Function(DateTime?, DateTime?) onSetDates) {
    final now = DateTime.now();
    switch (preset) {
      case 'TODAY':
        final s = DateTime(now.year, now.month, now.day, 0, 0, 0);
        final e = DateTime(now.year, now.month, now.day, 23, 59, 59);
        onSetDates(s, e);
        break;
      case 'YESTERDAY':
        final y = now.subtract(const Duration(days: 1));
        final s = DateTime(y.year, y.month, y.day, 0, 0, 0);
        final e = DateTime(y.year, y.month, y.day, 23, 59, 59);
        onSetDates(s, e);
        break;
      case 'THIS_WEEK':
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final s = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day, 0, 0, 0);
        final e = DateTime(now.year, now.month, now.day, 23, 59, 59);
        onSetDates(s, e);
        break;
      case 'THIS_MONTH':
        final s = DateTime(now.year, now.month, 1, 0, 0, 0);
        final e = DateTime(now.year, now.month, now.day, 23, 59, 59);
        onSetDates(s, e);
        break;
      case 'ALL':
        onSetDates(null, null);
        break;
      case 'CUSTOM':
        break;
    }
  }

  List<VisitorHistoryItem> _applyClientFilters(List<VisitorHistoryItem> rawList) {
    var list = List<VisitorHistoryItem>.from(rawList);

    // 1. widget.filterCategory filter
    if (widget.filterCategory != null) {
      list = list.where((item) {
        return item.category.toLowerCase() == widget.filterCategory!.toLowerCase();
      }).toList();
    }

    // 2. Client-side status fallback
    if (_selectedStatus != null && _selectedStatus != 'ALL') {
      list = list.where((item) {
        final st = item.status.toUpperCase();
        final target = _selectedStatus!.toUpperCase();
        if (target == 'CHECKED_IN') {
          return st.contains('CHECKED_IN') || st.contains('ENTERED') || st.contains('INSIDE');
        }
        if (target == 'CHECKED_OUT') {
          return st.contains('CHECKED_OUT') || st.contains('EXITED') || st.contains('COMPLETED');
        }
        if (target == 'PENDING') {
          return st.contains('PENDING');
        }
        if (target == 'APPROVED') {
          return st.contains('APPROVED');
        }
        if (target == 'REJECTED') {
          return st.contains('REJECTED');
        }
        return st == target;
      }).toList();
    }

    // 3. Pass/Record Type
    if (_selectedRecordType == 'PRE_APPROVED') {
      list = list.where((item) => item.isPreApproved).toList();
    } else if (_selectedRecordType == 'WALK_IN') {
      list = list.where((item) => !item.isPreApproved).toList();
    }

    // 4. Category
    if (_selectedCategory != 'ALL') {
      final target = _selectedCategory.toLowerCase();
      list = list.where((item) {
        final cat = item.category.toLowerCase();
        if (target == 'guest') {
          return cat.contains('guest') || cat.contains('vip') || cat.contains('invite');
        }
        return cat.contains(target);
      }).toList();
    }

    // 5. Pass Frequency
    if (_selectedFrequency == 'FREQUENT') {
      list = list.where((item) => item.inviteSubType == 'FREQUENT').toList();
    } else if (_selectedFrequency == 'ONCE') {
      list = list.where((item) => item.inviteSubType != 'FREQUENT').toList();
    }

    // 6. With Vehicle
    if (_onlyWithVehicle) {
      list = list.where((item) => item.vehicleNumber != null && item.vehicleNumber!.trim().isNotEmpty).toList();
    }

    // 7. Sort Order
    if (_sortOrder == 'OLDEST') {
      list.sort((a, b) {
        final da = DateTime.tryParse(a.dateStr ?? '') ?? DateTime(1970);
        final db = DateTime.tryParse(b.dateStr ?? '') ?? DateTime(1970);
        return da.compareTo(db);
      });
    } else {
      list.sort((a, b) {
        final da = DateTime.tryParse(a.dateStr ?? '') ?? DateTime(1970);
        final db = DateTime.tryParse(b.dateStr ?? '') ?? DateTime(1970);
        return db.compareTo(da);
      });
    }

    return list;
  }

  Widget _buildFilterSectionHeader({
    required BuildContext context,
    required String title,
    required IconData icon,
    String? subtitle,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 14.0, bottom: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 14, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(width: 6),
            Text(
              subtitle,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDateInputCard({
    required BuildContext context,
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isSet = value != null;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isSet
                ? theme.colorScheme.primary.withValues(alpha: 0.05)
                : (isDark ? AsmitaPalette.surfaceDark : theme.colorScheme.surface),
            border: Border.all(
              color: isSet ? theme.colorScheme.primary : theme.dividerColor,
              width: isSet ? 1.4 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10.5,
                      color: isSet ? theme.colorScheme.primary : theme.textTheme.bodySmall?.color,
                      fontWeight: isSet ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                  if (isSet && onClear != null)
                    GestureDetector(
                      onTap: onClear,
                      child: Icon(
                        Icons.close_rounded,
                        size: 14,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 13,
                    color: isSet ? theme.colorScheme.primary : theme.textTheme.bodyMedium?.color,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      isSet ? DateFormat('dd MMM yyyy').format(value) : 'Select date',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11.5,
                        fontWeight: isSet ? FontWeight.w600 : FontWeight.w400,
                        color: isSet ? theme.colorScheme.primary : theme.textTheme.bodyMedium?.color,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterPickerTile({
    required BuildContext context,
    required String selectedLabel,
    required IconData selectedIcon,
    required Color iconColor,
    required bool isCustomized,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isCustomized
                ? theme.colorScheme.primary.withValues(alpha: 0.05)
                : (isDark ? AsmitaPalette.surfaceDark : theme.colorScheme.surface),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isCustomized
                  ? theme.colorScheme.primary
                  : theme.dividerColor.withValues(alpha: 0.7),
              width: isCustomized ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(selectedIcon, size: 18, color: iconColor),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  selectedLabel,
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 13,
                    fontWeight: isCustomized ? FontWeight.w600 : FontWeight.w500,
                    color: isCustomized
                        ? (isDark ? Colors.white : theme.colorScheme.primary)
                        : theme.textTheme.bodyLarge?.color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNativeModalPicker<T>({
    required BuildContext context,
    required String title,
    required T selectedValue,
    required List<Map<String, dynamic>> items,
    required ValueChanged<T> onSelected,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isDark ? AsmitaPalette.surfaceDark : theme.colorScheme.surface;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (pickerCtx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(pickerCtx).size.height * 0.65,
          ),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 16, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AsmitaPalette.textDarkModeMain : AsmitaPalette.textDark,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => Navigator.pop(pickerCtx),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.5)),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, index) {
                      final item = items[index];
                      final val = item['value'] as T;
                      final label = item['label'] as String;
                      final icon = item['icon'] as IconData?;
                      final color = (item['color'] as Color?) ?? theme.colorScheme.primary;
                      final isSelected = val == selectedValue;

                      return Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          onTap: () {
                            Navigator.pop(pickerCtx);
                            onSelected(val);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? theme.colorScheme.primary.withValues(alpha: isDark ? 0.2 : 0.08)
                                  : (isDark ? AsmitaPalette.systemBGDark.withValues(alpha: 0.4) : AsmitaPalette.systemBG.withValues(alpha: 0.5)),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.dividerColor.withValues(alpha: 0.5),
                                width: isSelected ? 1.5 : 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                if (icon != null) ...[
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(icon, size: 18, color: color),
                                  ),
                                  const SizedBox(width: 12),
                                ],
                                Expanded(
                                  child: Text(
                                    label,
                                    style: TextStyle(
                                      fontFamily: 'Montserrat',
                                      fontSize: 13.5,
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                      color: isSelected
                                          ? (isDark ? Colors.white : theme.colorScheme.primary)
                                          : theme.textTheme.bodyLarge?.color,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Icon(
                                    Icons.check_circle_rounded,
                                    size: 20,
                                    color: theme.colorScheme.primary,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSegmentedControl<T>({
    required BuildContext context,
    required T selectedValue,
    required List<Map<String, dynamic>> options,
    required ValueChanged<T> onSelected,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AsmitaPalette.surfaceDark : const Color(0xFFF1F3F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: options.map((opt) {
          final val = opt['value'] as T;
          final label = opt['label'] as String;
          final icon = opt['icon'] as IconData?;
          final isSelected = val == selectedValue;

          return Expanded(
            child: GestureDetector(
              onTap: () => onSelected(val),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark ? theme.colorScheme.primary : theme.colorScheme.surface)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(
                        icon,
                        size: 14,
                        color: isSelected
                            ? (isDark ? Colors.white : theme.colorScheme.primary)
                            : theme.textTheme.bodyMedium?.color,
                      ),
                      const SizedBox(width: 4),
                    ],
                    Flexible(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 11.5,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? (isDark ? Colors.white : theme.colorScheme.primary)
                              : theme.textTheme.bodyMedium?.color,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildVehicleSwitchTile({
    required BuildContext context,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: value
            ? theme.colorScheme.primary.withValues(alpha: 0.05)
            : (isDark ? AsmitaPalette.surfaceDark : theme.colorScheme.surface),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value
              ? theme.colorScheme.primary
              : theme.dividerColor.withValues(alpha: 0.7),
          width: value ? 1.4 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: value
                  ? theme.colorScheme.primary.withValues(alpha: 0.15)
                  : theme.dividerColor.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.directions_car_rounded,
              size: 18,
              color: value ? theme.colorScheme.primary : theme.textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Only Visitors with Vehicle',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: value ? theme.colorScheme.primary : theme.textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Filter records with registered vehicle plate',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeTrackColor: theme.colorScheme.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  void _showFilterModal() {
    String? tempStatus = _selectedStatus;
    DateTime? tempStartDate = _startDate;
    DateTime? tempEndDate = _endDate;
    String tempDatePreset = _datePreset;
    String tempRecordType = _selectedRecordType;
    String tempCategory = _selectedCategory;
    String tempFrequency = _selectedFrequency;
    bool tempOnlyWithVehicle = _onlyWithVehicle;
    String tempSortOrder = _sortOrder;

    showAsmitaBottomSheet(
      context: context,
      customHeader: StatefulBuilder(
        builder: (context, setModalHeaderState) {
          int count = 0;
          if (tempStatus != null && tempStatus != 'ALL') count++;
          if (tempDatePreset != 'ALL' || tempStartDate != null || tempEndDate != null) count++;
          if (tempRecordType != 'ALL') count++;
          if (tempCategory != 'ALL') count++;
          if (tempFrequency != 'ALL') count++;
          if (tempOnlyWithVehicle) count++;
          if (tempSortOrder != 'NEWEST') count++;

          return Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.tune_rounded,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Filter History',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    Text(
                      count > 0 ? '$count filters selected' : 'Narrow down visitor records',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11.5,
                        color: count > 0
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).textTheme.bodySmall?.color,
                        fontWeight: count > 0 ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              if (count > 0)
                TextButton.icon(
                  onPressed: () {
                    setModalHeaderState(() {
                      tempStatus = null;
                      tempStartDate = null;
                      tempEndDate = null;
                      tempDatePreset = 'ALL';
                      tempRecordType = 'ALL';
                      tempCategory = 'ALL';
                      tempFrequency = 'ALL';
                      tempOnlyWithVehicle = false;
                      tempSortOrder = 'NEWEST';
                    });
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 14),
                  label: const Text('Reset'),
                  style: TextButton.styleFrom(
                    foregroundColor: AsmitaPalette.actionRed,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
            ],
          );
        },
      ),
      child: StatefulBuilder(
        builder: (context, setModalState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          int modalActiveCount = 0;
          if (tempStatus != null && tempStatus != 'ALL') modalActiveCount++;
          if (tempDatePreset != 'ALL' || tempStartDate != null || tempEndDate != null) modalActiveCount++;
          if (tempRecordType != 'ALL') modalActiveCount++;
          if (tempCategory != 'ALL') modalActiveCount++;
          if (tempFrequency != 'ALL') modalActiveCount++;
          if (tempOnlyWithVehicle) modalActiveCount++;
          if (tempSortOrder != 'NEWEST') modalActiveCount++;

          final statusOptions = [
            {'key': 'ALL', 'label': 'All', 'icon': Icons.tune_rounded, 'color': isDark ? const Color(0xFF60A5FA) : AsmitaPalette.deepNavy},
            {'key': 'PENDING', 'label': 'Pending', 'icon': Icons.schedule_rounded, 'color': AsmitaPalette.amberWarning},
            {'key': 'APPROVED', 'label': 'Approved', 'icon': Icons.check_circle_outline_rounded, 'color': AsmitaPalette.successGreen},
            {'key': 'CHECKED_IN', 'label': 'Inside HQ', 'icon': Icons.login_rounded, 'color': const Color(0xFF0D9488)},
            {'key': 'CHECKED_OUT', 'label': 'Checked Out', 'icon': Icons.logout_rounded, 'color': const Color(0xFF64748B)},
            {'key': 'REJECTED', 'label': 'Rejected', 'icon': Icons.cancel_outlined, 'color': AsmitaPalette.actionRed},
          ];

          final categoryOptions = [
            {'key': 'ALL', 'label': 'All Categories', 'icon': Icons.grid_view_rounded},
            {'key': 'Guest', 'label': 'Guest / VIP', 'icon': Icons.person_outline_rounded},
            {'key': 'Delivery', 'label': 'Delivery', 'icon': Icons.local_shipping_outlined},
            {'key': 'Cab', 'label': 'Cab / Taxi', 'icon': Icons.local_taxi_outlined},
            {'key': 'Service', 'label': 'Service / Vendor', 'icon': Icons.build_outlined},
          ];

          final frequencyOptions = [
            {'key': 'ALL', 'label': 'All Validities'},
            {'key': 'ONCE', 'label': 'Single Entry (Once)'},
            {'key': 'FREQUENT', 'label': 'Frequent / Recurring'},
          ];

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Date Range Section (Segmented Presets + Explicit From/To Inputs)
                      _buildFilterSectionHeader(
                        context: context,
                        title: 'Date Range',
                        icon: Icons.calendar_today_rounded,
                      ),
                      _buildSegmentedControl<String>(
                        context: context,
                        selectedValue: tempDatePreset,
                        options: [
                          {'value': 'ALL', 'label': 'All Time'},
                          {'value': 'TODAY', 'label': 'Today'},
                          {'value': 'THIS_WEEK', 'label': 'This Week'},
                          {'value': 'THIS_MONTH', 'label': 'This Month'},
                        ],
                        onSelected: (val) {
                          setModalState(() {
                            tempDatePreset = val;
                            _applyDatePreset(tempDatePreset, (s, e) {
                              tempStartDate = s;
                              tempEndDate = e;
                            });
                          });
                        },
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _buildDateInputCard(
                            context: context,
                            label: 'From Date',
                            value: tempStartDate,
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: tempStartDate ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (picked != null) {
                                setModalState(() {
                                  tempStartDate = picked;
                                  tempDatePreset = 'CUSTOM';
                                });
                              }
                            },
                            onClear: tempStartDate != null
                                ? () => setModalState(() {
                                      tempStartDate = null;
                                      tempDatePreset = 'CUSTOM';
                                    })
                                : null,
                          ),
                          const SizedBox(width: 12),
                          _buildDateInputCard(
                            context: context,
                            label: 'To Date',
                            value: tempEndDate,
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: tempEndDate ?? tempStartDate ?? DateTime.now(),
                                firstDate: tempStartDate ?? DateTime(2020),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (picked != null) {
                                setModalState(() {
                                  tempEndDate = picked;
                                  tempDatePreset = 'CUSTOM';
                                });
                              }
                            },
                            onClear: tempEndDate != null
                                ? () => setModalState(() {
                                      tempEndDate = null;
                                      tempDatePreset = 'CUSTOM';
                                    })
                                : null,
                          ),
                        ],
                      ),

                      // 2. Pass Type Section (Segmented Control)
                      _buildFilterSectionHeader(
                        context: context,
                        title: 'Pass Type',
                        icon: Icons.badge_outlined,
                      ),
                      _buildSegmentedControl<String>(
                        context: context,
                        selectedValue: tempRecordType,
                        options: [
                          {'value': 'ALL', 'label': 'All Passes', 'icon': Icons.all_inbox_rounded},
                          {'value': 'PRE_APPROVED', 'label': 'Pre-Approved', 'icon': Icons.verified_user_outlined},
                          {'value': 'WALK_IN', 'label': 'Walk-ins', 'icon': Icons.directions_walk_rounded},
                        ],
                        onSelected: (val) => setModalState(() => tempRecordType = val),
                      ),

                      // 3. Visitor Status Section (Native Mobile Modal Picker)
                      _buildFilterSectionHeader(
                        context: context,
                        title: 'Visitor Status',
                        icon: Icons.verified_outlined,
                      ),
                      Builder(
                        builder: (ctx) {
                          final currentKey = tempStatus ?? 'ALL';
                          final selected = statusOptions.firstWhere(
                            (o) => o['key'] == currentKey,
                            orElse: () => statusOptions.first,
                          );
                          final isCustomized = tempStatus != null && tempStatus != 'ALL';

                          return _buildFilterPickerTile(
                            context: context,
                            selectedLabel: selected['label'] as String,
                            selectedIcon: selected['icon'] as IconData,
                            iconColor: selected['color'] as Color,
                            isCustomized: isCustomized,
                            onTap: () {
                              _showNativeModalPicker<String>(
                                context: context,
                                title: 'Select Visitor Status',
                                selectedValue: currentKey,
                                items: statusOptions.map((st) => {
                                  'value': st['key'] as String,
                                  'label': st['label'] as String,
                                  'icon': st['icon'] as IconData,
                                  'color': st['color'] as Color,
                                }).toList(),
                                onSelected: (val) {
                                  setModalState(() {
                                    tempStatus = val == 'ALL' ? null : val;
                                  });
                                },
                              );
                            },
                          );
                        },
                      ),

                      // 4. Visitor Category Section (Native Mobile Modal Picker)
                      _buildFilterSectionHeader(
                        context: context,
                        title: 'Category',
                        icon: Icons.category_outlined,
                      ),
                      Builder(
                        builder: (ctx) {
                          final selected = categoryOptions.firstWhere(
                            (o) => o['key'] == tempCategory,
                            orElse: () => categoryOptions.first,
                          );
                          final isCustomized = tempCategory != 'ALL';

                          return _buildFilterPickerTile(
                            context: context,
                            selectedLabel: selected['label'] as String,
                            selectedIcon: selected['icon'] as IconData,
                            iconColor: Theme.of(context).colorScheme.primary,
                            isCustomized: isCustomized,
                            onTap: () {
                              _showNativeModalPicker<String>(
                                context: context,
                                title: 'Select Category',
                                selectedValue: tempCategory,
                                items: categoryOptions.map((opt) => {
                                  'value': opt['key'] as String,
                                  'label': opt['label'] as String,
                                  'icon': opt['icon'] as IconData,
                                  'color': Theme.of(context).colorScheme.primary,
                                }).toList(),
                                onSelected: (val) {
                                  setModalState(() {
                                    tempCategory = val;
                                  });
                                },
                              );
                            },
                          );
                        },
                      ),

                      // 5. Pass Validity Section (Native Mobile Modal Picker)
                      _buildFilterSectionHeader(
                        context: context,
                        title: 'Pass Validity',
                        icon: Icons.repeat_rounded,
                      ),
                      Builder(
                        builder: (ctx) {
                          final selected = frequencyOptions.firstWhere(
                            (o) => o['key'] == tempFrequency,
                            orElse: () => frequencyOptions.first,
                          );
                          final isCustomized = tempFrequency != 'ALL';

                          return _buildFilterPickerTile(
                            context: context,
                            selectedLabel: selected['label']!,
                            selectedIcon: Icons.repeat_rounded,
                            iconColor: Theme.of(context).colorScheme.primary,
                            isCustomized: isCustomized,
                            onTap: () {
                              _showNativeModalPicker<String>(
                                context: context,
                                title: 'Select Pass Validity',
                                selectedValue: tempFrequency,
                                items: frequencyOptions.map((opt) => {
                                  'value': opt['key'] as String,
                                  'label': opt['label']!,
                                  'icon': Icons.repeat_rounded,
                                  'color': Theme.of(context).colorScheme.primary,
                                }).toList(),
                                onSelected: (val) {
                                  setModalState(() {
                                    tempFrequency = val;
                                  });
                                },
                              );
                            },
                          );
                        },
                      ),

                      // 6. Vehicle Section (Toggle Switch Card)
                      _buildFilterSectionHeader(
                        context: context,
                        title: 'Vehicle',
                        icon: Icons.directions_car_outlined,
                      ),
                      _buildVehicleSwitchTile(
                        context: context,
                        value: tempOnlyWithVehicle,
                        onChanged: (val) => setModalState(() => tempOnlyWithVehicle = val),
                      ),

                      // 7. Sort By Section (Segmented Control)
                      _buildFilterSectionHeader(
                        context: context,
                        title: 'Sort By',
                        icon: Icons.sort_rounded,
                      ),
                      _buildSegmentedControl<String>(
                        context: context,
                        selectedValue: tempSortOrder,
                        options: [
                          {'value': 'NEWEST', 'label': 'Newest First', 'icon': Icons.arrow_downward_rounded},
                          {'value': 'OLDEST', 'label': 'Oldest First', 'icon': Icons.arrow_upward_rounded},
                        ],
                        onSelected: (val) => setModalState(() => tempSortOrder = val),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Action Buttons (Reset All & Apply Filters)
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _selectedStatus = null;
                          _startDate = null;
                          _endDate = null;
                          _datePreset = 'ALL';
                          _selectedRecordType = 'ALL';
                          _selectedCategory = 'ALL';
                          _selectedFrequency = 'ALL';
                          _onlyWithVehicle = false;
                          _sortOrder = 'NEWEST';
                        });
                        Navigator.pop(context);
                        _loadHistory();
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Theme.of(context).dividerColor),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Clear',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _selectedStatus = tempStatus;
                          _startDate = tempStartDate;
                          _endDate = tempEndDate;
                          _datePreset = tempDatePreset;
                          _selectedRecordType = tempRecordType;
                          _selectedCategory = tempCategory;
                          _selectedFrequency = tempFrequency;
                          _onlyWithVehicle = tempOnlyWithVehicle;
                          _sortOrder = tempSortOrder;
                        });
                        Navigator.pop(context);
                        _loadHistory();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 1,
                      ),
                      child: Text(
                        modalActiveCount > 0
                            ? 'Apply Filters ($modalActiveCount)'
                            : 'Apply Filters',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          color: Theme.of(context).colorScheme.surface,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildActiveFiltersBar(BuildContext context) {
    if (_activeFilterCount == 0) return const SizedBox.shrink();

    final chips = <Widget>[];

    // Status chip
    if (_selectedStatus != null && _selectedStatus != 'ALL') {
      final label = _selectedStatus == 'CHECKED_IN'
          ? 'Inside HQ'
          : (_selectedStatus == 'CHECKED_OUT'
              ? 'Checked Out'
              : _selectedStatus![0] + _selectedStatus!.substring(1).toLowerCase());
      chips.add(_buildActiveFilterChip(
        label: 'Status: $label',
        icon: Icons.verified_outlined,
        onRemove: () {
          setState(() => _selectedStatus = null);
          _loadHistory();
        },
      ));
    }

    // Date chip
    if (_datePreset != 'ALL' || _startDate != null || _endDate != null) {
      String dateLabel = _datePreset;
      if (_datePreset == 'TODAY') {
        dateLabel = 'Today';
      } else if (_datePreset == 'YESTERDAY') {
        dateLabel = 'Yesterday';
      } else if (_datePreset == 'THIS_WEEK') {
        dateLabel = 'This Week';
      } else if (_datePreset == 'THIS_MONTH') {
        dateLabel = 'This Month';
      } else if (_startDate != null && _endDate != null) {
        dateLabel = '${DateFormat('dd/MM').format(_startDate!)} - ${DateFormat('dd/MM').format(_endDate!)}';
      } else if (_startDate != null) {
        dateLabel = 'From ${DateFormat('dd/MM').format(_startDate!)}';
      } else {
        dateLabel = 'Custom Date';
      }

      chips.add(_buildActiveFilterChip(
        label: dateLabel,
        icon: Icons.calendar_today_rounded,
        onRemove: () {
          setState(() {
            _datePreset = 'ALL';
            _startDate = null;
            _endDate = null;
          });
          _loadHistory();
        },
      ));
    }

    // Pass Type chip
    if (_selectedRecordType != 'ALL') {
      chips.add(_buildActiveFilterChip(
        label: _selectedRecordType == 'PRE_APPROVED' ? 'Pre-Approved' : 'Walk-in',
        icon: Icons.badge_outlined,
        onRemove: () => setState(() => _selectedRecordType = 'ALL'),
      ));
    }

    // Category chip
    if (_selectedCategory != 'ALL') {
      chips.add(_buildActiveFilterChip(
        label: 'Category: $_selectedCategory',
        icon: Icons.category_outlined,
        onRemove: () => setState(() => _selectedCategory = 'ALL'),
      ));
    }

    // Frequency chip
    if (_selectedFrequency != 'ALL') {
      chips.add(_buildActiveFilterChip(
        label: _selectedFrequency == 'FREQUENT' ? 'Frequent' : 'Single Entry',
        icon: Icons.repeat_rounded,
        onRemove: () => setState(() => _selectedFrequency = 'ALL'),
      ));
    }

    // Vehicle chip
    if (_onlyWithVehicle) {
      chips.add(_buildActiveFilterChip(
        label: 'With Vehicle',
        icon: Icons.directions_car_rounded,
        onRemove: () => setState(() => _onlyWithVehicle = false),
      ));
    }

    // Sort chip
    if (_sortOrder != 'NEWEST') {
      chips.add(_buildActiveFilterChip(
        label: 'Oldest First',
        icon: Icons.arrow_upward_rounded,
        onRemove: () => setState(() => _sortOrder = 'NEWEST'),
      ));
    }

    // Clear All chip
    chips.add(
      InkWell(
        onTap: _clearAllFilters,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AsmitaPalette.actionRed.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AsmitaPalette.actionRed.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.clear_all_rounded, size: 14, color: AsmitaPalette.actionRed),
              SizedBox(width: 4),
              Text(
                'Clear All',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AsmitaPalette.actionRed,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return Container(
      height: 34,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: chips.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, index) => chips[index],
      ),
    );
  }

  Widget _buildActiveFilterChip({
    required String label,
    required VoidCallback onRemove,
    IconData? icon,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.only(left: 10, right: 6, top: 4, bottom: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: theme.colorScheme.primary),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.all(2.0),
              child: Icon(
                Icons.close_rounded,
                size: 13,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    bool isStaff = false;
    if (authState is AuthAuthenticated) {
      final user = authState.user;
      final rawRole = authState.sessionRole.isNotEmpty == true
          ? authState.sessionRole
          : (user.systemRole?.isNotEmpty == true
              ? user.systemRole
              : user.primaryRole);
      final role = PropertyRoleResolver.normalizeRole(
        rawRole,
        scope: user.roleScope,
        power: user.rolePower,
        isIndustrial: true,
      );
      isStaff = role == 'receptionist' || role == 'guard';
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // Aligned Unified Header Structure matches Dashboard Layouts seamlessly
          AsmitaPrimaryHeader(
            subtitleOverride: 'Visitor History',
            allowPropertySwitching: false,
            showBackButton: widget.onBack != null || Navigator.canPop(context),
            onBackPressed: widget.onBack,
          ),

          Expanded(
            child: BlocBuilder<VisitorBloc, VisitorState>(
              builder: (context, state) {
                if (state is VisitorLoading) {
                  return AsmitaSkeleton(
                    isLoading: true,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 200),
                      itemCount: 4,
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        return AsmitaSkeleton.visitorCard(
                          showActions: false,
                          margin: const EdgeInsets.only(bottom: 12),
                        );
                      },
                    ),
                  );
                }

                if (state is VisitorError) {
                  final isPermissionError = state.message.toLowerCase().contains('permission') || state.message.toLowerCase().contains('denied');
                  
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          state.message,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        AppButton(
                          onPressed: () {
                            if (isPermissionError) {
                              String requestTarget = 'tenant to share logs';
                              if (authState is AuthAuthenticated && authState.sessionRole == 'tenant') {
                                requestTarget = 'owner/admin for access';
                              }
                              AsmitaToast.show(context, message: 'Access request sent to $requestTarget.', type: AsmitaToastType.success);
                            } else {
                              _loadHistory(isRefresh: true);
                            }
                          },
                          icon: isPermissionError ? Icons.lock_open_rounded : Icons.refresh,
                          label: isPermissionError ? 'Request Access' : 'Retry',
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Theme.of(context).colorScheme.surface,
                          borderRadius: 12,
                        ),
                      ],
                    ),
                  );
                }

                final rawHistory = state is VisitorHistoryLoaded
                    ? state.history
                    : <VisitorHistoryItem>[];
                final historyList = _applyClientFilters(rawHistory);
                final filteredCount = historyList.length;

                return CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
                    AppRefresh.sliver(
                      onRefresh: () async {
                        final bloc = context.read<VisitorBloc>();
                        final future = bloc.stream
                            .firstWhere((s) => s is! VisitorLoading)
                            .timeout(const Duration(seconds: 4), onTimeout: () => bloc.state);
                        _loadHistory(isRefresh: true);
                        await future;
                      },
                    ),
                    SliverToBoxAdapter(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      _activeFilterCount > 0 ? 'Filtered Visitors' : 'All Visitors',
                                      style: TextStyle(
                                        fontFamily: 'Montserrat',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '$filteredCount',
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                InkWell(
                                  onTap: _showFilterModal,
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 7,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primary,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.25),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.tune_rounded,
                                          size: 15,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          _activeFilterCount > 0
                                              ? 'Filter ($_activeFilterCount)'
                                              : 'Filter',
                                          style: const TextStyle(
                                            fontFamily: 'Montserrat',
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _buildActiveFiltersBar(context),
                        ],
                      ),
                    ),
                    if (historyList.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 44, 24, 24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.filter_alt_off_rounded,
                                  size: 36,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                _activeFilterCount > 0
                                    ? 'No visitors match your selected filters'
                                    : 'No visitor history found',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              if (_activeFilterCount > 0) ...[
                                const SizedBox(height: 6),
                                Text(
                                  'Try adjusting or resetting your filter criteria.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 12,
                                    color: Theme.of(context).textTheme.bodyMedium?.color,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                ElevatedButton.icon(
                                  onPressed: _clearAllFilters,
                                  icon: const Icon(Icons.refresh_rounded, size: 16),
                                  label: const Text('Reset All Filters'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(context).colorScheme.primary,
                                    foregroundColor: Theme.of(context).colorScheme.surface,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.only(left: 16, right: 16, top: 4, bottom: 200),
                        sliver: SliverList.separated(
                          itemCount: historyList.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            return _buildVisitorHistoryCard(
                              context,
                              historyList[index],
                            );
                          },
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(
          bottom: AsmitaBottomNavBar.fabBottomPadding(context),
        ),
        child: FloatingActionButton.extended(
          heroTag: null, // Fixes Hero overlay bug in IndexedStack
          onPressed: () async {
            await AsmitaPreApproveWizard.showAsModalSheet(
              context,
              isGuardMode: isStaff,
              title: isStaff ? 'New Walk-in Visitor' : 'Pre-Approve Entry',
              subtitle: isStaff ? 'Record lobby guest entry details' : null,
            );
            if (!context.mounted) return;
            _loadHistory(isRefresh: true);
          },
          backgroundColor: Theme.of(context).colorScheme.primary,
          icon: Icon(
            isStaff ? Icons.person_add_rounded : Icons.add,
            color: Theme.of(context).colorScheme.surface,
          ),
          label: Text(
            isStaff ? 'New Walk-in' : 'Add Visitor',
            style: TextStyle(
              color: Theme.of(context).colorScheme.surface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVisitorHistoryCard(BuildContext context, VisitorHistoryItem historyItem) {
    final visit = historyItem.toIndustrialVisit();
    return AsmitaVisitorCard.fromIndustrialVisit(
      visit: visit,
      context: context,
      showSubtitle: false,
      onTap: () => AsmitaVisitorCard.showVisitDetailsSheet(context, visit),
    );
  }
}
