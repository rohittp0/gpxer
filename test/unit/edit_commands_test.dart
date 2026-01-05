import 'package:flutter_test/flutter_test.dart';
import 'package:gpxer/domain/models/edit_command.dart';
import 'package:gpxer/domain/models/gpx_document.dart';
import 'package:gpxer/domain/models/active_path.dart';
import 'package:latlong2/latlong.dart';
import 'package:gpx/gpx.dart';
import 'dart:typed_data';

void main() {
  group('EditCommands', () {
    late GpxDocument testDoc;

    setUp(() {
      // Create a test GPX document with a track segment
      final gpx = Gpx();
      gpx.version = '1.1';
      gpx.creator = 'test';

      final track = Trk();
      final segment = Trkseg();
      segment.trkpts = [
        Wpt(lat: 0, lon: 0, ele: 100),
        Wpt(lat: 1, lon: 1, ele: 150),
        Wpt(lat: 2, lon: 2, ele: 120),
      ];
      track.trksegs.add(segment);
      gpx.trks.add(track);

      testDoc = GpxDocument(
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
    });

    test('MovePointCommand executes and undoes correctly', () {
      final oldLocation = LatLng(1, 1);
      final newLocation = LatLng(1.5, 1.5);
      final command = MovePointCommand(
        index: 1,
        oldLocation: oldLocation,
        newLocation: newLocation,
        elevation: 150,
      );

      // Execute
      final updatedDoc = command.execute(testDoc);
      final points = updatedDoc.getActivePathPoints();
      expect(points[1].latitude, equals(1.5));
      expect(points[1].longitude, equals(1.5));
      expect(updatedDoc.isDirty, isTrue);

      // Undo
      final restoredDoc = command.undo(updatedDoc);
      final restoredPoints = restoredDoc.getActivePathPoints();
      expect(restoredPoints[1].latitude, equals(1.0));
      expect(restoredPoints[1].longitude, equals(1.0));
    });

    test('DeletePointCommand executes and undoes correctly', () {
      final command = DeletePointCommand(
        index: 1,
        location: LatLng(1, 1),
        elevation: 150,
      );

      // Execute - should remove point at index 1
      final updatedDoc = command.execute(testDoc);
      final points = updatedDoc.getActivePathPoints();
      expect(points.length, equals(2));
      expect(points[0].latitude, equals(0));
      expect(points[1].latitude, equals(2));

      // Undo - should restore point at index 1
      final restoredDoc = command.undo(updatedDoc);
      final restoredPoints = restoredDoc.getActivePathPoints();
      expect(restoredPoints.length, equals(3));
      expect(restoredPoints[1].latitude, equals(1));
    });

    test('InsertPointCommand executes and undoes correctly', () {
      final command = InsertPointCommand(
        index: 1,
        location: LatLng(0.5, 0.5),
        elevation: 125,
      );

      // Execute - should insert point at index 1
      final updatedDoc = command.execute(testDoc);
      final points = updatedDoc.getActivePathPoints();
      expect(points.length, equals(4));
      expect(points[1].latitude, equals(0.5));
      expect(points[1].longitude, equals(0.5));

      // Undo - should remove the inserted point
      final restoredDoc = command.undo(updatedDoc);
      final restoredPoints = restoredDoc.getActivePathPoints();
      expect(restoredPoints.length, equals(3));
      expect(restoredPoints[1].latitude, equals(1));
    });

    test('EditCoordinatesCommand executes and undoes correctly', () {
      final command = EditCoordinatesCommand(
        index: 1,
        oldLocation: LatLng(1, 1),
        newLocation: LatLng(1.2, 1.3),
        oldElevation: 150,
        newElevation: 160,
      );

      // Execute
      final updatedDoc = command.execute(testDoc);
      final points = updatedDoc.getActivePathPoints();
      final elevations = updatedDoc.getActivePathElevations();
      expect(points[1].latitude, equals(1.2));
      expect(points[1].longitude, equals(1.3));
      expect(elevations[1], equals(160));

      // Undo
      final restoredDoc = command.undo(updatedDoc);
      final restoredPoints = restoredDoc.getActivePathPoints();
      final restoredElevations = restoredDoc.getActivePathElevations();
      expect(restoredPoints[1].latitude, equals(1.0));
      expect(restoredPoints[1].longitude, equals(1.0));
      expect(restoredElevations[1], equals(150));
    });
  });
}
