import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netsu_app/core/l10n/generated/app_localizations.dart';
import 'package:netsu_app/core/utils/load_error.dart';
import 'package:netsu_app/core/widgets/state_views.dart';
import 'package:netsu_app/features/auth/presentation/auth_controller.dart';
import 'package:netsu_app/features/schedules/data/schedule_repository.dart';
import 'package:netsu_app/features/schedules/domain/area_schedule.dart';
import 'package:netsu_app/features/schedules/presentation/schedule_card.dart';

class ResidentHomeScreen extends ConsumerWidget {
  const ResidentHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final schemaError = ref.watch(authControllerProvider).schemaError;
    final schedules = ref.watch(residentSchedulesProvider);
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(residentSchedulesProvider),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        children: [
          Text(l10n.nextCollection, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          if (schemaError) Text(l10n.schemaBanner),
          schedules.when(
            loading: () => const SizedBox(height: 240, child: LoadingView()),
            error: (error, _) => ErrorView(
              message: loadErrorMessage(error, l10n),
              onRetry: () => ref.invalidate(residentSchedulesProvider),
            ),
            data: (items) {
              final next = nextCollection(items, DateTime.now());
              if (next == null) {
                return EmptyState(title: l10n.emptyTitle, body: l10n.noNextCollection);
              }
              return ScheduleCard(schedule: next);
            },
          ),
        ],
      ),
    );
  }
}
