/// Type of active path in a GPX document
enum ActivePathType {
  /// A track segment (trk/trkseg)
  trackSegment,

  /// A route (rte)
  route,

  /// Waypoints as fallback when no tracks or routes exist
  waypointsFallback,
}

/// Represents the active path (selected track segment or route) in a GPX document
class ActivePath {
  /// Type of active path
  final ActivePathType type;

  /// Track index (used when type is trackSegment)
  final int? trackIndex;

  /// Segment index within track (used when type is trackSegment)
  final int? segmentIndex;

  /// Route index (used when type is route)
  final int? routeIndex;

  const ActivePath({
    required this.type,
    this.trackIndex,
    this.segmentIndex,
    this.routeIndex,
  });

  /// Create active path for a track segment
  factory ActivePath.trackSegment(int trackIndex, int segmentIndex) {
    return ActivePath(
      type: ActivePathType.trackSegment,
      trackIndex: trackIndex,
      segmentIndex: segmentIndex,
    );
  }

  /// Create active path for a route
  factory ActivePath.route(int routeIndex) {
    return ActivePath(
      type: ActivePathType.route,
      routeIndex: routeIndex,
    );
  }

  /// Create active path using waypoints as fallback
  factory ActivePath.waypointsFallback() {
    return const ActivePath(
      type: ActivePathType.waypointsFallback,
    );
  }

  /// Create a copy with modified fields
  ActivePath copyWith({
    ActivePathType? type,
    int? trackIndex,
    int? segmentIndex,
    int? routeIndex,
  }) {
    return ActivePath(
      type: type ?? this.type,
      trackIndex: trackIndex ?? this.trackIndex,
      segmentIndex: segmentIndex ?? this.segmentIndex,
      routeIndex: routeIndex ?? this.routeIndex,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ActivePath &&
        other.type == type &&
        other.trackIndex == trackIndex &&
        other.segmentIndex == segmentIndex &&
        other.routeIndex == routeIndex;
  }

  @override
  int get hashCode {
    return Object.hash(type, trackIndex, segmentIndex, routeIndex);
  }

  @override
  String toString() {
    return 'ActivePath(type: $type, trackIndex: $trackIndex, segmentIndex: $segmentIndex, routeIndex: $routeIndex)';
  }
}
