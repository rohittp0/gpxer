import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Entry for a recently opened file
class RecentFileEntry {
  final String displayName;
  final String? path;
  final DateTime lastOpened;
  final int fileSizeBytes;

  const RecentFileEntry({
    required this.displayName,
    this.path,
    required this.lastOpened,
    required this.fileSizeBytes,
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'displayName': displayName,
      'path': path,
      'lastOpened': lastOpened.toIso8601String(),
      'fileSizeBytes': fileSizeBytes,
    };
  }

  /// Create from JSON
  factory RecentFileEntry.fromJson(Map<String, dynamic> json) {
    return RecentFileEntry(
      displayName: json['displayName'] as String,
      path: json['path'] as String?,
      lastOpened: DateTime.parse(json['lastOpened'] as String),
      fileSizeBytes: json['fileSizeBytes'] as int,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is RecentFileEntry &&
        other.displayName == displayName &&
        other.path == path &&
        other.lastOpened == lastOpened &&
        other.fileSizeBytes == fileSizeBytes;
  }

  @override
  int get hashCode {
    return Object.hash(displayName, path, lastOpened, fileSizeBytes);
  }
}

/// Store for managing recently opened files using SharedPreferences
class RecentFilesStore {
  static const String _key = 'recent_files';
  static const int _maxRecent = 10;

  final SharedPreferences _prefs;

  RecentFilesStore(this._prefs);

  /// Get list of recent files
  Future<List<RecentFileEntry>> getRecentFiles() async {
    final jsonString = _prefs.getString(_key);
    if (jsonString == null) return [];

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList
          .map((json) => RecentFileEntry.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Add a file to recent files
  Future<void> addRecentFile(RecentFileEntry entry) async {
    final recent = await getRecentFiles();

    // Remove existing entry with same path if it exists
    recent.removeWhere((e) => e.path != null && e.path == entry.path);

    // Add new entry at the beginning
    recent.insert(0, entry);

    // Keep only max recent files
    if (recent.length > _maxRecent) {
      recent.removeRange(_maxRecent, recent.length);
    }

    // Save to preferences
    final jsonList = recent.map((e) => e.toJson()).toList();
    await _prefs.setString(_key, jsonEncode(jsonList));
  }

  /// Clear all recent files
  Future<void> clearRecent() async {
    await _prefs.remove(_key);
  }
}

/// Provider for SharedPreferences instance
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be initialized in main()');
});

/// Provider for RecentFilesStore
final recentFilesStoreProvider = Provider<RecentFilesStore>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return RecentFilesStore(prefs);
});
