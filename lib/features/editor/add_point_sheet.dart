import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Bottom sheet for adding new points via Map or List tabs
class AddPointSheet extends StatefulWidget {
  final List<LatLng> existingPoints;
  final Function(int index, LatLng location, double? elevation) onInsert;

  const AddPointSheet({
    super.key,
    required this.existingPoints,
    required this.onInsert,
  });

  @override
  State<AddPointSheet> createState() => _AddPointSheetState();
}

class _AddPointSheetState extends State<AddPointSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  LatLng? _tempPoint;
  int? _anchorPointIndex;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Drag handle
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                // Title and tabs
                Row(
                  children: [
                    Text(
                      'Add point',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Tabs
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Map', icon: Icon(Icons.map)),
              Tab(text: 'List', icon: Icon(Icons.list)),
            ],
          ),
          // Tab views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMapTab(),
                _buildListTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapTab() {
    final center = widget.existingPoints.isEmpty
        ? LatLng(0, 0)
        : widget.existingPoints[widget.existingPoints.length ~/ 2];

    return Column(
      children: [
        // Instructions
        if (_tempPoint == null)
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue[50],
            child: Row(
              children: [
                const Icon(Icons.touch_app, color: Colors.blue),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Tap the map to create a new point',
                    style: TextStyle(color: Colors.blue[900]),
                  ),
                ),
              ],
            ),
          ),
        // Map
        Expanded(
          child: FlutterMap(
            options: MapOptions(
              initialCenter: center,
              initialZoom: 13.0,
              onTap: (tapPosition, point) {
                setState(() {
                  _tempPoint = point;
                  _anchorPointIndex = null;
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.gpxer',
              ),
              // Existing path polyline
              if (widget.existingPoints.length >= 2)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: widget.existingPoints,
                      strokeWidth: 4.0,
                      color: Colors.blue,
                    ),
                  ],
                ),
              // Existing points markers
              MarkerLayer(
                markers: widget.existingPoints.asMap().entries.map((entry) {
                  final index = entry.key;
                  final point = entry.value;
                  return Marker(
                    point: point,
                    width: 40,
                    height: 40,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _anchorPointIndex = index;
                        });
                      },
                      child: Icon(
                        Icons.location_on,
                        size: 40,
                        color: _anchorPointIndex == index
                            ? Colors.orange
                            : Colors.blue,
                      ),
                    ),
                  );
                }).toList(),
              ),
              // Temp point marker
              if (_tempPoint != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _tempPoint!,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.add_location,
                        size: 40,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        // Action bar
        if (_tempPoint != null) _buildMapActionBar(),
      ],
    );
  }

  Widget _buildMapActionBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          if (_anchorPointIndex == null) ...[
            Expanded(
              child: FilledButton.icon(
                onPressed: () => _insertAtEnd(),
                icon: const Icon(Icons.add_location),
                label: const Text('Insert at end'),
              ),
            ),
          ] else ...[
            Expanded(
              child: FilledButton.icon(
                onPressed: () => _insertBeforeAnchor(),
                icon: const Icon(Icons.add_location_alt),
                label: Text('Before #${_anchorPointIndex! + 1}'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.icon(
                onPressed: () => _insertAfterAnchor(),
                icon: const Icon(Icons.add_location),
                label: Text('After #${_anchorPointIndex! + 1}'),
              ),
            ),
          ],
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: () {
              setState(() {
                _tempPoint = null;
                _anchorPointIndex = null;
              });
            },
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildListTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Insert at start
        _buildInsertButton(
          label: 'Insert at start',
          icon: Icons.add_location_alt,
          onPressed: () => _showInsertDialog(0),
        ),
        const SizedBox(height: 16),
        // Existing points list
        ...widget.existingPoints.asMap().entries.map((entry) {
          final index = entry.key;
          final point = entry.value;
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Point info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Point #${index + 1}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Lat: ${point.latitude.toStringAsFixed(6)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          'Lon: ${point.longitude.toStringAsFixed(6)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  // Insert after button
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    tooltip: 'Insert after',
                    onPressed: () => _showInsertDialog(index + 1),
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 8),
        // Insert at end
        _buildInsertButton(
          label: 'Insert at end',
          icon: Icons.add_location,
          onPressed: () => _showInsertDialog(widget.existingPoints.length),
        ),
      ],
    );
  }

  Widget _buildInsertButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }

  void _showInsertDialog(int index) async {
    final latController = TextEditingController();
    final lonController = TextEditingController();
    final eleController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New point'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: latController,
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
                controller: lonController,
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
                controller: eleController,
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
                    return null;
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
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final lat = double.parse(latController.text);
                final lon = double.parse(lonController.text);
                final ele = eleController.text.isEmpty
                    ? null
                    : double.parse(eleController.text);

                widget.onInsert(index, LatLng(lat, lon), ele);
                Navigator.of(context).pop(true);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      Navigator.of(context).pop();
    }
  }

  void _insertAtEnd() {
    if (_tempPoint != null) {
      widget.onInsert(widget.existingPoints.length, _tempPoint!, null);
      Navigator.of(context).pop();
    }
  }

  void _insertBeforeAnchor() {
    if (_tempPoint != null && _anchorPointIndex != null) {
      widget.onInsert(_anchorPointIndex!, _tempPoint!, null);
      Navigator.of(context).pop();
    }
  }

  void _insertAfterAnchor() {
    if (_tempPoint != null && _anchorPointIndex != null) {
      widget.onInsert(_anchorPointIndex! + 1, _tempPoint!, null);
      Navigator.of(context).pop();
    }
  }
}
