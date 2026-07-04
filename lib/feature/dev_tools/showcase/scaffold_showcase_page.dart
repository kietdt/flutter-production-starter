// Dev Tools — Showcase
// Responsibility: A fully populated Scaffold so a developer sees how the theme
// affects the most common app chrome at once: AppBar, Drawer, FAB,
// NavigationBar, TabBar and assorted body widgets.

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../core/coordinator/coordinator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_toggle_button.dart';

class ScaffoldShowcasePage extends StatefulWidget {
  const ScaffoldShowcasePage({super.key});

  @override
  State<ScaffoldShowcasePage> createState() => _ScaffoldShowcasePageState();
}

class _ScaffoldShowcasePageState extends State<ScaffoldShowcasePage> {
  int _navIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Scaffold default'),
          actions: const [ThemeToggleButton()],
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'Details'),
              Tab(text: 'Activity'),
            ],
          ),
        ),
        drawer: _buildDrawer(context),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {},
          icon: const Icon(Icons.add),
          label: const Text('Action'),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _navIndex,
          onDestinationSelected: (i) => setState(() => _navIndex = i),
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.home_outlined), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
            NavigationDestination(
                icon: Icon(Icons.person_outline), label: 'Profile'),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Welcome', style: theme.textTheme.headlineSmall),
                    const Gap(AppSpacing.xs),
                    Text(
                      'This Scaffold combines the app chrome and common body '
                      'widgets so every themed surface is visible at once.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const Gap(AppSpacing.md),
                    Row(
                      children: [
                        FilledButton(
                            onPressed: () {}, child: const Text('Primary')),
                        const Gap(AppSpacing.sm),
                        OutlinedButton(
                            onPressed: () {}, child: const Text('Secondary')),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Gap(AppSpacing.md),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Search',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const Gap(AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                for (final t in ['All', 'Design', 'Code', 'Docs'])
                  FilterChip(
                      label: Text(t), selected: t == 'All', onSelected: (_) {}),
              ],
            ),
            const Gap(AppSpacing.sm),
            ...List.generate(
              3,
              (i) => ListTile(
                leading: CircleAvatar(child: Text('${i + 1}')),
                title: Text('List item ${i + 1}'),
                subtitle: const Text('Supporting line of text'),
                trailing: const Icon(Icons.chevron_right),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final theme = Theme.of(context);
    return NavigationDrawer(
      onDestinationSelected: (_) => Coordinator.pop(context),
      children: [
        DrawerHeader(
          decoration: BoxDecoration(color: theme.colorScheme.primaryContainer),
          child: Align(
            alignment: Alignment.bottomLeft,
            child: Text(
              'Menu',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ),
        const NavigationDrawerDestination(
            icon: Icon(Icons.dashboard_outlined), label: Text('Dashboard')),
        const NavigationDrawerDestination(
            icon: Icon(Icons.settings_outlined), label: Text('Settings')),
      ],
    );
  }
}
