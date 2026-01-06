import 'dart:io'; // For File operations
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:routesmith/app/icons.dart';
import 'package:routesmith/app/providers.dart';
import 'package:routesmith/data/recent_files_store.dart';
import 'package:routesmith/features/library/recent_files_controller.dart';

/// Library screen - Home screen for opening and creating GPX files
class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentFilesAsync = ref.watch(recentFilesControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('RouteSmith'),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              // Open GPX button
              ElevatedButton.icon(
                onPressed: () => _openGpx(context, ref),
                icon: const Icon(AppIcons.open),
                label: const Text('Open GPX'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(200, 50),
                ),
              ),
              const SizedBox(height: 16),
              // New GPX button
              OutlinedButton.icon(
                onPressed: () => _createNewGpx(context, ref),
                icon: const Icon(AppIcons.createNew),
                label: const Text('New GPX'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(200, 50),
                ),
              ),
              const SizedBox(height: 48),
              // Recent files section
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recent Files',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    recentFilesAsync.when(
                      data: (recentFiles) {
                        if (recentFiles.isEmpty) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24.0),
                              child: Text('No recent files'),
                            ),
                          );
                        }
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: recentFiles.length,
                          itemBuilder: (context, index) {
                            final file = recentFiles[index];

                            // Use file path + timestamp as unique key
                            final key = Key('${file.path}_${file.lastOpened.millisecondsSinceEpoch}');

                            return Dismissible(
                              key: key,
                              direction: DismissDirection.endToStart,
                              background: Container(
                                color: Colors.red,
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: const Icon(
                                  Icons.delete,
                                  color: Colors.white,
                                ),
                              ),
                              confirmDismiss: (direction) async {
                                // Show confirmation dialog before dismissing
                                return await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('Remove from recent files?'),
                                    content: Text(
                                      'Remove "${file.displayName}" from recent files?\n\n'
                                      'This will not delete the actual file.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(true),
                                        child: const Text('Remove'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              onDismissed: (direction) async {
                                // Remove from recent files
                                await ref
                                    .read(recentFilesControllerProvider.notifier)
                                    .removeRecent(file);

                                // Show snackbar with undo option
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Removed "${file.displayName}"'),
                                      action: SnackBarAction(
                                        label: 'Undo',
                                        onPressed: () {
                                          // Re-add the file to recents
                                          ref
                                              .read(recentFilesControllerProvider.notifier)
                                              .addRecent(file);
                                        },
                                      ),
                                    ),
                                  );
                                }
                              },
                              child: ListTile(
                                leading: const Icon(Icons.description),
                                title: Text(file.displayName),
                                subtitle: Text(
                                  '${_formatFileSize(file.fileSizeBytes)} • ${_formatDate(file.lastOpened)}',
                                ),
                                onTap: () => _reopenRecentFile(context, ref, file),
                              ),
                            );
                          },
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (error, stack) => Center(
                        child: Text('Error loading recent files: $error'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Open GPX flow (per CLAUDE.md specification)
  Future<void> _openGpx(BuildContext context, WidgetRef ref) async {
    // 1. Show file picker
    // Note: Using FileType.any because Android doesn't recognize 'gpx' as a standard extension
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      withData: true,
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) return;
    if (!context.mounted) return;

    final file = result.files.single;

    // Validate file extension
    if (!file.name.toLowerCase().endsWith('.gpx')) {
      _showError(context, 'Please select a GPX file (.gpx)');
      return;
    }

    if (file.bytes == null) {
      _showError(context, 'Could not read file data');
      return;
    }

    // 2. Show non-dismissible progress dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        title: Text('Opening GPX…'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Please wait...'),
          ],
        ),
      ),
    );

    // 3. Parse in service
    final ioService = ref.read(gpxIoServiceProvider);
    final doc = await ioService.parseGpxFromBytes(
      bytes: file.bytes!,
      displayName: file.name,
      sourcePath: file.path,
    );

    // Close progress dialog
    if (context.mounted) {
      Navigator.of(context).pop();
    }

    // 4. Handle result
    if (doc != null) {
      // Success: Set document and navigate to viewer
      ref.read(gpxDocumentProvider.notifier).state = doc;

      // Add to recent files
      final recentEntry = RecentFileEntry(
        displayName: doc.displayName,
        path: doc.sourcePath,
        lastOpened: DateTime.now(),
        fileSizeBytes: doc.sourceBytes.length,
      );
      await ref.read(recentFilesControllerProvider.notifier).addRecent(recentEntry);

      if (context.mounted) {
        context.push('/viewer');
      }
    } else {
      // 5. Failure: Show error dialog
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Couldn\'t open file'),
            content: const Text('This file is not valid GPX or could not be parsed.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  /// Reopen a recent file
  Future<void> _reopenRecentFile(
    BuildContext context,
    WidgetRef ref,
    RecentFileEntry recentFile,
  ) async {
    // 1. Check if file path exists
    if (recentFile.path == null) {
      _showError(context, 'File path not available');
      return;
    }

    // 2. Check if file exists on disk
    final file = File(recentFile.path!);
    if (!await file.exists()) {
      // File no longer exists - offer to remove from recents
      final shouldRemove = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('File not found'),
          content: Text(
            'The file "${recentFile.displayName}" could not be found. '
            'It may have been moved or deleted.\n\n'
            'Remove it from recent files?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Remove'),
            ),
          ],
        ),
      );

      if (shouldRemove == true && context.mounted) {
        await ref
            .read(recentFilesControllerProvider.notifier)
            .removeRecent(recentFile);
      }
      return;
    }

    if (!context.mounted) return;

    // 3. Show non-dismissible progress dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        title: Text('Opening GPX…'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Please wait...'),
          ],
        ),
      ),
    );

    try {
      // 4. Read file bytes
      final bytes = await file.readAsBytes();

      // 5. Parse using existing service
      final ioService = ref.read(gpxIoServiceProvider);
      final doc = await ioService.parseGpxFromBytes(
        bytes: bytes,
        displayName: recentFile.displayName,
        sourcePath: recentFile.path,
      );

      // Close progress dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // 6. Handle result
      if (doc != null) {
        // Success: Set document and navigate to viewer
        ref.read(gpxDocumentProvider.notifier).state = doc;

        // Update "last opened" timestamp in recent files
        final updatedEntry = RecentFileEntry(
          displayName: recentFile.displayName,
          path: recentFile.path,
          lastOpened: DateTime.now(),
          fileSizeBytes: bytes.length,
        );
        await ref
            .read(recentFilesControllerProvider.notifier)
            .addRecent(updatedEntry);

        if (context.mounted) {
          context.push('/viewer');
        }
      } else {
        // Parsing failed
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Couldn\'t open file'),
              content: const Text(
                'This file is not valid GPX or could not be parsed.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      // Close progress dialog
      if (context.mounted) {
        Navigator.of(context).pop();
        _showError(context, 'Error reading file: $e');
      }
    }
  }

  /// New GPX flow (per CLAUDE.md specification)
  Future<void> _createNewGpx(BuildContext context, WidgetRef ref) async {
    String fileName = 'untitled.gpx';
    bool isTrack = true;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Create new GPX'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'File name',
                      hintText: 'untitled.gpx',
                    ),
                    autofocus: true,
                    onChanged: (value) => fileName = value,
                    controller: TextEditingController(text: fileName),
                  ),
                  const SizedBox(height: 16),
                  RadioListTile<bool>(
                    title: const Text('Track (recommended)'),
                    value: true,
                    groupValue: isTrack,
                    onChanged: (value) {
                      setState(() => isTrack = value!);
                    },
                  ),
                  RadioListTile<bool>(
                    title: const Text('Route'),
                    value: false,
                    groupValue: isTrack,
                    onChanged: (value) {
                      setState(() => isTrack = value!);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true && context.mounted) {
      // Create new GPX document
      final ioService = ref.read(gpxIoServiceProvider);
      final doc = ioService.createNewGpx(
        displayName: fileName.isEmpty ? 'untitled.gpx' : fileName,
        isTrack: isTrack,
      );

      // Set document (already marked as isDirty in createNewGpx)
      ref.read(gpxDocumentProvider.notifier).state = doc;

      // Navigate to editor
      context.push('/editor');
    }
  }

  /// Show error dialog
  void _showError(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Format file size for display
  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  /// Format date for display
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
