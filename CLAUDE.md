# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Running the app
```bash
# Run on connected device/emulator (debug mode)
flutter run

# Run on specific device
flutter devices  # List available devices
flutter run -d <device-id>

# Run in release mode
flutter run --release
```

### Testing
```bash
# Run all tests
flutter test

# Run a specific test file
flutter test test/path/to/test_file.dart

# Run tests with coverage
flutter test --coverage

# Run integration tests (requires connected device)
flutter test integration_test
```

### Code Quality
```bash
# Analyze code for issues
flutter analyze

# Format code
dart format lib test

# Check formatting without applying
dart format --set-exit-if-changed lib test
```

### Dependencies
```bash
# Get dependencies
flutter pub get

# Upgrade dependencies
flutter pub upgrade

# Check for outdated packages
flutter pub outdated
```

### Build
```bash
# Build APK (Android)
flutter build apk

# Build App Bundle (Android)
flutter build appbundle

# Build iOS app (requires macOS)
flutter build ios
```

### Clean
```bash
# Clean build artifacts
flutter clean

# Full clean (removes build + .dart_tool + .packages)
flutter clean && flutter pub get
```

---

## RouteSmith + Viewer (Flutter, Android/iOS only)

### Project goal

Build a Flutter app that can:

1. **Open + view any GPX file on a map**

   * Plot GPX points as **markers**
   * Draw a **line (polyline)** connecting points in order
   * Provide a **Details** screen with computed stats (count, length, min/max elevation, file size, etc.)

2. **Edit an existing GPX**

   * Drag points to move them
   * Long‑press a point to open a menu (delete / edit coordinates / insert)
   * Add points via **Add mode** (map tab + list tab)

3. **Create a new GPX** (route or track)

4. **Export** edited/created GPX via **Save As** and **Share**

**Supported platforms:** Android + iOS only.

---

## Non-negotiables

* **No background location tracking**. This app is file-based; it does not need GPS permissions.
* **Edits are non-destructive** until the user exports/saves.
* Must support GPX files containing:

  * `trk` (tracks) with `trkseg` segments
  * `rte` (routes)
  * `wpt` (waypoints)
* If a GPX has multiple track segments or routes, user must be able to select which one is the “active path” for viewing/editing.
* App must remain usable with **large files** (thousands of points): polyline always renders; marker density can be reduced if needed.

---

## Tech stack (pin these dependencies)

### Mapping & interaction

* `flutter_map` (map widget) — use `FlutterMap(children: [...])`. ([Dart packages][1])
* `flutter_map_dragmarker` (draggable markers) — the drag marker layer should be placed last/top so it receives gestures. ([Dart packages][2])
* Use `MarkerLayer` and `PolylineLayer`. ([Dart packages][3])

### GPX parsing/writing

* `gpx` — use `GpxReader().fromString(...)` and `GpxWriter().asString(..., pretty: true)`. ([Dart packages][4])

  * Known limitations: no GPX 1.0, read/write from strings, does not validate schema declarations. ([Dart packages][4])

### File open/save (Android/iOS)

* `file_picker` — use `pickFiles()` and `saveFile()`; compatibility chart shows `saveFile()` supported on Android + iOS. ([Dart packages][5])

### Share

* `share_plus` — wraps Android `ACTION_SEND` and iOS `UIActivityViewController`. ([Dart packages][6])

### Temporary directories for share staging

* `path_provider` — use `getTemporaryDirectory()`; note temp files may be cleared anytime. ([Dart packages][7])

### Stats & distance

* `latlong2` — `Distance` default algorithm is Vincenty (accurate). ([Dart packages][8])

### Charts (elevation profile)

* `fl_chart` — use `LineChart`. ([Dart packages][9])

### State & navigation

* `flutter_riverpod` (state management) ([Dart packages][10])
* `go_router` (navigation) ([Dart packages][11])

### Persistence (recents)

* `shared_preferences` (store recent file metadata) ([Dart packages][12])

---

## Repo structure (create this)

```
lib/
  main.dart
  app/
    router.dart
    theme.dart

  domain/
    models/
      gpx_document.dart
      active_path.dart
      point_ref.dart
      edit_command.dart
    services/
      gpx_io_service.dart
      gpx_stats_service.dart
      gpx_edit_service.dart
      undo_redo_service.dart

  features/
    library/
      library_screen.dart
      recent_files_controller.dart
    viewer/
      viewer_screen.dart
      viewer_bottom_sheet.dart
      point_callout.dart
    details/
      details_screen.dart
      elevation_chart.dart
    editor/
      editor_screen.dart
      editor_toolbar.dart
      add_point_sheet.dart
      point_actions_sheet.dart
      dialogs/
        confirm_discard_dialog.dart
        confirm_delete_dialog.dart
        edit_coordinates_dialog.dart
    export/
      export_screen.dart
      export_controller.dart

  data/
    recent_files_store.dart
```

---

## GPX terminology & what “path” means in this app

### Definitions

* **Waypoint** (`wpt`): POI marker; not inherently a connected path.
* **Route** (`rte` + `rtept`): ordered points; good for planned route.
* **Track Segment** (`trk` + `trkseg` + `trkpt`): ordered points; good for recorded track.

### App rule

* The app always has **one active path** at a time:

  * either a selected `Route`
  * or a selected `Track Segment`
* Waypoints are shown as an optional overlay.

If a file has no routes/tracks but has waypoints, allow “Waypoints as path” as a fallback (use GPX list order).

---

## Data model (implement exactly)

### `GpxDocument`

Fields:

* `String id` (uuid)
* `String? sourcePath` (may be null depending on provider)
* `String displayName`
* `Uint8List sourceBytes`
* `Gpx gpx` (from `gpx` package)
* `ActivePath activePath`
* `bool isDirty`
* `DateTime openedAt`

### `ActivePath`

* `enum ActivePathType { trackSegment, route, waypointsFallback }`
* If `trackSegment`: store `trackIndex`, `segmentIndex`
* If `route`: store `routeIndex`

### UI point list (derived, do not store separately unless you want caching)

* `List<LatLng>` for the active path
* Optional `List<double?> elevations`

---

## Navigation (go_router)

Routes:

* `/` → Library
* `/viewer` → Map Viewer
* `/details` → Details
* `/editor` → Editor
* `/export` → Export

Use `GoRouter` navigation (`context.go(...)`). ([Dart packages][13])

---

## UI/UX specs (explicit behaviors)

### Global UI rules

* Material 3
* Use consistent icons:

  * Open: folder
  * New: add
  * Details: info
  * Edit: pencil
  * Export: share / download
  * Undo/Redo: standard icons
* All confirmation dialogs are **centered** (`showDialog`).
* All action menus are **modal bottom sheets** (`showModalBottomSheet`).

---

## Screen: Library (Home)

### Layout

* AppBar title: `RouteSmith`
* Body:

  * Primary button: **Open GPX**
  * Secondary button: **New GPX**
  * Below: “Recent files” list (if any)

### Open GPX flow (explicit)

When **Open GPX** is tapped:

1. Call `FilePicker.platform.pickFiles(...)` filtering to `.gpx`.
2. Immediately show a **centered modal progress dialog**:

   * Title: `Opening GPX…`
   * Spinner
   * Dialog is non-dismissible.
3. Parse in service:

   * bytes → utf8 string → `GpxReader().fromString(xml)` ([Dart packages][4])
4. If parse succeeds:

   * Close progress dialog
   * Navigate to `/viewer`
5. If parse fails:

   * Close progress dialog
   * Show a **centered AlertDialog**:

     * Title: `Couldn’t open file`
     * Body: `This file is not valid GPX or could not be parsed.`
     * Button: `OK`

### New GPX flow (explicit)

When **New GPX** is tapped:

1. Show **centered dialog** `Create new GPX` with:

   * Text field: File name (default `untitled.gpx`)
   * Radio:

     * `Track (recommended)`
     * `Route`
2. Buttons:

   * `Cancel`
   * `Create`
3. On Create:

   * Build a new empty `Gpx` model
   * If Track: create one `trk` with one empty `trkseg`
   * If Route: create one empty `rte`
   * Mark doc `isDirty = true`
   * Navigate to `/editor`

---

## Screen: Viewer (Map view mode)

### AppBar

* Back
* Title: filename
* Actions (right):

  1. **Info** → `/details`
  2. **Edit** → `/editor`
  3. **Export** → `/export`

### Map layers (order matters)

In `FlutterMap(children: [...])`, the **last child is topmost**. ([Flutter Map Docs][14])
Use this order:

1. `TileLayer` (base map)
2. `PolylineLayer` (active path line) ([Dart packages][15])
3. `MarkerLayer` (markers for path points and/or waypoints) ([Dart packages][3])

### Polyline rules

* Always draw the active path polyline if there are ≥ 2 points.
* If < 2 points: show a small banner at top: `Not enough points to draw a path.`

### Markers rules

* Always show:

  * Start marker (index 0)
  * End marker (last index)
* If active path has:

  * ≤ 500 points: show all markers
  * > 500 points: show only start/end + every Nth marker (N = ceil(count/500))

    * Provide a toggle in bottom sheet: “Show all markers” (warn about performance)

### Point tap behavior (viewer)

When a point marker is tapped:

* Show a **small callout card** anchored above the marker:

  * Title: `Point #123`
  * `Lat: 12.345678`
  * `Lon: 98.765432`
  * `Ele: 512 m` (only if present)

### Bottom sheet (viewer)

Use `DraggableScrollableSheet`:

* Collapsed height: ~90px
* Expanded height: up to ~55% screen

Collapsed content:

* `Distance: 12.4 km`
* `Points: 1204 • Elev: 210–860 m`

Expanded content:

* “Active path” selector:

  * Track segment dropdown (if track exists)
  * Route dropdown (if routes exist)
  * Toggle for “Show waypoints”
* Buttons:

  * `Details` (go `/details`)
  * `Export` (go `/export`)
* Extra stats:

  * ascent/descent (if elevation exists)
  * duration (if time exists)

---

## Screen: Details

### AppBar

* Back
* Title: `Details`

### Sections

1. **File**

   * Name
   * File size (bytes + KB)
2. **Active path stats**

   * Point count
   * Total length
   * Start coordinate / end coordinate
   * Bounding box
3. **Elevation**

   * Min / max
   * Total ascent / descent
4. **Elevation profile chart**

   * If at least 10 elevation points exist:

     * Render with `fl_chart` `LineChart` ([Dart packages][16])
   * Else:

     * Show text: `No elevation profile available.`

---

## Screen: Editor (Edit/Create mode)

### AppBar

* Back
* Title: filename (append `•` if dirty)
* Actions:

  * Undo
  * Redo
  * Done (go `/export`)

### Discard confirmation

If user taps back and `isDirty == true`:

* Show centered dialog:

  * Title: `Discard changes?`
  * Body: `You have unsaved edits.`
  * Buttons: `Cancel`, `Discard`

### Map layers (editor)

1. `TileLayer`
2. `PolylineLayer`
3. `MarkerLayer` for waypoints (optional, non-draggable)
4. `DragMarkers` for active path points (**must be last/top**) ([Dart packages][2])

### Drag-to-move behavior (editor)

* Each active path point is a `DragMarker`.
* On drag update:

  * Update that point’s lat/lon in the active path model immediately
  * Redraw polyline live
* On drag end:

  * Push `MovePointCommand` into undo stack
  * Mark document dirty
  * Show snackbar: `Point moved`

---

## Point long-press actions (editor)

### Trigger

When a user **long-presses** a path point marker:

* Open a **modal bottom sheet** titled `Point #N`.

### Bottom sheet actions (in order)

1. **Edit coordinates**
2. **Delete point**
3. **Insert before**
4. **Insert after**
5. Cancel (implicit by swipe down)

#### Edit coordinates flow

When **Edit coordinates** tapped:

1. Dismiss bottom sheet
2. Show **centered AlertDialog** with a form:

   * Latitude (required)
   * Longitude (required)
   * Elevation (optional)
3. Buttons: `Cancel`, `Save`
4. Validation:

   * lat in [-90, 90]
   * lon in [-180, 180]
5. On Save:

   * Update point
   * Push `EditCoordinatesCommand`
   * Mark dirty
   * Snackbar: `Point updated`

#### Delete point flow

When **Delete point** tapped:

1. Show centered confirm dialog:

   * Title: `Delete point?`
   * Body: `This will remove Point #N from the path.`
   * Buttons: `Cancel`, `Delete`
2. On Delete:

   * Remove point
   * Push `DeletePointCommand`
   * Mark dirty
   * Snackbar: `Point deleted`

#### Insert before/after flow (quick insert)

When **Insert before** or **Insert after** tapped:

1. Dismiss bottom sheet
2. Show a centered dialog `New point`:

   * Latitude / Longitude / Elevation
   * Buttons: Cancel / Add
3. On Add:

   * Insert at index N (before) or N+1 (after)
   * Push `InsertPointCommand`
   * Mark dirty

---

## Add feature (Add mode)

### Entry

Editor bottom toolbar contains:

* Button: `Add`

When `Add` is tapped:

* Open a **modal bottom sheet** (70% height) titled `Add point` with tabs:

  * `Map`
  * `List`

### Add → Map tab (tap map, then connect/insert)

Behavior:

1. When user taps the map:

   * Create a temporary “New point” marker at that coordinate.
   * Show a slim **action bar** above the bottom sheet:

     * `Insert at end`
     * `Insert before…`
     * `Insert after…`
     * `Cancel`
2. If user taps an existing point marker while the temp point exists:

   * Set that as “anchor point”
   * Update buttons to:

     * `Insert before point #N`
     * `Insert after point #N`
3. If user taps `Insert at end`:

   * Append point
   * Push `InsertPointCommand`
   * Mark dirty
   * Close the add sheet
4. If user taps `Insert before/after…` with no anchor selected:

   * Show a centered dialog: `Select a point first`
5. If user taps Cancel:

   * Remove temp marker
   * Stay in editor

### Add → List tab (insert relative to existing list)

Layout:

* Scrollable list of existing points:

  * Row shows `#N`, lat/lon, elevation
  * Right side button: `+ After`
* At top: `Insert at start`
* At bottom: `Insert at end`

When user taps any insert action:

1. Show centered `New point` dialog with lat/lon/ele
2. On Add:

   * Insert at chosen index
   * Push undo command
   * Mark dirty
3. Do not dismiss add sheet automatically (optional); if you do, be consistent.

---

## Undo/Redo (required)

Implement command stacks:

* `List<EditCommand> undoStack`
* `List<EditCommand> redoStack`

Rules:

* Any new command clears redoStack.
* Undo pops from undoStack, applies `undo()`, pushes to redoStack.
* Redo pops redoStack, applies `redo()`, pushes undoStack.

Commands to implement:

* MovePointCommand
* DeletePointCommand
* InsertPointCommand
* EditCoordinatesCommand

---

## Export (Save + Share)

### Export screen layout

AppBar:

* Back
* Title: `Export`

Body:

* File name text field (default: original name or `untitled.gpx`)
* Toggle: `Pretty format` (default ON)
* Buttons at bottom:

  * `Save As…`
  * `Share`

### Save As…

When **Save As…** tapped:

1. Generate XML via `GpxWriter().asString(gpx, pretty: isPretty)` ([Dart packages][4])
2. Call `FilePicker.platform.saveFile(...)` ([Dart packages][5])
3. If user cancels: do nothing
4. If path returned:

   * Write bytes to that path
   * Set `isDirty = false`
   * Snackbar: `Saved`

### Share

When **Share** tapped:

1. Generate XML
2. Use `getTemporaryDirectory()` to create a temp file path ([Dart packages][7])
3. Write XML bytes to temp file
4. Call `Share.shareXFiles([XFile(tempPath)])` (or equivalent) using `share_plus` ([Dart packages][6])

---

## Stats computations (Details + Viewer sheet)

Use `latlong2.Distance()` to compute total distance along active path (sum distance between consecutive points). Default uses Vincenty. ([Dart packages][8])

Compute:

* `pointCount`
* `totalDistanceMeters`
* `minElevation`, `maxElevation` (ignore null)
* `ascentMeters`, `descentMeters` (sum diffs between consecutive elevation points)
* `bounds`: minLat/maxLat/minLon/maxLon
* `fileSizeBytes`: original bytes length
* If timestamps exist: duration

---

## flutter_map rendering notes (do this)

* Layers stack in `children`; last is topmost. ([Flutter Map Docs][14])
* Place draggable markers layer last so gestures are not intercepted. ([Dart packages][2])
* For polyline interactivity (optional), `PolylineLayer` supports hit testing / minimum hitbox. ([Dart packages][15])

---

## Testing plan (do not skip)

### Unit tests (Dart)

Write tests for:

* GPX parse → active path extraction (route vs track segment)
* Export round-trip:

  * parse → modify → write → parse again → verify point list matches
* Stats service:

  * total distance for known coordinates
  * min/max elevation
  * ascent/descent

### Widget tests

Use `testWidgets` from `flutter_test`. ([Flutter Docs][17])

Test:

* Library screen: tapping Open shows loading dialog then navigates on success (mock services).
* Editor: long press opens point actions bottom sheet.
* Delete confirm dialog appears and deletes on confirm.
* Edit coordinates dialog rejects invalid lat/lon.

### Integration tests (Android emulator + iOS simulator)

Follow Flutter’s integration testing guide. ([Flutter Docs][18])

Automate scenarios:

1. Open GPX fixture → viewer shows distance + points
2. Enter editor → drag point → export → reopen exported file → verify coordinate changed
3. Add point via map tab → insert after anchor → export → reopen and verify count increased
4. Undo/redo works end-to-end

(Performance profiling via integration tests is supported; see Flutter recipe if needed.) ([Flutter Docs][19])

---

## Definition of done (acceptance checklist)

* [ ] Open GPX works on both Android + iOS using native picker
* [ ] Viewer renders markers + polyline in correct point order
* [ ] Details screen shows correct stats (validated against known fixture)
* [ ] Editor supports drag-to-move with live polyline update
* [ ] Long-press point opens actions sheet; delete + edit coordinates works
* [ ] Add mode supports both Map and List workflows
* [ ] Undo/Redo works for move/insert/delete/edit
* [ ] Export can Save As… and Share on both Android + iOS
* [ ] Unit + widget + integration tests exist and pass

---

## Implementation order (recommended)

1. Project skeleton: routing + riverpod providers
2. GPX IO service: open → parse → model; writer
3. Viewer screen: map + polyline + markers + bottom sheet summary
4. Details screen + stats service + elevation chart
5. Editor: drag markers + long-press actions + dialogs
6. Add mode: map insert + list insert
7. Undo/redo
8. Export screen: Save As + Share
9. Testing + performance tuning for large tracks

---

## Future Performance Optimizations (Currently Not Needed)

**Note**: The app currently performs well with large files (5000+ points) after implementing:
- Marker density limits (500 markers max in editor/viewer)
- Elevation chart downsampling (500 points max)
- Point/elevation caching in GpxDocument
- Stats computation caching with Provider.family
- Isolate-based GPX parsing

The following optimizations are documented for future use if needed for extremely large files (10,000+ points):

### Advanced Optimization 1: Viewport-Based Marker Rendering

**When to use**: If users zoom in on large files and still experience lag from off-screen markers

**Implementation**: Filter markers to only render those within the current viewport plus a buffer zone

```dart
class _ViewerScreenState extends ConsumerState<ViewerScreen> {
  final _mapController = MapController();
  LatLngBounds? _visibleBounds;

  @override
  void initState() {
    super.initState();
    _mapController.mapEventStream.listen(_onMapEvent);
  }

  void _onMapEvent(MapEvent event) {
    if (event is MapEventMove || event is MapEventRotate) {
      setState(() {
        _visibleBounds = _mapController.camera.visibleBounds;
      });
    }
  }

  List<Marker> _getVisibleMarkers(List<LatLng> allPoints) {
    if (_visibleBounds == null) return _getAllMarkers(allPoints);

    // Add 20% buffer around visible bounds
    final buffer = 0.2;
    final latRange = _visibleBounds!.north - _visibleBounds!.south;
    final lonRange = _visibleBounds!.east - _visibleBounds!.west;

    final expandedBounds = LatLngBounds(
      LatLng(_visibleBounds!.south - latRange * buffer,
             _visibleBounds!.west - lonRange * buffer),
      LatLng(_visibleBounds!.north + latRange * buffer,
             _visibleBounds!.east + lonRange * buffer),
    );

    return allPoints
        .asMap()
        .entries
        .where((entry) => expandedBounds.contains(entry.value))
        .map((entry) => _createMarker(entry.key, entry.value))
        .toList();
  }

  // In FlutterMap options:
  FlutterMap(
    options: MapOptions(
      initialCenter: center,
      initialZoom: zoom,
    ),
    mapController: _mapController,
    children: [
      TileLayer(...),
      PolylineLayer(...),
      MarkerLayer(markers: _getVisibleMarkers(points)),
    ],
  )
}
```

**Files to modify**:
- `lib/features/viewer/viewer_screen.dart`
- `lib/features/editor/editor_screen.dart` (for DragMarkers layer)

### Advanced Optimization 2: Incremental Polyline Rendering

**When to use**: If polyline redraws cause frame drops during edits on very large files

**Implementation**: Split polyline into segments that can be cached and only redrawn when modified

```dart
List<Polyline> _buildPolylineSegments(List<LatLng> points) {
  const segmentSize = 500;
  final polylines = <Polyline>[];

  for (int i = 0; i < points.length; i += segmentSize) {
    final end = (i + segmentSize < points.length)
        ? i + segmentSize
        : points.length;

    final segmentPoints = points.sublist(i, end);

    polylines.add(Polyline(
      points: segmentPoints,
      strokeWidth: 4.0,
      color: Colors.blue,
    ));
  }

  return polylines;
}

// Usage:
PolylineLayer(
  polylines: _buildPolylineSegments(points),
)
```

**Benefit**: Flutter can cache rendered polyline segments. When a point is edited, only the affected segment needs to be redrawn.

**Files to modify**:
- `lib/features/viewer/viewer_screen.dart`
- `lib/features/editor/editor_screen.dart`

### Advanced Optimization 3: Lazy Elevation Data Loading

**When to use**: If initial file loading is slow due to elevation data extraction

**Implementation**: Make elevation extraction truly lazy, only computing when Details screen is opened

```dart
// In GpxDocument, ensure getActivePathElevations() is only called by:
// - Details screen
// - Elevation chart

// Current implementation already has caching, but could add:
bool _elevationsRequested = false;

List<double?> getActivePathElevations() {
  if (!_elevationsRequested) {
    _elevationsRequested = true;
    // Log or track that elevations are now needed
  }
  // ... existing cached implementation
}
```

**Benefit**: Marginal - elevations are already cached. This would only help if parsing elevation data from GPX is expensive.

---

[1]: https://pub.dev/packages/flutter_map "flutter_map | Flutter package"
[2]: https://pub.dev/packages/flutter_map_dragmarker "flutter_map_dragmarker | Flutter package"
[3]: https://pub.dev/documentation/flutter_map/latest/flutter_map/MarkerLayer-class.html?utm_source=chatgpt.com "MarkerLayer class - flutter_map library - Dart API"
[4]: https://pub.dev/packages/gpx "gpx | Dart package"
[5]: https://pub.dev/packages/file_picker "file_picker | Flutter package"
[6]: https://pub.dev/packages/share_plus?utm_source=chatgpt.com "share_plus | Flutter package"
[7]: https://pub.dev/documentation/path_provider/latest/path_provider/getTemporaryDirectory.html?utm_source=chatgpt.com "getTemporaryDirectory function - path_provider.dart"
[8]: https://pub.dev/documentation/latlong2/latest/latlong2/Distance-class.html?utm_source=chatgpt.com "Distance class - latlong2 library - Dart API"
[9]: https://pub.dev/packages/fl_chart?utm_source=chatgpt.com "fl_chart | Flutter package"
[10]: https://pub.dev/packages/flutter_riverpod?utm_source=chatgpt.com "flutter_riverpod | Flutter package"
[11]: https://pub.dev/packages/go_router?utm_source=chatgpt.com "go_router | Flutter package"
[12]: https://pub.dev/packages/shared_preferences?utm_source=chatgpt.com "shared_preferences | Flutter package"
[13]: https://pub.dev/documentation/go_router/latest/topics/Navigation-topic.html?utm_source=chatgpt.com "Navigation topic - Dart API"
[14]: https://docs.fleaflet.dev/usage/layers?utm_source=chatgpt.com "Layers | flutter_map Docs"
[15]: https://pub.dev/documentation/flutter_map/latest/flutter_map/PolylineLayer-class.html "PolylineLayer class - flutter_map library - Dart API"
[16]: https://pub.dev/documentation/fl_chart/latest/fl_chart/LineChart-class.html?utm_source=chatgpt.com "LineChart class - fl_chart library - Dart API"
[17]: https://docs.flutter.dev/cookbook/testing/widget/introduction?utm_source=chatgpt.com "An introduction to widget testing"
[18]: https://docs.flutter.dev/testing/integration-tests?utm_source=chatgpt.com "Check app functionality with an integration test"
[19]: https://docs.flutter.dev/cookbook/testing/integration/profiling?utm_source=chatgpt.com "Measure performance with an integration test"

