import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gpxer/app/providers.dart';

/// Bottom sheet for viewer screen showing stats and actions
class ViewerBottomSheet extends ConsumerWidget {
  const ViewerBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final doc = ref.watch(gpxDocumentProvider);
    final stats = ref.watch(gpxStatsProvider);

    if (doc == null || stats == null) {
      return const SizedBox.shrink();
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.12,
      minChildSize: 0.12,
      maxChildSize: 0.55,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Collapsed content (always visible)
              Text(
                'Distance: ${stats.formattedDistance}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                _buildSummaryLine(stats),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              // Expanded content
              const Divider(),
              const SizedBox(height: 16),
              Text(
                'Active Path',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(_getActivePathDescription(doc)),
              const SizedBox(height: 24),
              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.go('/details'),
                      icon: const Icon(Icons.info),
                      label: const Text('Details'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => context.go('/export'),
                      icon: const Icon(Icons.share),
                      label: const Text('Export'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Extra stats
              if (stats.ascentMeters != null || stats.descentMeters != null) ...[
                const Divider(),
                const SizedBox(height: 16),
                Text(
                  'Elevation',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                if (stats.ascentMeters != null)
                  Text('Ascent: ${stats.ascentMeters!.toStringAsFixed(0)} m'),
                if (stats.descentMeters != null)
                  Text('Descent: ${stats.descentMeters!.toStringAsFixed(0)} m'),
              ],
            ],
          ),
        );
      },
    );
  }

  String _buildSummaryLine(stats) {
    final parts = <String>[];
    parts.add('Points: ${stats.pointCount}');

    if (stats.minElevation != null && stats.maxElevation != null) {
      parts.add(
        'Elev: ${stats.minElevation!.toStringAsFixed(0)}-${stats.maxElevation!.toStringAsFixed(0)} m',
      );
    }

    return parts.join(' • ');
  }

  String _getActivePathDescription(doc) {
    switch (doc.activePath.type.toString().split('.').last) {
      case 'trackSegment':
        return 'Track segment ${(doc.activePath.trackIndex ?? 0) + 1}-${(doc.activePath.segmentIndex ?? 0) + 1}';
      case 'route':
        return 'Route ${(doc.activePath.routeIndex ?? 0) + 1}';
      case 'waypointsFallback':
        return 'Waypoints';
      default:
        return 'Unknown';
    }
  }
}
