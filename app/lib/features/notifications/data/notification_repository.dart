import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:netsu_app/features/notifications/domain/app_notice.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) => NotificationRepository(Supabase.instance.client),
);

final noticesProvider = FutureProvider<List<AppNotice>>((ref) {
  return ref.watch(notificationRepositoryProvider).mine();
});

class NotificationRepository {
  NotificationRepository(this._client);

  final SupabaseClient _client;

  Future<List<AppNotice>> mine() async {
    final rows = await _client
        .from('notifications')
        .select('id, title, message, is_read, created_at')
        .order('created_at', ascending: false)
        .limit(50);
    return [
      for (final row in rows)
        AppNotice(
          id: row['id'] as String,
          title: row['title'] as String,
          message: row['message'] as String,
          isRead: row['is_read'] as bool? ?? false,
          createdAt: DateTime.parse(row['created_at'] as String),
        ),
    ];
  }

  Future<void> markRead(String id) {
    return _client.from('notifications').update({
      'is_read': true,
      'read_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', id);
  }
}
