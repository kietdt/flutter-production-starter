// Dev Tools — Showcase
// Responsibility: Render every TextTheme style so a developer can see the
// Material 3 type scale the theme exposes.

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_toggle_button.dart';

class TypographyShowcasePage extends StatelessWidget {
  const TypographyShowcasePage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    final styles = <_TextStyleEntry>[
      _TextStyleEntry('displayLarge', t.displayLarge),
      _TextStyleEntry('displayMedium', t.displayMedium),
      _TextStyleEntry('displaySmall', t.displaySmall),
      _TextStyleEntry('headlineLarge', t.headlineLarge),
      _TextStyleEntry('headlineMedium', t.headlineMedium),
      _TextStyleEntry('headlineSmall', t.headlineSmall),
      _TextStyleEntry('titleLarge', t.titleLarge),
      _TextStyleEntry('titleMedium', t.titleMedium),
      _TextStyleEntry('titleSmall', t.titleSmall),
      _TextStyleEntry('bodyLarge', t.bodyLarge),
      _TextStyleEntry('bodyMedium', t.bodyMedium),
      _TextStyleEntry('bodySmall', t.bodySmall),
      _TextStyleEntry('labelLarge', t.labelLarge),
      _TextStyleEntry('labelMedium', t.labelMedium),
      _TextStyleEntry('labelSmall', t.labelSmall),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Typography'),
        actions: const [ThemeToggleButton()],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: styles.length,
        separatorBuilder: (_, __) => const Divider(height: AppSpacing.lg),
        itemBuilder: (context, index) {
          final entry = styles[index];
          final size = entry.style?.fontSize?.toStringAsFixed(0) ?? '–';
          final weight = entry.style?.fontWeight?.value;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${entry.name}  ·  ${size}px${weight != null ? '  ·  w$weight' : ''}',
                style: t.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const Gap(AppSpacing.xs),
              Text('The quick brown fox', style: entry.style),
            ],
          );
        },
      ),
    );
  }
}

class _TextStyleEntry {
  final String name;
  final TextStyle? style;
  const _TextStyleEntry(this.name, this.style);
}
