import 'package:intl/intl.dart';

class AppDateFormatter {
  static String formatDate(dynamic date) {
    if (date == null) return 'N/A';
    try {
      DateTime dt;
      if (date is DateTime) {
        dt = date;
      } else if (date is String) {
        dt = DateTime.parse(date);
      } else {
        return date.toString();
      }
      return DateFormat('dd-MM-yyyy').format(dt.toLocal());
    } catch (_) {
      if (date is String && date.length >= 10) {
        final parts = date.substring(0, 10).split('-');
        if (parts.length == 3 && parts[0].length == 4) {
          return '${parts[2]}-${parts[1]}-${parts[0]}';
        }
      }
      return date.toString();
    }
  }

  static String formatDateTime(dynamic date) {
    if (date == null) return 'N/A';
    try {
      DateTime dt;
      if (date is DateTime) {
        dt = date;
      } else if (date is String) {
        dt = DateTime.parse(date);
      } else {
        return date.toString();
      }
      return DateFormat('dd-MM-yyyy • hh:mm a').format(dt.toLocal());
    } catch (_) {
      return date.toString();
    }
  }

  static String timeAgo(dynamic date) {
    if (date == null) return 'N/A';
    try {
      DateTime dt;
      if (date is DateTime) {
        dt = date;
      } else if (date is String) {
        dt = DateTime.parse(date);
      } else {
        return date.toString();
      }
      final now = DateTime.now();
      final difference = now.difference(dt.toLocal());
      
      if (difference.inDays > 7) {
        return formatDate(dt);
      } else if (difference.inDays >= 1) {
        return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
      } else if (difference.inHours >= 1) {
        return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
      } else if (difference.inMinutes >= 1) {
        return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
      } else {
        return 'Just now';
      }
    } catch (_) {
      return date.toString();
    }
  }
}
