import 'package:flutter_test/flutter_test.dart';
import 'package:netsu_app/core/utils/addis_time.dart';

void main() {
  test('converts a UTC instant to Addis Ababa wall time', () {
    final instant = DateTime.utc(2026, 11, 21, 15);
    expect(AddisTime.formatTime(instant), '6:00 PM');
    expect(AddisTime.formatDate(instant), 'Nov 21, 2026');
    final nextDay = DateTime.utc(2026, 11, 21, 21, 30);
    expect(AddisTime.formatDate(nextDay), 'Nov 22, 2026');
  });
}
