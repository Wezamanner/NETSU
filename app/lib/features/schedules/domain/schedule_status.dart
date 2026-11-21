enum ScheduleStatus {
  draft,
  published,
  assigned,
  onTheWay,
  inProgress,
  completed,
  delayed,
  cancelled,
}

ScheduleStatus? scheduleStatusFromString(String value) {
  return switch (value) {
    'draft' => ScheduleStatus.draft,
    'published' => ScheduleStatus.published,
    'assigned' => ScheduleStatus.assigned,
    'on_the_way' => ScheduleStatus.onTheWay,
    'in_progress' => ScheduleStatus.inProgress,
    'completed' => ScheduleStatus.completed,
    'delayed' => ScheduleStatus.delayed,
    'cancelled' => ScheduleStatus.cancelled,
    _ => null,
  };
}

String scheduleStatusToString(ScheduleStatus status) {
  return switch (status) {
    ScheduleStatus.draft => 'draft',
    ScheduleStatus.published => 'published',
    ScheduleStatus.assigned => 'assigned',
    ScheduleStatus.onTheWay => 'on_the_way',
    ScheduleStatus.inProgress => 'in_progress',
    ScheduleStatus.completed => 'completed',
    ScheduleStatus.delayed => 'delayed',
    ScheduleStatus.cancelled => 'cancelled',
  };
}

/// Mirrors `public.can_transition` in the database.
class ScheduleStatusMachine {
  const ScheduleStatusMachine._();

  static bool canTransition(ScheduleStatus from, ScheduleStatus to) {
    return switch (from) {
      ScheduleStatus.draft => to == ScheduleStatus.published,
      ScheduleStatus.published =>
        to == ScheduleStatus.assigned || to == ScheduleStatus.delayed || to == ScheduleStatus.cancelled,
      ScheduleStatus.assigned =>
        to == ScheduleStatus.onTheWay || to == ScheduleStatus.delayed || to == ScheduleStatus.cancelled,
      ScheduleStatus.onTheWay =>
        to == ScheduleStatus.inProgress || to == ScheduleStatus.delayed || to == ScheduleStatus.cancelled,
      ScheduleStatus.inProgress =>
        to == ScheduleStatus.completed || to == ScheduleStatus.delayed || to == ScheduleStatus.cancelled,
      ScheduleStatus.delayed =>
        to == ScheduleStatus.published ||
            to == ScheduleStatus.assigned ||
            to == ScheduleStatus.onTheWay ||
            to == ScheduleStatus.inProgress ||
            to == ScheduleStatus.cancelled,
      ScheduleStatus.completed || ScheduleStatus.cancelled => false,
    };
  }

  /// Buttons a worker may press. Delay still requires a reason in the caller.
  static List<ScheduleStatus> workerActions(ScheduleStatus from) {
    const allowed = {
      ScheduleStatus.onTheWay,
      ScheduleStatus.inProgress,
      ScheduleStatus.completed,
      ScheduleStatus.delayed,
    };
    return ScheduleStatus.values
        .where((status) => allowed.contains(status) && canTransition(from, status))
        .toList();
  }
}
