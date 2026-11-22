import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:netsu_app/features/auth/presentation/auth_controller.dart';
import 'package:netsu_app/features/reports/domain/garbage_report.dart';

final reportRepositoryProvider = Provider<ReportRepository>(
  (ref) => ReportRepository(Supabase.instance.client),
);

final myReportsProvider = FutureProvider<List<GarbageReport>>((ref) {
  final userId = ref.watch(authControllerProvider.select((s) => s.userId));
  if (userId == null) return Future.value(const []);
  return ref.watch(reportRepositoryProvider).mine();
});

final workerReportsProvider = FutureProvider<List<GarbageReport>>((ref) {
  final userId = ref.watch(authControllerProvider.select((s) => s.userId));
  if (userId == null) return Future.value(const []);
  return ref.watch(reportRepositoryProvider).assignedToWorker(userId);
});

class ReportRepository {
  ReportRepository(this._client);

  final SupabaseClient _client;

  Future<List<GarbageReport>> mine() async {
    final rows = await _client
        .from('garbage_reports')
        .select('id, description, status, address, lat, lng, admin_note, completed_at, created_at')
        .order('created_at', ascending: false)
        .limit(50);
    return [for (final row in rows) _fromRow(row)];
  }

  Future<List<GarbageReport>> assignedToWorker(String workerId) async {
    final rows = await _client
        .from('garbage_reports')
        .select('id, description, status, address, lat, lng, admin_note, completed_at, created_at')
        .eq('assigned_worker_id', workerId)
        .order('created_at', ascending: false)
        .limit(50);
    return [for (final row in rows) _fromRow(row)];
  }

  GarbageReport _fromRow(Map<String, dynamic> row) {
    return GarbageReport(
      id: row['id'] as String,
      description: row['description'] as String,
      status: row['status'] as String,
      createdAt: DateTime.parse(row['created_at'] as String),
      address: row['address'] as String?,
      lat: (row['lat'] as num?)?.toDouble(),
      lng: (row['lng'] as num?)?.toDouble(),
      adminNote: row['admin_note'] as String?,
      completedAt: row['completed_at'] == null ? null : DateTime.parse(row['completed_at'] as String),
    );
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
