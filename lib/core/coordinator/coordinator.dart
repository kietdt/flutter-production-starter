// Core Coordinator
// Responsibility: The single place that declares app navigation. Features and
// widgets express intent ("open the dev tools"); only this layer constructs
// routes and talks to Navigator.
//
// Why centralize: when routing migrates to go_router (PLAN.md GĐ 2.2), only this
// file changes — every call site (Coordinator.openX(context)) stays the same.
//
// RULE: `Navigator.` and `MaterialPageRoute` must appear ONLY inside this
// directory. See `.cursor/rules/navigation-coordinator.mdc`.

import 'package:flutter/material.dart';

import '../../feature/dev_tools/dev_tools_gallery_page.dart';

abstract final class Coordinator {
  /// Opens the developer Theme Gallery.
  static Future<void> openDevTools(BuildContext context) {
    return _push(context, (_) => const DevToolsGalleryPage());
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
