import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Export screen - Save As and Share GPX files
class ExportScreen extends StatelessWidget {
  const ExportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/viewer'),
        ),
        title: const Text('Export'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const TextField(
              decoration: InputDecoration(labelText: 'File name'),
            ),
            const SizedBox(height: 16),
            const SwitchListTile(
              title: Text('Pretty format'),
              value: true,
              onChanged: null, // TODO: Implement toggle
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Implement Save As
              },
              icon: const Icon(Icons.save),
              label: const Text('Save As...'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Implement Share
              },
              icon: const Icon(Icons.share),
              label: const Text('Share'),
            ),
          ],
        ),
      ),
    );
  }
}
