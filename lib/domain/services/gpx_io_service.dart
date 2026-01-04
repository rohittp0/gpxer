import 'dart:convert';
import 'dart:typed_data';
import 'package:gpx/gpx.dart';
import 'package:uuid/uuid.dart';
import 'package:gpxer/domain/models/gpx_document.dart';
import 'package:gpxer/domain/models/active_path.dart';

/// Service for GPX file I/O operations
class GpxIoService {
  final _uuid = const Uuid();

  /// Parse GPX from bytes
  Future<GpxDocument?> parseGpxFromBytes({
    required Uint8List bytes,
    required String displayName,
    String? sourcePath,
  }) async {
    try {
      // Decode bytes to UTF-8 string
      final xmlString = utf8.decode(bytes);

      // Parse GPX using GpxReader
      final gpx = GpxReader().fromString(xmlString);

      // Determine default active path
      final activePath = _determineActivePath(gpx);

      // Create GpxDocument
      return GpxDocument(
        id: _uuid.v4(),
        sourcePath: sourcePath,
        displayName: displayName,
        sourceBytes: bytes,
        gpx: gpx,
        activePath: activePath,
        isDirty: false,
        openedAt: DateTime.now(),
      );
    } catch (e) {
      // Return null if parsing fails
      return null;
    }
  }

  /// Create a new empty GPX document
  GpxDocument createNewGpx({
    required String displayName,
    required bool isTrack,
  }) {
    final gpx = Gpx();
    gpx.version = '1.1';
    gpx.creator = 'GPX Editor';
    gpx.metadata = Metadata();
    gpx.metadata!.name = displayName;
    gpx.metadata!.time = DateTime.now();

    ActivePath activePath;

    if (isTrack) {
      // Create empty track with one segment
      final track = Trk();
      track.name = 'Track 1';
      final segment = Trkseg();
      track.trksegs = [segment];
      gpx.trks = [track];

      activePath = ActivePath.trackSegment(0, 0);
    } else {
      // Create empty route
      final route = Rte();
      route.name = 'Route 1';
      gpx.rtes = [route];

      activePath = ActivePath.route(0);
    }

    final emptyBytes = Uint8List.fromList(utf8.encode(''));

    return GpxDocument(
      id: _uuid.v4(),
      sourcePath: null,
      displayName: displayName,
      sourceBytes: emptyBytes,
      gpx: gpx,
      activePath: activePath,
      isDirty: true,
      openedAt: DateTime.now(),
    );
  }

  /// Export GPX to XML string
  String exportToXml(Gpx gpx, {bool pretty = true}) {
    return GpxWriter().asString(gpx, pretty: pretty);
  }

  /// Determine the default active path for a GPX document
  /// Priority: first track segment > first route > waypoints fallback
  ActivePath _determineActivePath(Gpx gpx) {
    // Check for tracks
    if (gpx.trks.isNotEmpty) {
      final firstTrack = gpx.trks[0];
      if (firstTrack.trksegs.isNotEmpty) {
        return ActivePath.trackSegment(0, 0);
      }
    }

    // Check for routes
    if (gpx.rtes.isNotEmpty) {
      return ActivePath.route(0);
    }

    // Fallback to waypoints
    return ActivePath.waypointsFallback();
  }
}
