import 'package:material_ui/material_ui.dart';
import 'package:latlong2/latlong.dart';
import 'package:netsu_app/core/map/osrm_route.dart';
import 'package:netsu_app/core/widgets/osm_map_view.dart';

/// Route stops with an OSRM driving line when the public router answers.
class DrivingRouteMap extends StatefulWidget {
  const DrivingRouteMap({required this.stops, this.height = 240, super.key});

  final List<LatLng> stops;
  final double height;

  @override
  State<DrivingRouteMap> createState() => _DrivingRouteMapState();
}

class _DrivingRouteMapState extends State<DrivingRouteMap> {
  List<LatLng>? _line;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(DrivingRouteMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stops != widget.stops) _load();
  }

  Future<void> _load() async {
    final line = await OsrmRoute.drivingLine(widget.stops);
    if (!mounted) return;
    setState(() => _line = line);
  }

  @override
  Widget build(BuildContext context) {
    final stops = widget.stops;
    final center = stops.isEmpty ? const LatLng(7.6667, 36.8333) : stops.first;
    return SizedBox(
      height: widget.height,
      child: Stack(
        children: [
          OsmMapView(center: center, points: stops, line: _line ?? stops),
          if (_line == null && stops.length > 1)
            const Positioned(top: 12, right: 12, child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))),
        ],
      ),
    );
  }
}
