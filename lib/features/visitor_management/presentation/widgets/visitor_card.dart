import 'package:flutter/material.dart';
import '../../../../core/constants/design_system.dart';
import '../../utils/visitor_utils.dart';

class VisitorHistoryCard extends StatelessWidget {
  final Map<String, dynamic> item;

  const VisitorHistoryCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: () => VisitorUtils.showVisitorDetailsModal(context, item),
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
                        '${VisitorUtils.formatRawTime(item['startTime'])} - ${VisitorUtils.formatRawTime(item['endTime'])}',
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
  }
}
