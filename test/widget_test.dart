import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:routesmith/main.dart';
import 'package:routesmith/data/recent_files_store.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Initialize SharedPreferences for testing
    SharedPreferences.setMockInitialValues({});
    final sharedPreferences = await SharedPreferences.getInstance();

    // Build our app with ProviderScope and trigger a frame.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        ],
        child: const GPXEditorApp(),
      ),
    );

    // Wait for the app to build
    await tester.pumpAndSettle();

    // Verify that the Library screen is displayed
    expect(find.text('RouteSmith'), findsOneWidget);
    expect(find.text('Open GPX'), findsOneWidget);
    expect(find.text('New GPX'), findsOneWidget);
  });
}
