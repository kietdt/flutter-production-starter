# Project Memory & Architecture State
**Date:** October 10, 2026
**Project:** Flutter Production Starter
**Architecture:** Clean Architecture (data / domain / presentation), feature-first, with an `app/` composition layer

> History: phases GĐ 1–3 are tracked in `docs/PLAN.md`; the tech-lead review fixes (#1–#16) in
> `docs/superpowers/specs/2026-10-06-tech-lead-review-fixes.md`. State below is as of 2026-10-10:
> `flutter analyze` clean (strict lint set), `./tool/check_architecture.sh` clean, `flutter test` 126/126.

## 1. Layers & where things live

| Layer | Contents | May import |
|---|---|---|
| `lib/app/` | `bootstrap.dart` (`bootstrap(flavor)`, `initApp()`), `app.dart` (`MyApp`), `di/di.dart` (`sl`, `initDI()`), `router/auth_gate.dart` (`AuthGate`), `coordinator/coordinator.dart`, `auth/cubit/` (`AppAuthCubit`) | everything |
| `lib/core/` | config, error, local_storage, localization (+`cubit/`), network, theme (+`cubit/`), utils, widget | core only |
| `lib/domain/` | `UserEntity` (Equatable, `displayName`), `AuthRepository`, use cases | `core/error`, `core/utils` |
| `lib/data/` | datasources, models (`fromJson` via MapParser + `toEntity()`), `AuthRepositoryImpl` | domain, core |
| `lib/feature/` | `login/` (`login_page.dart`, `cubit/`, `form/`, `widget/`, `di/`), `home/` (`home_page.dart`), `dev_tools/` | domain, core, `app/coordinator`, `app/auth`; `app/di` only in `*_page.dart`; `feature/<x>/di/` may import data |

Boundaries are enforced by `tool/check_architecture.sh` (grep on `package:` imports; CI runs it). All imports are package imports (lint `always_use_package_imports`). `main*.dart` only call `bootstrap(Flavor.x)`.

## 2. Key mechanisms

### DI (`lib/app/di/di.dart`)
- `initDI()` is the only composition root: registers `SharedPrefsManager` (`await SharedPrefsManager.create()`), `AuthLocalDataSource`, `TokenManagement`, `NetworkClient`, auth datasource/repository, `LogoutUseCase`, `CheckSessionUseCase`, `AppAuthCubit`, `ThemeCubit`, `LocaleCubit`. No static `.instance` singletons.
- Feature-only registrations live in the feature: `LoginInjection.setup(sl)` (`feature/login/di/`) registers `LoginUseCase`, called from `LoginPage.newInstance()`.

### Auth & session
- `AppAuthCubit` (`AppAuthState{status, user}`, Equatable, `Nullable` copyWith) is the global session. `AuthGate` swaps `LoginPage.newInstance()` ⇄ `HomePage.newInstance()` on `status`.
- **Session = access token AND cached user.** `AuthRepository.currentUser()` (sync) returns the cached user when a token exists; `checkAuth()` restores it offline at startup. Token without a cached user (pre-#14 installs) → treated as logged out.
- Login: repository saves tokens + user (`StorageKeys.cachedUser`, JSON); `LoginPage` calls `AppAuthCubit.loggedIn(user:)`. Logout (button or failed refresh via `onUnauthorized`) clears tokens + user.
- Token refresh: `TokenManagement({storage: TokenStorage, refresher})` — idempotent `refreshToken()` (one shared `Completer`); `AuthInterceptor` skips the refresh flow for `requiresAuth: false` requests (login/refresh/logout).

### Error model (`.cursor/rules/error-model.mdc`)
`DioException → ServerException → sealed Failure → failure.message(context.l10n)`.
- `NetworkClient._mapException`: exhaustive switch on `DioExceptionType` (no `default` — it caught dio 5.11's new `transformTimeout`). `ServerException{type: NetworkErrorCode, statusCode, serverCode, serverMessage, cause}`; original stack kept via `Error.throwWithStackTrace`.
- `_parseErrorBody` is the single per-backend hook for the error-body format.
- `Failure` (sealed, `implements Exception`): `NetworkFailure(timeout|noConnection)`, `UnauthorizedFailure` (401), `ServerFailure(statusCode, serverCode, serverMessage)`, `CancelledFailure`, `UnknownFailure(cause, stackTrace)`. No UI text in `core/error`.
- `core/localization/failure_message.dart` maps failures to `AppLanguage` strings; `ServerFailure.serverMessage` shown only if `AppConfig.useServerErrorMessage`.
- `LoginState.failure` (not a string); `LoginState.failureMessage(l10n)` maps a 401 to `loginInvalidCredentials`. `LoginCubit` reports only `UnknownFailure` (with root cause) to `AppLogger.error`; expected failures are logged as info.
- Business errors: read `ServerFailure.serverCode` with a project enum — never add Failure subtypes.

### Localization
- Manual `AppLanguage` (en/vi), read via `context.l10n` (from `Localizations.localeOf`) — no static/global language. `LocaleCubit` (`core/localization/cubit/`) persists `StorageKeys.locale`. New keys are appended at the end.

### Logging & crash reporting
- `AppLogger` only (no `print`, no `dart:developer` outside it). `AppLogger.error(error:)` forwards to the pluggable `ErrorReporter`. `GlobalErrorHandler` + `AppBlocObserver` installed in `bootstrap()`.

### Network client
- `NetworkClient` typed `get/post/put/delete/patch`; `_withAuth` returns a new `Options` (never mutates the caller's); timeouts are `Duration`s. `dio` getter is `@visibleForTesting` (direct Dio calls would skip error mapping).

## 3. Quality gates
- `analysis_options.yaml`: `flutter_lints` + `strict-casts/raw-types/inference`, `always_use_package_imports`, `only_throw_errors`, `unawaited_futures` (error), `avoid_dynamic_calls`, `prefer_single_quotes`, `directives_ordering`, `prefer_const_constructors`, `prefer_final_locals`, `cancel_subscriptions`, `close_sinks`. Deliberately off: `require_trailing_commas`, `discarded_futures`, `sort_constructors_first` (reasons in the file). `very_good_analysis` was rejected (715 issues, conflicts with `explicit-local-types`).
- `tool/check_architecture.sh`: layer table + grep rules (Navigator outside coordinator, child-less `SizedBox` spacing, `dart:developer`, `== FeatureStatus.`, `json['…']` in data). Every rule in `AI_RULE.md` states "Enforced by" (lint / script / manual review).
- CI (`.github/workflows/ci.yml`, Flutter **3.29.3**, same as local): format check → architecture checks → analyze → `flutter test --coverage` (lcov uploaded as artifact); APK builds on manual dispatch.

## 4. Tests (`test/`, mirrors `lib/`) — 126 green
- Helpers (`test/helpers/`): `pump_app.dart` (boots real DI + `MyApp`; omit `prefs` to simulate an app restart), `fake_http_adapter.dart` (`FakeHttpAdapter` + `jsonResponse`), `in_memory_token_storage.dart`, `in_memory_auth_local_datasource.dart`, `session_prefs.dart` (`signedInPrefs`), `fake_error_reporter.dart`.
- Full-stack regression tests run the real NetworkClient → repository → cubit → UI with only the HTTP adapter faked: `feature/login/login_error_message_test.dart` (#13), `feature/home/session_user_test.dart` (#14), `core/network/auth_interceptor_test.dart` (#1/#2/#12).
- **Gotchas:**
  - Mock a failing async method with `thenAnswer((_) async => throw …)`, not `thenThrow` (sync throw escapes blocTest's zone → recorded states `[]`).
  - In `testWidgets`, never `await` a Dio call directly — the fake clock never advances; start it, then `pumpAndSettle()`.
  - Screens that boot "signed in" must seed `signedInPrefs` (token + cached user), not just a token.

## 5. Next steps
1. **SDK bump** (deliberately deferred): raise `environment.sdk` to `^3.7` → `dart format` switches to tall style and reformats nearly every file — do it as its own format-only commit. `flutter_lints` 6 needs Dart ≥ 3.8 (a newer Flutter than 3.29.3, local + CI together).
2. Major upgrades to evaluate with changelogs: `equatable` 3, `cupertino_icons` 2.
3. Replace placeholder staging/prod base URLs; native flavors if store builds per flavor are needed.
4. Per project: adapt `NetworkClient._parseErrorBody`, add an `ApiErrorCode` enum for business errors, decide `useServerErrorMessage`.
