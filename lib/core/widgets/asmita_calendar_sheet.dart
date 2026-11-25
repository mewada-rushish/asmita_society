import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../constants/design_system.dart';
import 'asmita_bottom_sheet.dart';

Future<DateTimeRange?> showAsmitaCalendarRangeSheet({
  required BuildContext context,
  required DateTimeRange initialRange,
  DateTime? firstDate,
  DateTime? lastDate,
  String title = 'Select Date Range',
  String? subtitle,
}) {
  return showAsmitaBottomSheet<DateTimeRange>(
    context: context,
    title: title,
    subtitle: subtitle,
    child: _AsmitaCalendarRangeBody(
      initialRange: initialRange,
      firstDate: firstDate ?? DateTime.now().subtract(const Duration(days: 365)),
      lastDate: lastDate ?? DateTime.now(),
    ),
  );
}

class _AsmitaCalendarRangeBody extends StatefulWidget {
  final DateTimeRange initialRange;
  final DateTime firstDate;
  final DateTime lastDate;

  const _AsmitaCalendarRangeBody({
    required this.initialRange,
    required this.firstDate,
    required this.lastDate,
  });

  @override
  State<_AsmitaCalendarRangeBody> createState() => _AsmitaCalendarRangeBodyState();
}

class _AsmitaCalendarRangeBodyState extends State<_AsmitaCalendarRangeBody> {
  late DateTime _displayedMonth;
  late DateTime _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _startDate = _dateOnly(widget.initialRange.start);
    _endDate = _dateOnly(widget.initialRange.end);
    _displayedMonth = DateTime(_endDate!.year, _endDate!.month, 1);
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
  DateTime get _firstOnly => _dateOnly(widget.firstDate);
  DateTime get _lastOnly => _dateOnly(widget.lastDate);

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

  void _onDayTap(DateTime day) {
    if (_isDisabled(day)) return;
    HapticFeedback.selectionClick();
    setState(() {
      if (_endDate != null) {
        // Start a fresh range
        _startDate = day;
        _endDate = null;
      } else {
        if (day.isBefore(_startDate)) {
          _endDate = _startDate;
          _startDate = day;
        } else {
          _endDate = day;
        }
      }
    });
  }

  void _applyQuickRange(DateTime start, DateTime end) {
    if (_isDisabled(start) || _isDisabled(end)) return;
    HapticFeedback.selectionClick();
    Navigator.of(context).pop(DateTimeRange(start: start, end: end));
  }

  void _applySelected() {
    final end = _endDate ?? _startDate;
    HapticFeedback.selectionClick();
    Navigator.of(context).pop(DateTimeRange(start: _startDate, end: end));
  }

  String get _rangeSummary {
    final end = _endDate ?? _startDate;
    if (_isSameDay(_startDate, end)) {
      return DateFormat('dd MMM yyyy').format(_startDate);
    }
    return '${DateFormat('dd MMM').format(_startDate)} – ${DateFormat('dd MMM yyyy').format(end)}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final todayOnly = _dateOnly(DateTime.now());
    final yesterdayOnly = todayOnly.subtract(const Duration(days: 1));
    final weekStartOnly = todayOnly.subtract(const Duration(days: 6));

    final daysInMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 0).day;
    final firstWeekdayOffset = _displayedMonth.weekday - 1; // Mo = 0 .. Su = 6
    // Always render 6 weeks (42 cells) so sheet height never changes between months
    const int totalCells = 42;

    final effectiveEnd = _endDate ?? _startDate;

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Quick Jump Range Chips
            Row(
              children: [
                _quickChip('Today', todayOnly, todayOnly),
                const SizedBox(width: 8),
                _quickChip('Yesterday', yesterdayOnly, yesterdayOnly),
                const SizedBox(width: 8),
                _quickChip('Last 7 Days', weekStartOnly, todayOnly),
              ],
            ),
            const SizedBox(height: 12),

            // Non-white Navy Month Navigation Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E3A8A) : AsmitaPalette.deepNavy,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: _canGoPrevMonth
                        ? () => setState(() => _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month - 1, 1))
                        : null,
                    icon: Icon(
                      Icons.chevron_left_rounded,
                      color: _canGoPrevMonth ? Colors.white : Colors.white38,
                    ),
                  ),
                  Text(
                    DateFormat('MMMM yyyy').format(_displayedMonth),
                    style: GoogleFonts.poppins(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    onPressed: _canGoNextMonth
                        ? () => setState(() => _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 1))
                        : null,
                    icon: Icon(
                      Icons.chevron_right_rounded,
                      color: _canGoNextMonth ? Colors.white : Colors.white38,
                    ),
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

            // Fixed 6-row (42-cell) Calendar Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: totalCells,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
                childAspectRatio: 1.18,
              ),
              itemBuilder: (_, index) {
                final dayNum = index - firstWeekdayOffset + 1;
                if (dayNum < 1 || dayNum > daysInMonth) {
                  return const SizedBox.shrink();
                }
                final day = DateTime(_displayedMonth.year, _displayedMonth.month, dayNum);
                final disabled = _isDisabled(day);
                final isStart = _isSameDay(day, _startDate);
                final isEnd = _isSameDay(day, effectiveEnd);
                final isEndpoint = isStart || isEnd;
                final inRange = !isEndpoint && day.isAfter(_startDate) && day.isBefore(effectiveEnd);
                final isToday = _isSameDay(day, todayOnly);

                return InkWell(
                  onTap: disabled ? null : () => _onDayTap(day),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isEndpoint
                          ? (isDark ? AsmitaPalette.deepNavyDark : AsmitaPalette.deepNavy)
                          : inRange
                              ? AsmitaPalette.subtleAccent(context)
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: isToday && !isEndpoint
                          ? Border.all(color: AsmitaPalette.primary(context), width: 1.3)
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$dayNum',
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: isEndpoint || isToday || inRange ? FontWeight.w700 : FontWeight.w500,
                        color: isEndpoint
                            ? Colors.white
                            : inRange
                                ? AsmitaPalette.primary(context)
                                : disabled
                                    ? AsmitaPalette.textTertiary(context).withValues(alpha: 0.4)
                                    : AsmitaPalette.textPrimary(context),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),

            // Selected Range Summary & Apply Button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? AsmitaPalette.surfaceDark : AsmitaPalette.systemBG,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AsmitaPalette.border(context)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _endDate == null ? 'Tap end date (or Apply single day)' : 'Selected Range',
                          style: GoogleFonts.poppins(fontSize: 10.5, fontWeight: FontWeight.w500, color: AsmitaPalette.textSecondary(context)),
                        ),
                        Text(
                          _rangeSummary,
                          style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: AsmitaPalette.textPrimary(context)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _applySelected,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AsmitaPalette.deepNavy,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text('Apply', style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }

  Widget _quickChip(String label, DateTime start, DateTime end) {
    final active = _isSameDay(start, _startDate) && _endDate != null && _isSameDay(end, _endDate!);
    final disabled = _isDisabled(start) || _isDisabled(end);
    return Expanded(
      child: InkWell(
        onTap: disabled ? null : () => _applyQuickRange(start, end),
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
