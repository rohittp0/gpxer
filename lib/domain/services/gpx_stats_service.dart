import 'package:latlong2/latlong.dart';
import 'package:routesmith/domain/models/gpx_document.dart';

/// Simple bounding box for GPX paths
class GpxBounds {
  final double minLat;
  final double maxLat;
  final double minLon;
  final double maxLon;

  const GpxBounds({
    required this.minLat,
    required this.maxLat,
    required this.minLon,
    required this.maxLon,
  });

  LatLng get center => LatLng(
        (minLat + maxLat) / 2,
        (minLon + maxLon) / 2,
      );
}

/// Statistics computed from a GPX document
class GpxStats {
  final int pointCount;
  final double totalDistanceMeters;
  final double? minElevation;
  final double? maxElevation;
  final double? ascentMeters;
  final double? descentMeters;
  final GpxBounds? bounds;
  final int fileSizeBytes;
  final Duration? duration;

  const GpxStats({
    required this.pointCount,
    required this.totalDistanceMeters,
    this.minElevation,
    this.maxElevation,
    this.ascentMeters,
    this.descentMeters,
    this.bounds,
    required this.fileSizeBytes,
    this.duration,
  });

  String get formattedDistance {
    if (totalDistanceMeters < 1000) {
      return '${totalDistanceMeters.toStringAsFixed(0)} m';
    } else {
      return '${(totalDistanceMeters / 1000).toStringAsFixed(2)} km';
    }
  }

  String? get formattedElevationRange {
    if (minElevation == null || maxElevation == null) return null;
    return '${minElevation!.toStringAsFixed(0)} - ${maxElevation!.toStringAsFixed(0)} m';
  }
}

/// Service for computing statistics from GPX documents
class GpxStatsService {
  /// Distance calculator using Vincenty algorithm (accurate)
  final _distance = const Distance();

  /// Calculate bounding box from a list of points
  static GpxBounds? calculateBounds(List<LatLng> points) {
    if (points.isEmpty) return null;

    double minLat = points[0].latitude;
    double maxLat = points[0].latitude;
    double minLon = points[0].longitude;
    double maxLon = points[0].longitude;

    for (final point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLon) minLon = point.longitude;
      if (point.longitude > maxLon) maxLon = point.longitude;
    }

    return GpxBounds(
      minLat: minLat,
      maxLat: maxLat,
      minLon: minLon,
      maxLon: maxLon,
    );
  }

  /// Calculate center point from a list of points
  static LatLng calculateCenter(List<LatLng> points) {
    final bounds = calculateBounds(points);
    return bounds?.center ?? LatLng(0, 0);
  }

  /// Calculate appropriate zoom level based on point spread
  static double calculateZoom(List<LatLng> points) {
    if (points.length < 2) return 13.0;

    final bounds = calculateBounds(points);
    if (bounds == null) return 13.0;

    final latDiff = bounds.maxLat - bounds.minLat;
    final lonDiff = bounds.maxLon - bounds.minLon;
    final maxDiff = latDiff > lonDiff ? latDiff : lonDiff;

    // Zoom level calculation based on coordinate span
    if (maxDiff > 10) return 5.0;
    if (maxDiff > 5) return 7.0;
    if (maxDiff > 1) return 9.0;
    if (maxDiff > 0.5) return 11.0;
    if (maxDiff > 0.1) return 13.0;
    return 15.0;
  }

  /// Compute comprehensive statistics for a GPX document
  GpxStats computeStats(GpxDocument doc) {
    final points = doc.getActivePathPoints();
    final elevations = doc.getActivePathElevations();

    // Compute total distance
    double totalDistance = 0.0;
    for (int i = 0; i < points.length - 1; i++) {
      totalDistance += _distance.as(LengthUnit.Meter, points[i], points[i + 1]);
    }

    // Compute elevation stats
    final validElevations =
        elevations.where((e) => e != null).cast<double>().toList();

    double? minEle;
    double? maxEle;
    double? ascent;
    double? descent;

    if (validElevations.isNotEmpty) {
      minEle = validElevations.reduce((a, b) => a < b ? a : b);
      maxEle = validElevations.reduce((a, b) => a > b ? a : b);

      // Calculate ascent and descent
      double totalAscent = 0.0;
      double totalDescent = 0.0;

      for (int i = 0; i < validElevations.length - 1; i++) {
        final diff = validElevations[i + 1] - validElevations[i];
        if (diff > 0) {
          totalAscent += diff;
        } else {
          totalDescent += diff.abs();
        }
      }

      ascent = totalAscent;
      descent = totalDescent;
    }

    // Compute bounds using static helper
    final bounds = calculateBounds(points);

    return GpxStats(
      pointCount: points.length,
      totalDistanceMeters: totalDistance,
      minElevation: minEle,
      maxElevation: maxEle,
      ascentMeters: ascent,
      descentMeters: descent,
      bounds: bounds,
      fileSizeBytes: doc.sourceBytes.length,
      duration: null, // TODO: Calculate from timestamps if available
    );
  }
}
