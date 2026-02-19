import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/saf_service.dart';

/// Provider for SAF service
final safServiceProvider = Provider<SAFService>((ref) {
  return SAFService();
});

/// Provider for folder state
final folderProvider =
    StateNotifierProvider<FolderNotifier, FolderState>((ref) {
  return FolderNotifier(ref.read(safServiceProvider));
});

/// State for selected folder
class FolderState {
  final String? folderPath;
  final String? folderName;
  final bool isLoading;
  final String? error;

  const FolderState({
    this.folderPath,
    this.folderName,
    this.isLoading = false,
    this.error,
  });

  bool get hasFolder => folderPath != null;

  FolderState copyWith({
    String? folderPath,
    String? folderName,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool clearFolder = false,
  }) {
    return FolderState(
      folderPath: clearFolder ? null : (folderPath ?? this.folderPath),
      folderName: clearFolder ? null : (folderName ?? this.folderName),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Notifier for folder state
class FolderNotifier extends StateNotifier<FolderState> {
  final SAFService _safService;

  FolderNotifier(this._safService) : super(const FolderState());

  /// Opens the SAF folder picker and updates state
  Future<bool> pickFolder() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final result = await _safService.pickFolder();

      if (result == null) {
        // User cancelled
        state = state.copyWith(isLoading: false);
        return false;
      }

      state = state.copyWith(
        folderPath: result.uri,
        folderName: result.name,
        isLoading: false,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to pick folder: $e',
      );
      return false;
    }
  }

  /// Clears the selected folder
  void clearFolder() {
    state = state.copyWith(clearFolder: true);
  }

  /// Opens the SAF picker pre-navigated to Downloads
  Future<bool> selectDownloads() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final result = await _safService.pickDownloadsFolder();

      if (result == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Folder selection cancelled. '
              'Please select a folder to continue.',
        );
        return false;
      }

      state = state.copyWith(
        folderPath: result.uri,
        folderName: result.name,
        isLoading: false,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to access Downloads: $e',
      );
      return false;
    }
  }

  /// Sets the folder directly (for testing or restoring state)
  void setFolder(String path, [String? name]) {
    final folderName = name ?? _safService.getFolderName(path);
    state = state.copyWith(
      folderPath: path,
      folderName: folderName,
    );
  }
}
