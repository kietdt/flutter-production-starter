// Dev Tools — Registry
// Responsibility: Single source of truth for the showcases rendered on the
// gallery home. Add a showcase by appending one entry here.

import 'package:flutter/material.dart';

import '../model/dev_showcase.dart';
import '../showcase/buttons_showcase_page.dart';
import '../showcase/cards_showcase_page.dart';
import '../showcase/color_showcase_page.dart';
import '../showcase/feedback_showcase_page.dart';
import '../showcase/inputs_showcase_page.dart';
import '../showcase/scaffold_showcase_page.dart';
import '../showcase/typography_showcase_page.dart';

const List<DevShowcase> kShowcases = [
  DevShowcase(
    title: 'Scaffold default',
    description: 'AppBar, Drawer, FAB, NavigationBar, Tabs & body widgets',
    icon: Icons.web_asset,
    pageBuilder: _scaffold,
  ),
  DevShowcase(
    title: 'Colors',
    description: 'Every ColorScheme role from the seed color',
    icon: Icons.palette_outlined,
    pageBuilder: _colors,
  ),
  DevShowcase(
    title: 'Typography',
    description: 'The full Material 3 text scale',
    icon: Icons.text_fields,
    pageBuilder: _typography,
  ),
  DevShowcase(
    title: 'Buttons',
    description: 'Filled, elevated, outlined, icon, FAB, segmented',
    icon: Icons.smart_button_outlined,
    pageBuilder: _buttons,
  ),
  DevShowcase(
    title: 'Inputs & Selection',
    description: 'TextField, checkbox, switch, radio, slider, chips',
    icon: Icons.edit_outlined,
    pageBuilder: _inputs,
  ),
  DevShowcase(
    title: 'Cards & Surfaces',
    description: 'Cards, list tiles, elevation tints',
    icon: Icons.dashboard_outlined,
    pageBuilder: _cards,
  ),
  DevShowcase(
    title: 'Feedback',
    description: 'SnackBar, dialog, bottom sheet, tooltip, progress',
    icon: Icons.notifications_outlined,
    pageBuilder: _feedback,
  ),
];

// Tear-off builders kept top-level so [kShowcases] stays a `const` list.
Widget _scaffold(BuildContext context) => const ScaffoldShowcasePage();
Widget _colors(BuildContext context) => const ColorShowcasePage();
Widget _typography(BuildContext context) => const TypographyShowcasePage();
Widget _buttons(BuildContext context) => const ButtonsShowcasePage();
Widget _inputs(BuildContext context) => const InputsShowcasePage();
Widget _cards(BuildContext context) => const CardsShowcasePage();
Widget _feedback(BuildContext context) => const FeedbackShowcasePage();
