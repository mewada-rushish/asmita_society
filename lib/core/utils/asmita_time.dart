import 'package:intl/intl.dart';

/// Centralized Mumbai / IST (+05:30) time conversion and formatting helper.
class AsmitaTime {
  static const Duration istOffset = Duration(hours: 5, minutes: 30);

  static DateTime toIst(DateTime dt) => dt.toUtc().add(istOffset);

  static DateTime nowIst() => toIst(DateTime.now());

  static DateTime? tryParseIst(dynamic raw) {
    if (raw == null) return null;
    final parsed = DateTime.tryParse(raw.toString().trim());
    if (parsed == null) return null;
    return toIst(parsed);
  }

  static String formatTime(dynamic raw, {bool includeZone = true}) {
    final dt = tryParseIst(raw);
    if (dt == null) return '--';
    final formatted = DateFormat('hh:mm a').format(dt);
    return includeZone ? '$formatted IST' : formatted;
  }

  static String formatDate(dynamic raw, {String pattern = 'dd MMM yyyy'}) {
    final dt = tryParseIst(raw);
    if (dt == null) return '';
    return DateFormat(pattern).format(dt);
  }

  static String formatDateTime(dynamic raw, {bool includeZone = true}) {
    final dt = tryParseIst(raw);
    if (dt == null) return '--';
    final formatted = DateFormat('dd MMM yyyy, hh:mm a').format(dt);
    return includeZone ? '$formatted IST' : formatted;
  }
}
