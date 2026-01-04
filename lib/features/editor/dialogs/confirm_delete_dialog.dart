import 'package:flutter/material.dart';

/// Confirmation dialog for deleting a point
class ConfirmDeleteDialog extends StatelessWidget {
  final int pointIndex;

  const ConfirmDeleteDialog({
    super.key,
    required this.pointIndex,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delete point?'),
      content: Text(
        'This will remove Point #${pointIndex + 1} from the path.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.red,
          ),
          child: const Text('Delete'),
        ),
      ],
    );
  }
}
