import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netsu_app/core/l10n/generated/app_localizations.dart';
import 'package:netsu_app/core/utils/addis_time.dart';
import 'package:netsu_app/core/utils/load_error.dart';
import 'package:netsu_app/core/widgets/state_views.dart';
import 'package:netsu_app/features/notifications/data/notification_repository.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final notices = ref.watch(noticesProvider);
    final theme = Theme.of(context);
    return notices.when(
      loading: () => const LoadingView(),
      error: (error, _) => ErrorView(
        message: loadErrorMessage(error, l10n),
        onRetry: () => ref.invalidate(noticesProvider),
      ),
      data: (items) {
        if (items.isEmpty) {
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(noticesProvider),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              children: [
                Text(l10n.navNotifications, style: theme.textTheme.headlineSmall),
                const SizedBox(height: 24),
                EmptyState(title: l10n.emptyTitle, body: l10n.emptyBody),
              ],
            ),
          );
        }
        final hasUnread = items.any((n) => !n.isRead);
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(noticesProvider),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            itemCount: items.length + 1,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Row(
                  children: [
                    Expanded(child: Text(l10n.navNotifications, style: theme.textTheme.headlineSmall)),
                    if (hasUnread)
                      TextButton(
                        onPressed: () async {
                          await ref.read(notificationRepositoryProvider).markAllRead();
                        },
                        child: Text(l10n.markAllRead),
                      ),
                  ],
                );
              }
              final notice = items[index - 1];
              return Card(
                color: notice.isRead
                    ? null
                    : theme.colorScheme.primaryContainer.withValues(alpha: 0.25),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            notice.isRead ? Icons.drafts_outlined : Icons.mark_email_unread_outlined,
                            size: 20,
                            color: notice.isRead ? theme.colorScheme.onSurfaceVariant : theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              notice.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: notice.isRead ? FontWeight.w500 : FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(notice.message),
                      const SizedBox(height: 8),
                      Text(
                        '${AddisTime.formatDate(notice.createdAt)} · ${AddisTime.formatTime(notice.createdAt)}',
                        style: theme.textTheme.bodySmall,
                      ),
                      if (!notice.isRead)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: () async {
                              await ref.read(notificationRepositoryProvider).markRead(notice.id);
                            },
                            child: Text(l10n.markRead),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
