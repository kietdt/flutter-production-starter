// Dev Tools — Showcase
// Responsibility: Preview every role of the active ColorScheme so a developer
// sees exactly what `ColorScheme.fromSeed(seedColor: AppColors.seed)` produces.

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_toggle_button.dart';
import '../widget/showcase_section.dart';

class ColorShowcasePage extends StatelessWidget {
  const ColorShowcasePage({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // (label, color, onColor) for the main paired roles.
    final pairs = <_ColorRole>[
      _ColorRole('primary', scheme.primary, scheme.onPrimary),
      _ColorRole('primaryContainer', scheme.primaryContainer,
          scheme.onPrimaryContainer),
      _ColorRole('secondary', scheme.secondary, scheme.onSecondary),
      _ColorRole('secondaryContainer', scheme.secondaryContainer,
          scheme.onSecondaryContainer),
      _ColorRole('tertiary', scheme.tertiary, scheme.onTertiary),
      _ColorRole('tertiaryContainer', scheme.tertiaryContainer,
          scheme.onTertiaryContainer),
      _ColorRole('error', scheme.error, scheme.onError),
      _ColorRole(
          'errorContainer', scheme.errorContainer, scheme.onErrorContainer),
      _ColorRole('surface', scheme.surface, scheme.onSurface),
      _ColorRole('surfaceContainerHighest', scheme.surfaceContainerHighest,
          scheme.onSurfaceVariant),
      _ColorRole(
          'inverseSurface', scheme.inverseSurface, scheme.onInverseSurface),
      _ColorRole('outline', scheme.outline, scheme.surface),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Colors'),
        actions: const [ThemeToggleButton()],
      ),
      body: ListView(
        children: [
          ShowcaseSection(
            title: 'Seed',
            description: 'Whole scheme is generated from AppColors.seed via '
                'ColorScheme.fromSeed. Brightness: ${scheme.brightness.name}.',
            child: _SwatchTile(
              role: _ColorRole('seed', AppColors.seed, Colors.white),
            ),
          ),
          ShowcaseSection(
            title: 'ColorScheme roles',
            description: 'Each tile shows the role color with its "on" color '
                'as text — exactly how Material 3 widgets pick contrast.',
            child: Column(
              children: [
                for (final role in pairs) ...[
                  _SwatchTile(role: role),
                  const Gap(AppSpacing.sm),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ColorRole {
  final String name;
  final Color color;
  final Color onColor;
  const _ColorRole(this.name, this.color, this.onColor);
}

/// Formats a [Color] as an #AARRGGBB string using the 0..1 component getters
/// (compatible with Flutter 3.27, where `toARGB32()` isn't available yet).
String _hex(Color c) {
  String channel(double v) =>
      (v * 255).round().toRadixString(16).padLeft(2, '0').toUpperCase();
  return '${channel(c.a)}${channel(c.r)}${channel(c.g)}${channel(c.b)}';
}

class _SwatchTile extends StatelessWidget {
  final _ColorRole role;
  const _SwatchTile({required this.role});

  @override
  Widget build(BuildContext context) {
    final hex = _hex(role.color);
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: role.color,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(role.name, style: TextStyle(color: role.onColor)),
          Text('#$hex',
              style: TextStyle(color: role.onColor, fontFamily: 'monospace')),
        ],
      ),
    );
  }
}
