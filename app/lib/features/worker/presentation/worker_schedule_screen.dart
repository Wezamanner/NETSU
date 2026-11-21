import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netsu_app/core/l10n/generated/app_localizations.dart';
import 'package:netsu_app/core/utils/load_error.dart';
import 'package:netsu_app/core/widgets/state_views.dart';
import 'package:netsu_app/features/schedules/data/schedule_repository.dart';
import 'package:netsu_app/features/schedules/presentation/schedule_card.dart';

class WorkerScheduleScreen extends ConsumerWidget {
  const WorkerScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final schedules = ref.watch(workerSchedulesProvider);
    return schedules.when(
      loading: () => const LoadingView(),
      error: (error, _) => ErrorView(
        message: loadErrorMessage(error, l10n),
        onRetry: () => ref.invalidate(workerSchedulesProvider),
      ),
      data: (items) {
        if (items.isEmpty) return EmptyState(title: l10n.navSchedule, body: l10n.workerTodayEmpty);
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(workerSchedulesProvider),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            children: [
              Text(l10n.navSchedule, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              for (final item in items) ...[ScheduleCard(schedule: item), const SizedBox(height: 12)],
            ],
          ),
        );
      },
    );
  }
}
