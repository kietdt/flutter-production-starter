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
- **Robust network layer** — `NetworkClient` wraps Dio with generic typed methods (`get<T>`, `post<T>`, …), global timeouts, and exhaustive `DioException → ServerException → sealed Failure` mapping, localized error text, and the root cause kept for crash reporting.
- **Native request retry** — `AuthInterceptor` retries the original request via `dio.fetch()` after a refresh, preserving headers and `FormData` without rebuilding the request.
- **BLoC / Cubit** — predictable state via `flutter_bloc`, with a unified `FeatureStatus` enum instead of one-off state classes.
- **Global auth state** — `AppAuthCubit` drives authenticated/unauthenticated routing app-wide and holds the signed-in user, restored offline from storage on app start.
- **Dependency Injection** — `get_it` service locator with lazy singletons.
- **Local storage** — `SharedPrefsManager` wrapper over `shared_preferences`, created once in `initDI()` and injected (no static singletons — everything goes through `get_it` + constructors).
- **Documented conventions** — enforced via [`AI_RULE.md`](AI_RULE.md) and `.cursor/rules/`.

---

## 🏗️ Architecture

Clean Architecture with a one-way dependency flow — outer layers depend inward, never the reverse.

```
┌──────────────────────────────────────────────────────────────┐
│  FEATURE (UI)                                                │
│  Pages • Widgets • Cubits (LoginCubit)                       │
│  Renders state, dispatches intents.                          │
└───────────────────────────────┬──────────────────────────────┘
                                │ calls
┌───────────────────────────────▼──────────────────────────────┐
│  DOMAIN (business rules)                                     │
│  Entities • Repository interfaces • UseCases                 │
│  Pure Dart, no Flutter / no Dio.                             │
└───────────────────────────────┬──────────────────────────────┘
                                │ implemented by
┌───────────────────────────────▼──────────────────────────────┐
│  DATA                                                        │
│  Repository impls • DataSources (remote/local) • Models      │
│  Models map to Entities via toEntity().                      │
└───────────────────────────────┬──────────────────────────────┘
                                │ uses
┌───────────────────────────────▼──────────────────────────────┐
│  CORE (cross-cutting)                                        │
│  NetworkClient • AuthInterceptor • TokenManagement           │
│  Errors • DI • Theme • Local storage • Logger                │
└──────────────────────────────────────────────────────────────┘
```

**Login flow:** `LoginPage` → `LoginCubit.login()` → `LoginUseCase` → `AuthRepository` → `AuthRemoteDataSource` → `NetworkClient`. On success the tokens and the user are stored locally, `AppAuthCubit.loggedIn(user:)` flips to `authenticated`, and the app renders `HomePage`. On the next launch `checkAuth()` restores the user from storage without a network call (a session needs both the access token and the cached user); logout — manual or after a failed refresh — clears both.

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
 refreshToken() starts   refreshToken() joins     refreshToken() joins
 refresher → POST /auth/refresh  (parked)               (parked)
      │                       │                       │
      ▼                       │                       │
 saveTokens()  ◄── MUST save before completing        │
      │                       │                       │
 _finishRefreshToken(newToken)│                       │
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
> `TokenManagement` depends only on core abstractions — `TokenStorage` (implemented by `AuthLocalDataSource`) and a `TokenRefresher` callback that `initDI()` wires to `AuthRemoteDataSource.refresh` (parsed via `TokenPairModel`). That breaks the `NetworkClient → AuthInterceptor → TokenManagement → network` cycle and makes it unit-testable with fakes.

---

## 🧯 Error Handling

```
DioException ──NetworkClient──▶ ServerException ──Repository──▶ Failure ──Widget──▶ failure.message(context.l10n)
                (type, statusCode,                (sealed)
                 serverCode, serverMessage)
```

| `ServerException.type` | `Failure` | Text (`AppLanguage`) |
|---|---|---|
| `timeout` | `NetworkFailure(timeout)` | `errorTimeout` |
| `connectionError`, `badCertificate` | `NetworkFailure(noConnection)` | `errorNoConnection` |
| `badResponse` 401 | `UnauthorizedFailure` | `errorUnauthorized` (login: `loginInvalidCredentials`) |
| `badResponse` other | `ServerFailure(statusCode, serverCode, serverMessage)` | `errorServer` |
| `cancelled` | `CancelledFailure` | `errorCancelled` |
| `unknown` / anything else | `UnknownFailure(cause, stackTrace)` | `errorUnknown` |

Failures never carry UI text, so messages follow the active language, and unexpected errors keep their root cause for the `ErrorReporter`.

**Adapting it to your backend** — three hooks, nothing else to touch:
1. **Error-body format** — `NetworkClient._parseErrorBody` reads `{"code", "message"}` by default; change it for shapes like `{"error": {...}}`.
2. **Business errors** (`OTP_EXPIRED`, `ACCOUNT_LOCKED`, …) — don't add `Failure` subtypes; map `ServerFailure.serverCode` with your own enum (e.g. `ApiErrorCode.fromServerCode`) to `context.l10n` strings.
3. **Server messages** — set `useServerErrorMessage: true` in `AppConfig.fromFlavor` only if your backend returns friendly, localized `message`s; otherwise the generic `errorServer` text is shown.

---

## 📁 Project Structure

```
lib/
├── app/                           # Composition layer — the only layer that may import every other
│   ├── auth/cubit/                # Global auth state (AppAuthCubit/State)
│   ├── coordinator/               # Coordinator — the only place that uses Navigator
│   ├── di/                        # get_it composition root (sl, initDI)
│   ├── router/                    # AuthGate (Login ⇄ Home)
│   ├── app.dart                   # MyApp (MaterialApp + global BlocProviders)
│   └── bootstrap.dart             # bootstrap(flavor): error handling → config → DI → runApp
│
├── core/                          # Cross-cutting infrastructure (imports only core)
│   ├── config/                    # AppConfig + Flavor
│   ├── error/                     # ServerException, Failure, NetworkErrorCode
│   ├── local_storage/             # SharedPrefsManager (registered in get_it)
│   ├── localization/              # AppLanguage (en/vi), cubit/ (LocaleCubit), failure_message
│   ├── network/
│   │   ├── interceptors/          # AuthInterceptor, LoggingInterceptor
│   │   ├── network_client.dart    # Dio wrapper, typed methods, error mapping
│   │   └── token_management.dart  # Completer-based concurrent refresh
│   ├── theme/                     # App theme + cubit/ (ThemeCubit)
│   ├── utils/                     # AppLogger, constants, FeatureStatus
│   └── widget/                    # Shared widgets (CustomButton)
│
├── data/                          # Data layer (imports domain + core)
│   ├── datasource/{remote,local}/ # AuthRemoteDataSource, AuthLocalDataSource
│   ├── model/                     # UserModel, AuthResponseModel (toEntity())
│   └── repository/                # AuthRepositoryImpl
│
├── domain/                        # Pure business layer (imports core/error|utils only)
│   ├── entity/                    # UserEntity
│   ├── repository/                # AuthRepository (interface)
│   └── usecase/                   # LoginUseCase, LogoutUseCase
│
├── feature/                       # UI features (domain, core, app/coordinator|auth)
│   ├── dev_tools/                 # Theme gallery (hidden in prod)
│   ├── home/                      # HomePage (greets AppAuthState.user)
│   └── login/                     # LoginPage.newInstance(), LoginForm, LoginCubit, di/
│
└── main*.dart                     # Entry points → app/bootstrap.dart
```

Layer boundaries are enforced by `tool/check_architecture.sh` (run in CI) — see `.cursor/rules/layer-dependencies.mdc`.

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK `3.29.3` (Dart `3.7.2`) — the version CI uses (`.github/workflows/ci.yml`)
- A running backend exposing `/auth/login` and `/auth/refresh`

### Setup

```bash
# 1. Clone
git clone https://github.com/kietdt/flutter-production-starter
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

Per-flavor behavior lives on `AppConfig`: `prod` turns off network logging
(`enableNetworkLogging`) and hides the developer Theme Gallery
(`showDevTools` — no entry on Home, `Coordinator.openDevTools` is a no-op).

### Quality checks

```bash
flutter analyze   # static analysis — should report: No issues found!
./tool/check_architecture.sh  # layer boundaries + grep-checked rules
flutter test      # run the test suite (126 tests)
```

### Release signing (Android)

Release builds are signed with the key described in `android/key.properties`
(git-ignored), and shrunk with R8 (`minifyEnabled` + `shrinkResources`, extra
rules in `android/app/proguard-rules.pro`).

```bash
# 1. Create an upload keystore (once) — keep it and its passwords safe, never commit them
keytool -genkey -v -keystore android/app/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# 2. Point Gradle at it (storeFile is relative to android/app/)
cp android/key.properties.example android/key.properties   # then fill in the passwords

# 3. Build
flutter build appbundle --release -t lib/main_prod.dart     # Play Store
flutter build apk --release -t lib/main_prod.dart           # sideload / testing
```

Without `android/key.properties` the release build still works but falls back to
the **debug key** (Gradle prints a warning) — fine for CI and local checks, not
uploadable to the Play Store.

**CI:** every push to `main` / pull request runs only analyze + test. APKs are
built **only on a manual run** (GitHub → Actions → CI → *Run workflow*), via the
`Build APKs` job. Its release step signs with the real key when these repository
secrets are set, and otherwise uses the debug-key fallback:
`ANDROID_KEYSTORE_BASE64` (`base64 -i upload-keystore.jks`),
`ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_PASSWORD`, `ANDROID_KEY_ALIAS`.

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

Planned enhancements (tracked in `docs/PLAN.md`):

- [x] **Theme** — Material 3 (`ColorScheme.fromSeed`) + dark mode via `ThemeCubit`
- [x] **Navigation** — Flutter's built-in `Navigator` via a `Coordinator`, plus an `AuthGate` widget for the top-level auth flow
- [x] **Error handling** — sealed `Failure` model, localized messages via `context.l10n`, root cause kept for crash reporting
- [x] **Form validation** — `formz` inputs for email/password
- [x] **Localization** — manual i18n (English + Vietnamese), no codegen — abstract `AppLanguage`, read in widgets via `context.l10n` (rebuilds on language switch)
- [x] **Tests** — `bloc_test` + `mocktail` covering cubits, usecases, refresh concurrency, and widgets (126 tests)
- [x] **Flavors** — dev / staging / prod entry points + per-flavor config (`AppConfig`)
- [x] **CI/CD** — GitHub Actions (format → architecture checks → analyze → test + coverage on push/PR; debug + release APK build on manual run)
- [x] **Release signing** — Android release key via `key.properties` + R8 shrinking

---

## 📄 License

MIT — see [`LICENSE`](LICENSE).
