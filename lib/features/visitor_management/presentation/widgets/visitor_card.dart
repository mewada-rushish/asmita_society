import 'package:flutter/material.dart';
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
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor, width: 1.5),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor, 
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
                      color: Theme.of(context).textTheme.titleLarge?.color,
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
                      color: Theme.of(context).textTheme.bodyMedium?.color,
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
                          color: Theme.of(context).textTheme.bodySmall?.color,
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
                        color: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Theme.of(context).colorScheme.error.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        '⚠️ Outside Schedule',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          color: Theme.of(context).colorScheme.error,
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
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item['date'] as String,
                  style: textTheme.bodyMedium?.copyWith(
                    fontFamily: 'Poppins',
                    color: Theme.of(context).colorScheme.primary, 
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
