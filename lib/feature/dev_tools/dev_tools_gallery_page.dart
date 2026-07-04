// Dev Tools — Main Screen
// Responsibility: Gallery home. Renders a grid of showcase cards from the
// registry; tapping a card opens the matching detail page.

import 'package:flutter/material.dart';

import '../../core/coordinator/coordinator.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_toggle_button.dart';
import 'model/dev_showcase.dart';
import 'registry/showcase_registry.dart';
import 'widget/showcase_card.dart';

class DevToolsGalleryPage extends StatelessWidget {
  const DevToolsGalleryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Theme Gallery'),
        actions: const [ThemeToggleButton()],
      ),
      body: SafeArea(
        child: GridView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 220,
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.md,
            childAspectRatio: 1.05,
          ),
          itemCount: kShowcases.length,
          itemBuilder: (context, index) {
            final showcase = kShowcases[index];
            return ShowcaseCard(
              showcase: showcase,
              onTap: () => _open(context, showcase),
            );
          },
        ),
      ),
    );
  }

  void _open(BuildContext context, DevShowcase showcase) {
    Coordinator.openShowcase(context, showcase.pageBuilder);
  }
}
