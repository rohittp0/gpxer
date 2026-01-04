import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

/// Dialog for inserting a new point
class InsertPointDialog extends StatefulWidget {
  final String title;

  const InsertPointDialog({
    super.key,
    required this.title,
  });

  @override
  State<InsertPointDialog> createState() => _InsertPointDialogState();
}

class _InsertPointDialogState extends State<InsertPointDialog> {
  late TextEditingController _latController;
  late TextEditingController _lonController;
  late TextEditingController _eleController;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _latController = TextEditingController();
    _lonController = TextEditingController();
    _eleController = TextEditingController();
  }

  @override
  void dispose() {
    _latController.dispose();
    _lonController.dispose();
    _eleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _latController,
              decoration: const InputDecoration(
                labelText: 'Latitude *',
                hintText: 'e.g., 37.7749',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Latitude is required';
                }
                final lat = double.tryParse(value);
                if (lat == null) {
                  return 'Invalid number';
                }
                if (lat < -90 || lat > 90) {
                  return 'Latitude must be between -90 and 90';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _lonController,
              decoration: const InputDecoration(
                labelText: 'Longitude *',
                hintText: 'e.g., -122.4194',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Longitude is required';
                }
                final lon = double.tryParse(value);
                if (lon == null) {
                  return 'Invalid number';
                }
                if (lon < -180 || lon > 180) {
                  return 'Longitude must be between -180 and 180';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _eleController,
              decoration: const InputDecoration(
                labelText: 'Elevation (optional)',
                hintText: 'e.g., 123.5',
                suffixText: 'm',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return null; // Optional field
                }
                final ele = double.tryParse(value);
                if (ele == null) {
                  return 'Invalid number';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final lat = double.parse(_latController.text);
              final lon = double.parse(_lonController.text);
              final ele = _eleController.text.isEmpty
                  ? null
                  : double.parse(_eleController.text);

              Navigator.of(context).pop(
                InsertPointResult(
                  location: LatLng(lat, lon),
                  elevation: ele,
                ),
              );
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}

/// Result data from insert point dialog
class InsertPointResult {
  final LatLng location;
  final double? elevation;

  const InsertPointResult({
    required this.location,
    this.elevation,
  });
}
