// Dev Tools — Showcase
// Responsibility: Preview the Material 3 button family, including how the
// theme's FilledButton/ElevatedButton styles apply, in enabled + disabled states.

import 'package:flutter/material.dart';

import '../../../core/theme/theme_toggle_button.dart';
import '../widget/showcase_section.dart';

class ButtonsShowcasePage extends StatelessWidget {
  const ButtonsShowcasePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buttons'),
        actions: const [ThemeToggleButton()],
      ),
      body: ListView(
        children: [
          ShowcaseSection(
            title: 'FilledButton',
            description: 'Styled by filledButtonTheme in app_theme.dart '
                '(min height 52, rounded ${12}px).',
            child: ShowcaseWrap(
              children: [
                FilledButton(onPressed: () {}, child: const Text('Enabled')),
                const FilledButton(onPressed: null, child: Text('Disabled')),
                FilledButton.tonal(
                    onPressed: () {}, child: const Text('Tonal')),
                FilledButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add),
                  label: const Text('Icon'),
                ),
              ],
            ),
          ),
          ShowcaseSection(
            title: 'ElevatedButton',
            description: 'Styled by elevatedButtonTheme in app_theme.dart.',
            child: ShowcaseWrap(
              children: [
                ElevatedButton(onPressed: () {}, child: const Text('Enabled')),
                const ElevatedButton(onPressed: null, child: Text('Disabled')),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.save),
                  label: const Text('Icon'),
                ),
              ],
            ),
          ),
          ShowcaseSection(
            title: 'OutlinedButton & TextButton',
            description: 'Material 3 defaults (not themed).',
            child: ShowcaseWrap(
              children: [
                OutlinedButton(onPressed: () {}, child: const Text('Outlined')),
                const OutlinedButton(onPressed: null, child: Text('Disabled')),
                TextButton(onPressed: () {}, child: const Text('Text')),
                const TextButton(onPressed: null, child: Text('Disabled')),
              ],
            ),
          ),
          ShowcaseSection(
            title: 'Icon buttons',
            child: ShowcaseWrap(
              children: [
                IconButton(onPressed: () {}, icon: const Icon(Icons.favorite)),
                IconButton.filled(
                    onPressed: () {}, icon: const Icon(Icons.favorite)),
                IconButton.filledTonal(
                    onPressed: () {}, icon: const Icon(Icons.favorite)),
                IconButton.outlined(
                    onPressed: () {}, icon: const Icon(Icons.favorite)),
                const IconButton(onPressed: null, icon: Icon(Icons.favorite)),
              ],
            ),
          ),
          ShowcaseSection(
            title: 'FloatingActionButton',
            child: ShowcaseWrap(
              children: [
                FloatingActionButton.small(
                    onPressed: () {}, child: const Icon(Icons.add)),
                FloatingActionButton(
                    onPressed: () {}, child: const Icon(Icons.add)),
                FloatingActionButton.extended(
                  onPressed: () {},
                  icon: const Icon(Icons.edit),
                  label: const Text('Extended'),
                ),
              ],
            ),
          ),
          ShowcaseSection(
            title: 'SegmentedButton',
            child: const _SegmentedDemo(),
          ),
        ],
      ),
    );
  }
}

class _SegmentedDemo extends StatefulWidget {
  const _SegmentedDemo();

  @override
  State<_SegmentedDemo> createState() => _SegmentedDemoState();
}

class _SegmentedDemoState extends State<_SegmentedDemo> {
  Set<int> _selected = {0};

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<int>(
      segments: const [
        ButtonSegment(value: 0, label: Text('Day'), icon: Icon(Icons.today)),
        ButtonSegment(value: 1, label: Text('Week')),
        ButtonSegment(value: 2, label: Text('Month')),
      ],
      selected: _selected,
      onSelectionChanged: (s) => setState(() => _selected = s),
    );
  }
}
