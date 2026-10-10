# CLAUDE.md

Guidance for Claude Code when working in this repository.

## Project

A production-ready Flutter starter built on **Clean Architecture** (data / domain / presentation) with a **feature-first** layout. State management is **flutter_bloc (Cubit)**; DI is **get_it**; navigation uses **Flutter's built-in Navigator** (imperative, via a `Coordinator`) with an auth-gated widget for the top-level flow; networking is **dio** with automatic token refresh.

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
- **`copyWith` nullable fields** take `Nullable<T?>?` (`lib/core/utils/nullable.dart`) so they can be cleared (`failure: const Nullable(null)`); clear stale failures on the `loading` emit.
- **Errors:** `DioException → ServerException → sealed Failure → failure.message(context.l10n)`. Failures carry no UI text; repositories keep the root cause in `UnknownFailure(cause, stackTrace)`; business errors via `ServerFailure.serverCode`. See `.cursor/rules/error-model.mdc`.
- **Navigation** goes through `lib/app/coordinator/coordinator.dart` — no `Navigator`/`MaterialPageRoute` in features/widgets.
- **BlocBuilder/BlocListener/BlocConsumer** always pass `buildWhen`/`listenWhen`.
- **Spacing** between widgets uses `Gap(...)` (from the `gap` package), not `SizedBox`.
- **Strings** in widgets via `context.l10n.<key>`; context-free code returns an enum and the widget maps it with `context.l10n`.
- **Logging** uses `AppLogger` (`lib/core/utils/app_logger.dart`) — never `print()` or raw `dart:developer` `log()`; errors passed as `error:` are forwarded to the pluggable `ErrorReporter` (`AppLogger.setReporter`). Uncaught/Bloc errors are wired in `bootstrap()`.
- Always `dart format` after changes and keep `flutter analyze` (strict lint set in `analysis_options.yaml`) and `./tool/check_architecture.sh` clean. Each rule in `AI_RULE.md` says whether a lint, the script, or review enforces it.

## Layout

```
lib/
├── app/            # composition: bootstrap, MyApp, di, router (AuthGate),
│                   #   coordinator, auth (AppAuthCubit) — may import every layer
├── core/           # cross-cutting: config (flavors),
│                   #   error, local_storage, localization, network,
│                   #   theme, utils (app_logger, map_ext, parse_utils), widget
├── data/           # datasource/(local|remote), model (+ fromJson/toEntity), repository
├── domain/         # entity, repository (abstract), usecase
└── feature/        # feature-first UI: <feature>/<feature>_page.dart + cubit/ + widget/ + di/
```

- **Layers:** `core` → nothing above it; `domain` → `core/error|utils`; `data` → `domain`/`core`; `feature` → `domain`/`core`/`app/coordinator`/`app/auth` (+ `app/di` only in `*_page.dart`); `app` → everything. Package imports only. Enforced by `tool/check_architecture.sh` (CI) — see `.cursor/rules/layer-dependencies.mdc`.
- **DI:** `lib/app/di/di.dart` exposes `sl = GetIt.instance` and `Future<void> initDI()` — the composition root. Everything (`SharedPrefsManager`, `AuthLocalDataSource`, `TokenManagement`, network client, auth repo/usecases, `AppAuthCubit`, `ThemeCubit`, `LocaleCubit`) is registered there and receives dependencies via constructors. No static `.instance` singletons; core/data/domain classes never call `sl` themselves. Tests: `SharedPreferences.setMockInitialValues(...)` then `await initDI()`; unit tests inject fakes (e.g. `test/helpers/in_memory_token_storage.dart`).
- **Flavors:** `AppConfig` + `Flavor` (dev/staging/prod). Entry points: `main.dart` (defaults to dev), `main_dev.dart`, `main_staging.dart`, `main_prod.dart` — all call `bootstrap(flavor)` (`lib/app/bootstrap.dart`), which installs global error handling (`GlobalErrorHandler`, `AppBlocObserver`), pins config, runs `initApp()` (`await initDI()`, which also loads `SharedPrefsManager`), then `runApp`.
- **Auth/routing:** a single `AppAuthCubit` drives the `AuthGate` widget (`lib/app/router/auth_gate.dart`) that swaps between `LoginPage`/`HomePage`; login/logout just flip its status and the widget tree rebuilds. `AppAuthState.user` is the global signed-in user: `loggedIn(user:)` sets it, `logout()` clears it, and `checkAuth()` restores it synchronously from storage (a session = access token **and** cached user, see `AuthRepository.currentUser()`). Screen-to-screen navigation goes through `Coordinator` (`lib/app/coordinator/coordinator.dart`) using Flutter's `Navigator`.
- **Localization:** custom `AppLanguage` (en/vi) with `LocaleCubit`; widgets read strings via `context.l10n` (never a static/global language — it won't rebuild on switch); theme via `ThemeCubit`. Toggle buttons in `core/`.

## Commands

```bash
flutter pub get
flutter run -t lib/main_dev.dart                   # or main_staging.dart / main_prod.dart
                                                   # flavors are Dart-level (AppConfig), no native --flavor setup
flutter analyze                                    # keep clean before committing
./tool/check_architecture.sh                       # layer boundaries + grep-checked rules (CI runs it)
dart format lib/ test/
flutter test                                       # bloc_test + mocktail; tests live in test/
flutter test test/feature/login/login_cubit_test.dart  # single file
```

## Testing notes

- Cubit tests use `bloc_test` + `mocktail`. When mocking a failing async method, stub it with `thenAnswer((_) async => throw ...)` (async-throw), **not** `thenThrow`; and remember `skip:` does not cover build-phase cascades (see `docs/MEMORY.md`).
