// App Coordinator
// Responsibility: The single place that declares app navigation. Features and
// widgets express intent ("open the dev tools"); only this layer constructs
// routes and talks to Navigator.
//
// Why centralize: if imperative routing ever changes, only this file does —
// every call site (Coordinator.openX(context)) stays the same. The top-level
// auth flow (login/home) is handled separately by the AuthGate widget.
//
// RULE: `Navigator.` and `MaterialPageRoute` must appear ONLY inside this
// directory. See `.cursor/rules/navigation-coordinator.mdc`.

import 'package:flutter/material.dart';

import 'package:flutter_production_starter/core/config/app_config.dart';
import 'package:flutter_production_starter/feature/dev_tools/dev_tools_gallery_page.dart';

abstract final class Coordinator {
  /// Opens the developer Theme Gallery. No-op when dev tools are disabled
  /// for the active flavor (prod), even if a call site forgot to hide its
  /// entry point.
  static Future<void> openDevTools(BuildContext context) async {
    if (!AppConfig.instance.showDevTools) return;
    await _push<void>(context, (_) => const DevToolsGalleryPage());
  }

  /// Opens a Theme Gallery showcase detail page.
  static Future<void> openShowcase(
    BuildContext context,
    WidgetBuilder builder,
  ) {
    return _push(context, builder);
  }

  /// Dismisses the current route (page, dialog or bottom sheet).
  static void pop<T>(BuildContext context, [T? result]) {
    Navigator.of(context).pop(result);
  }

  static Future<T?> _push<T>(BuildContext context, WidgetBuilder builder) {
    return Navigator.of(context).push<T>(
      MaterialPageRoute<T>(builder: builder),
    );
  }
}
