import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:netsu_app/features/profile/domain/user_profile.dart';

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(Supabase.instance.client),
);

final profileProvider = FutureProvider<UserProfile>((ref) {
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
        .select('id, full_name, phone, role, address, preferred_language, area_id, lat, lng, service_areas(name, kebele_code)')
        .eq('id', userId)
        .single();
    final area = row['service_areas'];
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
    );
  }

  Future<void> saveLocation({required double lat, required double lng}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw StateError('signed out');
    await _client.from('profiles').update({'lat': lat, 'lng': lng}).eq('id', userId);
  }
}
