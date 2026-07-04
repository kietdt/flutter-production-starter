# Changelog

All notable changes to this project are documented here. The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres
to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
- Routing with `go_router` (auth-guard redirect) alongside a `Coordinator` for
  imperative dev-tools navigation.
- Manual localization (English / Vietnamese) via an abstract `AppLanguage`.
- Developer Theme Gallery for previewing the design system.
