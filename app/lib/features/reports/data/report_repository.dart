import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:netsu_app/features/reports/domain/garbage_report.dart';

final reportRepositoryProvider = Provider<ReportRepository>(
  (ref) => ReportRepository(Supabase.instance.client),
);

final myReportsProvider = FutureProvider<List<GarbageReport>>((ref) {
  return ref.watch(reportRepositoryProvider).mine();
});

class ReportRepository {
  ReportRepository(this._client);

  final SupabaseClient _client;

  Future<List<GarbageReport>> mine() async {
    final rows = await _client
        .from('garbage_reports')
        .select('id, description, status, address, lat, lng, created_at')
        .order('created_at', ascending: false);
    return [
      for (final row in rows)
        GarbageReport(
          id: row['id'] as String,
          description: row['description'] as String,
          status: row['status'] as String,
          createdAt: DateTime.parse(row['created_at'] as String),
          address: row['address'] as String?,
          lat: (row['lat'] as num?)?.toDouble(),
          lng: (row['lng'] as num?)?.toDouble(),
        ),
    ];
  }

  Future<void> submit({
    required String areaId,
    required String description,
    required String address,
    required double lat,
    required double lng,
    XFile? photo,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw StateError('signed out');
    String? imagePath;
    if (photo != null) {
      final bytes = await photo.readAsBytes();
      if (bytes.length > 5 * 1024 * 1024) throw StateError('large');
      imagePath = '$userId/${DateTime.now().millisecondsSinceEpoch}.jpg';
      await _client.storage.from('report-images').uploadBinary(
        imagePath,
        bytes,
        fileOptions: const FileOptions(contentType: 'image/jpeg'),
      );
    }
    await _client.from('garbage_reports').insert({
      'resident_id': userId,
      'area_id': areaId,
      'description': description,
      'address': address,
      'lat': lat,
      'lng': lng,
      'image_path': imagePath,
    });
  }
}
