import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gpxer/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const GPXEditorApp());

    // Verify that the Library screen is displayed
    expect(find.text('GPX Editor'), findsOneWidget);
    expect(find.text('Open GPX'), findsOneWidget);
    expect(find.text('New GPX'), findsOneWidget);
  });
}
