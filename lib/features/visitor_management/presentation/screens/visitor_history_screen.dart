import 'package:asmita_society/core/utils/date_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:asmita_society/core/constants/design_system.dart';
import 'package:asmita_society/core/widgets/asmita_loading_indicator.dart';
import 'package:asmita_society/core/widgets/asmita_primary_header.dart';
import 'package:asmita_society/core/widgets/asmita_bottom_sheet.dart';
import 'package:asmita_society/core/widgets/asmita_animated_refresh.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/visitor_bloc.dart';
import '../../bloc/visitor_event.dart';
import '../../bloc/visitor_state.dart';
import '../../../../features/auth/bloc/auth_bloc.dart';
import '../../../../features/auth/bloc/auth_state.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:asmita_society/core/widgets/asmita_dialog.dart';
import '../../../dashboard/widgets/asmita_pre_approve_wizard.dart';
import 'package:asmita_society/core/widgets/asmita_toast.dart';
import '../../data/models/invite_model.dart';
import 'invite_pass_screen.dart';

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
        status: _selectedStatus,
        startDate: _startDate,
        endDate: _endDate,
      ),
    );
  }

  String _formatTime(String? dateStr, String? timeStr) {
    if (dateStr == null && timeStr == null) return '--:--';
    try {
      DateTime dt;
      if (dateStr != null && timeStr == null) {
        dt = DateTime.parse(dateStr).toLocal();
      } else if (dateStr != null && timeStr != null) {
        dt = DateTime.parse('${dateStr.split('T')[0]}T$timeStr').toLocal();
      } else {
        return timeStr ?? '--:--';
      }
      return DateFormat('hh:mm a').format(dt);
    } catch (_) {
      return '--:--';
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      final now = DateTime.now();
      if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
        return 'Today';
      }
      return AppDateFormatter.formatDate(dt);
    } catch (_) {
      return dateStr.split('T')[0];
    }
  }

  Map<String, dynamic> _normalizeItem(dynamic rawItem, String currentUserName) {
    final item = rawItem is Map
        ? Map<String, dynamic>.from(rawItem)
        : <String, dynamic>{};
    final isPreApproved = item['record_type'] == 'PRE_APPROVED';

    final name = (item['visitor_name'] != null && item['visitor_name'].toString().trim().isNotEmpty)
        ? item['visitor_name'].toString().trim()
        : (item['title'] ?? (isPreApproved ? 'VIP Guest' : 'Unknown'));
    final company = item['company_name'] ?? item['purpose'] ?? 'Visitor';
    final category = isPreApproved
        ? (item['invite_type'] ?? 'Invite')
        : (item['visitor_type_name'] ?? 'Walk-in');

    final entryTimeStr = item['checkin_at'] ?? item['start_time'];
    final exitTimeStr = item['checkout_at'] ?? item['end_time'];
    final dateStr = item['created_at'] ?? item['valid_from'];

    final entryTime = _formatTime(dateStr, entryTimeStr);
    final exitTime = _formatTime(dateStr, exitTimeStr);
    final date = _formatDate(dateStr);

    String status = item['status'] ?? 'Pending';
    final gate = isPreApproved ? 'Pre-Approved' : 'Main Gate';

    String? validToRaw = item['valid_to'];
    if (validToRaw != null &&
        item['invite_sub_type']?.toString().toUpperCase() == 'FREQUENT') {
      DateTime? validToDate = DateTime.tryParse(validToRaw.toString());
      if (validToDate != null) {
        DateTime now = DateTime.now();
        DateTime today = DateTime(now.year, now.month, now.day);
        DateTime expiry = DateTime(
          validToDate.year,
          validToDate.month,
          validToDate.day,
        );
        if (today.isAfter(expiry)) {
          status = 'Expired';
        }
      }
    }

    bool isOutsideSchedule = false;
    String? allowedDays = item['allowed_days'];
    String? startTime = item['start_time'];
    String? endTime = item['end_time'];
    if (allowedDays != null &&
        startTime != null &&
        endTime != null &&
        item['created_at'] != null) {
      DateTime entryDateTime =
          DateTime.tryParse(item['created_at'].toString()) ?? DateTime.now();
      String dayOfWeek = DateFormat('E').format(entryDateTime); // e.g., 'Mon'
      bool validDay = allowedDays.contains(dayOfWeek);

      final sParts = startTime.split(':');
      final eParts = endTime.split(':');
      bool validTime = true;
      if (sParts.length >= 2 && eParts.length >= 2) {
        int sHour = int.tryParse(sParts[0]) ?? 0;
        int sMin = int.tryParse(sParts[1]) ?? 0;
        int eHour = int.tryParse(eParts[0]) ?? 23;
        int eMin = int.tryParse(eParts[1]) ?? 59;

        int entryMins = entryDateTime.hour * 60 + entryDateTime.minute;
        int startMins = sHour * 60 + sMin;
        int endMins = eHour * 60 + eMin;

        if (entryMins < startMins || entryMins > endMins) validTime = false;
      }

      if (!validDay || !validTime) {
        isOutsideSchedule = true;
      }
    }

    IconData icon = Icons.person_rounded;
    Color brandColor = Theme.of(context).colorScheme.primary;

    if (category.toString().toLowerCase() == 'delivery') {
      icon = Icons.local_shipping_rounded;
      if (company.toString().toLowerCase().contains('amazon')) {
        brandColor = const Color(0xFFFF9900);
      } else if (company.toString().toLowerCase().contains('zomato')) {
        icon = Icons.fastfood_rounded;
        brandColor = const Color(0xFFCB202D);
      } else if (company.toString().toLowerCase().contains('swiggy')) {
        icon = Icons.fastfood_rounded;
        brandColor = const Color(0xFFFC8019);
      }
    } else if (company.toString().toLowerCase().contains('uber') ||
        category.toString().toLowerCase().contains('cab')) {
      icon = Icons.directions_car_rounded;
      brandColor = Colors.black;
    }

    // Default title is name, but for Cab/Delivery it should be the company/purpose
    String titleText = name;
    if (category.toString().toLowerCase() == 'delivery' ||
        category.toString().toLowerCase() == 'cab') {
      titleText = company;
    } else if (titleText.toLowerCase().contains('invite')) {
      titleText = company.isNotEmpty && company != 'Visitor'
          ? company
          : (isPreApproved ? 'VIP Guest' : titleText);
    }

    String subtitleText = isPreApproved
        ? 'by $currentUserName'
        : 'Entered via $gate';
    String modalSubtitleText = isPreApproved
        ? 'Pre-approved by $currentUserName'
        : 'Entered via $gate';

    return {
      'titleText': titleText,
      'subtitleText': subtitleText,
      'modalSubtitleText': modalSubtitleText,
      'name': name,
      'company': company,
      'category': category,
      'entryTime': entryTime,
      'exitTime': exitTime,
      'duration': 'N/A', // Compute actual duration if needed
      'gate': gate,
      'date': date,
      'status': status,
      'icon': icon,
      'brandColor': brandColor,
      'inviteSubType': item['invite_sub_type']?.toString().toUpperCase(),
      'allowedDays': allowedDays,
      'startTime': startTime,
      'endTime': endTime,
      'validTo': item['valid_to'] != null
          ? _formatDate(item['valid_to'].toString())
          : null,
      'vehicleNumber': item['vehicle_number'],
      'maxGuestCount': item['max_guest_count'],
      'isPrivate': item['is_private'] == true,
      'isOutsideSchedule': isOutsideSchedule,
      'passCode': item['pass_code']?.toString(),
      'qrCode': item['qr_code']?.toString(),
      'isPreApproved': isPreApproved,
      'rawItem': item,
    };
  }

  void _showVisitorDetailsModal(
    BuildContext context,
    Map<String, dynamic> visitor,
  ) {
    final textTheme = Theme.of(context).textTheme;

    showAsmitaBottomSheet(
      context: context,
      customHeader: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Visitor Avatar with High-Assurance Enclosed Border
          Center(
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: visitor['brandColor'] as Color,
                  width: 2,
                ),
              ),
              child: CircleAvatar(
                radius: 36,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                child: Icon(
                  visitor['icon'] as IconData,
                  color: visitor['brandColor'] as Color,
                  size: 32,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header Labels (Montserrat for structural emphasis)
          Center(
            child: Text(
              visitor['titleText'] as String,
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: (visitor['brandColor'] as Color).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                visitor['modalSubtitleText'] as String? ??
                    visitor['subtitleText'] as String,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: visitor['brandColor'] as Color,
                ),
              ),
            ),
          ),
          if (visitor['passCode'] != null && visitor['passCode'].toString().isNotEmpty) ...[
            const SizedBox(height: 8),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
                ),
                child: Text(
                  'PASS CODE: #${visitor['passCode']}',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Data Parameters Section (Poppins for legible data layouts)
            if (visitor['inviteSubType'] != null &&
                visitor['inviteSubType'] != 'ONCE')
              _buildDetailRow(
                textTheme,
                label: 'Frequency',
                value: visitor['inviteSubType'] as String,
              ),
            if (visitor['validTo'] != null &&
                visitor['inviteSubType'] == 'FREQUENT')
              _buildDetailRow(
                textTheme,
                label: 'Allowed Until',
                value: visitor['validTo'] as String,
              ),
            if (visitor['inviteSubType'] == 'FREQUENT' ||
                (visitor['allowedDays'] != null &&
                    visitor['allowedDays'].toString().isNotEmpty)) ...[
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Allowed Days',
                      style: textTheme.bodySmall?.copyWith(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                    _buildDaysIndicator(
                      visitor['allowedDays']?.toString().isNotEmpty == true
                          ? visitor['allowedDays'] as String
                          : 'Mon,Tue,Wed,Thu,Fri,Sat,Sun',
                    ),
                  ],
                ),
              ),
            ],
            if (visitor['startTime'] != null && visitor['endTime'] != null)
              _buildDetailRow(
                textTheme,
                label: 'Time Slot',
                value:
                    '${_formatRawTime(visitor['startTime'])} - ${_formatRawTime(visitor['endTime'])}',
              ),
            if (visitor['vehicleNumber'] != null &&
                visitor['vehicleNumber'].toString().isNotEmpty)
              _buildDetailRow(
                textTheme,
                label: 'Vehicle Number',
                value: visitor['vehicleNumber'] as String,
              ),
            if (visitor['maxGuestCount'] != null &&
                visitor['maxGuestCount'] > 1)
              _buildDetailRow(
                textTheme,
                label: 'Guest Count',
                value: visitor['maxGuestCount'].toString(),
              ),
            if (visitor['isPrivate'] == true)
              _buildDetailRow(
                textTheme,
                label: 'Entry Mode',
                value: 'Surprise / Secret Delivery',
                isHighlight: true,
              ),

            _buildDetailRow(
              textTheme,
              label: 'Gate Access Status',
              value: visitor['status'] as String,
              isStatus: true,
            ),
            _buildDetailRow(
              textTheme,
              label: 'Arrival Date',
              value: visitor['date'] as String,
            ),
            _buildDetailRow(
              textTheme,
              label: 'Entry Boundary Check',
              value: visitor['gate'] as String,
            ),
            _buildDetailRow(
              textTheme,
              label: 'Inbound Timestamp',
              value: visitor['entryTime'] as String,
            ),
            if (visitor['exitTime'] != '--')
              _buildDetailRow(
                textTheme,
                label: 'Outbound Timestamp',
                value: visitor['exitTime'] as String,
              ),

            if (visitor['qrCode'] != null && visitor['qrCode'].toString().isNotEmpty) ...[
              const SizedBox(height: 18),
              Center(
                child: Container(
                  width: 170,
                  height: 170,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: QrImageView(
                    data: visitor['qrCode'].toString(),
                    version: QrVersions.auto,
                    size: 146.0,
                    eyeStyle: QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    dataModuleStyle: QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  final raw = visitor['rawItem'];
                  if (raw is Map) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => InvitePassScreen(
                          invite: PreApprovedInvite.fromJson(
                            Map<String, dynamic>.from(raw),
                          ),
                        ),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.share_rounded, size: 16),
                label: const Text(
                  'View & Share Pass',
                  style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.surface,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    TextTheme textTheme, {
    required String label,
    required String value,
    bool isStatus = false,
    bool isHighlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: textTheme.bodyMedium?.copyWith(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Flex(
                  direction: Axis.horizontal,
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(
                    (constraints.constrainWidth() / 6).floor(),
                    (index) => SizedBox(
                      width: 3,
                      height: 1,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Theme.of(context).dividerColor,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          if (isStatus)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: value.toLowerCase() == 'expired'
                    ? Colors.red.withValues(alpha: 0.1)
                    : (value.toLowerCase().contains('entered') ||
                              value.toLowerCase().contains('exited')
                          ? Colors.green.withValues(alpha: 0.1)
                          : Theme.of(context).scaffoldBackgroundColor),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (value.toLowerCase() != 'expired' &&
                      value.toLowerCase() != 'pending') ...[
                    Icon(
                      Icons.check_circle_outline,
                      size: 14,
                      color: value.toLowerCase().contains('exited')
                          ? Colors.green.shade700
                          : Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    value,
                    style: textTheme.bodySmall?.copyWith(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      color: value.toLowerCase() == 'expired'
                          ? Colors.red
                          : (value.toLowerCase().contains('exited')
                                ? Colors.green.shade700
                                : Theme.of(context).colorScheme.primary),
                    ),
                  ),
                ],
              ),
            )
          else
            Text(
              value,
              style: textTheme.bodyMedium?.copyWith(
                fontFamily: 'Montserrat',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isHighlight
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDaysIndicator(String allowedDays) {
    final days = [
      {'key': 'Mon', 'label': 'M'},
      {'key': 'Tue', 'label': 'T'},
      {'key': 'Wed', 'label': 'W'},
      {'key': 'Thu', 'label': 'T'},
      {'key': 'Fri', 'label': 'F'},
      {'key': 'Sat', 'label': 'S'},
      {'key': 'Sun', 'label': 'S'},
    ];

    return Wrap(
      spacing: 6,
      children: days.map((day) {
        bool isAllowed = allowedDays.contains(day['key']!);
        return Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isAllowed
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            border: Border.all(
              color: isAllowed
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).dividerColor,
              width: 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            day['label']!,
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isAllowed
                  ? Theme.of(context).colorScheme.surface
                  : Theme.of(context).colorScheme.primary,
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showFilterModal() {
    String? tempStatus = _selectedStatus;
    DateTime? tempStartDate = _startDate;
    DateTime? tempEndDate = _endDate;

    showAsmitaBottomSheet(
      context: context,
      customHeader: Center(
        child: Text(
          'Filter History',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
      child: StatefulBuilder(
        builder: (context, setModalState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Status',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    [
                          'ALL',
                          'PENDING',
                          'APPROVED',
                          'REJECTED',
                          'CHECKED_IN',
                          'CHECKED_OUT',
                        ]
                        .map(
                          (s) => ChoiceChip(
                            label: Text(s),
                            selected:
                                tempStatus == s ||
                                (s == 'ALL' && tempStatus == null),
                            onSelected: (selected) {
                              if (selected) {
                                setModalState(
                                  () => tempStatus = s == 'ALL' ? null : s,
                                );
                              }
                            },
                            selectedColor: Theme.of(
                              context,
                            ).colorScheme.error.withValues(alpha: 0.1),
                            labelStyle: TextStyle(
                              fontFamily: 'Poppins',
                              color:
                                  (tempStatus == s ||
                                      (s == 'ALL' && tempStatus == null))
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                        .toList(),
              ),
              const SizedBox(height: 24),
              Text(
                'Date Range',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: tempStartDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setModalState(() => tempStartDate = picked);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(context).dividerColor,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          tempStartDate != null
                              ? DateFormat('dd-MM-yyyy').format(tempStartDate!)
                              : 'Start Date',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            color: tempStartDate != null
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: tempEndDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setModalState(() => tempEndDate = picked);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(context).dividerColor,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          tempEndDate != null
                              ? DateFormat('dd-MM-yyyy').format(tempEndDate!)
                              : 'End Date',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            color: tempEndDate != null
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _selectedStatus = null;
                          _startDate = null;
                          _endDate = null;
                        });
                        Navigator.pop(context);
                        _loadHistory();
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Theme.of(context).dividerColor),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Clear',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _selectedStatus = tempStatus;
                          _startDate = tempStartDate;
                          _endDate = tempEndDate;
                        });
                        Navigator.pop(context);
                        _loadHistory();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Apply Filters',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.surface,
                          fontWeight: FontWeight.w600,
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

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    String currentUserName = 'Resident';
    if (authState is AuthAuthenticated) {
      currentUserName = authState.user.fullName;
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // Aligned Unified Header Structure matches Dashboard Layouts seamlessly
          const AsmitaPrimaryHeader(),

          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (widget.onBack != null || Navigator.canPop(context))
                  GestureDetector(
                    onTap: () {
                      if (widget.onBack != null) {
                        widget.onBack!();
                      } else {
                        Navigator.pop(context);
                      }
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.only(
                        right: 12.0,
                        top: 4.0,
                        bottom: 4.0,
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                Expanded(
                  child: Text(
                    'Visitor History',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.filter_list_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  onPressed: _showFilterModal,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // Active filters chip area (optional, to show applied filters)
          if (_selectedStatus != null || _startDate != null || _endDate != null)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 4.0,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.filter_alt,
                    size: 14,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Filters applied: ${_selectedStatus ?? ''} '
                      '${_startDate != null ? DateFormat('dd/MM').format(_startDate!) : ''} '
                      '${_endDate != null ? '- ${DateFormat('dd/MM').format(_endDate!)}' : ''}',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedStatus = null;
                        _startDate = null;
                        _endDate = null;
                      });
                      _loadHistory();
                    },
                    child: Text(
                      'Clear',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          Expanded(
            child: BlocBuilder<VisitorBloc, VisitorState>(
              builder: (context, state) {
                if (state is VisitorLoading) {
                  return Center(
                    child: AsmitaLoadingIndicator(
                      color: Theme.of(context).colorScheme.primary,
                      size: 28,
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
                        ElevatedButton.icon(
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
                          icon: Icon(isPermissionError ? Icons.lock_open_rounded : Icons.refresh),
                          label: Text(isPermissionError ? 'Request Access' : 'Retry'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                            foregroundColor: Theme.of(
                              context,
                            ).colorScheme.surface,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                var rawHistory = state is VisitorHistoryLoaded
                    ? state.history
                    : [];
                if (widget.filterCategory != null) {
                  rawHistory = rawHistory.where((item) {
                    final rawItem = item is Map
                        ? Map<String, dynamic>.from(item)
                        : <String, dynamic>{};
                    final isPreApproved =
                        rawItem['record_type'] == 'PRE_APPROVED';
                    final category = isPreApproved
                        ? (rawItem['invite_type'] ?? 'Invite')
                        : 'Walk-in';
                    return category.toString().toLowerCase() ==
                        widget.filterCategory!.toLowerCase();
                  }).toList();
                }

                return CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
                    AsmitaAnimatedRefresh(
                      onRefresh: () async {
                        _loadHistory(isRefresh: true);
                        await Future.delayed(
                          const Duration(seconds: 1),
                        ); // UX delay
                      },
                    ),
                    if (rawHistory.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Text(
                            'No visitor history found',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              color: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.color,
                            ),
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 160),
                        sliver: SliverList.separated(
                          itemCount: rawHistory.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final item = _normalizeItem(
                              rawHistory[index],
                              currentUserName,
                            );
                            return _buildVisitorHistoryCard(context, item);
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
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null, // Fixes Hero overlay bug in IndexedStack
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const AsmitaDialog(
              title: 'Pre-Approve Entry',
              content: AsmitaPreApproveWizard(),
            ),
          );
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        icon: Icon(Icons.add, color: Theme.of(context).colorScheme.surface),
        label: Text(
          'Add Visitor',
          style: TextStyle(
            color: Theme.of(context).colorScheme.surface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildVisitorHistoryCard(BuildContext context, Map<String, dynamic> item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPreApproved = item['isPreApproved'] == true;
    final isOutsideSchedule = item['isOutsideSchedule'] == true;
    final passCode = item['passCode']?.toString();
    final qrCode = item['qrCode']?.toString();
    final hasPassCode = passCode != null && passCode.isNotEmpty;
    final hasQrCode = qrCode != null && qrCode.isNotEmpty;

    // Gradient determination
    List<Color> gradientColors;
    final category = (item['category'] ?? '').toString().toLowerCase();
    final company = (item['company'] ?? '').toString().toLowerCase();

    if (category == 'delivery') {
      gradientColors = const [Color(0xFFD97706), Color(0xFFF59E0B)];
    } else if (company.contains('uber') || category.contains('cab')) {
      gradientColors = const [Color(0xFF334155), Color(0xFF1E293B)];
    } else if (isPreApproved) {
      gradientColors = const [Color(0xFF1E293B), Color(0xFF27347B)];
    } else {
      gradientColors = const [Color(0xFF1E3A8A), Color(0xFF2563EB)];
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isOutsideSchedule
              ? AsmitaPalette.actionRed.withValues(alpha: 0.5)
              : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          width: isOutsideSchedule ? 1.5 : 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: isOutsideSchedule
                ? AsmitaPalette.actionRed.withValues(alpha: isDark ? 0.15 : 0.08)
                : (isDark ? Colors.black.withValues(alpha: 0.35) : const Color(0x0A0F172A)),
            blurRadius: 18,
            offset: const Offset(0, 6),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: isDark ? Colors.transparent : const Color(0x050F172A),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showVisitorDetailsModal(context, item),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Avatar + Title/Host + Action/QR Pill
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Squircle Avatar
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: gradientColors,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: gradientColors.last.withValues(alpha: isDark ? 0.35 : 0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.18),
                              width: 1.2,
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              item['icon'] as IconData,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                        if (isPreApproved)
                          Positioned(
                            right: -2,
                            bottom: -2,
                            child: Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF59E0B),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.surface,
                                  width: 1.8,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 3,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.star_rounded,
                                size: 11,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 14),

                    // Title & Subtitle
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['titleText'] as String,
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              if (isPreApproved) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF78350F).withValues(alpha: 0.35)
                                        : const Color(0xFFFEF3C7),
                                    borderRadius: BorderRadius.circular(5),
                                    border: Border.all(
                                      color: isDark
                                          ? const Color(0xFFB45309).withValues(alpha: 0.6)
                                          : const Color(0xFFFDE68A),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.star_rounded, size: 10, color: Color(0xFFD97706)),
                                      const SizedBox(width: 3),
                                      Text(
                                        'VIP PASS',
                                        style: TextStyle(
                                          fontFamily: 'Montserrat',
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          color: isDark
                                              ? const Color(0xFFFDE68A)
                                              : const Color(0xFFB45309),
                                          letterSpacing: 0.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),
                              ],
                              Flexible(
                                child: Text(
                                  item['subtitleText'] as String,
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: isDark
                                        ? AsmitaPalette.textDarkModeMuted
                                        : const Color(0xFF64748B),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          if (isOutsideSchedule) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF450A0A)
                                    : const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF7F1D1D)
                                      : const Color(0xFFFECACA),
                                ),
                              ),
                              child: const Text(
                                '⚠️ Outside Schedule',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 10,
                                  color: Color(0xFFDC2626),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(width: 10),

                    // Right affordance: QR badge or chevron
                    if (hasQrCode)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.qr_code_2_rounded,
                              size: 16,
                              color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1E3A8A),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'QR',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1E3A8A),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 13,
                        color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                      ),
                  ],
                ),

                // Inset Executive Meta Footer
                Container(
                  margin: const EdgeInsets.only(top: 13),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.7) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155).withValues(alpha: 0.6) : const Color(0xFFE2E8F0),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      // 1. Time & Date
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              Icons.schedule_rounded,
                              size: 14,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'TIME & DATE',
                                    style: TextStyle(
                                      fontFamily: 'Montserrat',
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                  Text(
                                    '${item['entryTime']} • ${item['date']}',
                                    style: TextStyle(
                                      fontFamily: 'Montserrat',
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Divider
                      Container(
                        width: 1,
                        height: 24,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),

                      // 2. Gate or Schedule Slot
                      if (item['inviteSubType'] == 'FREQUENT' && item['startTime'] != null && item['endTime'] != null)
                        Expanded(
                          child: Row(
                            children: [
                              Icon(
                                Icons.timelapse_rounded,
                                size: 14,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'SLOT',
                                      style: TextStyle(
                                        fontFamily: 'Montserrat',
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                    Text(
                                      '${_formatRawTime(item['startTime'])} - ${_formatRawTime(item['endTime'])}',
                                      style: TextStyle(
                                        fontFamily: 'Montserrat',
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Expanded(
                          child: Row(
                            children: [
                              Icon(
                                item['vehicleNumber'] != null
                                    ? Icons.directions_car_filled_rounded
                                    : Icons.meeting_room_rounded,
                                size: 14,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      item['vehicleNumber'] != null ? 'VEHICLE' : 'ACCESS GATE',
                                      style: TextStyle(
                                        fontFamily: 'Montserrat',
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                    Text(
                                      item['vehicleNumber']?.toString() ??
                                          (item['gate'] as String? ?? 'Main Gate'),
                                      style: TextStyle(
                                        fontFamily: 'Montserrat',
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                      // 3. Security Pass Code Ticket (if passCode exists)
                      if (hasPassCode) ...[
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: passCode));
                            HapticFeedback.selectionClick();
                            AsmitaToast.show(
                              context,
                              message: 'Pass code #$passCode copied to clipboard',
                              type: AsmitaToastType.success,
                            );
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0F172A) : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.vpn_key_rounded,
                                  size: 11,
                                  color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1E3A8A),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '#$passCode',
                                  style: TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                    color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1E3A8A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
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

  String _formatRawTime(dynamic rawTime) {
    if (rawTime == null) return '--';

    String timeStr = rawTime.toString();
    try {
      // If it's something like "14:30:00" or ISO format with time
      if (timeStr.contains('T')) {
        timeStr = timeStr.split('T')[1];
      }

      final parts = timeStr.split(':');
      if (parts.length >= 2) {
        int hour = int.tryParse(parts[0]) ?? 0;
        int minute = int.tryParse(parts[1]) ?? 0;
        final time = TimeOfDay(hour: hour, minute: minute);
        final now = DateTime.now();
        return DateFormat.jm().format(
          DateTime(now.year, now.month, now.day, time.hour, time.minute),
        );
      }
    } catch (e) {
      debugPrint('Error parsing raw time: $e');
    }
    return timeStr;
  }
}
