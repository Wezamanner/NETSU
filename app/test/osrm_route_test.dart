import 'package:flutter_test/flutter_test.dart';
import 'package:netsu_app/core/map/osrm_route.dart';

void main() {
  test('decodes an OSRM polyline', () {
    final points = decodePolyline(r'_p~iF~ps|U_ulLnnqC_mqNvxq`@');
    expect(points.length, 3);
    expect(points.first.latitude, closeTo(38.5, 0.001));
    expect(points.first.longitude, closeTo(-120.2, 0.001));
    expect(points.last.latitude, closeTo(43.252, 0.001));
    expect(points.last.longitude, closeTo(-126.453, 0.001));
  });

  test('an empty polyline has no points', () {
    expect(decodePolyline(''), isEmpty);
  });
}
