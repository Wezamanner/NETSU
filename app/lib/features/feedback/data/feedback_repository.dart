import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final feedbackRepositoryProvider = Provider<FeedbackRepository>(
  (ref) => FeedbackRepository(Supabase.instance.client),
);

class FeedbackRepository {
  FeedbackRepository(this._client);

  final SupabaseClient _client;

  Future<void> send({required String comment, required String kind, required int rating}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw StateError('signed out');
    await _client.from('feedback').insert({
      'resident_id': userId,
      'comment': comment,
      'type': kind,
      'rating': rating,
      'related_type': 'general',
    });
  }
}
