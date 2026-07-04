# Project Memory & Architecture State
**Date:** July 3, 2026
**Project:** Flutter Production Starter
**Architecture:** Clean Architecture

## 1. Current Progress (What has been implemented)

The core infrastructure layer has been solidly established, focusing on a production-grade, highly reliable Network and Local Storage mechanism.

### A. Local Storage (`lib/core/local_storage/`)
- **`SharedPrefsManager`**: A Singleton wrapper around the `shared_preferences` package. Provides synchronous-like access to data after initial `init()` and ensures a single unified way to save/read primitive data across the app. (Successfully initialized in `main.dart`).

### B. Error Handling (`lib/core/error/`) — Exception → Failure mapping
> Goal: the UI **never** sees a raw `e.toString()` (no status codes, no stack traces).
- **`ServerException`** (data layer): `message`, `code` (= `NetworkErrorCode.errorCode` string), parsed `error` map. Thrown by `NetworkClient`/datasources.
- **`NetworkErrorCode`** (enum, `switch`-based per `enum-mapping.mdc`): codes timeout/badResponse/cancelled/connectionError/unknown/unexpectedError. Getters: `errorCode` (machine string) + **`message`** (friendly UI text). Static **`fromCode(String?)`** parses the stored code back (defaults to `unknown`).
- **`Failure`** (abstract): `message` (UI-safe) + optional `code`. **`ServerFailure`** (server/network origin) and **`UnknownFailure`** (fallback, default friendly message).
- **`ServerException.toFailure()`** extension: builds a `ServerFailure` whose message comes from the **code** (drops technical detail), not the raw exception message.
- **Flow:** `AuthRepositoryImpl.login` `try { ... } on ServerException catch (e) { throw e.toFailure(); } catch (_) { throw const UnknownFailure(); }`. `LoginCubit` does `on Failure catch (e) → e.message` (fallback `UnknownFailure().message`); the login SnackBar shows that message.
- **Tests:** `test/error_handling_test.dart`.

### C. Network Layer (`lib/core/network/`)
- **`NetworkClient`**: A centralized API client wrapping `Dio`. 
  - Exposes generic typed methods (`get<T>`, `post<T>`, etc.).
  - Handles global timeout configurations.
  - Maps `DioException` natively into `ServerException` with exact error codes.
  - Supports bypassing authentication natively via `requiresAuth` parameter.
  - Passes its own `Dio` instance down to `AuthInterceptor` to allow native retry capabilities.
- **`TokenManagement`**: A highly concurrent, robust Singleton to manage Access/Refresh Tokens.
  - Uses `Completer<String?>` to queue multiple concurrent API requests when the token is being refreshed (prevents Spamming the Server).
  - Protects against race conditions by enforcing strict `saveTokens` execution prior to completing the refresh stream.
  - Correctly catches exceptions during refresh and aborts pending requesters.
  - Implements the real network call via `NetworkClient` to refresh tokens using the `/auth/refresh` endpoint.
- **`AuthInterceptor`**: 
  - Injects `Authorization: Bearer <token>` seamlessly.
  - Catches `401 Unauthorized`.
  - Intelligently triggers `TokenManagement.refreshToken()`.
  - Safely retries the original request natively via `dio.fetch()` without losing Data/FormData.

### D. Features & UI (`lib/feature/`)
- **Global Auth & DI Refactor**:
  - `AppAuthCubit`: Placed in `lib/core/auth/` and wrapped around `MaterialApp` to manage global authentication state (`AppAuthStatus.authenticated` / `AppAuthStatus.unauthenticated`).
  - Core DI (`lib/core/di/di.dart`): Configured to provide global singleton instances for dependencies like `NetworkClient`, `AuthRepository`, `AuthRemoteDataSource`, `LogoutUseCase`, `LoginUseCase`, and `AppAuthCubit`.
- **`Auth / Login Feature`**:
  - Uses Clean Architecture (Datasource -> Repository -> Usecase -> Cubit -> UI).
  - `LoginCubit`: Replaced the global `AuthCubit` to strictly manage just the Login lifecycle loading/success/error. Instantiated locally (Just-in-Time DI) inside `LoginPage`.
  - Listeners navigate states by notifying `AppAuthCubit` of a successful login to trigger re-routing to `HomePage`.
  - **formz validation:** `form/email_input.dart` (`EmailInput`, regex) + `form/password_input.dart` (`PasswordInput`, min 6), each with an `errorText` getter (switch-based, null while `pure`). `LoginState` holds `EmailInput`/`PasswordInput`/`isValid`; `LoginCubit.emailChanged`/`passwordChanged` recompute `isValid` via `Formz.validate`. `login()` guards on `!isValid` and reads `state.email/password.value` (the old hardcoded `test@example.com` bypass was removed).
  - `login_form.dart` is stateless: `_EmailField`/`_PasswordField`/`_SubmitButton`, each with its own `buildWhen` (per `bloc-optimization.mdc`). Submit is disabled unless `isValid` and not loading (shows a spinner while loading). No pre-filled credentials.
  - Tests: `test/login_cubit_test.dart`.
- **`Home Feature`**:
  - `HomeCubit`: Added specifically for `HomePage`.
  - Logout triggers `context.read<AppAuthCubit>().logout()` instead of instantiating its own feature's Cubit.
  - AppBar uses the shared `ThemeToggleButton`. The login screen's AppBar exposes the same button, so the theme can be switched before logging in too.

### E. Theming (`lib/core/theme/`) — Material 3
- **`AppTheme`**: Builds `lightTheme`/`darkTheme` from a single seed via `ColorScheme.fromSeed` with `useMaterial3: true`. Both brightnesses share the same component themes (AppBar, FilledButton, ElevatedButton, InputDecoration, Card, SnackBar) for a coherent look. Replaced the deprecated `primarySwatch`.
- **`AppColors` / `AppSpacing` / `AppRadius`** (`app_colors.dart`): Design tokens. `AppColors.seed` is the single rebrand point; spacing/radius scales keep paddings and corners consistent.
- **Button width is NOT forced by the theme.** `filledButtonTheme`/`elevatedButtonTheme` set `minimumSize: Size(64, 52)` (consistent height + shape only). Full-width is opt-in at the call site via `SizedBox(width: double.infinity)` — see `login_form.dart`. (Earlier `Size.fromHeight(52)` forced infinite width and crashed any button placed in a `Row`.)
- **`ThemeCubit` + `ThemeState`** (`part`/`part of`): Manages the active `ThemeMode`. `loadTheme()` restores the persisted choice at startup; `toggleTheme()` cycles modes; `setTheme()` applies an explicit mode. Persists the `ThemeMode.index` through `SharedPrefsManager` under `StorageKeys.themeMode`.
- **DI**: `ThemeCubit` registered as a global lazy singleton in `core/di/di.dart`. `main.dart` provides it via `MultiBlocProvider` and wraps `MaterialApp` in a `BlocBuilder<ThemeCubit, ThemeState>` to feed `darkTheme` + `themeMode`.
- **`ThemeToggleButton`** (`theme_toggle_button.dart`): Reusable AppBar action (`IconButton`) that cycles modes via `ThemeCubit`. Used on both Login and Home AppBars (single source, no duplicated toggle logic).
- **`StorageKeys`** (`core/utils/constants.dart`): Centralized SharedPrefs key names to avoid typos/collisions (currently `themeMode`).

### F. Dev Tools — Theme Gallery (`lib/feature/dev_tools/`)
A developer-only gallery to preview how every `app_theme.dart` config affects default Material 3 widgets (review the design system before building features).
- **`DevToolsGalleryPage`** (main screen at feature root): grid of cards rendered from a registry; tapping a card pushes the detail page.
- **`showcase_registry.dart`** (`kShowcases`): single `const List<DevShowcase>` — adding a showcase = appending one entry. `DevShowcase` model = title/description/icon/`WidgetBuilder`.
- **`showcase/`** — 7 detail pages: Scaffold default (AppBar/Drawer/FAB/NavigationBar/Tabs/body), Colors (all ColorScheme roles + hex), Typography (full TextTheme), Buttons, Inputs & Selection, Cards & Surfaces, Feedback (SnackBar/Dialog/BottomSheet/Tooltip/Progress).
- **`widget/showcase_section.dart`** (`ShowcaseSection` + `ShowcaseWrap`): reusable layout for detail pages. **`widget/showcase_card.dart`**: grid card.
- **State:** interactive demos use local `StatefulWidget` + `setState` (ephemeral UI state — no Cubit).
- **Entry point:** `Coordinator.openDevTools(context)`. Wired from the HomePage body ("Navigation" `InkWell`). `dev_tools.dart` is now a pure export barrel (no navigation code).
- **Flutter 3.27 note:** `Color.toARGB32()` is NOT available (use the 0..1 `.a/.r/.g/.b` getters — see `_hex` in `color_showcase_page.dart`); `withValues()` IS available.
- **Tests:** `test/dev_tools_gallery_test.dart` verifies the grid renders one card per showcase and every showcase page builds without throwing (uses `pump`, not `pumpAndSettle`, because progress indicators animate forever).

### G. Navigation — go_router (main screens) + Coordinator (dev tools)
**Main-screen routing = go_router** (`lib/core/router/app_router.dart`):
- `AppRoutes` = path constants (`/`, `/login`). `AppRouter(authCubit)` exposes a `GoRouter` with home + login routes.
- `redirect` is the auth guard: unauthenticated → `/login`; authenticated on `/login` → `/`. The whole auth flow is redirect-driven — `LoginCubit` success → `AppAuthCubit.loggedIn()` (flip status) and `logout()` are all that's needed; no manual navigation.
- `GoRouterRefreshStream extends ChangeNotifier` bridges `AppAuthCubit.stream` → the `Listenable` that `refreshListenable` wants, so the redirect re-runs on each auth change.
- `main.dart`: `MyApp` is a `StatefulWidget` that builds the same `AppAuthCubit` (from `sl`, `..checkAuth()`) + `GoRouter` **once**, provides the cubit via `BlocProvider.value`, and uses `MaterialApp.router(routerConfig:)`.

**Dev-tools navigation stays imperative** in **`Coordinator`** (`lib/core/coordinator/coordinator.dart`, `abstract final class`):
- `Coordinator.openDevTools(context)` / `openShowcase(context, builder)` / `pop(context)` use `Navigator`/`MaterialPageRoute` directly (intentional — the gallery is a dynamic registry of builders, not modeled as go_router routes).
- **Enforced rule:** `Navigator.` and `MaterialPageRoute` may appear ONLY inside `lib/core/coordinator/`. See `.cursor/rules/navigation-coordinator.mdc`. (go_router's `redirect`/route builders don't use `Navigator`, so the rule holds.)
- Overlay helpers (`showDialog`/`showModalBottomSheet`) stay in widgets but are dismissed via `Coordinator.pop(context)`.

### H. Localization (`lib/core/localization/`) — manual, NO codegen
> Deliberate choice (per user): no `.arb`/`flutter gen-l10n`. An abstract contract + per-language implementations, accessed statically without a `BuildContext`.
- **`AppLanguage`** (abstract, `app_language.dart`): declares every user-facing string (getters; `passwordTooShort(int min)` is a method). **`EnLanguage`/`ViLanguage`** (`languages/`) implement it with `const` constructors.
- **`AppLanguage.current`** is the facade call sites use: `AppLanguage.current.loginButton`. `AppLanguage.of(locale)` resolves the impl; `AppLanguage.setCurrent(locale)` swaps it (owned by `LocaleCubit`).
- **`AppLocale`** enum (en/vi): `code`, `label` (EN/VI), `flutterLocale`, `fromCode()`.
- **`LocaleCubit`** (+`LocaleState`): persists the chosen `AppLocale` via `SharedPrefsManager` (`StorageKeys.locale`) and keeps `AppLanguage.current` in sync (updates it BEFORE emitting). Registered as a lazy singleton in DI. **`LanguageToggleButton`** (EN⇄VI) sits in the Login & Home AppBars.
- **`main.dart`**: a top-level `BlocBuilder<LocaleCubit>` wraps `MaterialApp.router` so the whole tree rebuilds on locale change; sets `locale`, `supportedLocales`, and the `flutter_localizations` Global delegates.
- The old `app_localizations.dart` placeholder was deleted. Dev-tools strings stay English on purpose (developer-only).
- Tests: `test/localization_test.dart`.

### I. Flavors & Env Config (`lib/core/config/app_config.dart`)
- **`Flavor`** enum (`dev`/`staging`/`prod`). **`AppConfig`** carries `flavor`, `baseUrl`, `appName`; `AppConfig.fromFlavor(flavor)` maps each flavor to its base URL (`switch` per `enum-mapping.mdc`). `dev` reuses `AppConstants.devApiBaseUrl` (`http://localhost:8080`); staging/prod point at example hosts (placeholders to swap).
- **`AppConfig.instance`** is the active config; it **lazily defaults to the dev flavor** if `init()` was never called, so `flutter test` needs no setup. **`AppConfig.init(config)`** pins it and must be called before DI (the network client reads `baseUrl` from it).
- **Entry points:** `main.dart` exposes a shared `bootstrap(Flavor)` that pins `AppConfig` → `initApp()` (SharedPrefs + DI) → `runApp`. The default `main()` = `bootstrap(Flavor.dev)` (so `flutter run` needs no `-t`). `main_dev.dart` / `main_staging.dart` / `main_prod.dart` each call `bootstrap(Flavor.x)`. Run a flavor with `flutter run -t lib/main_<flavor>.dart`.
- **DI wiring:** `di.dart` builds `NetworkClient(baseUrl: AppConfig.instance.baseUrl, ...)` — the old hardcoded `AppConstants.apiBaseUrl` was renamed to `devApiBaseUrl` and is now only the dev URL.
- Tests: `test/app_config_test.dart`.

### J. Test Suite (`test/`) — 39 tests green
Runnable with `flutter test`; `flutter analyze` is clean.
- **`login_usecase_test.dart`**: mocks `AuthRepository` (mocktail) to assert `LoginUseCase.execute` delegates with the exact args and propagates a thrown `Failure` untouched.
- **`token_management_test.dart`** (the technical highlight): drives the concurrency-safe refresh directly. Registers a `MockNetworkClient` in `sl`, holds the `/auth/refresh` response open with a `Completer`, and asserts that (a) multiple concurrent `getToken()` callers all resolve to the *one* freshly-saved access token while the network is hit exactly once, (b) `getToken(force: true)` bypasses the queue and reads storage, (c) no stored refresh token → returns null without a network call, (d) a network failure releases queued waiters with `null` (not a hang) and rethrows to the refresh caller. Uses `SharedPreferences.setMockInitialValues({})` + `SharedPrefsManager.instance.init()`.
- **`login_page_test.dart`**: widget tests for `LoginPage`. Fields render, submit button gates on formz validity, a success flips `AppAuthCubit` → `authenticated`, a failure shows a friendly SnackBar (never a raw exception). **Gotcha:** the AppBar hosts the shared `ThemeToggleButton`/`LanguageToggleButton`, so the pump helper must also provide `ThemeCubit` + `LocaleCubit` (via `MultiBlocProvider`) or the toolbar throws provider-not-found and overflows.
- **`login_cubit_test.dart`**: 6 plain formz-validation cases + 2 `blocTest` emission-sequence cases (`[loading, success]` / `[loading, failure]`). **Gotcha:** to make a mocked async method fail, use `thenAnswer((_) async => throw ...)`, NOT `thenThrow(...)` — the latter throws synchronously, escapes into blocTest's guarded zone, and the recorded states come back `[]`.
- **`app_config_test.dart`**: `AppConfig.fromFlavor` base-URL mapping, `isProd`, the lazy dev default, and `init()` pinning.
- Pre-existing: `error_handling_test.dart`, `localization_test.dart`, `dev_tools_gallery_test.dart`, `widget_test.dart` (go_router redirect smoke test).

### K. CI/CD & Project Docs
- **`.github/workflows/ci.yml`**: one job (`analyze-test-build`) on push to `main` and every PR — `subosito/flutter-action@v2` (Flutter `3.27.4`, cache on) → `flutter pub get` → `flutter analyze` → `flutter test` → `flutter build apk --debug -t lib/main_dev.dart`. No format-check step (12 pre-existing lib files aren't `dart format`-clean; adding one would fail CI until they're reformatted).
- **`LICENSE`** (MIT, © 2026 kietdt) + **`CHANGELOG.md`** (Keep a Changelog: `Unreleased` = tests/flavors/CI/license; `1.0.0` = core architecture). README carries a CI badge and flavor run instructions.

## 2. Tech Stack & Dependencies Added
- `flutter_bloc: ^9.1.1`
- `equatable: ^2.0.8`
- `dio: ^5.9.2`
- `get_it: ^9.2.1`
- `formz: ^0.8.0`
- `shared_preferences: ^2.3.2`
- `go_router: ^14.6.2` (resolved 14.8.1)
- **dev:** `bloc_test: ^10.0.0`, `mocktail: ^1.0.4`

## 3. Active AI Rules (`.cursor/rules/`)
- `class-initialization.mdc`: Enforce named parameters for classes/models.
- `code-formatting.mdc`: Require trailing commas and proper formatting.
- `cubit-state-coupling.mdc`: Use `part`/`part of` for Cubits.
- `custom-logging.mdc`: Forbid `print()`, mandate `AppLogger`.
- `feature-status.mdc`: Use unified `FeatureStatus` enum instead of Abstract State Classes.
- `main-screen-placement.mdc`: Main screen file goes to feature root folder.
- `model-entity-separation.mdc`: Models `toEntity()` strictly separated from Domain Entities.
- `enum-mapping.mdc`: Enforce `switch` cases for Enum values mapping.
- `memory-update.mdc`: Mandate updating `MEMORY.md` after significant changes.
- `navigation-coordinator.mdc`: All screen navigation declared in `Coordinator`; no `Navigator`/`MaterialPageRoute` outside `lib/core/coordinator/`.

## 4. Next Steps (To-Do for next session)
> Tracked in detail in `PLAN.md`. **All three phases (GĐ 1, GĐ 2, GĐ 3) are complete and every checkbox in `PLAN.md` is now ticked (0 remaining `- [ ]`).** Re-verified 2026-07-03: `flutter test` → **39/39 pass**, `flutter analyze` → **No issues found!** The final open box (README flavor-run docs) was closed — the content already lived in README §Flavors from GĐ 3.4. Optional beyond-plan follow-ups:
1. Replace the placeholder staging/prod base URLs in `app_config.dart` with real backends.
2. Native flavor setup (Android `productFlavors` / iOS schemes) if store builds per flavor are needed — current flavors switch config via entry point only.
3. Reformat the 12 pre-existing non-`dart format`-clean lib files, then add a format-check step to CI.
4. Golden tests / coverage reporting if deeper QA is wanted.