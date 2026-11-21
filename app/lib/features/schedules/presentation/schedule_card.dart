import 'package:material_ui/material_ui.dart';
import 'package:netsu_app/core/l10n/generated/app_localizations.dart';
import 'package:netsu_app/core/utils/addis_time.dart';
import 'package:netsu_app/core/widgets/status_chip.dart';
import 'package:netsu_app/features/schedules/domain/area_schedule.dart';

class ScheduleCard extends StatelessWidget {
  const ScheduleCard({required this.schedule, this.footer, super.key});

  final AreaSchedule schedule;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.expectedLabel, style: theme.textTheme.labelLarge),
            const SizedBox(height: 4),
            Text(
              '${AddisTime.formatDate(schedule.expectedStart)} · ${AddisTime.formatTime(schedule.expectedStart)}',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(schedule.areaName),
            const SizedBox(height: 8),
            Text(l10n.arrivalMayVary, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 12),
            StatusChip(status: schedule.status),
            if (footer != null) ...[const SizedBox(height: 12), footer!],
          ],
        ),
      ),
    );
  }
}
