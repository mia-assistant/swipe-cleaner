import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/utils/file_utils.dart';
import '../../swipe/models/swipe_file.dart';

/// Service for SAF (Storage Access Framework) operations.
/// Uses a Kotlin platform channel for all file access via content URIs.
class SAFService {
  static const _channel = MethodChannel('com.manuelpa.swipecleaner/saf');

  String? _cacheDir;

  /// Opens the SAF directory picker and returns {uri, name} or null.
  Future<({String uri, String name})?> pickFolder() async {
    final result = await _channel.invokeMethod('pickDirectory');
    if (result == null) return null;
    final map = Map<String, dynamic>.from(result as Map);
    return (uri: map['uri'] as String, name: map['name'] as String);
  }

  /// Opens the SAF directory picker pre-navigated to Downloads.
  /// Returns {uri, name} or null if the user cancelled.
  Future<({String uri, String name})?> pickDownloadsFolder() async {
    final result = await _channel.invokeMethod(
      'pickDirectory',
      {'startWithDownloads': true},
    );
    if (result == null) return null;
    final map = Map<String, dynamic>.from(result as Map);
    return (uri: map['uri'] as String, name: map['name'] as String);
  }

  /// Lists all files in a SAF tree URI.
  Future<List<SwipeFile>> listFiles(String treeUri) async {
    final result = await _channel.invokeMethod('listFiles', {'treeUri': treeUri});
    if (result == null) return [];

    final list = (result as List).cast<Map>();
    final files = list.map((map) {
      final name = map['name'] as String;
      final extension = FileUtils.getExtension(name);
      final type = FileUtils.detectFileType(extension);

      return SwipeFile(
        uri: map['uri'] as String,
        name: name,
        extension: extension,
        sizeBytes: (map['sizeBytes'] as num).toInt(),
        modified: DateTime.fromMillisecondsSinceEpoch(
          (map['modified'] as num).toInt(),
        ),
        type: type,
      );
    }).toList();

    // Sort by modified date, newest first
    files.sort((a, b) => b.modified.compareTo(a.modified));

    return files;
  }

  /// Deletes a document by its SAF content URI.
  Future<bool> deleteDocument(String uri) async {
    final result = await _channel.invokeMethod<bool>(
      'deleteDocument',
      {'uri': uri},
    );
    return result ?? false;
  }

  /// Deletes multiple documents. Returns the count of successfully deleted.
  Future<int> deleteFiles(List<String> uris) async {
    int deleted = 0;
    for (final uri in uris) {
      try {
        if (await deleteDocument(uri)) deleted++;
      } catch (_) {}
    }
    return deleted;
  }

  /// Deletes a single file (alias for deleteDocument).
  Future<void> deleteFile(String uri) async {
    await deleteDocument(uri);
  }

  /// Copies a SAF document to local cache for display/processing.
  /// Returns the local filesystem path.
  Future<String> copyToCache(String contentUri, String fileName) async {
    _cacheDir ??= '${(await getTemporaryDirectory()).path}/saf_cache';

    // Use hash of content URI + original extension for uniqueness
    final cacheKey = contentUri.hashCode.toRadixString(16);
    final ext = p.extension(fileName);
    final destPath = '$_cacheDir/$cacheKey$ext';

    // Return immediately if already cached
    if (await File(destPath).exists()) return destPath;

    final result = await _channel.invokeMethod<String>(
      'copyToCache',
      {'uri': contentUri, 'destPath': destPath},
    );

    return result ?? destPath;
  }

  /// Clears the local SAF cache.
  Future<void> clearCache() async {
    if (_cacheDir != null) {
      final dir = Directory(_cacheDir!);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    }
    _cacheDir = null;
  }

  /// Gets the display name of a folder.
  /// Used as fallback; prefer the name returned by pickFolder().
  String getFolderName(String uriOrName) {
    if (!uriOrName.contains('/')) return uriOrName;
    return Uri.parse(uriOrName).pathSegments.lastOrNull ?? uriOrName;
  }
}
