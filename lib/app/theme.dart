import 'package:flutter/material.dart';

/// Application theme configuration for GPX Editor
/// Uses Material 3 design system
class AppTheme {
  /// Private constructor to prevent instantiation
  AppTheme._();

  /// Light theme configuration
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
      ),
      cardTheme: const CardTheme(
        elevation: 2,
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
    );
  }

  /// Dark theme configuration (optional, can be added later)
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.dark,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
      ),
      cardTheme: const CardTheme(
        elevation: 2,
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
    );
  }
}

/// Icon mappings for consistent usage across the app
class AppIcons {
  AppIcons._();

  // Navigation and actions
  static const IconData open = Icons.folder;
  static const IconData createNew = Icons.add;
  static const IconData details = Icons.info;
  static const IconData edit = Icons.edit;
  static const IconData export = Icons.share;
  static const IconData save = Icons.save;

  // Undo/Redo
  static const IconData undo = Icons.undo;
  static const IconData redo = Icons.redo;

  // Map markers
  static const IconData marker = Icons.location_on;
  static const IconData addLocation = Icons.add_location;

  // Point actions
  static const IconData delete = Icons.delete;
  static const IconData editCoordinates = Icons.edit_location;

  // Navigation
  static const IconData back = Icons.arrow_back;
  static const IconData done = Icons.check;
}
