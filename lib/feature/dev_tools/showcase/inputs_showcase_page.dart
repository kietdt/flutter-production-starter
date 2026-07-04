// Dev Tools — Showcase
// Responsibility: Preview text fields (which pick up inputDecorationTheme) and
// the selection controls. Stateful because the controls hold local UI state.

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_toggle_button.dart';
import '../widget/showcase_section.dart';

class InputsShowcasePage extends StatefulWidget {
  const InputsShowcasePage({super.key});

  @override
  State<InputsShowcasePage> createState() => _InputsShowcasePageState();
}

class _InputsShowcasePageState extends State<InputsShowcasePage> {
  bool _checkbox = true;
  bool _switchValue = true;
  int _radio = 0;
  double _slider = 0.4;
  final Set<String> _filters = {'Flutter'};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inputs & Selection'),
        actions: const [ThemeToggleButton()],
      ),
      body: ListView(
        children: [
          ShowcaseSection(
            title: 'TextField',
            description: 'Filled style comes from inputDecorationTheme in '
                'app_theme.dart (no visible border, rounded, primary focus).',
            child: Column(
              children: [
                const TextField(
                  decoration: InputDecoration(
                    labelText: 'Email',
                    hintText: 'you@example.com',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const Gap(AppSpacing.md),
                const TextField(
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
                const Gap(AppSpacing.md),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'With error',
                    errorText: 'This field is required',
                    prefixIcon: const Icon(Icons.error_outline),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {},
                    ),
                  ),
                ),
              ],
            ),
          ),
          ShowcaseSection(
            title: 'Checkbox, Switch, Radio',
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Switch'),
                  value: _switchValue,
                  onChanged: (v) => setState(() => _switchValue = v),
                ),
                CheckboxListTile(
                  title: const Text('Checkbox'),
                  value: _checkbox,
                  onChanged: (v) => setState(() => _checkbox = v ?? false),
                ),
                RadioListTile<int>(
                  title: const Text('Option A'),
                  value: 0,
                  groupValue: _radio,
                  onChanged: (v) => setState(() => _radio = v ?? 0),
                ),
                RadioListTile<int>(
                  title: const Text('Option B'),
                  value: 1,
                  groupValue: _radio,
                  onChanged: (v) => setState(() => _radio = v ?? 0),
                ),
              ],
            ),
          ),
          ShowcaseSection(
            title: 'Slider',
            child: Slider(
              value: _slider,
              onChanged: (v) => setState(() => _slider = v),
              divisions: 10,
              label: (_slider * 100).round().toString(),
            ),
          ),
          ShowcaseSection(
            title: 'Chips',
            child: ShowcaseWrap(
              children: [
                for (final label in ['Flutter', 'Dart', 'Material 3'])
                  FilterChip(
                    label: Text(label),
                    selected: _filters.contains(label),
                    onSelected: (sel) => setState(() {
                      sel ? _filters.add(label) : _filters.remove(label);
                    }),
                  ),
                const InputChip(label: Text('Input'), onDeleted: _noop),
                ActionChip(
                  label: const Text('Action'),
                  avatar: const Icon(Icons.bolt, size: 18),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

void _noop() {}
