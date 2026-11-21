import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:netsu_app/features/auth/presentation/auth_controller.dart';
import 'package:netsu_app/features/profile/domain/user_profile.dart';

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(Supabase.instance.client),
);

final profileProvider = FutureProvider<UserProfile>((ref) {
  final userId = ref.watch(authControllerProvider.select((s) => s.userId));
  if (userId == null) throw StateError('signed out');
  return ref.watch(profileRepositoryProvider).mine();
});

class ProfileRepository {
  ProfileRepository(this._client);

  final SupabaseClient _client;

  Future<UserProfile> mine() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw StateError('signed out');
    final row = await _client
        .from('profiles')
        .select('id, full_name, phone, role, address, preferred_language, area_id, lat, lng, notification_prefs, service_areas(name, kebele_code)')
        .eq('id', userId)
        .single();
    final area = row['service_areas'];
    final rawPrefs = row['notification_prefs'];
    final prefs = <String, bool>{
      if (rawPrefs is Map)
        for (final entry in rawPrefs.entries)
          if (entry.key is String && entry.value is bool) entry.key as String: entry.value as bool,
    };
    return UserProfile(
      id: row['id'] as String,
      fullName: row['full_name'] as String,
      phone: row['phone'] as String,
      role: row['role'] as String,
      language: row['preferred_language'] as String? ?? 'en',
      address: row['address'] as String?,
      areaId: row['area_id'] as String?,
      areaName: area is Map ? area['name'] as String? : null,
      kebeleCode: area is Map ? area['kebele_code'] as String? : null,
      lat: (row['lat'] as num?)?.toDouble(),
      lng: (row['lng'] as num?)?.toDouble(),
      notificationPrefs: prefs,
    );
  }

  Future<void> saveLocation({required double lat, required double lng}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw StateError('signed out');
    await _client.from('profiles').update({'lat': lat, 'lng': lng}).eq('id', userId);
  }

  Future<void> updateArea(String areaId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw StateError('signed out');
    await _client.from('profiles').update({'area_id': areaId}).eq('id', userId);
  }

  Future<void> updateNotificationPrefs(Map<String, bool> prefs) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw StateError('signed out');
    final sanitized = <String, bool>{
      ...prefs,
      'sms': false, // SMS is disabled in MVP (AGENTS.md Rule 8).
    };
    await _client.from('profiles').update({'notification_prefs': sanitized}).eq('id', userId);
  }
}
