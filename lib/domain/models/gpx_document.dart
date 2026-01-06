import 'dart:typed_data';
import 'package:gpx/gpx.dart';
import 'package:latlong2/latlong.dart';
import 'package:routesmith/domain/models/active_path.dart';

/// Represents a GPX document with metadata and active path state
class GpxDocument {
  /// Unique identifier for this document
  final String id;

  /// Source file path (may be null for newly created documents)
  final String? sourcePath;

  /// Display name for the document
  final String displayName;

  /// Original file bytes
  final Uint8List sourceBytes;

  /// Parsed GPX data
  final Gpx gpx;

  /// Currently active path (track segment or route)
  final ActivePath activePath;

  /// Whether the document has unsaved changes
  final bool isDirty;

  /// When the document was opened/created
  final DateTime openedAt;

  /// Cached active path points (computed lazily)
  List<LatLng>? _cachedPoints;

  /// Cached active path elevations (computed lazily)
  List<double?>? _cachedElevations;

  GpxDocument({
    required this.id,
    this.sourcePath,
    required this.displayName,
    required this.sourceBytes,
    required this.gpx,
    required this.activePath,
    this.isDirty = false,
    required this.openedAt,
  });

  /// Get all points from the active path as LatLng list
  List<LatLng> getActivePathPoints() {
    // Return cached value if available
    if (_cachedPoints != null) return _cachedPoints!;

    // Compute points based on active path type
    final points = switch (activePath.type) {
      ActivePathType.trackSegment => () {
          if (activePath.trackIndex != null &&
              activePath.segmentIndex != null &&
              gpx.trks.length > activePath.trackIndex! &&
              gpx.trks[activePath.trackIndex!].trksegs.length >
                  activePath.segmentIndex!) {
            final segment = gpx.trks[activePath.trackIndex!]
                .trksegs[activePath.segmentIndex!];
            return segment.trkpts
                .where((pt) => pt.lat != null && pt.lon != null)
                .map((pt) => LatLng(pt.lat!, pt.lon!))
                .toList();
          }
          return <LatLng>[];
        }(),
      ActivePathType.route => () {
          if (activePath.routeIndex != null &&
              gpx.rtes.length > activePath.routeIndex!) {
            final route = gpx.rtes[activePath.routeIndex!];
            return route.rtepts
                .where((pt) => pt.lat != null && pt.lon != null)
                .map((pt) => LatLng(pt.lat!, pt.lon!))
                .toList();
          }
          return <LatLng>[];
        }(),
      ActivePathType.waypointsFallback => gpx.wpts
          .where((pt) => pt.lat != null && pt.lon != null)
          .map((pt) => LatLng(pt.lat!, pt.lon!))
          .toList(),
    };

    // Cache and return
    _cachedPoints = points;
    return points;
  }

  /// Get elevations from the active path
  List<double?> getActivePathElevations() {
    // Return cached value if available
    if (_cachedElevations != null) return _cachedElevations!;

    // Compute elevations based on active path type
    final elevations = switch (activePath.type) {
      ActivePathType.trackSegment => () {
          if (activePath.trackIndex != null &&
              activePath.segmentIndex != null &&
              gpx.trks.length > activePath.trackIndex! &&
              gpx.trks[activePath.trackIndex!].trksegs.length >
                  activePath.segmentIndex!) {
            final segment = gpx.trks[activePath.trackIndex!]
                .trksegs[activePath.segmentIndex!];
            return segment.trkpts.map((pt) => pt.ele).toList();
          }
          return <double?>[];
        }(),
      ActivePathType.route => () {
          if (activePath.routeIndex != null &&
              gpx.rtes.length > activePath.routeIndex!) {
            final route = gpx.rtes[activePath.routeIndex!];
            return route.rtepts.map((pt) => pt.ele).toList();
          }
          return <double?>[];
        }(),
      ActivePathType.waypointsFallback =>
        gpx.wpts.map((pt) => pt.ele).toList(),
    };

    // Cache and return
    _cachedElevations = elevations;
    return elevations;
  }

  /// Create a deep copy of the GPX structure to avoid shared mutable state
  Gpx _deepCopyGpx() {
    final newGpx = Gpx();
    newGpx.version = gpx.version;
    newGpx.creator = gpx.creator;
    newGpx.metadata = gpx.metadata;
    newGpx.wpts = List.from(gpx.wpts);

    // Deep copy routes
    newGpx.rtes = gpx.rtes.map((route) {
      final newRoute = Rte();
      newRoute.name = route.name;
      newRoute.cmt = route.cmt;
      newRoute.desc = route.desc;
      newRoute.src = route.src;
      newRoute.number = route.number;
      newRoute.type = route.type;
      newRoute.extensions = route.extensions;
      newRoute.links = route.links;
      newRoute.rtepts = List<Wpt>.from(route.rtepts);
      return newRoute;
    }).toList();

    // Deep copy tracks
    newGpx.trks = gpx.trks.map((track) {
      final newTrack = Trk();
      newTrack.name = track.name;
      newTrack.cmt = track.cmt;
      newTrack.desc = track.desc;
      newTrack.src = track.src;
      newTrack.number = track.number;
      newTrack.type = track.type;
      newTrack.extensions = track.extensions;
      newTrack.links = track.links;

      // Deep copy segments
      newTrack.trksegs = track.trksegs.map((seg) {
        final newSeg = Trkseg();
        newSeg.extensions = seg.extensions;
        newSeg.trkpts = List<Wpt>.from(seg.trkpts);
        return newSeg;
      }).toList();

      return newTrack;
    }).toList();

    return newGpx;
  }

  /// Update a point at the given index with new coordinates
  GpxDocument updatePoint(int index, double lat, double lon, double? ele) {
    final newGpx = _deepCopyGpx();

    switch (activePath.type) {
      case ActivePathType.trackSegment:
        if (activePath.trackIndex != null &&
            activePath.segmentIndex != null) {
          final track = newGpx.trks[activePath.trackIndex!];
          final segment = track.trksegs[activePath.segmentIndex!];
          final point = segment.trkpts[index];

          segment.trkpts[index] = Wpt(
            lat: lat,
            lon: lon,
            ele: ele ?? point.ele,
            time: point.time,
            name: point.name,
            desc: point.desc,
          );
        }
        break;

      case ActivePathType.route:
        if (activePath.routeIndex != null) {
          final route = newGpx.rtes[activePath.routeIndex!];
          final point = route.rtepts[index];

          route.rtepts[index] = Wpt(
            lat: lat,
            lon: lon,
            ele: ele ?? point.ele,
            time: point.time,
            name: point.name,
            desc: point.desc,
          );
        }
        break;

      case ActivePathType.waypointsFallback:
        final point = newGpx.wpts[index];
        newGpx.wpts[index] = Wpt(
          lat: lat,
          lon: lon,
          ele: ele ?? point.ele,
          time: point.time,
          name: point.name,
          desc: point.desc,
        );
        break;
    }

    return copyWith(gpx: newGpx, isDirty: true).._invalidateCache();
  }

  /// Delete a point at the given index
  GpxDocument deletePoint(int index) {
    final newGpx = _deepCopyGpx();

    switch (activePath.type) {
      case ActivePathType.trackSegment:
        if (activePath.trackIndex != null &&
            activePath.segmentIndex != null) {
          final track = newGpx.trks[activePath.trackIndex!];
          final segment = track.trksegs[activePath.segmentIndex!];
          segment.trkpts.removeAt(index);
        }
        break;

      case ActivePathType.route:
        if (activePath.routeIndex != null) {
          final route = newGpx.rtes[activePath.routeIndex!];
          route.rtepts.removeAt(index);
        }
        break;

      case ActivePathType.waypointsFallback:
        newGpx.wpts.removeAt(index);
        break;
    }

    return copyWith(gpx: newGpx, isDirty: true).._invalidateCache();
  }

  /// Insert a point at the given index
  GpxDocument insertPoint(int index, double lat, double lon, double? ele) {
    final newGpx = _deepCopyGpx();
    final newPoint = Wpt(lat: lat, lon: lon, ele: ele);

    switch (activePath.type) {
      case ActivePathType.trackSegment:
        if (activePath.trackIndex != null &&
            activePath.segmentIndex != null) {
          final track = newGpx.trks[activePath.trackIndex!];
          final segment = track.trksegs[activePath.segmentIndex!];
          segment.trkpts.insert(index, newPoint);
        }
        break;

      case ActivePathType.route:
        if (activePath.routeIndex != null) {
          final route = newGpx.rtes[activePath.routeIndex!];
          route.rtepts.insert(index, newPoint);
        }
        break;

      case ActivePathType.waypointsFallback:
        newGpx.wpts.insert(index, newPoint);
        break;
    }

    return copyWith(gpx: newGpx, isDirty: true).._invalidateCache();
  }

  /// Invalidate cached points and elevations
  void _invalidateCache() {
    _cachedPoints = null;
    _cachedElevations = null;
  }

  /// Create a copy with modified fields
  GpxDocument copyWith({
    String? id,
    String? sourcePath,
    String? displayName,
    Uint8List? sourceBytes,
    Gpx? gpx,
    ActivePath? activePath,
    bool? isDirty,
    DateTime? openedAt,
  }) {
    final newDoc = GpxDocument(
      id: id ?? this.id,
      sourcePath: sourcePath ?? this.sourcePath,
      displayName: displayName ?? this.displayName,
      sourceBytes: sourceBytes ?? this.sourceBytes,
      gpx: gpx ?? this.gpx,
      activePath: activePath ?? this.activePath,
      isDirty: isDirty ?? this.isDirty,
      openedAt: openedAt ?? this.openedAt,
    );

    // Preserve cache if gpx and activePath are not being modified
    if (gpx == null && activePath == null) {
      newDoc._cachedPoints = _cachedPoints;
      newDoc._cachedElevations = _cachedElevations;
    }

    return newDoc;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is GpxDocument &&
        other.id == id &&
        other.sourcePath == sourcePath &&
        other.displayName == displayName &&
        other.gpx == gpx &&
        other.activePath == activePath &&
        other.isDirty == isDirty &&
        other.openedAt == openedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      sourcePath,
      displayName,
      gpx,
      activePath,
      isDirty,
      openedAt,
    );
  }

  @override
  String toString() {
    return 'GpxDocument(id: $id, displayName: $displayName, isDirty: $isDirty, activePath: $activePath)';
  }
}
