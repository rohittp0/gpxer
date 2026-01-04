import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gpxer/domain/models/edit_command.dart';
import 'package:gpxer/domain/models/gpx_document.dart';

/// Service for managing undo/redo operations
class UndoRedoService {
  final List<EditCommand> _undoStack = [];
  final List<EditCommand> _redoStack = [];

  /// Whether undo is available
  bool get canUndo => _undoStack.isNotEmpty;

  /// Whether redo is available
  bool get canRedo => _redoStack.isNotEmpty;

  /// Execute a command and add it to the undo stack
  GpxDocument executeCommand(EditCommand command, GpxDocument doc) {
    final newDoc = command.execute(doc);
    _undoStack.add(command);
    _redoStack.clear(); // Clear redo stack when new command is executed
    return newDoc;
  }

  /// Undo the last command
  GpxDocument? undo(GpxDocument doc) {
    if (!canUndo) return null;

    final command = _undoStack.removeLast();
    final newDoc = command.undo(doc);
    _redoStack.add(command);
    return newDoc;
  }

  /// Redo the last undone command
  GpxDocument? redo(GpxDocument doc) {
    if (!canRedo) return null;

    final command = _redoStack.removeLast();
    final newDoc = command.redo(doc);
    _undoStack.add(command);
    return newDoc;
  }

  /// Clear all undo/redo history
  void clear() {
    _undoStack.clear();
    _redoStack.clear();
  }
}

/// Provider for undo/redo service
final undoRedoServiceProvider = Provider<UndoRedoService>((ref) {
  return UndoRedoService();
});

/// Provider for tracking undo/redo state
final undoRedoStateProvider = StateNotifierProvider<UndoRedoStateNotifier, UndoRedoState>((ref) {
  return UndoRedoStateNotifier();
});

/// State for undo/redo availability
class UndoRedoState {
  final bool canUndo;
  final bool canRedo;

  const UndoRedoState({
    required this.canUndo,
    required this.canRedo,
  });

  UndoRedoState copyWith({bool? canUndo, bool? canRedo}) {
    return UndoRedoState(
      canUndo: canUndo ?? this.canUndo,
      canRedo: canRedo ?? this.canRedo,
    );
  }
}

/// State notifier for undo/redo state
class UndoRedoStateNotifier extends StateNotifier<UndoRedoState> {
  UndoRedoStateNotifier() : super(const UndoRedoState(canUndo: false, canRedo: false));

  void update(bool canUndo, bool canRedo) {
    state = UndoRedoState(canUndo: canUndo, canRedo: canRedo);
  }
}
