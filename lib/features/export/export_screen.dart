import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gpxer/app/providers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:gpx/gpx.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Export screen - Save As and Share GPX files
class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({super.key});

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  late TextEditingController _fileNameController;
  bool _prettyFormat = true;

  @override
  void initState() {
    super.initState();
    final doc = ref.read(gpxDocumentProvider);
    _fileNameController = TextEditingController(
      text: doc?.displayName ?? 'untitled.gpx',
    );
  }

  @override
  void dispose() {
    _fileNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final doc = ref.watch(gpxDocumentProvider);

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

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/editor'),
        ),
        title: const Text('Export'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // File name input
            TextField(
              controller: _fileNameController,
              decoration: const InputDecoration(
                labelText: 'File name',
                border: OutlineInputBorder(),
                suffixText: '.gpx',
              ),
            ),
            const SizedBox(height: 16),

            // Pretty format toggle
            SwitchListTile(
              title: const Text('Pretty format'),
              subtitle: const Text('Add indentation and line breaks for readability'),
              value: _prettyFormat,
              onChanged: (value) {
                setState(() {
                  _prettyFormat = value;
                });
              },
            ),

            const Spacer(),

            // Save As button
            FilledButton.icon(
              onPressed: () => _handleSaveAs(doc),
              icon: const Icon(Icons.save),
              label: const Text('Save As...'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 12),

            // Share button
            OutlinedButton.icon(
              onPressed: () => _handleShare(doc),
              icon: const Icon(Icons.share),
              label: const Text('Share'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  /// Handle Save As action
  Future<void> _handleSaveAs(doc) async {
    try {
      // Generate GPX XML
      final xml = GpxWriter().asString(doc.gpx, pretty: _prettyFormat);

      // Get filename
      String fileName = _fileNameController.text.trim();
      if (!fileName.endsWith('.gpx')) {
        fileName = '$fileName.gpx';
      }

      // Show save dialog
      final outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save GPX File',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['gpx'],
      );

      if (outputPath == null) {
        // User canceled
        return;
      }

      // Write file
      final file = File(outputPath);
      await file.writeAsString(xml);

      // Mark document as clean and update source path
      final updatedDoc = doc.copyWith(
        isDirty: false,
        sourcePath: outputPath,
        displayName: fileName,
      );
      ref.read(gpxDocumentProvider.notifier).state = updatedDoc;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved to $outputPath')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving file: $e')),
        );
      }
    }
  }

  /// Handle Share action
  Future<void> _handleShare(doc) async {
    try {
      // Generate GPX XML
      final xml = GpxWriter().asString(doc.gpx, pretty: _prettyFormat);

      // Get filename
      String fileName = _fileNameController.text.trim();
      if (!fileName.endsWith('.gpx')) {
        fileName = '$fileName.gpx';
      }

      // Create temp file
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/$fileName');
      await tempFile.writeAsString(xml);

      // Share file
      await Share.shareXFiles(
        [XFile(tempFile.path)],
        subject: 'GPX File: $fileName',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sharing GPX file')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing file: $e')),
        );
      }
    }
  }
}
