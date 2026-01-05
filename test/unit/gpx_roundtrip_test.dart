import 'package:flutter_test/flutter_test.dart';
import 'package:gpx/gpx.dart';

void main() {
  group('GPX Round-trip', () {
    test('parse → modify → write → parse preserves data', () {
      // Original GPX XML
      const originalXml = '''<?xml version="1.0" encoding="UTF-8"?>
<gpx version="1.1" creator="test">
  <trk>
    <name>Test Track</name>
    <trkseg>
      <trkpt lat="37.7749" lon="-122.4194">
        <ele>100.0</ele>
      </trkpt>
      <trkpt lat="37.7750" lon="-122.4195">
        <ele>105.0</ele>
      </trkpt>
      <trkpt lat="37.7751" lon="-122.4196">
        <ele>110.0</ele>
      </trkpt>
    </trkseg>
  </trk>
</gpx>''';

      // Parse
      final gpx1 = GpxReader().fromString(originalXml);
      expect(gpx1.trks.length, equals(1));
      expect(gpx1.trks[0].trksegs.length, equals(1));
      expect(gpx1.trks[0].trksegs[0].trkpts.length, equals(3));

      // Modify - change second point
      final track = gpx1.trks[0];
      final segment = track.trksegs[0];
      final originalPoint = segment.trkpts[1];
      segment.trkpts[1] = Wpt(
        lat: 37.7755,
        lon: -122.4199,
        ele: 108.0,
        name: originalPoint.name,
        desc: originalPoint.desc,
      );

      // Write
      final xml = GpxWriter().asString(gpx1, pretty: true);
      expect(xml, isNotEmpty);

      // Parse again
      final gpx2 = GpxReader().fromString(xml);
      expect(gpx2.trks.length, equals(1));
      expect(gpx2.trks[0].trksegs.length, equals(1));
      expect(gpx2.trks[0].trksegs[0].trkpts.length, equals(3));

      // Verify modification persisted
      final modifiedPoint = gpx2.trks[0].trksegs[0].trkpts[1];
      expect(modifiedPoint.lat, equals(37.7755));
      expect(modifiedPoint.lon, equals(-122.4199));
      expect(modifiedPoint.ele, equals(108.0));

      // Verify other points unchanged
      final firstPoint = gpx2.trks[0].trksegs[0].trkpts[0];
      expect(firstPoint.lat, equals(37.7749));
      expect(firstPoint.lon, equals(-122.4194));
      expect(firstPoint.ele, equals(100.0));

      final lastPoint = gpx2.trks[0].trksegs[0].trkpts[2];
      expect(lastPoint.lat, equals(37.7751));
      expect(lastPoint.lon, equals(-122.4196));
      expect(lastPoint.ele, equals(110.0));
    });

    test('handles routes correctly', () {
      const routeXml = '''<?xml version="1.0" encoding="UTF-8"?>
<gpx version="1.1" creator="test">
  <rte>
    <name>Test Route</name>
    <rtept lat="37.0" lon="-122.0">
      <ele>50.0</ele>
    </rtept>
    <rtept lat="38.0" lon="-121.0">
      <ele>60.0</ele>
    </rtept>
  </rte>
</gpx>''';

      final gpx1 = GpxReader().fromString(routeXml);
      expect(gpx1.rtes.length, equals(1));
      expect(gpx1.rtes[0].rtepts.length, equals(2));

      final xml = GpxWriter().asString(gpx1, pretty: true);
      final gpx2 = GpxReader().fromString(xml);

      expect(gpx2.rtes.length, equals(1));
      expect(gpx2.rtes[0].rtepts.length, equals(2));
      expect(gpx2.rtes[0].rtepts[0].lat, equals(37.0));
      expect(gpx2.rtes[0].rtepts[1].lat, equals(38.0));
    });
  });
}
