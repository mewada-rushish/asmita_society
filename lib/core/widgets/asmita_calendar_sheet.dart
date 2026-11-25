import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../constants/design_system.dart';
import 'asmita_bottom_sheet.dart';

Future<DateTime?> showAsmitaCalendarSheet({
  required BuildContext context,
  required DateTime initialDate,
  DateTime? firstDate,
  DateTime? lastDate,
  String title = 'Select Date',
  String? subtitle,
}) {
  return showAsmitaBottomSheet<DateTime>(
    context: context,
    title: title,
    subtitle: subtitle,
    child: _AsmitaCalendarBody(
      initialDate: initialDate,
      firstDate: firstDate ?? DateTime.now().subtract(const Duration(days: 365)),
      lastDate: lastDate ?? DateTime.now(),
    ),
  );
}

class _AsmitaCalendarBody extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;

  const _AsmitaCalendarBody({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
  });

  @override
  State<_AsmitaCalendarBody> createState() => _AsmitaCalendarBodyState();
}

class _AsmitaCalendarBodyState extends State<_AsmitaCalendarBody> {
  late DateTime _displayedMonth;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime(widget.initialDate.year, widget.initialDate.month, widget.initialDate.day);
    _displayedMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
  }

  DateTime get _firstOnly => DateTime(widget.firstDate.year, widget.firstDate.month, widget.firstDate.day);
  DateTime get _lastOnly => DateTime(widget.lastDate.year, widget.lastDate.month, widget.lastDate.day);

  bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  bool _isDisabled(DateTime day) => day.isBefore(_firstOnly) || day.isAfter(_lastOnly);

  bool get _canGoPrevMonth {
    final prev = DateTime(_displayedMonth.year, _displayedMonth.month - 1, 1);
    final lastDayOfPrev = DateTime(prev.year, prev.month + 1, 0);
    return !lastDayOfPrev.isBefore(_firstOnly);
  }

  bool get _canGoNextMonth {
    final next = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 1);
    return !next.isAfter(_lastOnly);
  }

  void _selectAndClose(DateTime day) {
    if (_isDisabled(day)) return;
    HapticFeedback.selectionClick();
    Navigator.of(context).pop(day);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final yesterdayOnly = todayOnly.subtract(const Duration(days: 1));
    final weekAgoOnly = todayOnly.subtract(const Duration(days: 7));

    final daysInMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 0).day;
    final firstWeekdayOffset = _displayedMonth.weekday - 1; // Monday = 0 .. Sunday = 6
    final totalCells = ((firstWeekdayOffset + daysInMonth + 6) ~/ 7) * 7;

    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Quick Jump Chips
          Row(
            children: [
              _quickChip('Today', todayOnly),
              const SizedBox(width: 8),
              _quickChip('Yesterday', yesterdayOnly),
              const SizedBox(width: 8),
              _quickChip('7 Days Ago', weekAgoOnly),
            ],
          ),
          const SizedBox(height: 14),

          // Month Navigation Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? AsmitaPalette.surfaceDark : AsmitaPalette.systemBG,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AsmitaPalette.border(context)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: _canGoPrevMonth
                      ? () => setState(() => _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month - 1, 1))
                      : null,
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                Text(
                  DateFormat('MMMM yyyy').format(_displayedMonth),
                  style: GoogleFonts.poppins(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: AsmitaPalette.textPrimary(context),
                  ),
                ),
                IconButton(
                  onPressed: _canGoNextMonth
                      ? () => setState(() => _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 1))
                      : null,
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Weekday Headers
          Row(
            children: const ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su']
                .map(
                  (d) => Expanded(
                    child: Center(
                      child: Text(
                        d,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),

          // Calendar Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: totalCells,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
            ),
            itemBuilder: (_, index) {
              final dayNum = index - firstWeekdayOffset + 1;
              if (dayNum < 1 || dayNum > daysInMonth) {
                return const SizedBox.shrink();
              }
              final day = DateTime(_displayedMonth.year, _displayedMonth.month, dayNum);
              final disabled = _isDisabled(day);
              final selected = _isSameDay(day, _selectedDate);
              final isToday = _isSameDay(day, todayOnly);

              return InkWell(
                onTap: disabled ? null : () => _selectAndClose(day),
                borderRadius: BorderRadius.circular(11),
                child: Container(
                  decoration: BoxDecoration(
                    color: selected
                        ? (isDark ? AsmitaPalette.deepNavyDark : AsmitaPalette.deepNavy)
                        : (isToday ? AsmitaPalette.subtleAccent(context) : Colors.transparent),
                    borderRadius: BorderRadius.circular(11),
                    border: isToday && !selected
                        ? Border.all(color: AsmitaPalette.primary(context), width: 1.3)
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$dayNum',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: selected || isToday ? FontWeight.w700 : FontWeight.w500,
                      color: selected
                          ? Colors.white
                          : disabled
                              ? AsmitaPalette.textTertiary(context).withValues(alpha: 0.45)
                              : AsmitaPalette.textPrimary(context),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _quickChip(String label, DateTime target) {
    final active = _isSameDay(target, _selectedDate);
    final disabled = _isDisabled(target);
    return Expanded(
      child: InkWell(
        onTap: disabled ? null : () => _selectAndClose(target),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active ? AsmitaPalette.deepNavy : AsmitaPalette.surface(context),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: active ? AsmitaPalette.deepNavy : AsmitaPalette.border(context)),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: active ? Colors.white : AsmitaPalette.textPrimary(context),
            ),
          ),
        ),
      ),
    );
  }
}
