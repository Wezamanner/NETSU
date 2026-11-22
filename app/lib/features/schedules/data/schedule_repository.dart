import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:netsu_app/features/auth/presentation/auth_controller.dart';
import 'package:netsu_app/features/schedules/domain/area_schedule.dart';
import 'package:netsu_app/features/schedules/domain/schedule_status.dart';

final scheduleRepositoryProvider = Provider<ScheduleRepository>(
  (ref) => ScheduleRepository(Supabase.instance.client),
);

final residentSchedulesProvider = FutureProvider<List<AreaSchedule>>((ref) {
  final userId = ref.watch(authControllerProvider.select((s) => s.userId));
  if (userId == null) return Future.value(const []);
  return ref.watch(scheduleRepositoryProvider).forResident();
});

final workerSchedulesProvider = FutureProvider<List<AreaSchedule>>((ref) {
  final userId = ref.watch(authControllerProvider.select((s) => s.userId));
  if (userId == null) return Future.value(const []);
  return ref.watch(scheduleRepositoryProvider).forWorker(userId);
});

class ScheduleRepository {
  ScheduleRepository(this._client);

  final SupabaseClient _client;

  Future<List<AreaSchedule>> forResident() async {
    final rows = await _client
        .from('collection_schedules')
        .select('id, expected_start, expected_end, status, change_reason, service_areas(name, kebele_code)')
        .neq('status', 'draft')
        .order('expected_start');
    return [for (final row in rows) _schedule(row, const [])];
  }

  Future<List<AreaSchedule>> forWorker(String userId) async {
    final links = await _client.from('schedule_workers').select('schedule_id').eq('worker_id', userId);
    final ids = [for (final row in links) row['schedule_id'] as String];
    if (ids.isEmpty) return const [];
    final rows = await _client
        .from('collection_schedules')
        .select('id, expected_start, expected_end, status, change_reason, route_id, service_areas(name, kebele_code)')
        .inFilter('id', ids)
        .order('expected_start');
    final routeIds = [for (final row in rows) if (row['route_id'] is String) row['route_id'] as String];
    final stopsByRoute = await _stops(routeIds);
    return [
      for (final row in rows) _schedule(row, stopsByRoute[row['route_id'] as String?] ?? const []),
    ];
  }

  Future<void> updateStatus({
    required String scheduleId,
    required ScheduleStatus status,
    String? reason,
    String? completionNote,
  }) async {
    final trimmedNote = completionNote?.trim();
    final params = <String, dynamic>{
      'target_schedule': scheduleId,
      'next_status': scheduleStatusToString(status),
      'reason': reason,
      'completion_note': (trimmedNote != null && trimmedNote.isNotEmpty) ? trimmedNote : null,
    };
    try {
      await _client.rpc('update_schedule_status', params: params);
    } on PostgrestException catch (e) {
      // Fallback only if the 4-arg migration has not been applied yet (PGRST202).
      if (e.code == 'PGRST202' && params.containsKey('completion_note')) {
        params.remove('completion_note');
        await _client.rpc('update_schedule_status', params: params);
      } else {
        rethrow;
      }
    }
  }

  Future<Map<String, List<MapStop>>> _stops(List<String> routeIds) async {
    if (routeIds.isEmpty) return const {};
    final rows = await _client.from('routes').select('id, stops').inFilter('id', routeIds);
    return {for (final row in rows) row['id'] as String: parseStops(row['stops'])};
  }

  AreaSchedule _schedule(Map<String, dynamic> row, List<MapStop> stops) {
    final area = row['service_areas'];
    final name = area is Map ? '${area['kebele_code'] ?? ''} · ${area['name'] ?? ''}'.trim() : '';
    return AreaSchedule(
      id: row['id'] as String,
      expectedStart: DateTime.parse(row['expected_start'] as String),
      expectedEnd: row['expected_end'] == null ? null : DateTime.parse(row['expected_end'] as String),
      status: scheduleStatusFromString(row['status'] as String) ?? ScheduleStatus.published,
      areaName: name,
      changeReason: row['change_reason'] as String?,
      stops: stops,
    );
  }
}
