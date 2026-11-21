import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class AddisTime {
  const AddisTime._();

  static const zoneName = 'Africa/Addis_Ababa';
  static bool _ready = false;

  static void ensureInitialized() {
    if (_ready) return;
    tzdata.initializeTimeZones();
    _ready = true;
  }

  static tz.Location get location {
    ensureInitialized();
    return tz.getLocation(zoneName);
  }

  /// Wall-clock parts in Addis Ababa for an absolute instant.
  static DateTime wallClock(DateTime instant) {
    final local = tz.TZDateTime.from(instant.toUtc(), location);
    return DateTime(local.year, local.month, local.day, local.hour, local.minute, local.second);
  }

  static String formatTime(DateTime instant) {
    final wall = wallClock(instant);
    final hour = wall.hour % 12 == 0 ? 12 : wall.hour % 12;
    final minute = wall.minute.toString().padLeft(2, '0');
    final suffix = wall.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $suffix';
  }

  static bool isSameDay(DateTime a, DateTime b) {
    final left = wallClock(a);
    final right = wallClock(b);
    return left.year == right.year && left.month == right.month && left.day == right.day;
  }

  static String formatDate(DateTime instant) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final wall = wallClock(instant);
    return '${months[wall.month - 1]} ${wall.day}, ${wall.year}';
  }
}
