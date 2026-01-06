import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:routesmith/data/recent_files_store.dart';

/// Controller for managing recent files
class RecentFilesController extends AsyncNotifier<List<RecentFileEntry>> {
  @override
  Future<List<RecentFileEntry>> build() async {
    final store = ref.read(recentFilesStoreProvider);
    return store.getRecentFiles();
  }

  /// Add a file to recent files
  Future<void> addRecent(RecentFileEntry entry) async {
    final store = ref.read(recentFilesStoreProvider);
    await store.addRecentFile(entry);
    // Refresh the list
    ref.invalidateSelf();
  }

  /// Clear all recent files
  Future<void> clearRecent() async {
    final store = ref.read(recentFilesStoreProvider);
    await store.clearRecent();
    // Refresh the list
    ref.invalidateSelf();
  }

  /// Remove a specific file from recent files
  Future<void> removeRecent(RecentFileEntry entry) async {
    final store = ref.read(recentFilesStoreProvider);
    await store.removeRecentFile(entry);
    // Refresh the list
    ref.invalidateSelf();
  }
}

/// Provider for recent files controller
final recentFilesControllerProvider =
    AsyncNotifierProvider<RecentFilesController, List<RecentFileEntry>>(() {
  return RecentFilesController();
});
