import 'package:asmita_society/core/utils/date_formatter.dart';
import 'package:flutter/material.dart';
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
import 'package:asmita_society/core/widgets/asmita_dialog.dart';
import '../../../dashboard/widgets/asmita_pre_approve_wizard.dart';

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
    context.read<VisitorBloc>().add(LoadMyHistory(
      residentId: residentId, 
      isRefresh: isRefresh,
      status: _selectedStatus,
      startDate: _startDate,
      endDate: _endDate,
    ));
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
    final item = rawItem is Map ? Map<String, dynamic>.from(rawItem) : <String, dynamic>{};
    final isPreApproved = item['record_type'] == 'PRE_APPROVED';

    final name = item['visitor_name'] ?? item['title'] ?? 'Unknown';
    final company = item['company_name'] ?? item['purpose'] ?? 'Visitor';
    final category = isPreApproved ? (item['invite_type'] ?? 'Invite') : (item['visitor_type_name'] ?? 'Walk-in');
    
    final entryTimeStr = item['checkin_at'] ?? item['start_time'];
    final exitTimeStr = item['checkout_at'] ?? item['end_time'];
    final dateStr = item['created_at'] ?? item['valid_from'];

    final entryTime = _formatTime(dateStr, entryTimeStr);
    final exitTime = _formatTime(dateStr, exitTimeStr);
    final date = _formatDate(dateStr);

    String status = item['status'] ?? 'Pending';
    final gate = isPreApproved ? 'Pre-Approved' : 'Main Gate';
    
    String? validToRaw = item['valid_to'];
    if (validToRaw != null && item['invite_sub_type']?.toString().toUpperCase() == 'FREQUENT') {
      DateTime? validToDate = DateTime.tryParse(validToRaw.toString());
      if (validToDate != null) {
        DateTime now = DateTime.now();
        DateTime today = DateTime(now.year, now.month, now.day);
        DateTime expiry = DateTime(validToDate.year, validToDate.month, validToDate.day);
        if (today.isAfter(expiry)) {
          status = 'Expired';
        }
      }
    }

    bool isOutsideSchedule = false;
    String? allowedDays = item['allowed_days'];
    String? startTime = item['start_time'];
    String? endTime = item['end_time'];
    if (allowedDays != null && startTime != null && endTime != null && item['created_at'] != null) {
      DateTime entryDateTime = DateTime.tryParse(item['created_at'].toString()) ?? DateTime.now();
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
    Color brandColor = AsmitaPalette.deepNavy;

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
    } else if (company.toString().toLowerCase().contains('uber') || category.toString().toLowerCase().contains('cab')) {
      icon = Icons.directions_car_rounded;
      brandColor = Colors.black;
    }

    // Default title is name, but for Cab/Delivery/Guest it should be the company/purpose
    String titleText = name;
    if (category.toString().toLowerCase() == 'delivery' || 
        category.toString().toLowerCase() == 'cab' || 
        icon != Icons.person_rounded ||
        name.toLowerCase().contains('invite')) {
      titleText = company;
      // Clean up cases where company name might be empty or redundant
      if (titleText.toLowerCase().contains('invite')) {
        titleText = titleText.replaceAll(RegExp(r' invite', caseSensitive: false), '').trim();
      }
    }

    String subtitleText = isPreApproved ? 'by $currentUserName' : 'Entered via $gate';
    String modalSubtitleText = isPreApproved ? 'Pre-approved by $currentUserName' : 'Entered via $gate';

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
      'validTo': item['valid_to'] != null ? _formatDate(item['valid_to'].toString()) : null,
      'vehicleNumber': item['vehicle_number'],
      'maxGuestCount': item['max_guest_count'],
      'isPrivate': item['is_private'] == true,
      'isOutsideSchedule': isOutsideSchedule,
    };
  }

  void _showVisitorDetailsModal(BuildContext context, Map<String, dynamic> visitor) {
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
                border: Border.all(color: visitor['brandColor'] as Color, width: 2),
              ),
              child: CircleAvatar(
                radius: 36,
                backgroundColor: AsmitaPalette.systemBG,
                child: Icon(
                  visitor['icon'] as IconData, 
                  color: visitor['brandColor'] as Color, 
                  size: 32
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Header Labels (Montserrat for structural emphasis)
          Center(
            child: Text(
              visitor['titleText'] as String,
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AsmitaPalette.deepNavy,
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
                visitor['modalSubtitleText'] as String? ?? visitor['subtitleText'] as String,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: visitor['brandColor'] as Color,
                ),
              ),
            ),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [

              // Data Parameters Section (Poppins for legible data layouts)
              if (visitor['inviteSubType'] != null && visitor['inviteSubType'] != 'ONCE')
                _buildDetailRow(textTheme, label: 'Frequency', value: visitor['inviteSubType'] as String),
              if (visitor['validTo'] != null && visitor['inviteSubType'] == 'FREQUENT')
                _buildDetailRow(textTheme, label: 'Allowed Until', value: visitor['validTo'] as String),
              if (visitor['inviteSubType'] == 'FREQUENT' || (visitor['allowedDays'] != null && visitor['allowedDays'].toString().isNotEmpty)) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                          color: AsmitaPalette.textLight,
                        ),
                      ),
                      _buildDaysIndicator(visitor['allowedDays']?.toString().isNotEmpty == true ? visitor['allowedDays'] as String : 'Mon,Tue,Wed,Thu,Fri,Sat,Sun'),
                    ],
                  ),
                ),
              ],
              if (visitor['startTime'] != null && visitor['endTime'] != null)
                _buildDetailRow(textTheme, label: 'Time Slot', value: '${_formatRawTime(visitor['startTime'])} - ${_formatRawTime(visitor['endTime'])}'),
              if (visitor['vehicleNumber'] != null && visitor['vehicleNumber'].toString().isNotEmpty)
                _buildDetailRow(textTheme, label: 'Vehicle Number', value: visitor['vehicleNumber'] as String),
              if (visitor['maxGuestCount'] != null && visitor['maxGuestCount'] > 1)
                _buildDetailRow(textTheme, label: 'Guest Count', value: visitor['maxGuestCount'].toString()),
              if (visitor['isPrivate'] == true)
                _buildDetailRow(textTheme, label: 'Entry Mode', value: 'Surprise / Secret Delivery', isHighlight: true),
                
              _buildDetailRow(textTheme, label: 'Gate Access Status', value: visitor['status'] as String, isStatus: true),
              _buildDetailRow(textTheme, label: 'Arrival Date', value: visitor['date'] as String),
              _buildDetailRow(textTheme, label: 'Entry Boundary Check', value: visitor['gate'] as String),
              _buildDetailRow(textTheme, label: 'Inbound Timestamp', value: visitor['entryTime'] as String),
              if (visitor['exitTime'] != '--')
                _buildDetailRow(textTheme, label: 'Outbound Timestamp', value: visitor['exitTime'] as String),
              

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
              color: AsmitaPalette.deepNavy,
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
                    (index) => const SizedBox(
                      width: 3, 
                      height: 1, 
                      child: DecoratedBox(decoration: BoxDecoration(color: AsmitaPalette.borderGrey)),
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
                    : (value.toLowerCase().contains('entered') || value.toLowerCase().contains('exited')
                        ? Colors.green.withValues(alpha: 0.1)
                        : AsmitaPalette.systemBG),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (value.toLowerCase() != 'expired' && value.toLowerCase() != 'pending') ...[
                    Icon(Icons.check_circle_outline, 
                      size: 14, 
                      color: value.toLowerCase().contains('exited') ? Colors.green.shade700 : AsmitaPalette.deepNavy
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
                          : (value.toLowerCase().contains('exited') ? Colors.green.shade700 : AsmitaPalette.deepNavy),
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
                color: isHighlight ? AsmitaPalette.actionRed : AsmitaPalette.deepNavy,
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
            color: isAllowed ? AsmitaPalette.actionRed : Colors.transparent,
            border: Border.all(
              color: isAllowed ? AsmitaPalette.actionRed : AsmitaPalette.borderGrey,
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
              color: isAllowed ? Colors.white : AsmitaPalette.deepNavy,
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
      customHeader: const Center(
        child: Text(
          'Filter History',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AsmitaPalette.deepNavy,
          ),
        ),
      ),
      child: StatefulBuilder(
        builder: (context, setModalState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Status',
                style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: AsmitaPalette.deepNavy),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['ALL', 'PENDING', 'APPROVED', 'REJECTED', 'CHECKED_IN', 'CHECKED_OUT']
                    .map((s) => ChoiceChip(
                          label: Text(s),
                          selected: tempStatus == s || (s == 'ALL' && tempStatus == null),
                          onSelected: (selected) {
                            if (selected) {
                              setModalState(() => tempStatus = s == 'ALL' ? null : s);
                            }
                          },
                          selectedColor: AsmitaPalette.actionRed.withValues(alpha: 0.1),
                          labelStyle: TextStyle(
                            fontFamily: 'Poppins',
                            color: (tempStatus == s || (s == 'ALL' && tempStatus == null)) ? AsmitaPalette.actionRed : AsmitaPalette.deepNavy,
                            fontWeight: FontWeight.w600,
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 24),
              const Text(
                'Date Range',
                style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: AsmitaPalette.deepNavy),
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
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: AsmitaPalette.borderGrey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          tempStartDate != null ? DateFormat('dd-MM-yyyy').format(tempStartDate!) : 'Start Date',
                          style: TextStyle(fontFamily: 'Poppins', color: tempStartDate != null ? AsmitaPalette.deepNavy : AsmitaPalette.textLight),
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
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: AsmitaPalette.borderGrey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          tempEndDate != null ? DateFormat('dd-MM-yyyy').format(tempEndDate!) : 'End Date',
                          style: TextStyle(fontFamily: 'Poppins', color: tempEndDate != null ? AsmitaPalette.deepNavy : AsmitaPalette.textLight),
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
                        side: const BorderSide(color: AsmitaPalette.borderGrey),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Clear', style: TextStyle(color: AsmitaPalette.deepNavy, fontWeight: FontWeight.w600)),
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
                        backgroundColor: AsmitaPalette.actionRed,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Apply Filters', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
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
    final textTheme = Theme.of(context).textTheme;
    final authState = context.read<AuthBloc>().state;
    String currentUserName = 'Resident';
    if (authState is AuthAuthenticated) {
      currentUserName = authState.user.fullName;
    }

    return Scaffold(
      backgroundColor: AsmitaPalette.systemBG,
      body: Column(
        children: [
          // Aligned Unified Header Structure matches Dashboard Layouts seamlessly
          const AsmitaPrimaryHeader(),
          
          if (widget.onBack != null || Navigator.canPop(context))
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () {
                      if (widget.onBack != null) {
                        widget.onBack!();
                      } else {
                        Navigator.pop(context);
                      }
                    },
                    behavior: HitTestBehavior.opaque,
                    child: const Padding(
                      padding: EdgeInsets.only(right: 12.0, top: 4.0, bottom: 4.0),
                      child: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AsmitaPalette.deepNavy),
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Visitor History',
                      style: TextStyle(fontFamily: 'Montserrat', fontSize: 18, fontWeight: FontWeight.w800, color: AsmitaPalette.deepNavy),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.filter_list_rounded, color: AsmitaPalette.deepNavy),
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
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 4.0),
              child: Row(
                children: [
                  const Icon(Icons.filter_alt, size: 14, color: AsmitaPalette.textLight),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Filters applied: ${_selectedStatus ?? ''} '
                      '${_startDate != null ? DateFormat('dd/MM').format(_startDate!) : ''} '
                      '${_endDate != null ? '- ${DateFormat('dd/MM').format(_endDate!)}' : ''}',
                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AsmitaPalette.textLight),
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
                    child: const Text('Clear', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AsmitaPalette.actionRed, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),

          Expanded(
            child: BlocBuilder<VisitorBloc, VisitorState>(
              builder: (context, state) {
                debugPrint('VisitorHistoryScreen BlocBuilder State: $state');
                  if (state is VisitorLoading) {
                    return const Center(
                      child: AsmitaLoadingIndicator(color: AsmitaPalette.actionRed, size: 28),
                    );
                  }

                if (state is VisitorError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          state.message,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Montserrat',
                            color: AsmitaPalette.actionRed,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            _loadHistory(isRefresh: true);
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AsmitaPalette.actionRed,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                var rawHistory = state is VisitorHistoryLoaded ? state.history : [];
                if (widget.filterCategory != null) {
                  rawHistory = rawHistory.where((item) {
                    final rawItem = item is Map ? Map<String, dynamic>.from(item) : <String, dynamic>{};
                    final isPreApproved = rawItem['record_type'] == 'PRE_APPROVED';
                    final category = isPreApproved ? (rawItem['invite_type'] ?? 'Invite') : 'Walk-in';
                    return category.toString().toLowerCase() == widget.filterCategory!.toLowerCase();
                  }).toList();
                }
                
                return CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  slivers: [
                    AsmitaAnimatedRefresh(
                      onRefresh: () async {
                        _loadHistory(isRefresh: true);
                        await Future.delayed(const Duration(seconds: 1)); // UX delay
                      },
                    ),
                    if (rawHistory.isEmpty)
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Text(
                            'No visitor history found',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              color: AsmitaPalette.textLight,
                            ),
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.all(16),
                        sliver: SliverList.separated(
                          itemCount: rawHistory.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final item = _normalizeItem(rawHistory[index], currentUserName);
                            return InkWell(
                              onTap: () => _showVisitorDetailsModal(context, item),
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AsmitaPalette.borderGrey, width: 1.5),
                                ),
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: const BoxDecoration(
                                        color: AsmitaPalette.systemBG, 
                                        shape: BoxShape.circle
                                      ),
                                      child: Icon(
                                        item['icon'] as IconData, 
                                        color: item['brandColor'] as Color, 
                                        size: 22
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item['titleText'] as String,
                                            style: textTheme.titleLarge?.copyWith(
                                              fontFamily: 'Montserrat',
                                              fontSize: 15, 
                                              fontWeight: FontWeight.w800,
                                              color: AsmitaPalette.deepNavy,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            item['subtitleText'] as String,
                                            style: textTheme.bodyMedium?.copyWith(
                                              fontFamily: 'Poppins',
                                              fontSize: 12, 
                                              fontWeight: FontWeight.w500,
                                              color: AsmitaPalette.textLight,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (item['inviteSubType'] == 'FREQUENT' || item['allowedDays'] != null) ...[
                                            if (item['startTime'] != null && item['endTime'] != null) ...[
                                              const SizedBox(height: 6),
                                              Text(
                                                '${_formatRawTime(item['startTime'])} - ${_formatRawTime(item['endTime'])}',
                                                style: textTheme.bodySmall?.copyWith(
                                                  fontFamily: 'Poppins',
                                                  fontSize: 11,
                                                  color: AsmitaPalette.deepNavy,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ],
                                          if (item['isOutsideSchedule'] == true) ...[
                                            const SizedBox(height: 4),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.red.shade50,
                                                borderRadius: BorderRadius.circular(4),
                                                border: Border.all(color: Colors.red.shade200),
                                              ),
                                              child: const Text(
                                                '⚠️ Outside Schedule',
                                                style: TextStyle(
                                                  fontFamily: 'Poppins',
                                                  fontSize: 10,
                                                  color: Colors.red,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          item['entryTime'] as String,
                                          style: textTheme.bodyLarge?.copyWith(
                                            fontFamily: 'Poppins',
                                            fontSize: 13, 
                                            fontWeight: FontWeight.w600,
                                            color: AsmitaPalette.deepNavy,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          item['date'] as String,
                                          style: textTheme.bodyMedium?.copyWith(
                                            fontFamily: 'Poppins',
                                            fontSize: 11, 
                                            color: AsmitaPalette.actionRed, 
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
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
        backgroundColor: AsmitaPalette.deepNavy,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Visitor', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
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
        return DateFormat.jm().format(DateTime(now.year, now.month, now.day, time.hour, time.minute));
      }
    } catch (e) {
      debugPrint('Error parsing raw time: $e');
    }
    return timeStr;
  }
}