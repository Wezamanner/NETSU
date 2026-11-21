import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:netsu_app/core/l10n/generated/app_localizations.dart';
import 'package:netsu_app/core/location/device_location.dart';
import 'package:netsu_app/core/utils/addis_time.dart';
import 'package:netsu_app/core/utils/load_error.dart';
import 'package:netsu_app/core/widgets/osm_map_view.dart';
import 'package:netsu_app/core/widgets/state_views.dart';
import 'package:netsu_app/features/reports/data/report_repository.dart';
import 'package:netsu_app/features/schedules/data/schedule_repository.dart';
import 'package:netsu_app/features/schedules/domain/area_schedule.dart';
import 'package:netsu_app/features/schedules/domain/schedule_status.dart';
import 'package:netsu_app/features/schedules/presentation/schedule_card.dart';

class WorkerTodayScreen extends ConsumerWidget {
  const WorkerTodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final schedules = ref.watch(workerSchedulesProvider);
    final reports = ref.watch(workerReportsProvider);

    return schedules.when(
      loading: () => const LoadingView(),
      error: (error, _) => ErrorView(
        message: loadErrorMessage(error, l10n),
        onRetry: () => ref.invalidate(workerSchedulesProvider),
      ),
      data: (items) {
        final today = items.where((item) => AddisTime.isSameDay(item.expectedStart, DateTime.now())).toList();
        final assignedReports = reports.asData?.value ?? const [];

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(workerSchedulesProvider);
            ref.invalidate(workerReportsProvider);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            children: [
              Text(l10n.navToday, style: theme.textTheme.headlineSmall),
              const SizedBox(height: 16),
              if (today.isEmpty)
                EmptyState(title: l10n.navToday, body: l10n.workerTodayEmpty)
              else
                for (final item in today) ...[
                  ScheduleCard(
                    schedule: item,
                    footer: _Actions(schedule: item),
                  ),
                  if (item.stops.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 220,
                      child: OsmMapView(
                        center: LatLng(item.stops.first.lat, item.stops.first.lng),
                        points: [for (final stop in item.stops) LatLng(stop.lat, stop.lng)],
                        line: [for (final stop in item.stops) LatLng(stop.lat, stop.lng)],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(l10n.mapDisclaimer),
                  ],
                  const SizedBox(height: 20),
                ],
              if (assignedReports.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(l10n.assignedReports, style: theme.textTheme.titleLarge),
                const SizedBox(height: 12),
                for (final r in assignedReports) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.description, style: theme.textTheme.titleMedium),
                          const SizedBox(height: 4),
                          Text(
                            '${r.status} · ${AddisTime.formatDate(r.createdAt)}',
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                          if (r.address != null && r.address!.trim().isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(r.address!),
                          ],
                          if (r.adminNote != null && r.adminNote!.trim().isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text('${l10n.adminNoteLabel}: ${r.adminNote!}', style: theme.textTheme.bodySmall),
                          ],
                          if (r.lat != null && r.lng != null) ...[
                            const SizedBox(height: 10),
                            OutlinedButton(
                              onPressed: () => _openDirections(context, r.lat!, r.lng!),
                              child: Text(l10n.openDirections),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ],
          ),
        );
      },
    );
  }
}

Future<void> _openDirections(BuildContext context, double lat, double lng) async {
  final here = await DeviceLocation.ask(context);
  final uri = here == null
      ? Uri.https('www.openstreetmap.org', '/', {'mlat': '$lat', 'mlon': '$lng'})
      : Uri.https('www.openstreetmap.org', '/directions', {
          'engine': 'fossgis_osrm_car',
          'route': '${here.latitude},${here.longitude};$lat,$lng',
        });
  await launchUrl(uri, webOnlyWindowName: '_blank');
}

class _Actions extends ConsumerWidget {
  const _Actions({required this.schedule});

  final AreaSchedule schedule;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final actions = ScheduleStatusMachine.workerActions(schedule.status);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final action in actions) ...[
          FilledButton(
            onPressed: () => _apply(context, ref, action),
            child: Text(_label(l10n, action)),
          ),
          const SizedBox(height: 8),
        ],
        if (schedule.stops.isNotEmpty)
          OutlinedButton(
            onPressed: () => _openDirections(context, schedule.stops.first.lat, schedule.stops.first.lng),
            child: Text(l10n.openDirections),
          ),
      ],
    );
  }

  Future<void> _apply(BuildContext context, WidgetRef ref, ScheduleStatus next) async {
    final l10n = AppLocalizations.of(context);
    String? reason;
    String? completionNote;
    if (next == ScheduleStatus.delayed) {
      reason = await _promptText(context, l10n, title: l10n.delayReason, hint: l10n.delayReason);
      if (reason == null || reason.trim().isEmpty) return;
    } else if (next == ScheduleStatus.completed) {
      completionNote = await _promptText(
        context,
        l10n,
        title: l10n.completionNoteTitle,
        hint: l10n.completionNoteHint,
        allowEmpty: true,
      );
      if (completionNote == null) return;
    }
    try {
      await ref.read(scheduleRepositoryProvider).updateStatus(
        scheduleId: schedule.id,
        status: next,
        reason: reason,
        completionNote: completionNote,
      );
      ref.invalidate(workerSchedulesProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.statusUpdated)));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.statusFailed)));
      }
    }
  }

  Future<String?> _promptText(
    BuildContext context,
    AppLocalizations l10n, {
    required String title,
    required String hint,
    bool allowEmpty = false,
  }) async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(controller: controller, maxLines: 3, decoration: InputDecoration(labelText: hint)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.notNow)),
            FilledButton(
              onPressed: () {
                final text = controller.text.trim();
                if (!allowEmpty && text.isEmpty) return;
                Navigator.pop(context, text);
              },
              child: Text(l10n.save),
            ),
          ],
        );
      },
    );
    controller.dispose();
    return value;
  }

  String _label(AppLocalizations l10n, ScheduleStatus status) {
    return switch (status) {
      ScheduleStatus.onTheWay => l10n.statusOnTheWay,
      ScheduleStatus.inProgress => l10n.statusInProgress,
      ScheduleStatus.completed => l10n.statusCompleted,
      ScheduleStatus.delayed => l10n.statusDelayed,
      _ => l10n.save,
    };
  }
}
