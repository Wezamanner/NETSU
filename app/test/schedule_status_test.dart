import 'package:flutter_test/flutter_test.dart';
import 'package:netsu_app/features/schedules/domain/schedule_status.dart';

void main() {
  test('follows the main path and blocks skips', () {
    expect(ScheduleStatusMachine.canTransition(ScheduleStatus.draft, ScheduleStatus.published), isTrue);
    expect(ScheduleStatusMachine.canTransition(ScheduleStatus.draft, ScheduleStatus.completed), isFalse);
    expect(ScheduleStatusMachine.canTransition(ScheduleStatus.published, ScheduleStatus.assigned), isTrue);
    expect(ScheduleStatusMachine.canTransition(ScheduleStatus.assigned, ScheduleStatus.onTheWay), isTrue);
    expect(ScheduleStatusMachine.canTransition(ScheduleStatus.onTheWay, ScheduleStatus.inProgress), isTrue);
    expect(ScheduleStatusMachine.canTransition(ScheduleStatus.inProgress, ScheduleStatus.completed), isTrue);
  });

  test('allows delay and return, and treats completed and cancelled as terminal', () {
    expect(ScheduleStatusMachine.canTransition(ScheduleStatus.published, ScheduleStatus.delayed), isTrue);
    expect(ScheduleStatusMachine.canTransition(ScheduleStatus.delayed, ScheduleStatus.assigned), isTrue);
    expect(ScheduleStatusMachine.canTransition(ScheduleStatus.completed, ScheduleStatus.published), isFalse);
    expect(ScheduleStatusMachine.canTransition(ScheduleStatus.cancelled, ScheduleStatus.published), isFalse);
  });

  test('worker actions are only the field steps', () {
    expect(
      ScheduleStatusMachine.workerActions(ScheduleStatus.assigned),
      [ScheduleStatus.onTheWay, ScheduleStatus.delayed],
    );
    expect(ScheduleStatusMachine.workerActions(ScheduleStatus.draft), isEmpty);
  });
}
