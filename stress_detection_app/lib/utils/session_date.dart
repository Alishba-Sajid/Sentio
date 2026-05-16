import 'package:intl/intl.dart';

/// Parses Supabase timestamps (UTC) and formats in the device's local timezone.
class SessionDate {
  static DateTime parseLocal(String? raw) {
    if (raw == null || raw.isEmpty) return DateTime.now();
    final parsed = DateTime.parse(raw);
    return parsed.toLocal();
  }

  static String formatListTile(String? raw) {
    return DateFormat('MMM d, yyyy • h:mm a').format(parseLocal(raw));
  }
}
