# CLAUDE.md

Guidance for Claude Code when working in this repository.

## Project

A production-ready Flutter starter built on **Clean Architecture** (data / domain / presentation) with a **feature-first** layout. State management is **flutter_bloc (Cubit)**; DI is **get_it**; routing is **go_router**; networking is **dio** with automatic token refresh.

## Coding rules — read first

This project has an explicit, enforced rule set. **Before writing or changing code, follow them.**

- Machine-readable rules live in `.cursor/rules/*.mdc` (one rule per file).
- `AI_RULE.md` is the human-readable mirror of those rules and must stay in sync with `.cursor/rules/` — when you add/change a rule in one place, update the other.

Highest-frequency rules to keep in mind:
- **Named constructor params** for every class/model/entity/exception/failure.
- **Model ≠ Entity**: models never `extend` entities; they expose `toEntity()`.
- **JSON parsing** goes through the `MapParser` extension (`lib/core/utils/map_ext.dart`) — never raw `json['key']` with manual casts. Repositories delegate parsing to models' `fromJson`.
- **State via `FeatureStatus` enum** (`init/loading/success/failure/empty`) — no per-feature status classes. Check status through its getters (`status.isLoading`), never `status == FeatureStatus.loading`.
- **Enums** own their logic: mapping via an exhaustive `switch` getter; comparisons via `bool get isX` getters (not `==` at call sites).
- **Cubit + State** are linked with `part` / `part of`; the state folder is named `cubit/` (or `bloc/` for a Bloc).
- **Navigation** goes through `lib/core/coordinator/coordinator.dart` — no `Navigator`/`MaterialPageRoute` in features/widgets.
- **BlocBuilder/BlocListener/BlocConsumer** always pass `buildWhen`/`listenWhen`.
- **Spacing** between widgets uses `Gap(...)` (from the `gap` package), not `SizedBox`.
- **Logging** uses `AppLogger` (`lib/core/utils/app_logger.dart`) — never `print()` or raw `dart:developer` `log()`.
- Always `dart format` after changes and keep `flutter analyze` clean.

## Layout

```
lib/
├── core/           # cross-cutting: auth, config (flavors), coordinator, di,
│                   #   error, local_storage, localization, network, router,
│                   #   theme, utils (app_logger, map_ext, parse_utils), widget
├── data/           # datasource/(local|remote), model (+ fromJson/toEntity), repository
├── domain/         # entity, repository (abstract), usecase
└── feature/        # feature-first UI: <feature>/<feature>_page.dart + cubit/ + widget/ + di/
```

- **DI:** `lib/core/di/di.dart` exposes `sl = GetIt.instance` and `initDI()`. Global singletons (network client, auth repo/usecases, `AppAuthCubit`, `ThemeCubit`, `LocaleCubit`) are registered there.
- **Flavors:** `AppConfig` + `Flavor` (dev/staging/prod). Entry points: `main.dart` (defaults to dev), `main_dev.dart`, `main_staging.dart`, `main_prod.dart`. `bootstrap(flavor)` pins config, runs `initApp()` (init `SharedPrefsManager`, then `initDI()`), then `runApp`.
- **Auth/routing:** a single `AppAuthCubit` drives both the `go_router` auth guard (`lib/core/router/app_router.dart`) and the widget tree; login/logout redirects flow from its state.
- **Localization:** custom `AppLanguage` (en/vi) with `LocaleCubit`; theme via `ThemeCubit`. Toggle buttons in `core/`.

## Commands

```bash
flutter pub get
flutter run -t lib/main_dev.dart                   # or main_staging.dart / main_prod.dart
                                                   # flavors are Dart-level (AppConfig), no native --flavor setup
flutter analyze                                    # keep clean before committing
dart format lib/ test/
flutter test                                       # bloc_test + mocktail; tests live in test/
flutter test test/login_cubit_test.dart            # single file
```

## Testing notes

- Cubit tests use `bloc_test` + `mocktail`. When mocking a failing async method, stub it with `thenAnswer((_) async => throw ...)` (async-throw), **not** `thenThrow`; and remember `skip:` does not cover build-phase cascades (see `MEMORY.md`).
