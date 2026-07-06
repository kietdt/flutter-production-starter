# Flutter Production Starter

> A clean, production-grade Flutter starter built on **Clean Architecture** — featuring a battle-tested, **concurrency-safe token-refresh network layer**, BLoC/Cubit state management, and dependency injection with `get_it`.

[![CI](https://github.com/kietdt/flutter-production-starter/actions/workflows/ci.yml/badge.svg)](https://github.com/kietdt/flutter-production-starter/actions/workflows/ci.yml)
![Flutter](https://img.shields.io/badge/Flutter-3.6%2B-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.6%2B-0175C2?logo=dart&logoColor=white)
![Architecture](https://img.shields.io/badge/Architecture-Clean-success)
![License](https://img.shields.io/badge/License-MIT-blue)

---

## ✨ Features

- **Clean Architecture** — strict separation across `data` / `domain` / `feature` / `core` layers with one-way dependencies.
- **Concurrency-safe token refresh** — a `Completer`-based queue serializes concurrent `401`s into a single refresh call, preventing server spam and race conditions. *(See [Token Refresh Flow](#-token-refresh-flow) — the centerpiece.)*
- **Robust network layer** — `NetworkClient` wraps Dio with generic typed methods (`get<T>`, `post<T>`, …), global timeouts, and native `DioException → ServerException` mapping with strongly-typed error codes.
- **Native request retry** — `AuthInterceptor` retries the original request via `dio.fetch()` after a refresh, preserving headers and `FormData` without rebuilding the request.
- **BLoC / Cubit** — predictable state via `flutter_bloc`, with a unified `FeatureStatus` enum instead of one-off state classes.
- **Global auth state** — `AppAuthCubit` drives authenticated/unauthenticated routing app-wide.
- **Dependency Injection** — `get_it` service locator with lazy singletons.
- **Local storage** — `SharedPrefsManager` singleton wrapper over `shared_preferences`.
- **Documented conventions** — enforced via [`AI_RULE.md`](AI_RULE.md) and `.cursor/rules/`.

---

## 🏗️ Architecture

Clean Architecture with a one-way dependency flow — outer layers depend inward, never the reverse.

```
┌──────────────────────────────────────────────────────────────┐
│  FEATURE (UI)                                                 │
│  Pages • Widgets • Cubits (LoginCubit, HomeCubit)            │
│  Renders state, dispatches intents.                          │
└───────────────────────────────┬──────────────────────────────┘
                                 │ calls
┌───────────────────────────────▼──────────────────────────────┐
│  DOMAIN (business rules)                                      │
│  Entities • Repository interfaces • UseCases                 │
│  Pure Dart, no Flutter / no Dio.                             │
└───────────────────────────────┬──────────────────────────────┘
                                 │ implemented by
┌───────────────────────────────▼──────────────────────────────┐
│  DATA                                                         │
│  Repository impls • DataSources (remote/local) • Models      │
│  Models map to Entities via toEntity().                      │
└───────────────────────────────┬──────────────────────────────┘
                                 │ uses
┌───────────────────────────────▼──────────────────────────────┐
│  CORE (cross-cutting)                                         │
│  NetworkClient • AuthInterceptor • TokenManagement           │
│  Errors • DI • Theme • Local storage • Logger                │
└──────────────────────────────────────────────────────────────┘
```

**Login flow:** `LoginPage` → `LoginCubit.login()` → `LoginUseCase` → `AuthRepository` → `AuthRemoteDataSource` → `NetworkClient`. On success, `AppAuthCubit` flips to `authenticated` and the app renders `HomePage`.

---

## 🔐 Token Refresh Flow

The standout piece. When the access token expires, many in-flight requests can fail with `401` **simultaneously**. A naive implementation fires N refresh calls. This starter serializes them through a single `Completer<String?>`:

```
 Request A (401)        Request B (401)        Request C (401)
      │                       │                       │
      ▼                       ▼                       ▼
 ┌─────────────────────────────────────────────────────────┐
 │              AuthInterceptor.onError (401)              │
 └─────────────────────────────────────────────────────────┘
      │                       │                       │
      │  isRefreshing? NO     │  isRefreshing? YES    │  isRefreshing? YES
      ▼                       ▼                       ▼
 startRefreshToken()    await completer.future   await completer.future
 POST /auth/refresh           (parked)                 (parked)
      │                       │                       │
      ▼                       │                       │
 saveTokens()  ◄── MUST save before completing        │
      │                       │                       │
 finishRefreshToken(newToken) │                       │
      │  ──── completes ────► │  ──── completes ────► │
      ▼                       ▼                       ▼
 dio.fetch(retry)        dio.fetch(retry)        dio.fetch(retry)
   (isRetry=true)          (isRetry=true)          (isRetry=true)
```

Key guarantees:
- **Single refresh** — only the first `401` calls `/auth/refresh`; the rest `await` the same `Completer`.
- **No stale reads** — tokens are persisted **before** the `Completer` completes, so parked requesters never read the old token.
- **No infinite loops** — a retried request is flagged `isRetry`; a second `401` aborts instead of retrying again.
- **Clean failure** — if refresh fails, tokens are cleared and `onUnauthorized()` logs the user out globally.
- **Deadlock-free** — the refresh call itself uses `requiresAuth: false` to bypass the interceptor.

> Implementation: `lib/core/network/token_management.dart` + `lib/core/network/interceptors/auth_interceptor.dart`.

---

## 📁 Project Structure

```
lib/
├── core/                          # Cross-cutting infrastructure
│   ├── auth/                      # Global auth state (AppAuthCubit/State)
│   ├── di/                        # get_it service locator (initDI)
│   ├── error/                     # ServerException, Failure, NetworkErrorCode
│   ├── local_storage/             # SharedPrefsManager singleton
│   ├── localization/              # Localization scaffolding
│   ├── network/
│   │   ├── interceptors/          # AuthInterceptor, LoggingInterceptor
│   │   ├── network_client.dart    # Dio wrapper, typed methods, error mapping
│   │   └── token_management.dart  # Completer-based concurrent refresh
│   ├── theme/                     # App theme
│   ├── utils/                     # AppLogger, constants, FeatureStatus
│   └── widget/                    # Shared widgets (CustomButton)
│
├── data/                          # Data layer
│   ├── datasource/{remote,local}/ # AuthRemoteDataSource, AuthLocalDataSource
│   ├── model/                     # UserModel, AuthResponseModel (toEntity())
│   └── repository/                # AuthRepositoryImpl
│
├── domain/                        # Pure business layer
│   ├── entity/                    # UserEntity
│   ├── repository/                # AuthRepository (interface)
│   └── usecase/                   # LoginUseCase, LogoutUseCase
│
├── feature/                       # UI features
│   ├── home/                      # HomePage + HomeCubit
│   └── login/                     # LoginPage, LoginForm + LoginCubit
│
└── main.dart                      # Bootstrap: init storage → DI → runApp
```

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK `3.27.4` (Dart `3.6.2`)
- A running backend exposing `/auth/login` and `/auth/refresh`

### Setup

```bash
# 1. Clone
git clone <your-repo-url>
cd flutter-production-starter

# 2. Install dependencies
flutter pub get

# 3. Configure the API base URL per environment
#    Edit the per-flavor URLs in lib/core/config/app_config.dart
#    (dev defaults to http://localhost:8080)

# 4. Run (defaults to the dev flavor)
flutter run
```

### Flavors

Three build flavors — `dev`, `staging`, `prod` — each with its own entry point and
base URL (see `lib/core/config/app_config.dart`). Pick one via the target file:

```bash
flutter run -t lib/main_dev.dart       # local backend
flutter run -t lib/main_staging.dart   # staging backend
flutter run -t lib/main_prod.dart      # production backend

# Bare `flutter run` uses lib/main.dart, which is equivalent to the dev flavor.
```

### Quality checks

```bash
flutter analyze   # static analysis — should report: No issues found!
flutter test      # run the test suite (39 tests)
```

---

## 🧩 Coding Conventions

Conventions are documented and enforced via [`AI_RULE.md`](AI_RULE.md) and `.cursor/rules/`. Highlights:

- **Named parameters** for classes and models.
- **Trailing commas** + consistent formatting.
- **No `print()`** — use `AppLogger`.
- **`part` / `part of`** to couple a Cubit with its state.
- **`FeatureStatus` enum** instead of bespoke state classes.
- **Model ↔ Entity separation** — models expose `toEntity()`; domain stays pure.
- **Enum mapping** via `switch` getters, not constructors.

---

## 🗺️ Roadmap

Planned enhancements (tracked in `PLAN.md`):

- [x] **Theme** — Material 3 (`ColorScheme.fromSeed`) + dark mode via `ThemeCubit`
- [x] **Routing** — `go_router` with auth-guard redirect
- [x] **Error handling** — map `Exception → Failure` so the UI never sees raw `e.toString()`
- [x] **Form validation** — `formz` inputs for email/password
- [x] **Localization** — manual i18n (English + Vietnamese), no codegen — abstract `AppLanguage` + `AppLanguage.current`
- [x] **Tests** — `bloc_test` + `mocktail` covering cubits, usecases, refresh concurrency, and widgets (39 tests)
- [x] **Flavors** — dev / staging / prod entry points + per-flavor config (`AppConfig`)
- [x] **CI/CD** — GitHub Actions (analyze → test → build)

---

## 📄 License

MIT — see [`LICENSE`](LICENSE).
