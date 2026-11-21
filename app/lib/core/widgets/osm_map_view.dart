import 'package:material_ui/material_ui.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// OpenStreetMap view. Public tiles, no API key. Not a live truck map.
class OsmMapView extends StatelessWidget {
  const OsmMapView({
    this.center = const LatLng(7.6667, 36.8333),
    this.zoom = 14,
    this.points = const [],
    this.line = const [],
    this.onTap,
    super.key,
  });

  final LatLng center;
  final double zoom;
  final List<LatLng> points;
  final List<LatLng> line;
  final ValueChanged<LatLng>? onTap;

  @override
  Widget build(BuildContext context) {
    final markers = points.isEmpty ? [center] : points;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: FlutterMap(
        options: MapOptions(
          initialCenter: center,
          initialZoom: zoom,
          onTap: onTap == null ? null : (_, point) => onTap!(point),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'et.gov.jimma.waste.netsu_app',
          ),
          if (line.length > 1) PolylineLayer(polylines: [Polyline(points: line, color: const Color(0xFF0F6B4C), strokeWidth: 4)]),
          CircleLayer(
            circles: [
              for (final point in markers)
                CircleMarker(
                  point: point,
                  radius: 8,
                  color: const Color(0xFF0F6B4C),
                  borderStrokeWidth: 2,
                  borderColor: Colors.white,
                ),
            ],
          ),
          const RichAttributionWidget(attributions: [TextSourceAttribution('OpenStreetMap contributors')]),
        ],
      ),
    );
  }
}
