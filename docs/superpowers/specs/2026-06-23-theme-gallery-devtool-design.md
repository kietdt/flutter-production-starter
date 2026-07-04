# Theme Gallery / Dev Tool — Design

**Date:** 2026-06-23
**Goal:** A developer-only gallery that previews how every config in
`lib/core/theme/app_theme.dart` affects default Material 3 widgets, so a
developer can eyeball the design system before building real features.

## Access
- `Coordinator.openDevTools(context)` opens the gallery home. All navigation is
  declared in `lib/core/coordinator/coordinator.dart` (see
  `.cursor/rules/navigation-coordinator.mdc`); features never call `Navigator`
  directly.
- Wired from the HomePage body ("Navigation" entry).

## Architecture (data-driven, extensible)

```
lib/feature/dev_tools/
├── dev_tools_gallery_page.dart   # HOME: grid of showcase cards (main screen at feature root)
├── dev_tools.dart                # Barrel + DevTools.open(context) helper
├── model/dev_showcase.dart       # Model: title, description, icon, WidgetBuilder pageBuilder
├── registry/showcase_registry.dart # Single list of all showcases
├── widget/showcase_card.dart     # Grid card (icon + name + description)
├── widget/showcase_section.dart  # Reusable "title + description + demo" block
└── showcase/
    ├── scaffold_showcase_page.dart   # Full Scaffold: AppBar, FAB, Drawer, BottomNav, body
    ├── color_showcase_page.dart      # All ColorScheme roles as labelled swatches
    ├── typography_showcase_page.dart # All TextTheme styles (displayLarge → labelSmall)
    ├── buttons_showcase_page.dart    # Filled/Elevated/Outlined/Text/Icon/FAB/Segmented (enabled+disabled)
    ├── inputs_showcase_page.dart     # TextField + Checkbox/Radio/Switch/Slider/Chips
    ├── cards_showcase_page.dart      # Card, ListTile, elevation/surface tints
    └── feedback_showcase_page.dart   # SnackBar, Dialog, BottomSheet, Tooltip, Progress
```

## Key decisions
- **Registry-driven home:** the grid renders from a `List<DevShowcase>`; adding a
  showcase = adding one entry. No UI edits needed to grow the gallery.
- **Reusable `ShowcaseSection`:** consistent layout across all detail screens.
- **Local UI state only:** interactive demos (Switch/Slider/Checkbox) use
  `StatefulWidget` + `setState`. No Cubit — Cubit is for business state, this is
  ephemeral preview state.
- **Each showcase has its own Scaffold + AppBar** carrying the shared
  `ThemeToggleButton`, so component themes apply and light/dark is switchable in place.
- **No new dependencies.** Pure Flutter Material 3.

## Scope
All 7 showcases built now (no "Coming soon" placeholders).
```
