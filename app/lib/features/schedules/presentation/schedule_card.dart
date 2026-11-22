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
    final scheme = theme.colorScheme;
    final wall = AddisTime.wallClock(schedule.expectedStart);
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 72,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text(
                        months[wall.month - 1].toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.onPrimary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                      ),
                      Text(
                        '${wall.day}',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: scheme.onPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.expectedLabel, style: theme.textTheme.labelLarge?.copyWith(color: scheme.onSurfaceVariant)),
                      const SizedBox(height: 2),
                      Text(AddisTime.formatTime(schedule.expectedStart), style: theme.textTheme.headlineSmall),
                      const SizedBox(height: 4),
                      Text(schedule.areaName, style: theme.textTheme.bodyLarge),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.info_outline, size: 18, color: scheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    l10n.arrivalMayVary,
                    style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
            if (schedule.changeReason != null && schedule.changeReason!.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.secondaryContainer.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(schedule.changeReason!.trim(), style: theme.textTheme.bodyMedium),
              ),
            ],
            const SizedBox(height: 12),
            StatusChip(status: schedule.status),
            if (footer != null) ...[const SizedBox(height: 12), footer!],
          ],
        ),
      ),
    );
  }
}
