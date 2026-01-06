import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import 'package:gpxer/app/providers.dart';
import 'package:gpxer/domain/services/gpx_stats_service.dart';
import 'package:gpxer/features/viewer/viewer_bottom_sheet.dart';
import 'package:gpxer/features/viewer/point_callout.dart';

/// Viewer screen - Display GPX on map with markers and polyline
class ViewerScreen extends ConsumerStatefulWidget {
  const ViewerScreen({super.key});

  @override
  ConsumerState<ViewerScreen> createState() => _ViewerScreenState();
}

class _ViewerScreenState extends ConsumerState<ViewerScreen> {
  int? _selectedPointIndex;
  bool _showAllMarkers = false;

  @override
  Widget build(BuildContext context) {
    final doc = ref.watch(gpxDocumentProvider);

    if (doc == null) {
      // No document loaded, redirect to library
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.go('/');
        }
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final points = doc.getActivePathPoints();
    final elevations = doc.getActivePathElevations();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(doc.displayName),
        actions: [
          IconButton(
            icon: const Icon(Icons.info),
            tooltip: 'Details',
            onPressed: () => context.push('/details'),
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit',
            onPressed: () => context.push('/editor'),
          ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Export',
            onPressed: () => context.push('/export'),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Map
          if (points.isEmpty)
            const Center(
              child: Text('No points to display'),
            )
          else if (points.length < 2)
            Column(
              children: [
                Container(
                  color: Colors.orange[100],
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: const [
                      Icon(Icons.warning, color: Colors.orange),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text('Not enough points to draw a path.'),
                      ),
                    ],
                  ),
                ),
                Expanded(child: _buildMap(points, elevations)),
              ],
            )
          else
            _buildMap(points, elevations),
          // Point callout (if a point is selected)
          if (_selectedPointIndex != null &&
              _selectedPointIndex! < points.length)
            Positioned(
              top: 100,
              left: MediaQuery.of(context).size.width / 2 - 100,
              child: SizedBox(
                width: 200,
                child: PointCallout(
                  pointIndex: _selectedPointIndex!,
                  location: points[_selectedPointIndex!],
                  elevation: _selectedPointIndex! < elevations.length
                      ? elevations[_selectedPointIndex!]
                      : null,
                ),
              ),
            ),
          // Bottom sheet
          const ViewerBottomSheet(),
        ],
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
        onTap: (_, __) {
          setState(() {
            _selectedPointIndex = null;
          });
        },
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
        // Layer 3: Markers (path points) - TOP
        MarkerLayer(
          markers: _buildMarkers(points, elevations),
        ),
      ],
    );
  }

  /// Build markers according to CLAUDE.md specification
  List<Marker> _buildMarkers(List<LatLng> points, List<double?> elevations) {
    if (points.isEmpty) return [];

    final markers = <Marker>[];

    // Always show start marker (green)
    markers.add(_createMarker(
      index: 0,
      point: points[0],
      color: Colors.green,
      label: 'Start',
    ));

    // Always show end marker (red) if we have more than 1 point
    if (points.length > 1) {
      markers.add(_createMarker(
        index: points.length - 1,
        point: points[points.length - 1],
        color: Colors.red,
        label: 'End',
      ));
    }

    // Middle points logic
    if (_showAllMarkers || points.length <= 500) {
      // Show all markers
      for (int i = 1; i < points.length - 1; i++) {
        markers.add(_createMarker(
          index: i,
          point: points[i],
          color: Colors.blue,
          label: '#${i + 1}',
        ));
      }
    } else {
      // Show every Nth marker
      final n = (points.length / 500).ceil();
      for (int i = n; i < points.length - 1; i += n) {
        markers.add(_createMarker(
          index: i,
          point: points[i],
          color: Colors.blue,
          label: '#${i + 1}',
        ));
      }
    }

    return markers;
  }

  Marker _createMarker({
    required int index,
    required LatLng point,
    required Color color,
    required String label,
  }) {
    return Marker(
      point: point,
      width: 30,
      height: 30,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedPointIndex = index;
          });
        },
        child: Icon(
          Icons.location_on,
          color: color,
          size: 30,
        ),
      ),
    );
  }

  /// Calculate center point from bounds
  LatLng _calculateCenter(List<LatLng> points) {
    return GpxStatsService.calculateCenter(points);
  }

  /// Calculate appropriate zoom level
  double _calculateZoom(List<LatLng> points) {
    return GpxStatsService.calculateZoom(points);
  }
}
