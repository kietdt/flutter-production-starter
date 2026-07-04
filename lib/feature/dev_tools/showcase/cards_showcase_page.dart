// Dev Tools — Showcase
// Responsibility: Preview cards (themed via cardTheme), list tiles and the
// Material 3 surface elevation tints.

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_toggle_button.dart';
import '../widget/showcase_section.dart';

class CardsShowcasePage extends StatelessWidget {
  const CardsShowcasePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cards & Surfaces'),
        actions: const [ThemeToggleButton()],
      ),
      body: ListView(
        children: [
          ShowcaseSection(
            title: 'Card (themed)',
            description: 'Uses cardTheme from app_theme.dart (flat, tinted '
                'surface, large radius).',
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Card title',
                        style: Theme.of(context).textTheme.titleMedium),
                    const Gap(AppSpacing.xs),
                    const Text(
                        'Body content sitting on the themed card surface.'),
                  ],
                ),
              ),
            ),
          ),
          ShowcaseSection(
            title: 'Card variants',
            child: Column(
              children: const [
                Card.filled(
                  child: ListTile(
                    leading: Icon(Icons.layers),
                    title: Text('Card.filled'),
                  ),
                ),
                Gap(AppSpacing.sm),
                Card.outlined(
                  child: ListTile(
                    leading: Icon(Icons.crop_square),
                    title: Text('Card.outlined'),
                  ),
                ),
              ],
            ),
          ),
          ShowcaseSection(
            title: 'ListTile',
            child: Card(
              child: Column(
                children: [
                  const ListTile(
                    leading: CircleAvatar(child: Icon(Icons.person)),
                    title: Text('Single line'),
                    trailing: Icon(Icons.chevron_right),
                  ),
                  const Divider(height: 0),
                  ListTile(
                    leading: const Icon(Icons.notifications_outlined),
                    title: const Text('Two line'),
                    subtitle: const Text('Supporting text below the title'),
                    trailing: Switch(value: true, onChanged: (_) {}),
                  ),
                ],
              ),
            ),
          ),
          ShowcaseSection(
            title: 'Elevation tints',
            description: 'Material 3 tints surfaces by elevation using the '
                'primary color.',
            child: Row(
              children: [
                for (final e in [0.0, 1.0, 3.0, 6.0])
                  Expanded(
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                      child: Material(
                        elevation: e,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        child: SizedBox(
                          height: 64,
                          child: Center(child: Text('e$e')),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
