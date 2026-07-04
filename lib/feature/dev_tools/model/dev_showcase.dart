// Dev Tools — Model
// Responsibility: Describe a single entry in the theme gallery.

import 'package:flutter/material.dart';

/// One showcase entry rendered as a card on the gallery home. Tapping a card
/// pushes the page built by [pageBuilder].
class DevShowcase {
  final String title;
  final String description;
  final IconData icon;
  final WidgetBuilder pageBuilder;

  const DevShowcase({
    required this.title,
    required this.description,
    required this.icon,
    required this.pageBuilder,
  });
}
