import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Public OSRM driving geometry. Cached per stop list. Falls back to the stops
/// themselves when the service is unavailable.
class OsrmRoute {
  const OsrmRoute._();

  static const endpoint = 'https://router.project-osrm.org/route/v1/driving';
  static const _userAgent = 'NetsuJimmaWaste/1.0 (Jimma municipal pilot)';
  static final _cache = <String, List<LatLng>>{};

  static Future<List<LatLng>> drivingLine(List<LatLng> stops) async {
    if (stops.length < 2) return stops;
    final key = stops.map((p) => '${p.latitude.toStringAsFixed(5)},${p.longitude.toStringAsFixed(5)}').join(';');
    final cached = _cache[key];
    if (cached != null) return cached;
    try {
      final path = stops.map((p) => '${p.longitude},${p.latitude}').join(';');
      final uri = Uri.parse('$endpoint/$path?overview=full&geometries=polyline');
      final response = await http.get(uri, headers: {
        'Accept': 'application/json',
        if (!kIsWeb) 'User-Agent': _userAgent,
      });
      if (response.statusCode != 200) return stops;
      final encoded = _encodedGeometry(response.body);
      if (encoded == null) return stops;
      final line = decodePolyline(encoded);
      if (line.length < 2) return stops;
      _cache[key] = line;
      return line;
    } catch (_) {
      return stops;
    }
  }

  static String? _encodedGeometry(String body) {
    const marker = '"geometry":"';
    final start = body.indexOf(marker);
    if (start < 0) return null;
    final from = start + marker.length;
    final end = body.indexOf('"', from);
    if (end < 0) return null;
    return body.substring(from, end);
  }
}

/// Google/OSRM polyline, precision 1e5.
List<LatLng> decodePolyline(String encoded) {
  final points = <LatLng>[];
  var index = 0;
  var lat = 0;
  var lng = 0;
  while (index < encoded.length) {
    final dLat = _delta(encoded, index);
    index = dLat.$2;
    lat += dLat.$1;
    final dLng = _delta(encoded, index);
    index = dLng.$2;
    lng += dLng.$1;
    points.add(LatLng(lat / 1e5, lng / 1e5));
  }
  return points;
}

(int, int) _delta(String encoded, int index) {
  var shift = 0;
  var result = 0;
  int byte;
  do {
    byte = encoded.codeUnitAt(index++) - 63;
    result |= (byte & 0x1f) << shift;
    shift += 5;
  } while (byte >= 0x20 && index < encoded.length);
  final delta = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
  return (delta, index);
}
