import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_dragmarker/flutter_map_dragmarker.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import 'package:gpxer/app/providers.dart';
import 'package:gpxer/domain/models/edit_command.dart';
import 'package:gpxer/domain/services/undo_redo_service.dart';
import 'package:gpxer/features/editor/point_actions_sheet.dart';
import 'package:gpxer/features/editor/dialogs/edit_coordinates_dialog.dart';
import 'package:gpxer/features/editor/dialogs/confirm_delete_dialog.dart';
import 'package:gpxer/features/editor/dialogs/insert_point_dialog.dart';
import 'package:gpxer/features/editor/add_point_sheet.dart';

/// Editor screen - Edit GPX with drag markers and point actions
class EditorScreen extends ConsumerStatefulWidget {
  const EditorScreen({super.key});

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  // Track original positions for undo on drag end
  final Map<int, LatLng> _originalPositions = {};

  @override
  Widget build(BuildContext context) {
    final doc = ref.watch(gpxDocumentProvider);
    final undoRedoService = ref.watch(undoRedoServiceProvider);
    final undoRedoState = ref.watch(undoRedoStateProvider);

    if (doc == null) {
      // No document, redirect to library
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          context.go('/');
        }
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final points = doc.getActivePathPoints();
    final elevations = doc.getActivePathElevations();

    return PopScope(
      canPop: !doc.isDirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop && doc.isDirty) {
          final shouldDiscard = await _showDiscardDialog(context);
          if (shouldDiscard == true && context.mounted) {
            context.go('/');
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              if (doc.isDirty) {
                final shouldDiscard = await _showDiscardDialog(context);
                if (shouldDiscard == true && context.mounted) {
                  context.go('/');
                }
              } else {
                context.go('/');
              }
            },
          ),
          title: Text(doc.isDirty ? '${doc.displayName} •' : doc.displayName),
          actions: [
            IconButton(
              icon: const Icon(Icons.undo),
              onPressed: undoRedoState.canUndo
                  ? () => _handleUndo(undoRedoService, doc)
                  : null,
            ),
            IconButton(
              icon: const Icon(Icons.redo),
              onPressed: undoRedoState.canRedo
                  ? () => _handleRedo(undoRedoService, doc)
                  : null,
            ),
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: () => context.go('/export'),
            ),
          ],
        ),
        body: points.isEmpty
            ? const Center(
                child: Text('No points to edit'),
              )
            : _buildMap(points, elevations),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showAddMode(points),
          icon: const Icon(Icons.add_location),
          label: const Text('Add'),
        ),
      ),
    );
  }

  Widget _buildMap(List<LatLng> points, List<double?> elevations) {
    final center = _calculateCenter(points);
    final zoom = _calculateZoom(points);

    return FlutterMap(
      options: MapOptions(
        initialCenter: center,
        initialZoom: zoom,
      ),
      children: [
        // Layer 1: Tile layer (base map) - BOTTOM
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.gpxer',
        ),
        // Layer 2: Polyline (active path line)
        if (points.length >= 2)
          PolylineLayer(
            polylines: [
              Polyline(
                points: points,
                strokeWidth: 4.0,
                color: Colors.blue,
              ),
            ],
          ),
        // Layer 3: DragMarkers (draggable path points) - TOP (CRITICAL for gestures)
        DragMarkers(
          markers: _buildDragMarkers(points, elevations),
        ),
      ],
    );
  }

  /// Build draggable markers for all path points
  List<DragMarker> _buildDragMarkers(
      List<LatLng> points, List<double?> elevations) {
    return List.generate(points.length, (index) {
      final point = points[index];
      final elevation = index < elevations.length ? elevations[index] : null;

      // Color coding: start = green, end = red, middle = blue
      Color color;
      if (index == 0) {
        color = Colors.green;
      } else if (index == points.length - 1) {
        color = Colors.red;
      } else {
        color = Colors.blue;
      }

      return DragMarker(
        point: point,
        size: const Size(40, 40),
        offset: const Offset(0, -20),
        builder: (context, point, isDragging) {
          return Icon(
            Icons.location_on,
            size: 40,
            color: isDragging ? color.withOpacity(0.7) : color,
          );
        },
        onDragStart: (details, point) {
          // Store original position for undo command
          _originalPositions[index] = point;
        },
        onDragUpdate: (details, point) {
          // Update point immediately for live polyline redraw
          _updatePointPosition(index, point, elevation);
        },
        onDragEnd: (details, point) {
          // Create and execute MovePointCommand for undo/redo
          final original = _originalPositions[index];
          if (original != null && original != point) {
            _executeMoveCommand(index, original, point, elevation);
          }
          _originalPositions.remove(index);
        },
        onLongPress: (point) {
          _showPointActions(index, point, elevation);
        },
      );
    });
  }

  /// Update point position in real-time (for live polyline update)
  void _updatePointPosition(int index, LatLng newPoint, double? elevation) {
    final doc = ref.read(gpxDocumentProvider);
    if (doc == null) return;

    final updatedDoc = doc.updatePoint(
      index,
      newPoint.latitude,
      newPoint.longitude,
      elevation,
    );
    ref.read(gpxDocumentProvider.notifier).state = updatedDoc;
  }

  /// Execute move command through undo/redo service
  void _executeMoveCommand(
    int index,
    LatLng oldLocation,
    LatLng newLocation,
    double? elevation,
  ) {
    final doc = ref.read(gpxDocumentProvider);
    if (doc == null) return;

    final undoRedoService = ref.read(undoRedoServiceProvider);
    final command = MovePointCommand(
      index: index,
      oldLocation: oldLocation,
      newLocation: newLocation,
      elevation: elevation,
    );

    final updatedDoc = undoRedoService.executeCommand(command, doc);
    ref.read(gpxDocumentProvider.notifier).state = updatedDoc;

    // Update undo/redo state
    ref.read(undoRedoStateProvider.notifier).update(
          undoRedoService.canUndo,
          undoRedoService.canRedo,
        );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Point moved')),
    );
  }

  /// Show Add Mode sheet
  void _showAddMode(List<LatLng> points) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddPointSheet(
        existingPoints: points,
        onInsert: (index, location, elevation) {
          _handleInsertPointAtIndex(index, location, elevation);
        },
      ),
    );
  }

  /// Handle insert point at specific index (from Add Mode)
  void _handleInsertPointAtIndex(int index, LatLng location, double? elevation) {
    final doc = ref.read(gpxDocumentProvider);
    if (doc == null) return;

    final undoRedoService = ref.read(undoRedoServiceProvider);
    final command = InsertPointCommand(
      index: index,
      location: location,
      elevation: elevation,
    );

    final updatedDoc = undoRedoService.executeCommand(command, doc);
    ref.read(gpxDocumentProvider.notifier).state = updatedDoc;

    // Update undo/redo state
    ref.read(undoRedoStateProvider.notifier).update(
          undoRedoService.canUndo,
          undoRedoService.canRedo,
        );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Point inserted')),
    );
  }

  /// Show point actions bottom sheet
  void _showPointActions(int index, LatLng point, double? elevation) {
    showModalBottomSheet(
      context: context,
      builder: (context) => PointActionsSheet(
        pointIndex: index,
        onEditCoordinates: () => _handleEditCoordinates(index, point, elevation),
        onDelete: () => _handleDeletePoint(index, point, elevation),
        onInsertBefore: () => _handleInsertPoint(index, isAfter: false),
        onInsertAfter: () => _handleInsertPoint(index + 1, isAfter: true),
      ),
    );
  }

  /// Handle edit coordinates action
  void _handleEditCoordinates(int index, LatLng currentPoint, double? currentElevation) async {
    final result = await showDialog<EditCoordinatesResult>(
      context: context,
      builder: (context) => EditCoordinatesDialog(
        currentLocation: currentPoint,
        currentElevation: currentElevation,
      ),
    );

    if (result != null && mounted) {
      final doc = ref.read(gpxDocumentProvider);
      if (doc == null) return;

      final undoRedoService = ref.read(undoRedoServiceProvider);
      final command = EditCoordinatesCommand(
        index: index,
        oldLocation: currentPoint,
        newLocation: result.location,
        oldElevation: currentElevation,
        newElevation: result.elevation,
      );

      final updatedDoc = undoRedoService.executeCommand(command, doc);
      ref.read(gpxDocumentProvider.notifier).state = updatedDoc;

      // Update undo/redo state
      ref.read(undoRedoStateProvider.notifier).update(
            undoRedoService.canUndo,
            undoRedoService.canRedo,
          );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Point updated')),
      );
    }
  }

  /// Handle delete point action
  void _handleDeletePoint(int index, LatLng point, double? elevation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmDeleteDialog(pointIndex: index),
    );

    if (confirmed == true && mounted) {
      final doc = ref.read(gpxDocumentProvider);
      if (doc == null) return;

      final undoRedoService = ref.read(undoRedoServiceProvider);
      final command = DeletePointCommand(
        index: index,
        location: point,
        elevation: elevation,
      );

      final updatedDoc = undoRedoService.executeCommand(command, doc);
      ref.read(gpxDocumentProvider.notifier).state = updatedDoc;

      // Update undo/redo state
      ref.read(undoRedoStateProvider.notifier).update(
            undoRedoService.canUndo,
            undoRedoService.canRedo,
          );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Point deleted')),
      );
    }
  }

  /// Handle insert point action (before or after)
  void _handleInsertPoint(int insertIndex, {required bool isAfter}) async {
    final result = await showDialog<InsertPointResult>(
      context: context,
      builder: (context) => InsertPointDialog(
        title: isAfter ? 'Insert after point #$insertIndex' : 'Insert before point #${insertIndex + 1}',
      ),
    );

    if (result != null && mounted) {
      final doc = ref.read(gpxDocumentProvider);
      if (doc == null) return;

      final undoRedoService = ref.read(undoRedoServiceProvider);
      final command = InsertPointCommand(
        index: insertIndex,
        location: result.location,
        elevation: result.elevation,
      );

      final updatedDoc = undoRedoService.executeCommand(command, doc);
      ref.read(gpxDocumentProvider.notifier).state = updatedDoc;

      // Update undo/redo state
      ref.read(undoRedoStateProvider.notifier).update(
            undoRedoService.canUndo,
            undoRedoService.canRedo,
          );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Point inserted')),
      );
    }
  }

  /// Handle undo button press
  void _handleUndo(UndoRedoService undoRedoService, doc) {
    final newDoc = undoRedoService.undo(doc);
    if (newDoc != null) {
      ref.read(gpxDocumentProvider.notifier).state = newDoc;
      ref.read(undoRedoStateProvider.notifier).update(
            undoRedoService.canUndo,
            undoRedoService.canRedo,
          );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Undo')),
      );
    }
  }

  /// Handle redo button press
  void _handleRedo(UndoRedoService undoRedoService, doc) {
    final newDoc = undoRedoService.redo(doc);
    if (newDoc != null) {
      ref.read(gpxDocumentProvider.notifier).state = newDoc;
      ref.read(undoRedoStateProvider.notifier).update(
            undoRedoService.canUndo,
            undoRedoService.canRedo,
          );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Redo')),
      );
    }
  }

  /// Show discard changes confirmation dialog
  Future<bool?> _showDiscardDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('You have unsaved edits.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
  }

  /// Calculate center point from bounds
  LatLng _calculateCenter(List<LatLng> points) {
    if (points.isEmpty) return LatLng(0, 0);

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

    return LatLng((minLat + maxLat) / 2, (minLon + maxLon) / 2);
  }

  /// Calculate appropriate zoom level
  double _calculateZoom(List<LatLng> points) {
    if (points.length < 2) return 13.0;

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

    final latDiff = maxLat - minLat;
    final lonDiff = maxLon - minLon;
    final maxDiff = latDiff > lonDiff ? latDiff : lonDiff;

    // Simple zoom calculation
    if (maxDiff > 10) return 5.0;
    if (maxDiff > 5) return 7.0;
    if (maxDiff > 1) return 9.0;
    if (maxDiff > 0.5) return 11.0;
    if (maxDiff > 0.1) return 13.0;
    return 15.0;
  }
}
