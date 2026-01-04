import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gpxer/app/providers.dart';
import 'package:gpxer/features/details/elevation_chart.dart';

/// Details screen - Show GPX stats and elevation profile
class DetailsScreen extends ConsumerWidget {
  const DetailsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final doc = ref.watch(gpxDocumentProvider);
    final stats = ref.watch(gpxStatsProvider);

    if (doc == null || stats == null) {
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

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/viewer'),
        ),
        title: const Text('Details'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // File section
          _buildSection(
            context,
            'File',
            [
              _buildRow('Name', doc.displayName),
              _buildRow(
                'Size',
                '${stats.fileSizeBytes} bytes (${_formatBytes(stats.fileSizeBytes)})',
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Active path stats section
          _buildSection(
            context,
            'Active Path Stats',
            [
              _buildRow('Points', '${stats.pointCount}'),
              _buildRow('Length', stats.formattedDistance),
              if (points.isNotEmpty) ...[
                _buildRow(
                  'Start',
                  '${points.first.latitude.toStringAsFixed(6)}, ${points.first.longitude.toStringAsFixed(6)}',
                ),
                _buildRow(
                  'End',
                  '${points.last.latitude.toStringAsFixed(6)}, ${points.last.longitude.toStringAsFixed(6)}',
                ),
              ],
              if (stats.bounds != null)
                _buildRow(
                  'Bounds',
                  'Lat: ${stats.bounds!.minLat.toStringAsFixed(4)} to ${stats.bounds!.maxLat.toStringAsFixed(4)}\n'
                  'Lon: ${stats.bounds!.minLon.toStringAsFixed(4)} to ${stats.bounds!.maxLon.toStringAsFixed(4)}',
                ),
            ],
          ),
          const SizedBox(height: 24),

          // Elevation section (if available)
          if (stats.minElevation != null && stats.maxElevation != null) ...[
            _buildSection(
              context,
              'Elevation',
              [
                _buildRow(
                  'Range',
                  '${stats.minElevation!.toStringAsFixed(0)} - ${stats.maxElevation!.toStringAsFixed(0)} m',
                ),
                if (stats.ascentMeters != null)
                  _buildRow('Ascent', '${stats.ascentMeters!.toStringAsFixed(0)} m'),
                if (stats.descentMeters != null)
                  _buildRow('Descent', '${stats.descentMeters!.toStringAsFixed(0)} m'),
              ],
            ),
            const SizedBox(height: 24),
          ],

          // Elevation profile chart
          Text(
            'Elevation Profile',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          ElevationChart(
            points: points,
            elevations: elevations,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> rows) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: rows,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
  }
}
