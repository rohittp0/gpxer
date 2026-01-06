import 'package:latlong2/latlong.dart';
import 'package:routesmith/domain/models/gpx_document.dart';

/// Abstract base class for edit commands (Command pattern for undo/redo)
abstract class EditCommand {
  /// Execute the command
  GpxDocument execute(GpxDocument doc);

  /// Undo the command
  GpxDocument undo(GpxDocument doc);

  /// Redo the command (default implementation calls execute)
  GpxDocument redo(GpxDocument doc) => execute(doc);
}

/// Command to move a point to a new location
class MovePointCommand extends EditCommand {
  final int index;
  final LatLng oldLocation;
  final LatLng newLocation;
  final double? elevation;

  MovePointCommand({
    required this.index,
    required this.oldLocation,
    required this.newLocation,
    this.elevation,
  });

  @override
  GpxDocument execute(GpxDocument doc) {
    return doc.updatePoint(
      index,
      newLocation.latitude,
      newLocation.longitude,
      elevation,
    );
  }

  @override
  GpxDocument undo(GpxDocument doc) {
    return doc.updatePoint(
      index,
      oldLocation.latitude,
      oldLocation.longitude,
      elevation,
    );
  }
}

/// Command to delete a point
class DeletePointCommand extends EditCommand {
  final int index;
  final LatLng location;
  final double? elevation;

  DeletePointCommand({
    required this.index,
    required this.location,
    this.elevation,
  });

  @override
  GpxDocument execute(GpxDocument doc) {
    return doc.deletePoint(index);
  }

  @override
  GpxDocument undo(GpxDocument doc) {
    return doc.insertPoint(index, location.latitude, location.longitude, elevation);
  }
}

/// Command to insert a point at a specific index
class InsertPointCommand extends EditCommand {
  final int index;
  final LatLng location;
  final double? elevation;

  InsertPointCommand({
    required this.index,
    required this.location,
    this.elevation,
  });

  @override
  GpxDocument execute(GpxDocument doc) {
    return doc.insertPoint(index, location.latitude, location.longitude, elevation);
  }

  @override
  GpxDocument undo(GpxDocument doc) {
    return doc.deletePoint(index);
  }
}

/// Command to edit point coordinates
class EditCoordinatesCommand extends EditCommand {
  final int index;
  final LatLng oldLocation;
  final LatLng newLocation;
  final double? oldElevation;
  final double? newElevation;

  EditCoordinatesCommand({
    required this.index,
    required this.oldLocation,
    required this.newLocation,
    this.oldElevation,
    this.newElevation,
  });

  @override
  GpxDocument execute(GpxDocument doc) {
    return doc.updatePoint(
      index,
      newLocation.latitude,
      newLocation.longitude,
      newElevation,
    );
  }

  @override
  GpxDocument undo(GpxDocument doc) {
    return doc.updatePoint(
      index,
      oldLocation.latitude,
      oldLocation.longitude,
      oldElevation,
    );
  }
}
