import 'package:flutter_test/flutter_test.dart';
import 'package:gpxer/domain/services/gpx_stats_service.dart';
import 'package:gpxer/domain/models/gpx_document.dart';
import 'package:gpxer/domain/models/active_path.dart';
import 'package:gpx/gpx.dart';
import 'dart:typed_data';

void main() {
  group('GpxStatsService', () {
    late GpxStatsService service;

    setUp(() {
      service = GpxStatsService();
    });

    test('computes stats for track segment with elevations', () {
      // Create a simple GPX document
      final gpx = Gpx();
      gpx.version = '1.1';
      gpx.creator = 'test';

      // Add a track with a segment
      final track = Trk();
      final segment = Trkseg();
      segment.trkpts = [
        Wpt(lat: 0, lon: 0, ele: 100),
        Wpt(lat: 0, lon: 1, ele: 150),
        Wpt(lat: 1, lon: 1, ele: 120),
      ];
      track.trksegs.add(segment);
      gpx.trks.add(track);

      final doc = GpxDocument(
        id: 'test-id',
        displayName: 'test.gpx',
        sourceBytes: Uint8List.fromList('test'.codeUnits),
        gpx: gpx,
        activePath: const ActivePath(
          type: ActivePathType.trackSegment,
          trackIndex: 0,
          segmentIndex: 0,
        ),
        openedAt: DateTime.now(),
      );

      final stats = service.computeStats(doc);

      // Verify basic stats
      expect(stats.pointCount, equals(3));
      expect(stats.totalDistanceMeters, greaterThan(0));
      expect(stats.totalDistanceMeters, greaterThan(200000)); // ~200km
      expect(stats.fileSizeBytes, equals(4));

      // Verify elevation stats
      expect(stats.minElevation, equals(100.0));
      expect(stats.maxElevation, equals(150.0));
      expect(stats.ascentMeters, equals(50.0)); // 0→1: +50
      expect(stats.descentMeters, equals(30.0)); // 1→2: -30

      // Verify bounds
      expect(stats.bounds, isNotNull);
      expect(stats.bounds!.minLat, equals(0.0));
      expect(stats.bounds!.maxLat, equals(1.0));
      expect(stats.bounds!.minLon, equals(0.0));
      expect(stats.bounds!.maxLon, equals(1.0));
    });

    test('handles route points correctly', () {
      final gpx = Gpx();
      gpx.version = '1.1';
      gpx.creator = 'test';

      final route = Rte();
      route.rtepts = [
        Wpt(lat: 37.0, lon: -122.0, ele: 50),
        Wpt(lat: 38.0, lon: -121.0, ele: 60),
      ];
      gpx.rtes.add(route);

      final doc = GpxDocument(
        id: 'test-id',
        displayName: 'test.gpx',
        sourceBytes: Uint8List.fromList('test'.codeUnits),
        gpx: gpx,
        activePath: const ActivePath(
          type: ActivePathType.route,
          routeIndex: 0,
        ),
        openedAt: DateTime.now(),
      );

      final stats = service.computeStats(doc);

      expect(stats.pointCount, equals(2));
      expect(stats.totalDistanceMeters, greaterThan(0));
      expect(stats.minElevation, equals(50.0));
      expect(stats.maxElevation, equals(60.0));
      expect(stats.ascentMeters, equals(10.0));
      expect(stats.descentMeters, equals(0.0));
    });

    test('handles missing elevations correctly', () {
      final gpx = Gpx();
      gpx.version = '1.1';
      gpx.creator = 'test';

      final track = Trk();
      final segment = Trkseg();
      segment.trkpts = [
        Wpt(lat: 0, lon: 0),
        Wpt(lat: 0, lon: 1),
        Wpt(lat: 1, lon: 1),
      ];
      track.trksegs.add(segment);
      gpx.trks.add(track);

      final doc = GpxDocument(
        id: 'test-id',
        displayName: 'test.gpx',
        sourceBytes: Uint8List.fromList('test'.codeUnits),
        gpx: gpx,
        activePath: const ActivePath(
          type: ActivePathType.trackSegment,
          trackIndex: 0,
          segmentIndex: 0,
        ),
        openedAt: DateTime.now(),
      );

      final stats = service.computeStats(doc);

      expect(stats.pointCount, equals(3));
      expect(stats.totalDistanceMeters, greaterThan(0));
      expect(stats.minElevation, isNull);
      expect(stats.maxElevation, isNull);
      expect(stats.ascentMeters, isNull);
      expect(stats.descentMeters, isNull);
    });

    test('formats distance correctly', () {
      final gpx = Gpx();
      gpx.version = '1.1';
      final track = Trk();
      final segment = Trkseg();
      segment.trkpts = [Wpt(lat: 0, lon: 0), Wpt(lat: 0, lon: 0.001)];
      track.trksegs.add(segment);
      gpx.trks.add(track);

      final doc = GpxDocument(
        id: 'test',
        displayName: 'test.gpx',
        sourceBytes: Uint8List(0),
        gpx: gpx,
        activePath: const ActivePath(
          type: ActivePathType.trackSegment,
          trackIndex: 0,
          segmentIndex: 0,
        ),
        openedAt: DateTime.now(),
      );

      final stats = service.computeStats(doc);

      // Small distance should be in meters
      expect(stats.formattedDistance, contains('m'));
      expect(stats.formattedDistance, isNot(contains('km')));
    });
  });
}
