// Dev Tools — Widget
// Responsibility: Consistent "title + optional description + demo" block used
// by every detail showcase page.

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../core/theme/app_colors.dart';

class ShowcaseSection extends StatelessWidget {
  final String title;
  final String? description;
  final Widget child;

  const ShowcaseSection({
    super.key,
    required this.title,
    this.description,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleMedium),
          if (description != null) ...[
            const Gap(AppSpacing.xs),
            Text(
              description!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const Gap(AppSpacing.md),
          child,
          const Divider(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

/// A horizontal-wrapping row with consistent gaps, handy for laying out a set
/// of demo widgets (buttons, chips, swatches) inside a [ShowcaseSection].
class ShowcaseWrap extends StatelessWidget {
  final List<Widget> children;

  const ShowcaseWrap({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: children,
    );
  }
}
