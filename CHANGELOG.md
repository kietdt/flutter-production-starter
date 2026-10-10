# Changelog

All notable changes to this project are documented here. The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres
to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed (tech-lead review #10, #13–#16)
- **`lib/app/` composition layer** — `bootstrap`, `MyApp`, DI, `AuthGate`,
  `Coordinator` and `AppAuthCubit` moved out of `core/`; layer boundaries are
  enforced by `tool/check_architecture.sh` in CI. All imports are package imports.
- **Error model** — sealed `Failure` (`NetworkFailure`, `UnauthorizedFailure`,
  `ServerFailure`, `CancelledFailure`, `UnknownFailure`) with no UI text; messages
  come from `context.l10n`, `ServerException` keeps `statusCode`/`serverCode`/
  `serverMessage`, and unexpected errors keep their root cause.
- **Global user** — `AppAuthState.user`, cached locally at login and restored
  offline on app start; a session now needs both the token and the cached user.
- **Strict lint set** (`strict-casts/raw-types/inference`, `only_throw_errors`,
  `unawaited_futures`, …) and "Enforced by" notes on every rule in `AI_RULE.md`.
- States extend `Equatable`; `LoginPage`/`HomePage` use `newInstance()`;
  `NetworkClient` no longer mutates caller `Options`; `PLAN.md`/`MEMORY.md` moved
  to `docs/`; tests mirror `lib/`. CI pins Flutter 3.29.3 and adds format check +
  coverage.

### Fixed
- Login errors were always shown in English; a wrong password showed
  "An unexpected error occurred" instead of "Incorrect email or password".

### Removed
- Empty `HomeCubit`.

### Added
- **Test suite** (`bloc_test` + `mocktail`): use-case delegation, `TokenManagement`
  refresh-concurrency (`Completer` queue), `LoginCubit` emission sequences, and
  `LoginPage` widget tests — 39 tests total.
- **Build flavors** — `dev` / `staging` / `prod` via `AppConfig` with per-flavor
  base URLs and dedicated entry points (`main_dev.dart`, `main_staging.dart`,
  `main_prod.dart`); the network client's base URL now comes from `AppConfig`.
- **CI** — GitHub Actions workflow running analyze → test → debug build on push/PR.
- **MIT License** and this changelog.

## [1.0.0] - 2026-06-24

### Added
- Clean Architecture skeleton (`data` / `domain` / `feature` / `core`).
- Concurrency-safe network layer: `NetworkClient` over Dio, `AuthInterceptor`
  with native retry, and `TokenManagement` refresh queue guarded by a `Completer`.
- Auth/login feature (Datasource → Repository → UseCase → Cubit → UI) with formz
  validation and `Exception → Failure` mapping (UI never sees raw error strings).
- Material 3 theming with light/dark mode and a persisted `ThemeCubit`.
- Navigation with Flutter's built-in `Navigator`: a `Coordinator` centralizes
  imperative navigation and an `AuthGate` widget drives the top-level auth flow
  (login/home) off `AppAuthCubit` status.
- Manual localization (English / Vietnamese) via an abstract `AppLanguage`.
- Developer Theme Gallery for previewing the design system.
