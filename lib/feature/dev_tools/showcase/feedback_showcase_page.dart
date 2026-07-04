// Dev Tools — Showcase
// Responsibility: Trigger the transient Material 3 surfaces — SnackBar (themed),
// Dialog, BottomSheet, Tooltip — plus progress indicators.

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../core/coordinator/coordinator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_toggle_button.dart';
import '../widget/showcase_section.dart';

class FeedbackShowcasePage extends StatelessWidget {
  const FeedbackShowcasePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feedback'),
        actions: const [ThemeToggleButton()],
      ),
      body: ListView(
        children: [
          ShowcaseSection(
            title: 'SnackBar',
            description: 'Floating + rounded from snackBarTheme in '
                'app_theme.dart.',
            child: ShowcaseWrap(
              children: [
                FilledButton(
                  onPressed: () => _showSnackBar(context),
                  child: const Text('Show SnackBar'),
                ),
                FilledButton.tonal(
                  onPressed: () => _showSnackBar(context, action: true),
                  child: const Text('With action'),
                ),
              ],
            ),
          ),
          ShowcaseSection(
            title: 'Dialog',
            child: ShowcaseWrap(
              children: [
                FilledButton(
                  onPressed: () => _showDialog(context),
                  child: const Text('AlertDialog'),
                ),
              ],
            ),
          ),
          ShowcaseSection(
            title: 'Bottom sheet',
            child: ShowcaseWrap(
              children: [
                FilledButton(
                  onPressed: () => _showSheet(context),
                  child: const Text('Modal sheet'),
                ),
              ],
            ),
          ),
          ShowcaseSection(
            title: 'Tooltip',
            description: 'Long-press / hover the icon.',
            child: Tooltip(
              message: 'Tooltip message',
              child: IconButton(
                onPressed: () {},
                icon: const Icon(Icons.info_outline),
              ),
            ),
          ),
          ShowcaseSection(
            title: 'Progress indicators',
            child: Row(
              children: const [
                CircularProgressIndicator(),
                Gap(AppSpacing.lg),
                Expanded(child: LinearProgressIndicator()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(BuildContext context, {bool action = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('This is a themed SnackBar'),
        action: action ? SnackBarAction(label: 'Undo', onPressed: () {}) : null,
      ),
    );
  }

  Future<void> _showDialog(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.help_outline),
        title: const Text('Dialog title'),
        content: const Text('Supporting text explaining the action.'),
        actions: [
          TextButton(
            onPressed: () => Coordinator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Coordinator.pop(context),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Future<void> _showSheet(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bottom sheet', style: Theme.of(context).textTheme.titleLarge),
            const Gap(AppSpacing.sm),
            const Text('Modal content anchored to the bottom of the screen.'),
            const Gap(AppSpacing.lg),
            FilledButton(
              onPressed: () => Coordinator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}
