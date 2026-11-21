import 'package:material_ui/material_ui.dart';
import 'package:netsu_app/core/l10n/generated/app_localizations.dart';
import 'package:netsu_app/features/schedules/domain/schedule_status.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({required this.status, super.key});

  final ScheduleStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (label, icon, color) = switch (status) {
      ScheduleStatus.draft => (l10n.statusDraft, Icons.edit_outlined, Colors.blueGrey),
      ScheduleStatus.published => (l10n.statusPublished, Icons.event_available, Colors.teal),
      ScheduleStatus.assigned => (l10n.statusAssigned, Icons.assignment_ind_outlined, Colors.indigo),
      ScheduleStatus.onTheWay => (l10n.statusOnTheWay, Icons.local_shipping_outlined, Colors.orange),
      ScheduleStatus.inProgress => (l10n.statusInProgress, Icons.play_circle_outline, Colors.blue),
      ScheduleStatus.completed => (l10n.statusCompleted, Icons.check_circle_outline, Colors.green),
      ScheduleStatus.delayed => (l10n.statusDelayed, Icons.schedule, Colors.deepOrange),
      ScheduleStatus.cancelled => (l10n.statusCancelled, Icons.cancel_outlined, Colors.red),
    };
    return Chip(
      avatar: Icon(icon, size: 18, color: color),
      label: Text(label),
      side: BorderSide(color: color),
    );
  }
}
