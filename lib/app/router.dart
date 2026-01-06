import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:routesmith/features/library/library_screen.dart';
import 'package:routesmith/features/viewer/viewer_screen.dart';
import 'package:routesmith/features/details/details_screen.dart';
import 'package:routesmith/features/editor/editor_screen.dart';
import 'package:routesmith/features/export/export_screen.dart';

/// Application router configuration using GoRouter
class AppRouter {
  /// Private constructor to prevent instantiation
  AppRouter._();

  /// Router configuration
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'library',
        builder: (context, state) => const LibraryScreen(),
      ),
      GoRoute(
        path: '/viewer',
        name: 'viewer',
        builder: (context, state) => const ViewerScreen(),
      ),
      GoRoute(
        path: '/details',
        name: 'details',
        builder: (context, state) => const DetailsScreen(),
      ),
      GoRoute(
        path: '/editor',
        name: 'editor',
        builder: (context, state) => const EditorScreen(),
      ),
      GoRoute(
        path: '/export',
        name: 'export',
        builder: (context, state) => const ExportScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.uri.path}'),
      ),
    ),
  );
}
