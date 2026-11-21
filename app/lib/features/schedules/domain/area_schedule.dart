import 'package:netsu_app/features/schedules/domain/schedule_status.dart';

class MapStop {
  const MapStop({required this.name, required this.lat, required this.lng, required this.order});

  final String name;
  final double lat;
  final double lng;
  final int order;
}

class AreaSchedule {
  const AreaSchedule({
    required this.id,
    required this.expectedStart,
    required this.status,
    required this.areaName,
    this.expectedEnd,
    this.changeReason,
    this.stops = const [],
  });

  final String id;
  final DateTime expectedStart;
  final DateTime? expectedEnd;
  final ScheduleStatus status;
  final String areaName;
  final String? changeReason;
  final List<MapStop> stops;
}

List<MapStop> parseStops(Object? raw) {
  if (raw is! List) return const [];
  final stops = <MapStop>[];
  for (final item in raw) {
    if (item is! Map) continue;
    final lat = item['lat'];
    final lng = item['lng'];
    if (lat is! num || lng is! num) continue;
    final order = item['order'];
    stops.add(
      MapStop(
        name: item['name'] is String ? item['name'] as String : '',
        lat: lat.toDouble(),
        lng: lng.toDouble(),
        order: order is num ? order.toInt() : stops.length,
      ),
    );
  }
  stops.sort((a, b) => a.order.compareTo(b.order));
  return stops;
}

/// Next collection a resident should see. Completed and cancelled are skipped.
AreaSchedule? nextCollection(List<AreaSchedule> items, DateTime now) {
  final upcoming = [
    for (final item in items)
      if (item.status != ScheduleStatus.completed &&
          item.status != ScheduleStatus.cancelled &&
          !item.expectedStart.isBefore(now.subtract(const Duration(hours: 8))))
        item,
  ]..sort((a, b) => a.expectedStart.compareTo(b.expectedStart));
  if (upcoming.isEmpty) return null;
  return upcoming.first;
}
