import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Service to persist and restore swipe session progress
class SessionStorageService {
  static const _key = 'swipe_session';

  /// Save current session state
  static Future<void> saveSession(SwipeSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(session.toJson()));
  }

  /// Load saved session, if any
  static Future<SwipeSession?> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_key);
    if (json == null) return null;

    try {
      return SwipeSession.fromJson(jsonDecode(json));
    } catch (e) {
      // Corrupted data, clear it
      await clearSession();
      return null;
    }
  }

  /// Check if a saved session exists
  static Future<bool> hasSession() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_key);
  }

  /// Clear saved session
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

/// Saved swipe session data
class SwipeSession {
  final String folderUri;
  final String folderName;
  final List<String> toDeleteUris;
  final List<String> toKeepUris;
  final DateTime savedAt;

  SwipeSession({
    required this.folderUri,
    required this.folderName,
    required this.toDeleteUris,
    required this.toKeepUris,
    required this.savedAt,
  });

  int get totalReviewed => toDeleteUris.length + toKeepUris.length;

  Map<String, dynamic> toJson() => {
        'folderUri': folderUri,
        'folderName': folderName,
        'toDeleteUris': toDeleteUris,
        'toKeepUris': toKeepUris,
        'savedAt': savedAt.toIso8601String(),
      };

  factory SwipeSession.fromJson(Map<String, dynamic> json) => SwipeSession(
        folderUri: json['folderUri'] as String,
        folderName: json['folderName'] as String,
        toDeleteUris: List<String>.from(json['toDeleteUris']),
        toKeepUris: List<String>.from(json['toKeepUris']),
        savedAt: DateTime.parse(json['savedAt'] as String),
      );
}
