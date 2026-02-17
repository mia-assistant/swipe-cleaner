import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Gradient definitions for visual polish
class AppGradients {
  AppGradients._();

  // Primary accent gradients (deep indigo → violet)
  static const LinearGradient accentLight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF4F46E5), // Indigo 600
      Color(0xFF7C3AED), // Violet 600
    ],
  );

  static const LinearGradient accentDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF8B5CF6), // Violet 500
      Color(0xFFA78BFA), // Violet 400
    ],
  );

  // Background gradients with visible warmth
  static const LinearGradient backgroundLight = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFFBFAFE), // Warm near-white with violet tint
      Color(0xFFEDE9F7), // Clear violet tint
    ],
  );

  static const LinearGradient backgroundDark = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF0A0A0F),
      Color(0xFF110D1F), // Visible violet dark tint
    ],
  );

  // Card surface gradients (subtle shimmer effect)
  static const LinearGradient cardLight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFFFFF),
      Color(0xFFF9F7FF), // Noticeable violet tint
    ],
  );

  static const LinearGradient cardDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1A1A22),
      Color(0xFF181725), // Visible violet tint
    ],
  );

  // Keep/Delete action gradients
  static const LinearGradient keepGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF10B981), // Emerald 500
      Color(0xFF059669), // Emerald 600
    ],
  );

  static const LinearGradient deleteGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFEF4444), // Red 500
      Color(0xFFDC2626), // Red 600
    ],
  );

  // Semantic gradient getters
  static LinearGradient accent(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light
          ? accentLight
          : accentDark;

  static LinearGradient background(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light
          ? backgroundLight
          : backgroundDark;

  static LinearGradient card(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light
          ? cardLight
          : cardDark;
}

/// Polished shadow definitions
class AppShadows {
  AppShadows._();

  // Soft elevation shadows for light mode
  static List<BoxShadow> cardLight = [
    BoxShadow(
      color: const Color(0xFF4F46E5).withOpacity(0.10),
      blurRadius: 24,
      offset: const Offset(0, 8),
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
      spreadRadius: 0,
    ),
  ];

  // Subtle glow for dark mode
  static List<BoxShadow> cardDark = [
    BoxShadow(
      color: const Color(0xFF8B5CF6).withOpacity(0.12),
      blurRadius: 32,
      offset: const Offset(0, 8),
      spreadRadius: -4,
    ),
  ];

  // Elevated shadows (buttons, FABs)
  static List<BoxShadow> elevatedLight = [
    BoxShadow(
      color: const Color(0xFF4F46E5).withOpacity(0.30),
      blurRadius: 16,
      offset: const Offset(0, 4),
      spreadRadius: 0,
    ),
    BoxShadow(
      color: const Color(0xFF4F46E5).withOpacity(0.12),
      blurRadius: 4,
      offset: const Offset(0, 2),
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> elevatedDark = [
    BoxShadow(
      color: const Color(0xFF8B5CF6).withOpacity(0.25),
      blurRadius: 20,
      offset: const Offset(0, 4),
      spreadRadius: -2,
    ),
  ];

  // Semantic shadow getters
  static List<BoxShadow> card(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light
          ? cardLight
          : cardDark;

  static List<BoxShadow> elevated(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light
          ? elevatedLight
          : elevatedDark;
}
