import 'package:flutter_test/flutter_test.dart';
import 'package:netsu_app/features/schedules/domain/area_schedule.dart';
import 'package:netsu_app/features/schedules/domain/schedule_status.dart';

void main() {
  test('next collection skips completed and cancelled', () {
    final now = DateTime.utc(2026, 11, 21, 9);
    final items = [
      AreaSchedule(
        id: 'old',
        expectedStart: DateTime.utc(2026, 11, 20, 6),
        status: ScheduleStatus.completed,
        areaName: '04',
      ),
      AreaSchedule(
        id: 'next',
        expectedStart: DateTime.utc(2026, 11, 22, 6),
        status: ScheduleStatus.published,
        areaName: '04',
      ),
    ];
    expect(nextCollection(items, now)?.id, 'next');
    expect(parseStops([
      {'name': 'School', 'lat': 7.66, 'lng': 36.83, 'order': 2},
      {'name': 'Market', 'lat': 7.67, 'lng': 36.84, 'order': 1},
    ]).map((stop) => stop.name), ['Market', 'School']);
  });
}
