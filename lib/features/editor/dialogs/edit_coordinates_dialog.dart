import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

/// Dialog for editing point coordinates
class EditCoordinatesDialog extends StatefulWidget {
  final LatLng currentLocation;
  final double? currentElevation;

  const EditCoordinatesDialog({
    super.key,
    required this.currentLocation,
    this.currentElevation,
  });

  @override
  State<EditCoordinatesDialog> createState() => _EditCoordinatesDialogState();
}

class _EditCoordinatesDialogState extends State<EditCoordinatesDialog> {
  late TextEditingController _latController;
  late TextEditingController _lonController;
  late TextEditingController _eleController;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _latController = TextEditingController(
      text: widget.currentLocation.latitude.toString(),
    );
    _lonController = TextEditingController(
      text: widget.currentLocation.longitude.toString(),
    );
    _eleController = TextEditingController(
      text: widget.currentElevation?.toString() ?? '',
    );
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
      title: const Text('Edit coordinates'),
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
                EditCoordinatesResult(
                  location: LatLng(lat, lon),
                  elevation: ele,
                ),
              );
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

/// Result data from edit coordinates dialog
class EditCoordinatesResult {
  final LatLng location;
  final double? elevation;

  const EditCoordinatesResult({
    required this.location,
    this.elevation,
  });
}
