import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:netsu_app/core/utils/phone_number.dart';
import 'package:netsu_app/features/areas/domain/service_area.dart';

class AuthRepository {
  AuthRepository(this._client);

  final SupabaseClient _client;

  Future<void> signIn({required String phone, required String password}) {
    return _client.auth.signInWithPassword(
      email: PhoneNumber.syntheticEmail(phone),
      password: password,
    );
  }

  Future<void> signUp({
    required String fullName,
    required String phone,
    required String password,
    required String areaId,
    required String address,
    required String languageCode,
  }) {
    return _client.auth.signUp(
      email: PhoneNumber.syntheticEmail(phone),
      password: password,
      data: {
        'full_name': fullName,
        'phone': phone,
        'area_id': areaId,
        'address': address,
        'preferred_language': languageCode,
      },
    );
  }

  Future<void> signOut() => _client.auth.signOut();

  Future<List<ServiceArea>> activeAreas() async {
    final rows = await _client
        .from('service_areas')
        .select('id, name, kebele_code')
        .eq('active', true)
        .order('kebele_code');
    return [
      for (final row in rows)
        ServiceArea(
          id: row['id'] as String,
          name: row['name'] as String,
          kebeleCode: row['kebele_code'] as String,
        ),
    ];
  }
}
