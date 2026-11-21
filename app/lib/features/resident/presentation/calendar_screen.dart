import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netsu_app/core/l10n/generated/app_localizations.dart';
import 'package:netsu_app/core/utils/load_error.dart';
import 'package:netsu_app/core/widgets/state_views.dart';
import 'package:netsu_app/features/schedules/data/schedule_repository.dart';
import 'package:netsu_app/features/schedules/presentation/schedule_card.dart';

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final schedules = ref.watch(residentSchedulesProvider);
    return schedules.when(
      loading: () => const LoadingView(),
      error: (error, _) => ErrorView(
        message: loadErrorMessage(error, l10n),
        onRetry: () => ref.invalidate(residentSchedulesProvider),
      ),
      data: (items) {
        final now = DateTime.now();
        final upcoming = items.where((item) => !item.expectedStart.isBefore(now)).toList();
        final previous = items.where((item) => item.expectedStart.isBefore(now)).toList().reversed.toList();
        if (items.isEmpty) return EmptyState(title: l10n.emptyTitle, body: l10n.noNextCollection);
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(residentSchedulesProvider),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            children: [
              Text(l10n.navCalendar, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              Text(l10n.upcoming, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (upcoming.isEmpty) Text(l10n.noNextCollection),
              for (final item in upcoming) ...[ScheduleCard(schedule: item), const SizedBox(height: 12)],
              const SizedBox(height: 8),
              Text(l10n.previousCollections, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (previous.isEmpty) Text(l10n.emptyTitle),
              for (final item in previous) ...[ScheduleCard(schedule: item), const SizedBox(height: 12)],
            ],
          ),
        );
      },
    );
  }
}
