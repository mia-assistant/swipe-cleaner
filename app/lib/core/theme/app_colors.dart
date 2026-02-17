import 'package:flutter/material.dart';

/// App color palette for light and dark themes
class AppColors {
  AppColors._();

  // Light Theme Colors
  static const Color lightBackground = Color(0xFFF8F7FC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightPrimary = Color(0xFF1A1A1A);
  static const Color lightAccent = Color(0xFF4F46E5);
  static const Color lightKeep = Color(0xFF10B981);
  static const Color lightDelete = Color(0xFFEF4444);
  static const Color lightMuted = Color(0xFF9CA3AF);

  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF0A0A0F);
  static const Color darkSurface = Color(0xFF16151F);
  static const Color darkPrimary = Color(0xFFFAFAFA);
  static const Color darkAccent = Color(0xFF8B5CF6);
  static const Color darkKeep = Color(0xFF34D399);
  static const Color darkDelete = Color(0xFFF87171);
  static const Color darkMuted = Color(0xFF6B7280);

  // Semantic colors that adapt to theme
  static Color background(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light
          ? lightBackground
          : darkBackground;

  static Color surface(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light
          ? lightSurface
          : darkSurface;

  static Color primary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light
          ? lightPrimary
          : darkPrimary;

  static Color accent(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light
          ? lightAccent
          : darkAccent;

  static Color keep(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light
          ? lightKeep
          : darkKeep;

  static Color delete(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light
          ? lightDelete
          : darkDelete;

  static Color muted(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light
          ? lightMuted
          : darkMuted;
}
