// Core Theme Module
// Responsibility: Brand seed color and shared design tokens (spacing, radius).
// These tokens keep the UI consistent and make the theme easy to rebrand.

import 'package:flutter/material.dart';

/// Brand colors. The whole [ColorScheme] is derived from [seed] via
/// `ColorScheme.fromSeed`, so changing this single value rebrands the app.
class AppColors {
  AppColors._();

  /// Primary brand seed used to generate the Material 3 color scheme.
  static const Color seed = Color(0xFF2962FF);

  /// Semantic accent used for destructive/error affordances.
  static const Color danger = Color(0xFFD32F2F);
}

/// Consistent spacing scale (in logical pixels) for paddings and gaps.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

/// Corner radii used across cards, buttons and inputs.
class AppRadius {
  AppRadius._();

  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
}
