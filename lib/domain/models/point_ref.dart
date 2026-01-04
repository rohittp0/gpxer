import 'package:latlong2/latlong.dart';

/// Reference to a point in a GPX path
class PointRef {
  /// Index of the point in the active path
  final int index;

  /// Location (latitude/longitude)
  final LatLng location;

  /// Elevation (may be null)
  final double? elevation;

  const PointRef({
    required this.index,
    required this.location,
    this.elevation,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PointRef &&
        other.index == index &&
        other.location == location &&
        other.elevation == elevation;
  }

  @override
  int get hashCode {
    return Object.hash(index, location, elevation);
  }

  @override
  String toString() {
    return 'PointRef(index: $index, location: $location, elevation: $elevation)';
  }
}
