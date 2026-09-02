import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/design_system.dart';
import '../../../../core/widgets/asmita_bottom_sheet.dart';

class VisitorUtils {
  static String formatTime(String? dateStr, String? timeStr) {
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

  static String formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      final now = DateTime.now();
      if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
        return 'Today';
      }
      return DateFormat('MMM dd, yyyy').format(dt);
    } catch (_) {
      return dateStr.split('T')[0];
    }
  }

  static String formatRawTime(dynamic rawTime) {
    if (rawTime == null) return '--';
    
    String timeStr = rawTime.toString();
    try {
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

  static Map<String, dynamic> normalizeItem(dynamic rawItem, String currentUserName) {
    final item = rawItem is Map ? Map<String, dynamic>.from(rawItem) : <String, dynamic>{};
    final isPreApproved = item['record_type'] == 'PRE_APPROVED';

    final name = item['visitor_name'] ?? item['title'] ?? 'Unknown';
    final company = item['company_name'] ?? item['purpose'] ?? 'Visitor';
    final category = isPreApproved ? (item['invite_type'] ?? 'Invite') : 'Walk-in';
    
    final entryTimeStr = item['checkin_at'] ?? item['start_time'];
    final exitTimeStr = item['checkout_at'] ?? item['end_time'];
    final dateStr = item['created_at'] ?? item['valid_from'];

    final entryTime = formatTime(dateStr, entryTimeStr);
    final exitTime = formatTime(dateStr, exitTimeStr);
    final date = formatDate(dateStr);

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
      String dayOfWeek = DateFormat('E').format(entryDateTime);
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

    String titleText = name;
    if (category.toString().toLowerCase() == 'delivery' || 
        category.toString().toLowerCase() == 'cab' || 
        icon != Icons.person_rounded ||
        name.toLowerCase().contains('invite')) {
      titleText = company;
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
      'duration': 'N/A', 
      'gate': gate,
      'date': date,
      'status': status,
      'icon': icon,
      'brandColor': brandColor,
      'inviteSubType': item['invite_sub_type']?.toString().toUpperCase(),
      'allowedDays': allowedDays,
      'startTime': startTime,
      'endTime': endTime,
      'validTo': item['valid_to'] != null ? formatDate(item['valid_to'].toString()) : null,
      'vehicleNumber': item['vehicle_number'],
      'maxGuestCount': item['max_guest_count'],
      'isPrivate': item['is_private'] == true,
      'isOutsideSchedule': isOutsideSchedule,
    };
  }

  static void showVisitorDetailsModal(BuildContext context, Map<String, dynamic> visitor) {
    final textTheme = Theme.of(context).textTheme;

    showAsmitaBottomSheet(
      context: context,
      title: '',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
          const SizedBox(height: 24),
          const Divider(color: AsmitaPalette.borderGrey, height: 1),
          const SizedBox(height: 20),

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
            _buildDetailRow(textTheme, label: 'Time Slot', value: '${formatRawTime(visitor['startTime'])} - ${formatRawTime(visitor['endTime'])}'),
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
    );
  }

  static Widget _buildDetailRow(
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
          Expanded(
            child: Text(
              label,
              style: textTheme.bodyMedium?.copyWith(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AsmitaPalette.textLight,
              ),
            ),
          ),
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

  static Widget _buildDaysIndicator(String allowedDays) {
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
}
