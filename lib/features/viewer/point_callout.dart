import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

/// Callout card shown when a point marker is tapped
class PointCallout extends StatelessWidget {
  final int pointIndex;
  final LatLng location;
  final double? elevation;

  const PointCallout({
    super.key,
    required this.pointIndex,
    required this.location,
    this.elevation,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Point #${pointIndex + 1}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text('Lat: ${location.latitude.toStringAsFixed(6)}'),
            Text('Lon: ${location.longitude.toStringAsFixed(6)}'),
            if (elevation != null) Text('Ele: ${elevation!.toStringAsFixed(0)} m'),
          ],
        ),
      ),
    );
  }
}
