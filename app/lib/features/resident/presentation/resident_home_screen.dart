import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:netsu_app/core/l10n/generated/app_localizations.dart';
import 'package:netsu_app/core/utils/load_error.dart';
import 'package:netsu_app/core/widgets/state_views.dart';
import 'package:netsu_app/features/auth/presentation/auth_controller.dart';
import 'package:netsu_app/features/notifications/data/notification_repository.dart';
import 'package:netsu_app/features/profile/data/profile_repository.dart';
import 'package:netsu_app/features/schedules/data/schedule_repository.dart';
import 'package:netsu_app/features/schedules/domain/area_schedule.dart';
import 'package:netsu_app/features/schedules/presentation/schedule_card.dart';

class ResidentHomeScreen extends ConsumerWidget {
  const ResidentHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final schemaError = ref.watch(authControllerProvider).schemaError;
    final schedules = ref.watch(residentSchedulesProvider);
    final profile = ref.watch(profileProvider).asData?.value;
    final unread = ref.watch(unreadNoticesCountProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(residentSchedulesProvider);
        ref.invalidate(profileProvider);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.nextCollection, style: theme.textTheme.headlineSmall),
                    if (profile?.kebeleCode != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${profile!.kebeleCode} · ${profile.areaName ?? ''}',
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ],
                ),
              ),
              if (profile != null && profile.areaId == null)
                TextButton.icon(
                  onPressed: () => context.go('/resident/profile'),
                  icon: const Icon(Icons.location_city_outlined, size: 18),
                  label: Text(l10n.changeKebele),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (schemaError) Text(l10n.schemaBanner),
          schedules.when(
            loading: () => const SizedBox(height: 200, child: LoadingView()),
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
          const SizedBox(height: 24),
          Text(l10n.quickActions, style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.report_outlined,
                  label: l10n.reportGarbage,
                  onTap: () => context.go('/resident/report'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.calendar_month_outlined,
                  label: l10n.viewCalendar,
                  onTap: () => context.go('/resident/calendar'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _QuickActionCard(
            icon: Icons.notifications_outlined,
            label: unread > 0 ? '${l10n.navNotifications} ($unread)' : l10n.navNotifications,
            onTap: () => context.go('/resident/notifications'),
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Row(
            children: [
              Icon(icon, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
