import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/thumbnail_service.dart';
import '../../../core/utils/file_utils.dart';
import '../../folder_picker/services/saf_service.dart';
import '../models/swipe_file.dart';

/// Provider for the singleton ThumbnailService.
final thumbnailServiceProvider = Provider((ref) => ThumbnailService.instance);

/// Provider for SAF service (used for copying files to local cache).
final _safServiceProvider = Provider((ref) => SAFService());

/// Provider that holds cached display paths: { contentUri → localPath }.
/// For images: the local copy of the file.
/// For video/PDF: the generated thumbnail path.
/// Widgets watch this to reactively display thumbnails as they become available.
final thumbnailCacheProvider =
    StateNotifierProvider<ThumbnailCacheNotifier, Map<String, String?>>(
  (ref) => ThumbnailCacheNotifier(ref),
);

/// Notifier that manages the display-path cache and handles background preloading.
class ThumbnailCacheNotifier extends StateNotifier<Map<String, String?>> {
  final Ref _ref;

  ThumbnailCacheNotifier(this._ref) : super({});

  /// Number of files to preload ahead of the current index.
  static const int _preloadAhead = 5;

  /// File types that need local caching for display.
  static const _displayTypes = {FileType.image, FileType.video, FileType.pdf};

  /// Generates/caches a display path for [file] and updates the cache.
  Future<void> _generateFor(SwipeFile file) async {
    // Skip if already cached or unsupported type
    if (state.containsKey(file.uri)) return;
    if (!_displayTypes.contains(file.type)) return;

    // Mark as in-progress (null value)
    state = {...state, file.uri: null};

    String? path;
    if (file.type == FileType.image) {
      // Images: copy from SAF to local cache for direct display
      path = await _copyToLocal(file);
    } else {
      // Video/PDF: copy to local then generate thumbnail
      path = await _generateThumbnail(file);
    }

    if (path != null && mounted) {
      state = {...state, file.uri: path};
    }
  }

  /// Copies a SAF document to local cache.
  Future<String?> _copyToLocal(SwipeFile file) async {
    try {
      final safService = _ref.read(_safServiceProvider);
      return await safService.copyToCache(file.uri, file.name);
    } catch (e) {
      return null;
    }
  }

  /// Copies file to local cache, then generates a thumbnail.
  Future<String?> _generateThumbnail(SwipeFile file) async {
    final localPath = await _copyToLocal(file);
    if (localPath == null) return null;

    final service = _ref.read(thumbnailServiceProvider);
    return await service.generateThumbnail(file, localPath);
  }

  /// Preloads display paths for files around [currentIndex].
  /// Call after files are loaded and after each swipe.
  Future<void> preload(List<SwipeFile> files, int currentIndex) async {
    final endIndex = min(currentIndex + _preloadAhead, files.length);

    for (var i = currentIndex; i < endIndex; i++) {
      final file = files[i];

      if (_displayTypes.contains(file.type) &&
          !state.containsKey(file.uri)) {
        // Fire and forget — each file updates the cache independently
        _generateFor(file);
      }
    }
  }

  /// Clears all cached paths (e.g. on folder change).
  void clear() {
    _ref.read(thumbnailServiceProvider).clearCache();
    state = {};
  }
}
