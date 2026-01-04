import 'package:latlong2/latlong.dart';
import 'package:gpxer/domain/models/gpx_document.dart';
import 'package:gpx/gpx.dart';
import 'package:gpxer/domain/models/active_path.dart';

/// Service for editing GPX documents
class GpxEditService {
  /// Move a point to a new location
  GpxDocument movePoint(GpxDocument doc, int index, LatLng newLocation) {
    final elevations = doc.getActivePathElevations();
    final elevation = index < elevations.length ? elevations[index] : null;

    return doc.updatePoint(
      index,
      newLocation.latitude,
      newLocation.longitude,
      elevation,
    );
  }

  /// Delete a point at the given index
  GpxDocument deletePoint(GpxDocument doc, int index) {
    final newGpx = _copyGpx(doc.gpx);

    switch (doc.activePath.type) {
      case ActivePathType.trackSegment:
        if (doc.activePath.trackIndex != null &&
            doc.activePath.segmentIndex != null) {
          final track = newGpx.trks[doc.activePath.trackIndex!];
          final segment = track.trksegs[doc.activePath.segmentIndex!];
          segment.trkpts.removeAt(index);
        }
        break;

      case ActivePathType.route:
        if (doc.activePath.routeIndex != null) {
          final route = newGpx.rtes[doc.activePath.routeIndex!];
          route.rtepts.removeAt(index);
        }
        break;

      case ActivePathType.waypointsFallback:
        newGpx.wpts.removeAt(index);
        break;
    }

    return doc.copyWith(gpx: newGpx, isDirty: true);
  }

  /// Insert a point at the given index
  GpxDocument insertPoint(
    GpxDocument doc,
    int index,
    LatLng location, [
    double? elevation,
  ]) {
    final newGpx = _copyGpx(doc.gpx);

    final newPoint = Wpt(
      lat: location.latitude,
      lon: location.longitude,
      ele: elevation,
    );

    switch (doc.activePath.type) {
      case ActivePathType.trackSegment:
        if (doc.activePath.trackIndex != null &&
            doc.activePath.segmentIndex != null) {
          final track = newGpx.trks[doc.activePath.trackIndex!];
          final segment = track.trksegs[doc.activePath.segmentIndex!];
          segment.trkpts.insert(index, newPoint);
        }
        break;

      case ActivePathType.route:
        if (doc.activePath.routeIndex != null) {
          final route = newGpx.rtes[doc.activePath.routeIndex!];
          route.rtepts.insert(index, newPoint);
        }
        break;

      case ActivePathType.waypointsFallback:
        newGpx.wpts.insert(index, newPoint);
        break;
    }

    return doc.copyWith(gpx: newGpx, isDirty: true);
  }

  /// Edit coordinates of a point
  GpxDocument editCoordinates(
    GpxDocument doc,
    int index,
    double lat,
    double lon, [
    double? elevation,
  ]) {
    return doc.updatePoint(index, lat, lon, elevation);
  }

  /// Create a deep copy of a Gpx object
  Gpx _copyGpx(Gpx gpx) {
    final newGpx = Gpx();
    newGpx.version = gpx.version;
    newGpx.creator = gpx.creator;
    newGpx.metadata = gpx.metadata;

    // Deep copy waypoints
    newGpx.wpts = gpx.wpts.map((wpt) => _copyWpt(wpt)).toList();

    // Deep copy routes
    newGpx.rtes = gpx.rtes.map((rte) {
      final newRte = Rte();
      newRte.name = rte.name;
      newRte.desc = rte.desc;
      newRte.rtepts = rte.rtepts.map((pt) => _copyWpt(pt)).toList();
      return newRte;
    }).toList();

    // Deep copy tracks
    newGpx.trks = gpx.trks.map((trk) {
      final newTrk = Trk();
      newTrk.name = trk.name;
      newTrk.desc = trk.desc;
      newTrk.trksegs = trk.trksegs.map((seg) {
        final newSeg = Trkseg();
        newSeg.trkpts = seg.trkpts.map((pt) => _copyWpt(pt)).toList();
        return newSeg;
      }).toList();
      return newTrk;
    }).toList();

    return newGpx;
  }

  /// Create a copy of a waypoint
  Wpt _copyWpt(Wpt wpt) {
    return Wpt(
      lat: wpt.lat,
      lon: wpt.lon,
      ele: wpt.ele,
      time: wpt.time,
      name: wpt.name,
      desc: wpt.desc,
    );
  }
}
