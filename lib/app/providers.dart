import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gpxer/domain/models/gpx_document.dart';
import 'package:gpxer/domain/services/gpx_io_service.dart';
import 'package:gpxer/domain/services/gpx_stats_service.dart';
import 'package:gpxer/domain/services/gpx_edit_service.dart';

/// Global provider for the current GPX document
final gpxDocumentProvider = StateProvider<GpxDocument?>((ref) => null);

/// Provider for GPX IO service
final gpxIoServiceProvider = Provider<GpxIoService>((ref) {
  return GpxIoService();
});

/// Provider for GPX stats service
final gpxStatsServiceProvider = Provider<GpxStatsService>((ref) {
  return GpxStatsService();
});

/// Provider for GPX edit service
final gpxEditServiceProvider = Provider<GpxEditService>((ref) {
  return GpxEditService();
});

/// Provider for current GPX stats (computed from document)
final gpxStatsProvider = Provider((ref) {
  final doc = ref.watch(gpxDocumentProvider);
  if (doc == null) return null;

  final statsService = ref.watch(gpxStatsServiceProvider);
  return statsService.computeStats(doc);
});
