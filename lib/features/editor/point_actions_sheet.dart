import 'package:flutter/material.dart';

/// Bottom sheet with point action options
class PointActionsSheet extends StatelessWidget {
  final int pointIndex;
  final VoidCallback onEditCoordinates;
  final VoidCallback onDelete;
  final VoidCallback onInsertBefore;
  final VoidCallback onInsertAfter;

  const PointActionsSheet({
    super.key,
    required this.pointIndex,
    required this.onEditCoordinates,
    required this.onDelete,
    required this.onInsertBefore,
    required this.onInsertAfter,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Point #${pointIndex + 1}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          const Divider(),
          // Actions
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit coordinates'),
            onTap: () {
              Navigator.of(context).pop();
              onEditCoordinates();
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Delete point', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.of(context).pop();
              onDelete();
            },
          ),
          ListTile(
            leading: const Icon(Icons.add_location_alt),
            title: const Text('Insert before'),
            onTap: () {
              Navigator.of(context).pop();
              onInsertBefore();
            },
          ),
          ListTile(
            leading: const Icon(Icons.add_location),
            title: const Text('Insert after'),
            onTap: () {
              Navigator.of(context).pop();
              onInsertAfter();
            },
          ),
        ],
      ),
    );
  }
}
