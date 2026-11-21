import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:netsu_app/features/auth/presentation/auth_controller.dart';
import 'package:netsu_app/features/notifications/domain/app_notice.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) => NotificationRepository(Supabase.instance.client),
);

/// Streams the signed-in user's in-app notifications in real time.
final noticesProvider = StreamProvider<List<AppNotice>>((ref) {
  final userId = ref.watch(authControllerProvider.select((s) => s.userId));
  if (userId == null) return Stream.value(const []);
  return ref.watch(notificationRepositoryProvider).watchMine(userId);
});

final unreadNoticesCountProvider = Provider<int>((ref) {
  final notices = ref.watch(noticesProvider).asData?.value ?? const <AppNotice>[];
  return notices.where((n) => !n.isRead).length;
});

class NotificationRepository {
  NotificationRepository(this._client);

  final SupabaseClient _client;

  Stream<List<AppNotice>> watchMine(String userId) {
    return _client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('recipient_id', userId)
        .order('created_at', ascending: false)
        .limit(50)
        .map((rows) => [
              for (final row in rows)
                if (row['channel'] == 'in_app' && row['delivery_status'] != 'cancelled')
                  AppNotice(
                    id: row['id'] as String,
                    title: row['title'] as String,
                    message: row['message'] as String,
                    isRead: row['is_read'] as bool? ?? false,
                    createdAt: DateTime.parse(row['created_at'] as String),
                  ),
            ]);
  }

  Future<void> markRead(String id) {
    return _client.from('notifications').update({
      'is_read': true,
      'read_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', id);
  }

  Future<void> markAllRead() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    await _client
        .from('notifications')
        .update({
          'is_read': true,
          'read_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('recipient_id', userId)
        .eq('is_read', false);
  }
}
