# 🛠️ SPEC — Khắc phục 16 vấn đề từ Tech-Lead Review

> **Ngày review:** 2026-10-06
> **Trạng thái lúc review:** `flutter analyze` sạch · `flutter test` 39/39 pass — nhưng có 3 bug runtime đã được **xác nhận bằng test probe**.
> **Rà lại 2026-10-10** (sau #11/#12): `flutter analyze` sạch · `flutter test` 94/94 — các mục còn mở (#10, #13–#16) đã viết lại theo code hiện tại, kèm số liệu đo thật.
>
> **Ràng buộc đã chốt (từ `docs/PLAN.md`, không đổi):**
> - Navigation: `Navigator` built-in qua `Coordinator` + `AuthGate` (không go_router).
> - Error handling: **giữ try/catch**, map `Exception → Failure` (không thêm fpdart/Either).
>
> **Quy tắc thực hiện mỗi mục:** tuân thủ `.cursor/rules/*.mdc` + `AI_RULE.md` · viết test hồi quy **trước** khi sửa (bug) · `dart format lib/ test/` · `flutter analyze` sạch · `flutter test` pass.

---

## 📊 Bảng tiến độ tổng quan

| Giai đoạn | Nội dung | Mục | Trạng thái | Tiến độ |
|-----------|----------|-----|------------|---------|
| **P0** | Bug runtime nghiêm trọng | #1 #2 #3 | ✅ Hoàn thành | 3/3 |
| **P1** | Bảo mật & ổn định | #4 #5 #6 #7 #8 #9 | ✅ Hoàn thành | 5/5 (#4 ⏭️ bỏ qua) |
| **P2** | Kiến trúc | #10 #11 #12 #13 #14 #15 | ✅ Hoàn thành | 6/6 |
| **P3** | Dọn dẹp nhỏ | #16 | ✅ Hoàn thành | 1/1 (nâng SDK để commit riêng) |

**Chú thích:** ⬜ Chưa bắt đầu · 🟡 Đang làm · ✅ Hoàn thành · ⏭️ Bỏ qua

> ### 👉 BƯỚC TIẾP THEO
> P0 (~~#1~~ ~~#2~~ ~~#3~~) ✅ xong (2026-10-06). #4 ⏭️ bỏ qua (2026-10-07). P1 (#5 → #9) ✅ xong (2026-10-07). #11 + #12 ✅ xong (2026-10-08). #10, #13 → #16 ✅ xong (2026-10-10). Còn lại: **review + commit**, rồi một commit riêng nâng `environment.sdk` ≥ 3.7 + format tall style (#16), và chạy thử app trên thiết bị thật.

**Thứ tự phụ thuộc gợi ý:** #1 → #2 → #3 → #11 → #12 (cùng đụng token layer, làm liền mạch) → **#10 → #13 → #14 → #15 → #16**:
- #10 trước: di chuyển file `core/ → app/` đổi đường dẫn mà #13/#14 sẽ sửa; chuyển import sang `package:` trước để việc di chuyển chỉ còn là `sed`.
- #13 trước #14: cả hai cùng sửa `LoginState` / `LoginPage`; #14 dùng lại pattern `Nullable` + `Failure` mới.
- #15 sau #10/#13: lint nào khoá thay đổi của mục nào thì bật **ngay trong mục đó** (`always_use_package_imports` ở #10, `only_throw_errors` ở #13); #15 bật phần còn lại.
- #16 cuối: nâng SDK đổi style `dart format` toàn bộ file → làm khi không còn nhánh nào đang mở.

---

## 🔴 P0 — Bug runtime nghiêm trọng

### #1 — Deadlock khi `/auth/refresh` trả 401 ✅

**Vấn đề:** Request refresh (`requiresAuth: false`) vẫn đi qua `AuthInterceptor.onError`. Khi refresh trả 401, `isRefreshing == true` → `await getToken()` chờ completer mà completer lại chờ chính request refresh → treo vĩnh viễn. Probe test: `TIMEOUT (hang)`, user không bị logout.
**File:** `lib/core/network/interceptors/auth_interceptor.dart:36-57`

- [x] Viết test hồi quy `test/core/network/auth_interceptor_test.dart`: fake `HttpClientAdapter` luôn trả 401, có refresh token cũ → gọi request bất kỳ → kỳ vọng **kết thúc với lỗi** (không timeout), `onUnauthorized` được gọi đúng 1 lần, token bị xoá.
- [x] Trong `onError`: nếu `err.requestOptions.extra['requiresAuth'] == false` → `return handler.next(err)` ngay (bỏ qua toàn bộ luồng refresh).
- [x] Thêm case test: login sai mật khẩu (401, `requiresAuth: false`) khi còn refresh token cũ → **không** gọi refresh, trả lỗi thẳng.
- [x] Đặt key `'requiresAuth'` / `'isRetry'` thành hằng số (vd. `RequestExtraKeys`) thay vì string literal rải rác.

**Done khi:** test hồi quy pass, không còn đường nào trong interceptor `await` completer từ chính request refresh.

> **Kết quả (2026-10-06):** `onError` trả `handler.next(err)` ngay cho request `requiresAuth: false`; thêm `lib/core/network/request_extra_keys.dart`. Test `test/core/network/auth_interceptor_test.dart` (2 case) fail trước khi sửa (TimeoutException) → pass sau khi sửa. `flutter analyze` sạch, `flutter test` 41/41.

---

### #2 — Refresh token có thể bị gọi song song 2 lần ✅

**Vấn đề:** `TokenManagement.refreshToken()` không idempotent — nếu completer đang tồn tại vẫn tiếp tục gọi network. Trong interceptor, giữa check `isRefreshing` và gọi `refreshToken()` có `await getToken()` → 2 request 401 đồng thời đều lọt qua. Với refresh-token rotation, lần 2 fail → logout oan.
**File:** `lib/core/network/token_management.dart:49-66`, `auth_interceptor.dart:52-84`

- [x] Viết test hồi quy: 2–3 request đồng thời nhận 401 qua **interceptor thật** (không gọi trực tiếp `getToken`) → kỳ vọng endpoint `/auth/refresh` bị gọi **đúng 1 lần**, tất cả request được retry thành công.
- [x] Đầu `refreshToken()`: `if (_refreshTokenCompleter != null) return _refreshTokenCompleter!.future;` rồi mới tạo completer mới.
- [x] Gộp `startRefreshToken()` vào `refreshToken()` (đặt private), không để caller bên ngoài tự quản lý vòng đời completer.
- [x] Đơn giản hoá interceptor: bỏ nhánh `isRefreshing` riêng — chỉ cần gọi `refreshToken()` (đã idempotent).
- [x] Giữ logic "token đã được refresh bởi request khác" (`currentToken != requestToken`) và có test cho nó.

**Done khi:** test concurrency pass qua interceptor; `token_management_test.dart` cũ vẫn pass.

> **Kết quả (2026-10-06):**
> - `refreshToken()` idempotent: có completer đang chạy thì trả `future` của nó; completer được tạo **đồng bộ** trước mọi `await`. `startRefreshToken()` bị xoá, `finishRefreshToken()` → private `_finishRefreshToken()`.
> - Interceptor: bỏ nhánh `isRefreshing` riêng; đọc token bằng `getAccessTokenSync()` để không có `await` giữa check và `refreshToken()`. Chỉ request **khởi động** refresh mới `clearTokens()` + `onUnauthorized()` khi thất bại → logout đúng 1 lần.
> - Test: `token_management_test.dart` thêm case 3 lời gọi `refreshToken()` đồng thời → network 1 lần (**fail trước khi sửa: gọi 3 lần**). `auth_interceptor_test.dart` thêm 3 case qua interceptor thật: 3×401 đồng thời → 1 refresh + retry thành công; refresh thất bại → cả 3 lỗi, `onUnauthorized` 1 lần; token đã được rotate → retry không refresh.
> - ⚠️ Ghi chú: ở tầng interceptor, race **không tái hiện được** với storage đồng bộ hiện tại (khe `await` chỉ là microtask) — 3 test interceptor pass cả trên code cũ, đóng vai trò khoá hành vi. Race sẽ thành thật nếu sau này chuyển sang storage async (vd. secure storage — #4 hiện bỏ qua), lúc đó bất biến idempotent ở `TokenManagement` là lớp bảo vệ chính.
> - `flutter analyze` sạch, `flutter test` 45/45, chạy lặp 5 lần không flaky.

---

### #3 — Đổi ngôn ngữ không cập nhật UI ✅

**Vấn đề:** Widget đọc `AppLanguage.current` (static) → không phụ thuộc `InheritedWidget`; `home: const AuthGate()` là const nên subtree không rebuild. Probe test: toggle EN→VI, title vẫn `"Login"`.
**File:** `lib/main.dart:58-82`, `lib/core/localization/app_language.dart`, mọi chỗ dùng `AppLanguage.current`

- [x] Viết test hồi quy widget: boot app → tap `EN` → kỳ vọng AppBar title = `'Đăng nhập'`.
- [x] Tạo `AppLanguageScope extends InheritedWidget` (hoặc dùng `Localizations` + `LocalizationsDelegate<AppLanguage>`) cung cấp `AppLanguage` hiện tại.
- [x] Thêm extension `BuildContext.l10n` → `AppLanguageScope.of(context)`.
- [x] Thay `AppLanguage.current.x` trong **widget** bằng `context.l10n.x` (login, home, dev_tools, toggle buttons…).
- [x] Với chỗ không có context (vd. `EmailInput.errorText`): trả về **enum lỗi**, để widget map sang chuỗi qua `context.l10n` (đúng rule `ui-logic-in-state` / `enum-mapping`).
- [x] Giữ `AppLanguage.current` chỉ cho chỗ ngoài widget tree (nếu còn); ghi chú rõ trong doc comment.
- [x] Cập nhật `.cursor/rules/append-locale-keys.mdc` + `AI_RULE.md` về cách dùng `context.l10n`.

**Done khi:** test hồi quy pass; `grep -rn "AppLanguage.current" lib/feature` trả về rỗng.

> **Kết quả (2026-10-06):**
> - Chọn phương án **`Localizations`** thay vì `InheritedWidget` riêng: `context.l10n` (`lib/core/localization/app_language_context.dart`) đọc `Localizations.localeOf(context)` mà `MaterialApp` đã cung cấp → tự đăng ký dependency, không cần widget/delegate mới, test bọc `MaterialApp` vẫn chạy (mặc định `en`).
> - **Gỡ hẳn facade static** `AppLanguage.current` / `setCurrent` (không còn chỗ dùng ngoài widget tree) → chỉ còn một cách đọc chuỗi. `LocaleCubit` chỉ còn emit + persist.
> - Migrate 13 call site: `home.dart`, `login_page.dart`, `login_form.dart`, `theme_toggle_button.dart`; `MaterialApp.title` → `onGenerateTitle`.
> - Form input: `EmailValidationError` / `PasswordValidationError` có `message(AppLanguage l10n)`; `errorText` → `errorText(AppLanguage l10n)`.
> - Rule mới `.cursor/rules/localization-context.mdc` + `AI_RULE.md` §32 (tách rule riêng thay vì nhét vào `append-locale-keys.mdc` vì khác chủ đề); cập nhật `CLAUDE.md`, `README.md`.
> - Test: `test/core/localization/locale_switch_test.dart` (3 case: Login title/label, lỗi field đang hiển thị, Home title) — **fail trước khi sửa** (vẫn hiện tiếng Anh) → pass. `flutter analyze` sạch, `flutter test` 48/48.

---

## 🟠 P1 — Bảo mật & ổn định

### #4 — Token lưu plaintext trong SharedPreferences ⏭️ BỎ QUA

> **Quyết định (2026-10-07):** giữ token trong SharedPreferences — rủi ro chấp nhận được với dự án này, chi phí chuyển đổi không xứng (Keychain/Keystore + migration + xử lý reinstall iOS, Android `minSdk 23` / `compileSdk 36` / tắt Auto Backup, sửa toàn bộ test đang seed token qua SharedPreferences). Bản cài đặt thử đã được **revert**; các bước dưới giữ lại để tham khảo nếu sau này cần.

**File:** `lib/core/network/token_management.dart:12-47`

- [ ] ~~Thêm dependency `flutter_secure_storage`.~~
- [ ] ~~Tạo interface `TokenStorage` (`read/save/clear` access + refresh) và impl `SecureTokenStorage`.~~
- [ ] ~~Cache token trong memory sau lần đọc đầu; nạp ở `bootstrap` để `checkAuth()` vẫn đồng bộ.~~
- [ ] ~~Migration: token plaintext cũ → secure storage rồi xoá bản cũ.~~
- [ ] ~~iOS: xoá token khi reinstall (Keychain tồn tại sau uninstall) — cờ trong SharedPreferences.~~
- [ ] ~~Test với fake `TokenStorage`.~~

---

### #5 — LoggingInterceptor log password/token ✅

**File:** `lib/core/network/interceptors/logging_interceptor.dart`, `lib/core/di/di.dart`

- [x] Chỉ add `LoggingInterceptor` khi `kDebugMode && !AppConfig.instance.isProd`.
- [x] Thêm hàm `_redact()` che các key nhạy cảm: `password`, `accessToken`, `refreshToken`, `token`, header `Authorization` → `***`.
- [x] Đặt `LoggingInterceptor` **sau** `AuthInterceptor` nhưng log header đã redact.
- [x] Test unit cho `_redact()` (map lồng nhau, list).

> **Kết quả (2026-10-07):**
> - `AppConfig.enableNetworkLogging => kDebugMode && !isProd`. `NetworkClient` nhận `enableLogging` (mặc định `false`, an toàn); `initDI()` truyền cờ từ `AppConfig` → bật/tắt ở 1 chỗ, test được mà không cần đổi flavor.
> - Thay `_redact()` private bằng `LogRedactor.redact()` (`lib/core/network/log_redactor.dart`) để test trực tiếp: đệ quy Map/List + field của `FormData`, trả bản sao (không mutate request), so key không phân biệt hoa thường và bỏ `_`/`-` (`access_token`, `Refresh-Token`… đều khớp). Key nhạy cảm mà value là map/list thì che nguyên khối.
> - `LoggingInterceptor` redact cả headers (log mới — thấy `Authorization` vì đứng sau `AuthInterceptor`), query, body, response data và error data (response login/refresh chứa token).
> - Rule `custom-logging.mdc` + `AI_RULE.md` §6 thêm mục **Secrets**.
> - Test: `test/core/network/log_redactor_test.dart` (8 case), `test/core/network/network_client_logging_test.dart` (2 case: tắt → không có interceptor; bật → đứng sau `AuthInterceptor`), `app_config_test.dart` +1 case. Tất cả fail (compile) trước khi cài đặt → pass. `flutter analyze` sạch, `flutter test` 59/59.

---

### #6 — Thiếu global error handling ✅

**File:** `lib/main.dart:22-27`, `lib/core/utils/app_logger.dart`

- [x] Trong `bootstrap()`: set `FlutterError.onError` và `PlatformDispatcher.instance.onError` → `AppLogger.error(...)`.
- [x] Thêm hook `AppLogger.setReporter(ErrorReporter)` (interface) để sau này cắm Crashlytics/Sentry mà không sửa call site.
- [x] Bọc `Bloc.observer = AppBlocObserver()` log `onError` của mọi Cubit.
- [ ] (Tuỳ chọn) `ErrorWidget.builder` thân thiện cho release. — ⏭️ chưa làm (xem ghi chú).

> **Kết quả (2026-10-07):**
> - `ErrorReporter` (`lib/core/error/error_reporter.dart`): interface `report({error, stackTrace, message, fatal})`. `AppLogger.setReporter(ErrorReporter?)`; `AppLogger.error` thêm `fatal` (mặc định `false`) và chuyển tiếp sang reporter **chỉ khi có `error` object** (log thuần chuỗi không bị report). Reporter ném lỗi → bị nuốt + log, không làm crash app / không đệ quy.
> - `GlobalErrorHandler.install()` (`lib/core/error/global_error_handler.dart`): `FlutterError.onError` vẫn gọi `FlutterError.presentError` (giữ dump console mặc định) rồi `AppLogger.error(fatal: true)`; `PlatformDispatcher.onError` log `fatal: true` và trả `true`. Không dùng `runZonedGuarded` — `PlatformDispatcher.onError` là cách Flutter khuyến nghị hiện nay.
> - `AppBlocObserver` (`lib/core/error/app_bloc_observer.dart`): `onError` → `AppLogger.error('Unhandled error in <Cubit>', fatal: false)`.
> - `bootstrap()` cài cả hai ngay sau `ensureInitialized()` (trước DI) để bắt cả lỗi lúc khởi tạo; có comment chỗ cắm reporter.
> - Bỏ qua `ErrorWidget.builder`: release mặc định đã hiện ô xám trơn (không lộ stack trace); widget thân thiện cần `context.l10n` nhưng `ErrorWidget` có thể dựng ngoài `MaterialApp`/`Localizations` → nên làm cùng thiết kế UI lỗi thật, không làm vội.
> - Rule `custom-logging.mdc` + `AI_RULE.md` §6 thêm mục **Crash reporting**; `CLAUDE.md` cập nhật mục Logging + bootstrap.
> - Test (fail compile trước khi cài đặt → pass): `test/core/utils/app_logger_test.dart` (6 case), `test/core/error/global_error_handler_test.dart` (2), `test/core/error/app_bloc_observer_test.dart` (1); fake dùng chung ở `test/helpers/fake_error_reporter.dart`. `bootstrap()` không có test (gọi `runApp`) — chỉ review. `flutter analyze` sạch, `flutter test` 68/68.

---

### #7 — Android release ký bằng debug key ✅

**File:** `android/app/build.gradle:35-37`

- [x] Thêm `signingConfigs.release` đọc từ `android/key.properties` (đã ignore trong `android/.gitignore`).
- [x] Fallback về debug signing khi không có `key.properties` (để CI / dev build vẫn chạy) + log warning.
- [x] Bật `minifyEnabled true`, `shrinkResources true`, thêm `proguard-rules.pro` cơ bản.
- [x] Tạo `android/key.properties.example` và hướng dẫn trong `README.md`.
- [x] (Tuỳ chọn) CI: tạo `key.properties` từ GitHub Secrets cho job build release.

> **Kết quả (2026-10-07):**
> - `android/app/build.gradle`: đọc `rootProject.file("key.properties")`; có file → `signingConfigs.release` (`storeFile` tương đối với `android/app/`); không có → `signingConfigs.debug` + `logger.warn(...)`. Release bật `minifyEnabled` + `shrinkResources` + `proguard-android-optimize.txt` + `proguard-rules.pro`.
> - `android/app/proguard-rules.pro`: chỉ giữ line number cho stack trace (rule của Flutter đã được Flutter Gradle plugin tự thêm; plugin mang consumer rules riêng).
> - `android/key.properties.example` (không bị ignore) + mục **Release signing (Android)** trong `README.md` (tạo keystore, build appbundle/apk, fallback, secrets CI); cập nhật số test 48 → 68 và Roadmap.
> - CI (`.github/workflows/ci.yml`) tách 2 job: `analyze-test` chạy mỗi push `main` / PR; `build` (`needs: analyze-test`) **chỉ chạy khi bấm manual** (`workflow_dispatch`) — build debug APK (dev) + release APK (prod). Job `build` chỉ có cờ `HAS_RELEASE_KEYSTORE` ở job-level; bước `Set up release signing` (chỉ chạy khi có secret) giải mã `ANDROID_KEYSTORE_BASE64` → `upload-keystore.jks` và ghi `key.properties`; không có secret → fallback debug key nhưng vẫn kiểm tra được cấu hình R8.
> - **Kiểm chứng** (Flutter 3.29.3 local, `apksigner verify --print-certs`): không có `key.properties` → build OK, cert `CN=Android Debug`, Gradle in `WARNING: android/key.properties not found…`; có `key.properties` trỏ keystore tạm → build OK, cert `CN=Starter Test Upload`. File `key.properties` tạm đã xoá. R8 không báo lỗi; **chưa chạy thử APK đã minify trên thiết bị** và chưa chạy CI thật (Flutter 3.27.4).

---

### #8 — Dev Tools lộ trong prod ✅

**File:** `lib/feature/home/home.dart:36-39`, `lib/core/coordinator/coordinator.dart:19`

- [x] Thêm `bool get showDevTools => !isProd;` vào `AppConfig`.
- [x] Ẩn entry point trên Home khi `!AppConfig.instance.showDevTools` (dùng `Visibility`/điều kiện theo rule `widget-visibility-newinstance`).
- [x] `Coordinator.openDevTools` assert/no-op khi prod.
- [x] Widget test: flavor prod → không tìm thấy entry Dev Tools.

> **Kết quả (2026-10-07):**
> - `AppConfig.showDevTools => !isProd`.
> - Home: dùng **collection-if** `if (AppConfig.instance.showDevTools) InkWell(...)` thay vì `Visibility` — cờ tĩnh theo flavor (không phải state của Cubit) nên không cần `newInstance`/`Builder`, và không mount widget rỗng nào (đúng tinh thần rule `widget-visibility-newinstance`).
> - `Coordinator.openDevTools`: chọn **no-op** (không `assert`) khi prod — an toàn cả release lẫn khi chạy `main_prod.dart` ở debug; là lớp chặn thứ 2 nếu sau này có entry point khác quên ẩn.
> - Test `test/feature/home/dev_tools_entry_test.dart` (5 case): getter theo flavor; Home dev có / prod không có entry `Navigation`; `openDevTools` dev mở `DevToolsGalleryPage` / prod không mở. Hai case prod **fail trước khi sửa** → pass. `flutter analyze` sạch, `flutter test` 73/73.
> - ⚠️ Code `DevToolsGalleryPage` vẫn nằm trong binary prod (cờ runtime nên tree-shaking không loại được) — chỉ không truy cập được. Muốn loại hẳn cần `const bool.fromEnvironment` / entry point riêng; chưa cần ở mức này.
> - `README.md` mục Flavors: ghi hành vi theo flavor (`enableNetworkLogging`, `showDevTools`); số test 68 → 73.

---

### #9 — `LoginState.copyWith` không xoá được field nullable ✅

**File:** `lib/feature/login/cubit/login_state.dart:20-36`, `login_cubit.dart`

- [x] Hỗ trợ clear field: dùng sentinel / `ValueGetter<String?>? errorMessage` cho `errorMessage` và `user`.
- [x] Khi `login()` bắt đầu (emit loading) → reset `errorMessage = null`.
- [x] Test: failure → login lại success → `errorMessage == null`.
- [x] Áp dụng cùng pattern cho các state khác có field nullable; ghi vào `AI_RULE.md`.

> **Kết quả (2026-10-07):**
> - Dùng wrapper **`Nullable<T?>`** (`lib/core/utils/nullable.dart`, lấy từ dự án `flutter_game_space_dodge` theo yêu cầu — ban đầu làm bằng `ValueGetter`, đã thay). `LoginState.copyWith`: `user` / `errorMessage` nhận `Nullable<T?>?` — bỏ qua = giữ, `const Nullable(null)` = xoá, `Nullable(v)` = gán. Constructor `Nullable` để positional (ngoại lệ có chủ đích của rule named-params, ghi trong rule).
> - `LoginCubit.login()`: emit `loading` kèm `errorMessage: const Nullable(null)`; success `user: Nullable(user)`; failure `errorMessage: Nullable(e.message)`.
> - Các state khác (`AppAuthState`, `ThemeState`, `LocaleState`, `HomeState`) hiện **không có field nullable** → không cần đổi; rule áp dụng khi thêm (vd. `AppAuthState.user` ở #14).
> - Rule mới `.cursor/rules/copywith-nullable-fields.mdc` + `AI_RULE.md` §33; thêm 1 dòng vào `CLAUDE.md`.
> - Test `test/login_cubit_test.dart` +4: blocTest fail → retry success, kỳ vọng `loading`/`success` lần 2 có `errorMessage == null` (**fail trước khi sửa**: `loading` lần 2 vẫn mang `'No internet connection'`); 3 test `copyWith` (giữ / xoá / gán). `flutter analyze` sạch, `flutter test` 77/77.

---

## 🟡 P2 — Kiến trúc

### #10 — Dependency giữa các tầng bị ngược ✅

**Vấn đề (rà lại code 2026-10-10):**
- `core/coordinator/coordinator.dart:16` import `feature/dev_tools/dev_tools_gallery_page.dart`, trong khi `feature/dev_tools` lại import coordinator → vòng import **core ↔ feature**.
- `core/router/app_router.dart:17-18` import `feature/home`, `feature/login`.
- `core/di/di.dart:10-16` import `data/` + `domain/` — composition root nhưng đang nằm trong `core`.
- `core/auth/app_auth_cubit.dart:2-3` import `domain/usecase`.
- `bootstrap()` + `MyApp` nằm trong `main.dart`; `main_dev/staging/prod.dart` import ngược lại `main.dart`.
- `feature/login/login_page.dart:8` import `core/di` để lấy `sl()` — chấp nhận được (điểm tạo Cubit của màn hình) nhưng phải ghi thành ngoại lệ trong quy ước.
- ~~Vòng `token_management → di → network_client`~~ — đã hết từ #11. `domain` đã sạch (chỉ import nội bộ); `data` không import `feature`/`di`.
- `lib/` có **157 import tương đối** → di chuyển file phải sửa tay từng đường dẫn `../../..`.

**File:** `lib/main.dart`, `lib/main_*.dart`, `lib/core/{auth,coordinator,di,router}/`, `lib/feature/**` (import), `test/**` (import)

**Thiết kế:**
```
lib/app/
├── app.dart                          # MyApp (MaterialApp + BlocProvider toàn cục)  ← main.dart
├── bootstrap.dart                    # bootstrap(flavor), initApp()                 ← main.dart
├── di/di.dart                        # sl + initDI() — composition root             ← core/di/
├── router/auth_gate.dart             # AuthGate                                     ← core/router/app_router.dart
├── coordinator/coordinator.dart      #                                              ← core/coordinator/
└── auth/cubit/app_auth_cubit.dart    # + app_auth_state.dart (part of)              ← core/auth/
```
(`app_router.dart` đổi tên theo class `AuthGate`; `auth/cubit/` theo rule `state-folder-naming`.)

| Tầng | Được import |
|---|---|
| `core` | chỉ `core` + package ngoài |
| `domain` | `domain`, `core` (error, utils) |
| `data` | `data`, `domain`, `core` |
| `feature/<x>` | chính nó, `domain`, `core`, `app/coordinator`, `app/auth`; `app/di` **chỉ** trong `*_page.dart` để lấy `sl()` khi tạo Cubit; `feature/<x>/di/` (composition riêng của feature) được import `data` |
| `app` | tất cả |
| `main_*.dart` | `app/bootstrap.dart`, `core/config` |

Cấm: feature A import feature B (đi qua `Coordinator`); feature import `data` (trừ `feature/<x>/di/`). Vòng `app/coordinator ↔ feature/<x>/<x>_page.dart` là **có chủ đích** (Coordinator phải biết page để push) — Dart cho phép, script không chặn.

- [x] **B1 — import `package:`:** `dart fix --apply --code=always_use_package_imports` (tự sửa cả 157 chỗ) + bật lint `always_use_package_imports` để khoá (chuyển từ #15 sang đây). Commit riêng, không đổi logic.
- [x] **B2 — di chuyển file:** `git mv` theo bảng trên (giữ lịch sử), sửa import bằng `sed` trên đường dẫn `package:` (`core/di/` → `app/di/`…). `main*.dart` chỉ còn import `app/bootstrap.dart` + `core/config`.
- [x] **B3 — script kiểm tra:** `tool/check_architecture.sh` (grep trên `package:flutter_production_starter/<tầng>/`, exit 1 khi vi phạm bảng trên); thêm step chạy script **trước** `flutter analyze` trong job `analyze-test` của CI. Kiểm chứng: cố tình thêm 1 import sai → script fail, xoá đi → pass. (#15 sẽ thêm các check rule khác vào cùng script.)
- [x] **B4 — quy ước:** rule mới `.cursor/rules/layer-dependencies.mdc` + mục mới trong `AI_RULE.md` (bảng trên + ngoại lệ `*_page.dart` / `feature/<x>/di/`).
- [x] **B5 — docs & test:** `CLAUDE.md` (Layout, DI, Auth/routing — đường dẫn `core/di`, `core/router`, `core/coordinator`), `README.md` (cây thư mục), `.cursor/rules/navigation-coordinator.mdc` + `AI_RULE.md` (đường dẫn coordinator), `test/core/auth/` → `test/app/auth/`, import trong `test/`.

**Done khi:** `tool/check_architecture.sh` pass và chạy trong CI; `lib/core/` không còn import `data/domain/feature/app`; `flutter analyze` sạch; `flutter test` pass (≥ 94); chạy app dev: Login → Home → Dev Tools → Logout vẫn đúng.


> **Kết quả (2026-10-10):**
> - B1: `dart fix --apply --code=always_use_package_imports` (157 chỗ, 55 file) + bật lint. B2: `git mv` sang `lib/app/{di,router/auth_gate.dart,coordinator,auth/cubit}` + tách `main.dart` thành `app/bootstrap.dart` / `app/app.dart`; `main*.dart` chỉ còn `bootstrap(Flavor.x)`. `test/core/auth/` → `test/app/auth/`.
> - B3: `tool/check_architecture.sh` (bảng tầng + cấm feature→feature, feature→data ngoài `di/`, `app/di` chỉ trong `*_page.dart`, `main*` chỉ import bootstrap/config). Kiểm chứng: chèn 3 import sai → script báo đủ 3 + exit 1; gỡ ra → pass. Step CI `Architecture checks` trước `Analyze`.
> - B4/B5: rule `.cursor/rules/layer-dependencies.mdc` + `AI_RULE.md` §34; cập nhật `CLAUDE.md` (Layout/Layers/DI/Flavors/Auth), `README.md` (cây thư mục), đường dẫn coordinator trong `navigation-coordinator.mdc` + `AI_RULE.md` §11.
> - `flutter analyze` sạch, `flutter test` 94/94 tại thời điểm xong #10. ⚠️ Chưa chạy app trên thiết bị — luồng Login → Home → Logout được phủ bằng widget test full-app (xem #14).

---

### #11 — Hai cơ chế DI song song (static singleton + get_it) ✅

**File:** `token_management.dart`, `shared_prefs_manager.dart`, `auth_repository_impl.dart:27,44,52`, `app_auth_cubit.dart:13`

- [x] Bỏ `static instance` của `TokenManagement` → đăng ký vào `get_it`, inject qua constructor (`SharedPrefsManager` / local datasource, `remoteDataSource`).
- [x] `SharedPrefsManager`: đăng ký `registerSingleton` sau `init()`; các cubit nhận qua constructor (đã đúng với Theme/Locale).
- [x] Hiện thực `AuthLocalDataSource` (đang là dead code) bọc phần đọc/ghi token qua `SharedPrefsManager`; `AuthRepositoryImpl` nhận `localDataSource` thay vì gọi `TokenManagement.instance`.
- [x] `AppAuthCubit.checkAuth()` đi qua usecase/repository (`GetAuthStatusUseCase` hoặc `AuthRepository.hasSession()`), không đọc token trực tiếp.
- [x] `AuthInterceptor` nhận `TokenManagement` qua constructor.
- [x] Cập nhật test để mock qua constructor (mocktail), bỏ phụ thuộc `SharedPreferences.setMockInitialValues` ở unit test thuần.

> **Kết quả #11 + #12 (2026-10-08, làm gộp vì cùng sửa luồng refresh):**
> - **Phá vòng `NetworkClient → AuthInterceptor → TokenManagement → network`** bằng abstraction trong core (đã chốt với user): `TokenManagement({storage, refresher})` chỉ phụ thuộc `TokenStorage` (interface, `lib/core/network/token_storage.dart`) + `TokenRefresher` (typedef callback trả `TokenPair`, `lib/core/network/token_pair.dart`). `initDI()` nối `refresher` → `sl<AuthRemoteDataSource>().refresh(rt)` (resolve lazy lúc refresh). Core không import data/di → khớp sẵn hướng #10.
> - **Data:** `AuthLocalDataSource implements TokenStorage`, `AuthLocalDataSourceImpl(prefs:)` dùng `StorageKeys.accessToken/refreshToken` (**giữ nguyên key** `access_token`/`refresh_token` → user đang đăng nhập không bị logout khi update). `AuthRepositoryImpl(remoteDataSource:, localDataSource:)` + `hasSession()`.
> - **Domain:** `AuthRepository.hasSession()` + `CheckSessionUseCase`; `AppAuthCubit(checkSessionUseCase:, logoutUseCase:)`.
> - **`SharedPrefsManager`:** bỏ `static instance`; `SharedPrefsManager({required SharedPreferences prefs})` + `static create()`; `_prefs` non-null nên bỏ các nhánh `?? false`. `initDI()` thành `async` và tự `registerSingleton(await SharedPrefsManager.create())`; `initApp()` chỉ còn `await initDI()`.
> - `AuthInterceptor(tokenManagement:)`, `NetworkClient(tokenManagement:)`. Ngoài `di.dart` chỉ còn `sl` ở `main.dart` và `LoginPage` (điểm tạo Cubit của màn hình).
> - Test: `test/token_management_test.dart` → `test/core/network/token_management_test.dart` dùng `InMemoryTokenStorage` (`test/helpers/`) + refresher giả — **không còn SharedPreferences/`sl`**. Test interceptor tự nối graph thật (storage → TokenManagement → `AuthRemoteDataSourceImpl` → NetworkClient). Mới: `auth_local_datasource_test` (3), `auth_repository_impl_test` (5), `app_auth_cubit_test` (3), `token_pair_model_test` (2). Các test widget chuyển sang `await initDI()`.
> - Docs: `CLAUDE.md` (DI, bootstrap), `README.md` (local storage, sơ đồ refresh — sửa luôn tên `startRefreshToken`/`finishRefreshToken` đã cũ từ #2, số test), ví dụ trong `.cursor/rules/repository-json-parsing.mdc` (bản `AI_RULE.md` §12 không có ví dụ nên không đổi).
> - `flutter analyze` sạch, `flutter test` 94/94; `test/core/network` chạy lặp 5 lần không flaky.

---

### #12 — Logic refresh bị trùng, vi phạm rule MapParser ✅

**File:** `token_management.dart:65-103`, `auth_remote_datasource.dart:34-43`

- [x] `TokenManagement.refreshToken()` gọi `AuthRemoteDataSource.refresh()` (inject), bỏ `sl<NetworkClient>()` và `data['accessToken'] as String`.
- [x] Tạo `TokenPairModel` (accessToken, refreshToken) parse qua `MapParser`, nếu response refresh không chứa `user`.
- [x] Xoá vòng import `token_management → di`.
- [x] Test: response refresh thiếu `accessToken` → coi là fail, clear token, `onUnauthorized`.

> **Kết quả (2026-10-08, gộp với #11 — xem chi tiết ở #11):**
> - `AuthRemoteDataSource.refresh()` trả `TokenPairModel` (`lib/data/model/token_pair_model.dart`, `parseString` + `toEntity()` → `TokenPair`); `TokenManagement` gọi qua `refresher` được inject, không còn `sl`, `NetworkClient`, `as String`, hay import `di`.
> - Response thiếu `accessToken` → `StateError`, **không lưu gì**; qua interceptor: request lỗi, token bị xoá, `onUnauthorized` 1 lần (test mới trong `auth_interceptor_test.dart`).
> - Sửa thêm: server **không rotate** refresh token (response thiếu `refreshToken`) → giữ refresh token hiện tại thay vì ghi chuỗi rỗng (trước đây làm mất session ở lần refresh sau). Có test.

---

### #13 — Error model chưa chặt ✅

**Vấn đề (rà lại code 2026-10-10, sau #11/#12):**
- `Failure` là `abstract class` thường, **không** `implements Exception` → `throw e.toFailure()` sẽ vi phạm `only_throw_errors` (#15) và không `switch` exhaustive được.
- Failure mang **chuỗi tiếng Anh cố định** (`NetworkErrorCode.message`) → `LoginCubit` gán `e.message` vào `LoginState.errorMessage` → SnackBar **luôn tiếng Anh dù đang ở VI** (cùng loại lỗi #3). Fallback `context.l10n.loginFailed` không bao giờ chạy vì lúc failure `errorMessage` luôn khác null.
- **Sai mật khẩu hiện "An unexpected error occurred."**: nhánh `badResponse` lấy `code = errorData['code'] ?? statusCode` (vd. `'401'`) → `NetworkErrorCode.fromCode('401')` rơi về `unknown`. Status code chỉ còn nằm trong chuỗi `'[401] …'` → không phân biệt được 401 / 4xx / 5xx.
- `ServerException.code` trộn 2 thứ: tên enum dạng string (`'timeout'`) và mã server trả về → phải round-trip `errorCode` / `fromCode`.
- `_mapException` có `default` (`badCertificate` rơi vào `unknown` âm thầm) và trả kiểu `Exception` thay vì `ServerException`.
- Repository `catch (_) { throw const UnknownFailure(); }` **nuốt nguyên nhân gốc** (vd. lỗi parse model) → `AppLogger.error` ở Cubit chỉ thấy `UnknownFailure`, `ErrorReporter` (#6) mất cause + stack trace.

**File:** `lib/core/error/failures.dart:11-46`, `lib/core/error/exceptions.dart:6-79`, `lib/core/network/network_client.dart:170-225`, `lib/data/repository/auth_repository_impl.dart:36-41`, `lib/feature/login/cubit/login_cubit.dart:54-65`, `login_state.dart:9`, `login_page.dart:33-38`, `lib/core/localization/app_language.dart`

**Thiết kế đề xuất** (giữ try/catch theo `docs/PLAN.md`, không Either):
```dart
// core/error/exceptions.dart — tầng data, KHÔNG chứa chuỗi UI
enum NetworkErrorCode { timeout, connectionError, badCertificate, badResponse, cancelled, unknown }

class ServerException implements Exception {
  final NetworkErrorCode type;
  final int? statusCode;       // HTTP status (chỉ có khi badResponse)
  final String? serverCode;    // mã nghiệp vụ trong body lỗi (vd. 'OTP_EXPIRED')
  final String? serverMessage; // message trong body lỗi — mặc định chỉ để log
  final Object? cause;
  const ServerException({required this.type, this.statusCode, this.serverCode, this.serverMessage, this.cause});
}

// core/error/failures.dart — sealed: mọi subtype buộc nằm cùng library
// (ngoại lệ có chủ đích của rule one-class-per-file, ghi vào rule)
sealed class Failure implements Exception { const Failure(); }
final class NetworkFailure extends Failure { final NetworkFailureReason reason; } // timeout / noConnection
final class UnauthorizedFailure extends Failure {}                              // 401
final class ServerFailure extends Failure { final int? statusCode; final String? serverCode; final String? serverMessage; }
final class CancelledFailure extends Failure {}                                 // giữ: dự án dùng CancelToken sẽ không bị báo lỗi oan
final class UnknownFailure extends Failure { final Object? cause; final StackTrace? stackTrace; }
```

| `ServerException.type` | → `Failure` | Key `AppLanguage` |
|---|---|---|
| `timeout` | `NetworkFailure(reason: timeout)` | `errorTimeout` |
| `connectionError`, `badCertificate` | `NetworkFailure(reason: noConnection)` | `errorNoConnection` (gộp — người dùng không xử lý khác nhau) |
| `badResponse` + 401 | `UnauthorizedFailure` | `errorUnauthorized` (login: `loginInvalidCredentials`) |
| `badResponse` khác | `ServerFailure(statusCode, serverCode, serverMessage)` | `errorServer` (hoặc `serverMessage` nếu bật cờ — xem dưới) |
| `cancelled` | `CancelledFailure` | `errorCancelled` |
| `unknown` / lỗi khác | `UnknownFailure(cause, stackTrace)` | `errorUnknown` |

**Điểm tuỳ biến cho từng dự án** (boilerplate chỉ dựng khung, ghi rõ trong `README.md`):
1. **Format body lỗi của backend** (`{code, message}`, `{error: {...}}`, `errors: [...]`…) — gom vào **một** hàm `_parseErrorBody(Object? data)` trong `NetworkClient` (đọc qua `MapParser`, trả `serverCode` + `serverMessage`). Dự án mới chỉ sửa hàm này.
2. **Lỗi nghiệp vụ** (`OTP_EXPIRED`, `ACCOUNT_LOCKED`…) — **không** thêm subtype vào `Failure` (core không phụ thuộc nghiệp vụ). Mỗi dự án tự tạo enum (vd. `ApiErrorCode.fromServerCode(String?)` + getter map l10n) đọc từ `ServerFailure.serverCode`.
3. **Hiển thị message của server** — cờ `AppConfig.useServerErrorMessage`, mặc định `false` (không lộ chi tiết kỹ thuật). Bật khi backend đảm bảo `message` thân thiện và đúng ngôn ngữ.

**Các bước:**
- [x] **Test hồi quy trước** (phải fail trên code hiện tại):
  - Widget: locale VI + repository ném lỗi mất mạng → SnackBar hiện chuỗi **tiếng Việt** (hiện đang ra tiếng Anh).
  - Widget/unit: login nhận 401 → hiện `loginInvalidCredentials` (hiện đang ra "An unexpected error occurred.").
- [x] `ServerException` như thiết kế trên; bỏ `NetworkErrorCode.errorCode` / `message` / `fromCode` (không round-trip string nữa), thêm `badCertificate`.
- [x] `NetworkClient._mapException` trả `ServerException`, `switch` exhaustive trên `DioExceptionType` (bỏ `default`); giữ `statusCode` dạng `int`; body lỗi đọc qua `_parseErrorBody` (điểm tuỳ biến 1). Nhánh `catch (e)` trong `_request` → `type: unknown, cause: e`.
- [x] `Failure` → `sealed class Failure implements Exception` với các subtype trên. `ValidationFailure` (lỗi theo field 400/422) **chỉ thêm khi có API cần** — hiện chưa có, không tạo class rỗng.
- [x] `ServerException.toFailure()` switch exhaustive theo bảng trên. Repository: `catch (e, st)` → `UnknownFailure(cause: e, stackTrace: st)` thay vì nuốt lỗi.
- [x] Mapping `Failure` → chuỗi đặt ở `lib/core/localization/failure_message.dart`: `extension FailureMessage on Failure { String message(AppLanguage l10n) => switch (this) {...} }` (cùng pattern `EmailValidationError.message(l10n)` của #3); nhánh `ServerFailure` trả `serverMessage` khi `AppConfig.useServerErrorMessage` bật và message khác rỗng, ngược lại `errorServer`. Thêm cờ vào `AppConfig` + các key ở bảng vào `AppLanguage` + `EnLanguage` + `ViLanguage`.
- [x] `LoginState`: `String? errorMessage` → `Failure? failure` (`copyWith` nhận `Nullable<Failure?>?`, clear ở emit `loading` như #9). `LoginCubit` emit `failure: Nullable(e)`; nhánh `catch (e, st)` dự phòng → `UnknownFailure(cause: e, stackTrace: st)`.
- [x] `LoginPage` map `state.failure` → chuỗi qua `context.l10n`; riêng `UnauthorizedFailure` dùng `loginInvalidCredentials`. Phân nhánh trên `Failure` bằng `switch` exhaustive (không `is`/`==` rải rác).
- [x] Bật lint `only_throw_errors` ngay trong mục này (không chờ #15) để khoá `Failure implements Exception`. Đã đo: 2 chỗ trong `lib/` (chính là `auth_repository_impl.dart:38,40` — tự hết khi `Failure implements Exception`) + 4 chỗ trong `test/` (`throw` biến kiểu `Object`, `ServerFailure` cũ).
- [x] Cập nhật test: viết lại `test/error_handling_test.dart` theo bảng mapping (mỗi dòng 1 case) + `_mapException` qua fake adapter (401 giữ `statusCode`, `serverCode`/`serverMessage` được giữ, `badCertificate` → `noConnection`); `failure_message` với cờ `useServerErrorMessage` bật/tắt; `login_cubit_test.dart`, `login_page_test.dart` (đổi `thenThrow` → `thenAnswer((_) async => throw …)`), `login_usecase_test.dart`; `auth_interceptor_test.dart` thêm `.having(type/statusCode)`.
- [x] Docs: rule mới `.cursor/rules/error-model.mdc` + mục mới trong `AI_RULE.md` (sealed `Failure`, không chuỗi UI trong `core/error`, map qua `context.l10n`, lỗi nghiệp vụ đi qua `serverCode` chứ không thêm subtype, ngoại lệ one-class-per-file); cập nhật ví dụ `ServerException` ở `AI_RULE.md` §1 + `class-initialization.mdc` nếu đổi constructor; 1 dòng trong `CLAUDE.md`; `README.md`: mục `error/`, feature list + hướng dẫn **3 điểm tuỳ biến** ở trên.

**Done khi:** 2 test hồi quy fail trước → pass sau; `lib/core/error/` không còn chuỗi hiển thị nào; `_mapException` không còn `default`; `only_throw_errors` bật, `flutter analyze` sạch, `flutter test` pass.


> **Kết quả (2026-10-10):**
> - Test hồi quy `test/feature/login/login_error_message_test.dart` (2 case, chạy stack thật, chỉ giả HTTP adapter) — **fail trước khi sửa**; đã xác nhận code cũ hiện "No internet connection…" (tiếng Anh ở VI) và "An unexpected error occurred." cho 401 → pass sau khi sửa.
> - `ServerException{type, statusCode, serverCode, serverMessage, cause}`; `_mapException` exhaustive, giữ stack gốc bằng `Error.throwWithStackTrace`; `_parseErrorBody` là điểm tuỳ biến duy nhất. Bỏ `default` đã bắt được ngay `DioExceptionType.transformTimeout` (mới trong dio 5.11) khi nâng dependency ở #16 → map vào `timeout`, có test.
> - `sealed Failure implements Exception` + 5 subtype (có `toString()` để log); `toFailure(stackTrace:)`; repository `catch (e, st)` → `UnknownFailure(cause, stackTrace)`.
> - `core/localization/failure_message.dart` + 7 key mới (EN/VI); cờ `AppConfig.useServerErrorMessage` (mặc định `false`). `LoginState.failure` + `failureMessage(l10n)` (401 → `loginInvalidCredentials`). `LoginCubit` chỉ gửi `UnknownFailure` (kèm cause) lên `AppLogger.error`/reporter; lỗi "dự kiến" (mất mạng, sai mật khẩu…) chỉ log info — tránh nhiễu crash report.
> - Lint `only_throw_errors` bật; `FakeErrorReporter.throwOnReport` đổi sang `Exception?`.
> - Test: `test/error_handling_test.dart` → viết lại thành `test/core/error/error_handling_test.dart` (mapping Dio→ServerException qua fake adapter, bảng ServerException→Failure, repository, FailureMessage + cờ); cập nhật `login_cubit_test` (+UnknownFailure giữ cause, +3 case `failureMessage`), `login_page_test`, `login_usecase_test` (bỏ `thenThrow`), `auth_interceptor_test` (assert `type` + `statusCode: 401`).
> - Docs: `.cursor/rules/error-model.mdc` + `AI_RULE.md` §35, ngoại lệ sealed trong `one-class-per-file` (+ `AI_RULE.md` §30), ví dụ `ServerException` ở §1 + `class-initialization.mdc`, 1 dòng `CLAUDE.md`, mục **🧯 Error Handling** trong `README.md` (bảng mapping + 3 điểm tuỳ biến). `flutter test` 109/109 lúc xong #13.

---

### #14 — Thiếu trạng thái user toàn cục ✅

**Vấn đề (rà lại code 2026-10-10):**
- `AppAuthState` chỉ có `status`; `loggedIn()` không nhận user (`app_auth_cubit.dart:24`), `LoginPage` gọi `loggedIn()` không truyền gì (`login_page.dart:32`) → user vừa đăng nhập bị bỏ đi; `LoginState.user` chỉ còn dùng để log + test.
- Mở lại app: `checkAuth()` chỉ biết **có token** (`AuthRepository.hasSession()`), không có user → Home không hiện được tên/email; feature nào cần user phải tự gọi API.
- `AuthResponseModel.user` có trong response login nhưng không được lưu.
- Test `AppAuthCubit` đã có từ #11 (`test/core/auth/app_auth_cubit_test.dart`, 3 case) → chỉ cần mở rộng.

**File:** `lib/core/auth/app_auth_cubit.dart:16-31` + `app_auth_state.dart` (sau #10: `lib/app/auth/cubit/`), `lib/domain/repository/auth_repository.dart:13`, `lib/domain/usecase/check_session_usecase.dart`, `lib/domain/entity/user_entity.dart`, `lib/data/datasource/local/auth_local_datasource.dart`, `lib/data/repository/auth_repository_impl.dart`, `lib/core/utils/constants.dart` (`StorageKeys`), `lib/feature/login/login_page.dart:31-33`, `lib/feature/home/home.dart`

**Quyết định — khôi phục user khi mở lại app:**

| Cách | Ưu | Nhược |
|---|---|---|
| **A. Cache user** (JSON) trong SharedPreferences qua `AuthLocalDataSource` | `checkAuth()` vẫn đồng bộ, không màn chờ mạng, chạy offline | Thông tin user có thể cũ tới lần login sau |
| **B. Gọi `GET /auth/me`** khi mở app | Luôn mới | `checkAuth()` thành async + cần mạng; mỗi backend một endpoint khác nhau |

→ **Chọn A làm mặc định cho boilerplate.** Dự án nào có `/auth/me` thì tự thêm usecase làm mới user sau khi vào Home (không làm sẵn).

**Bất biến:** có phiên ⇔ có access token **và** có user đã cache. Token có mà user không có (bản cài cũ chưa lưu user) → coi như hết phiên → về Login; token cũ bị ghi đè ở lần login sau. Boilerplate chưa phát hành nên chấp nhận được — dự án đã phát hành phải tự viết migration.

- [x] **Test trước** (fail trên code hiện tại): `checkAuth()` có token + user cache → `authenticated` với `state.user` đúng; login thành công → `AppAuthCubit.state.user` là user vừa login; logout → `user == null`.
- [x] `UserEntity extends Equatable` (để `previous.user != current.user` so theo giá trị).
- [x] Data: `AuthLocalDataSource` thêm `UserModel? get cachedUser`, `saveUser(UserModel)`, `clearUser()`; key mới `StorageKeys.cachedUser` (JSON string, parse qua `UserModel.fromJson` — đúng rule MapParser). JSON hỏng → coi như không có, không crash.
- [x] `AuthRepository.hasSession()` → `UserEntity? currentUser()` (đồng bộ, `null` = không có phiên); `CheckSessionUseCase.execute()` trả `UserEntity?`. `AuthRepositoryImpl.login()` lưu token **và** user; `logout()` xoá cả hai.
- [x] `AppAuthState`: thêm `UserEntity? user`, `copyWith` nhận `Nullable<UserEntity?>?` (#9). `loggedIn({required UserEntity user})`; `logout()` → `user: const Nullable(null)`; `checkAuth()` dùng user trả về từ usecase.
- [x] Đường logout do refresh thất bại (interceptor → `onUnauthorized` → `AppAuthCubit.logout()`) cũng xoá user — có test.
- [x] `LoginPage`: giữ `LoginState.user` làm cầu nối; listener đọc `final UserEntity? user = state.user` rồi gọi `loggedIn(user: user)` khi success (không dùng `!`).
- [x] Home hiển thị tên bằng `BlocSelector<AppAuthCubit, AppAuthState, UserEntity?>`; thêm key `homeGreeting(String name)` vào `AppLanguage` + EN/VI.
- [x] Test: mở rộng `app_auth_cubit_test.dart`, `auth_repository_impl_test.dart` (lưu/xoá user, token có mà user không có), `auth_local_datasource_test.dart` (JSON hỏng), `login_page_test.dart` (AppAuthCubit nhận đúng user), widget test Home hiện tên.
- [x] Docs: `CLAUDE.md` mục Auth/routing (AppAuthCubit giữ user), `README.md`.

**Done khi:** đăng nhập → Home hiện tên; tắt hẳn app mở lại → vẫn hiện tên, không gọi mạng; logout (bấm nút hoặc refresh thất bại) → `user == null` + về Login; test pass.


> **Kết quả (2026-10-10):**
> - Test hồi quy `test/feature/home/session_user_test.dart` (full app, chỉ giả HTTP): login → Home chào "Hello, Kiet"; khởi động lại → vẫn chào, **0 request mạng**; logout → quên user kể cả sau khi khởi động lại; refresh 401 → `onUnauthorized` → về Login + xoá user. Hai case chào **fail trước khi sửa**.
> - Chọn cách A. `AuthLocalDataSource` thêm `cachedUser`/`saveUser`/`clearUser` (`StorageKeys.cachedUser`, JSON hỏng → `null`); `AuthRepository.hasSession()` → `currentUser()`; `CheckSessionUseCase` trả `UserEntity?`; `UserEntity extends Equatable` + `displayName`.
> - `AppAuthState.user` (+ `Nullable` copyWith), `loggedIn({required user})`, `logout()`/`checkAuth()` xoá/khôi phục user. `LoginPage` chuyển `state.user` (không dùng `!`). Home chào bằng `context.select` + collection-if (không mount widget rỗng — rule `widget-visibility-newinstance`); key `homeGreeting(name)`.
> - Test cũ chỉ seed `access_token` giờ seed `signedInPrefs` (`test/helpers/session_prefs.dart`); thêm case "token mà không có user → Login". Helper `InMemoryAuthLocalDataSource`. Mở rộng `app_auth_cubit_test` (4), `auth_repository_impl_test` (currentUser 3 case, lưu/xoá user), `auth_local_datasource_test` (+3), `login_page_test` (AppAuthCubit nhận đúng user).
> - Docs: `CLAUDE.md` (Auth/routing), `README.md`. `flutter test` 119/119 lúc xong #14.

---

### #15 — Rule chưa được enforce bằng lint ✅

**Đã đo (2026-10-10, chạy `flutter analyze` trên bản sao repo, không sửa repo):**
- **`very_good_analysis` 8.0 → 715 issue**: 334 `public_member_api_docs` (bắt doc cho mọi public member), 42 `omit_local_variable_types` — **ngược trực tiếp** rule `explicit-local-types` của dự án, 17 `avoid_catches_without_on_clauses`… → **Không chọn VGA**: phải tắt nhiều rule mới khớp với rule set riêng, và quá nặng cho dự án dùng boilerplate.
- **`flutter_lints` + rule chọn lọc → 337 issue**, phần lớn `dart fix` tự sửa được: 157 `always_use_package_imports` (làm ở #10), 65 `require_trailing_commas`, 45 `sort_constructors_first`, 27 `directives_ordering`, 21 `discarded_futures`, 7 `prefer_const_constructors`, 6 `only_throw_errors` (làm ở #13), 5 `inference_failure_on_function_invocation`, 2 `prefer_single_quotes`, 1 `strict_raw_type`, 1 `prefer_final_locals`. `strict-casts`, `unawaited_futures`, `avoid_dynamic_calls`, `cancel_subscriptions`, `close_sinks`: **0**.
- `avoid_print`, `use_build_context_synchronously` **đã có sẵn** trong `flutter_lints` 5 → không cần khai báo lại.
- `flutter_lints` 6.0 **không resolve được** với `sdk: ^3.6.2` hiện tại → nâng cùng SDK ở #16.

**Quyết định:** giữ `flutter_lints` + bộ rule dưới. **Bỏ** so với bản cũ:
- `require_trailing_commas` — từ Dart 3.7 `dart format` (tall style) tự quản lý dấu phẩy cuối và xung đột với lint này; #16 sẽ nâng SDK.
- `discarded_futures` — 21 hit, đa số là `when(...)`/`act:` trong `blocTest` và `onPressed: () => cubit.x()`; `unawaited_futures` đã đủ bắt lỗi thật.
- `sort_constructors_first` — ngược style hiện tại (field trước constructor).

**File:** `analysis_options.yaml`, `tool/check_architecture.sh` (tạo ở #10), `.github/workflows/ci.yml`, `AI_RULE.md`, `.cursor/rules/*.mdc`

- [x] Cập nhật `analysis_options.yaml`:
  ```yaml
  include: package:flutter_lints/flutter.yaml
  analyzer:
    language:
      strict-casts: true
      strict-raw-types: true
      strict-inference: true
    errors:
      unawaited_futures: error
  linter:
    rules:
      - always_use_package_imports   # bật từ #10
      - only_throw_errors            # bật từ #13
      - unawaited_futures
      - avoid_dynamic_calls
      - prefer_single_quotes
      - directives_ordering
      - prefer_const_constructors
      - prefer_final_locals
      - cancel_subscriptions
      - close_sinks
  ```
- [x] `dart fix --apply` (≈ 37 chỗ), sửa tay 6 chỗ: `strict-inference` — `dio.fetch<dynamic>` (`auth_interceptor.dart:125`), `Coordinator.pop<void>` (4 chỗ trong `feedback_showcase_page.dart`, `scaffold_showcase_page.dart`); `strict-raw-types` — `Response<dynamic>` (`logging_interceptor.dart:31`). `flutter analyze` sạch.
- [x] Thêm check rule đặc thù vào `tool/check_architecture.sh` (bỏ qua dòng comment; đã chạy thử — code hiện tại **0 vi phạm**):
  - `Navigator.` / `MaterialPageRoute` ngoài `app/coordinator/` (`navigation-coordinator`; `showDialog`/`showModalBottomSheet` được phép theo rule)
  - `SizedBox(height: …)` / `SizedBox(width: …)` không có `child` (`use-gap-not-sizedbox`)
  - `dart:developer` ngoài `core/utils/app_logger.dart` (`custom-logging`; `print` đã có `avoid_print`)
  - `== FeatureStatus.` / `!= FeatureStatus.` ngoài `feature_status.dart` (`feature-status`)
  - `json['…']` trong `lib/data/` (`map-parser-json`)
- [x] Đối chiếu toàn bộ `.cursor/rules/*.mdc` (33 file hiện tại + rule mới của #10/#13): rule nào được lint/script khoá thì ghi "enforced by `<lint>` / `check_architecture.sh`" ở cả rule file lẫn `AI_RULE.md`. Rule không tự động hoá được (vd. `buildWhen`/`listenWhen` bắt buộc — grep nhiều dòng không tin cậy) → ghi rõ "review thủ công".
- [x] Không dùng `custom_lint` — thêm dependency + analyzer plugin chậm; grep đủ cho quy mô boilerplate. Ghi lý do vào `AI_RULE.md`.

**Done khi:** `flutter analyze` sạch với bộ lint mới; `tool/check_architecture.sh` pass trong CI; mỗi rule trong `AI_RULE.md` có ghi chú enforced / review thủ công.


> **Kết quả (2026-10-10):**
> - `analysis_options.yaml` đúng bộ ở trên (ghi lý do 3 lint không bật ngay trong file). `dart fix --apply` sửa 52 chỗ; sửa tay đúng 6 chỗ đã đo (`dio.fetch<dynamic>`, `Response<dynamic>`, 4× `Coordinator.pop<void>`).
> - `tool/check_architecture.sh` thêm 5 check rule (bỏ qua dòng comment). Kiểm chứng: chèn 5 vi phạm → báo đủ 5 + exit 1; gỡ ra → pass.
> - Toàn bộ 35 rule có dòng **Enforced by** ở cả `.mdc` lẫn `AI_RULE.md` (10 rule tự động, còn lại "manual review"); thêm đoạn **Enforcement** (gồm lý do không dùng `custom_lint`) đầu `AI_RULE.md`; `CLAUDE.md` thêm lệnh `./tool/check_architecture.sh`.
> - `flutter analyze` sạch, `flutter test` 119/119.

---

## ⚪ P3 — Dọn dẹp nhỏ

### #16 — Các điểm nhỏ còn lại ✅

> Rà lại code 2026-10-10 — mỗi điểm ghi kèm hiện trạng đo được.

- [x] **NetworkClient lặp code + sửa `Options` của caller:** 5 method `get/post/put/delete/patch` (`network_client.dart:47-168`) lặp cùng một khối và **gán thẳng** `mergedOptions.extra = …` lên `Options` mà caller truyền vào (side effect bất ngờ nếu caller dùng lại `Options`). Gộp qua helper `_withAuth(Options?, bool requiresAuth)` trả `Options` **mới** (`options?.copyWith(extra: …) ?? Options(extra: …)`). Timeout `int` ms → `Duration`.
  - Getter public `Dio get dio` (`network_client.dart:45`) cho phép gọi thẳng Dio → **bỏ qua `_mapException`** (ném `DioException` thay vì `ServerException`, phá error model #13). Hiện chỉ test dùng (`auth_interceptor_test.dart:90`, `network_client_logging_test.dart:26`) → đánh dấu `@visibleForTesting`; khi cần upload thì thêm method `upload()` đi qua `_request`.
- [x] **Equatable cho State:** `equatable ^2.0.8` có trong `pubspec.yaml` nhưng **chưa dùng ở đâu**. `LoginState`, `HomeState`, `AppAuthState`, `ThemeState`, `LocaleState` extend `Equatable` → bỏ emit/rebuild thừa (`UserEntity` đã làm ở #14; `EmailInput`/`PasswordInput` của formz đã có `==`). Cập nhật rule `cubit-state-coupling` + `AI_RULE.md`. Chốt version `equatable` (2 hay 3) ở bước Dependencies trước.
- [x] **Feature mẫu chưa theo rule của chính boilerplate** (dự án sau sẽ copy theo mẫu):
  - `screen-newinstance-injection`: `LoginPage`/`HomePage` dựng `BlocProvider` trong `build`, chưa có `static Widget newInstance()` / `feature/<x>/di/` như `CLAUDE.md` mô tả. → Sửa 2 feature mẫu theo rule **hoặc** nới rule nếu thấy thừa — **cần chốt trước khi làm**.
  - `state-folder-naming`: `core/theme/theme_cubit.dart`, `core/localization/locale_cubit.dart` (+ state) chưa nằm trong thư mục `cubit/` (`AppAuthCubit` đã chuyển ở #10).
- [x] **Cấu trúc `test/` mirror `lib/`:** đã mirror một phần (`test/core/…`, `test/data/…`, `test/feature/home/`, `test/helpers/` có từ #6/#11). Còn **8 file ở gốc `test/`**: `app_config_test` → `test/core/config/`, `dev_tools_gallery_test` → `test/feature/dev_tools/`, `error_handling_test` → `test/core/error/` (viết lại ở #13), `localization_test` → `test/core/localization/`, `login_cubit_test` + `login_page_test` → `test/feature/login/`, `login_usecase_test` → `test/domain/usecase/`, `widget_test` → `test/app/`. Thêm `test/helpers/pump_app.dart` nếu các widget test còn lặp phần dựng `MaterialApp` + l10n. Sửa lệnh ví dụ `flutter test test/login_cubit_test.dart` trong `CLAUDE.md`.
- [x] **Dọn root repo:** `PLAN.md`, `MEMORY.md` → `docs/`; sửa tham chiếu trong `CLAUDE.md`, `AI_RULE.md`, `README.md`, `.cursor/rules/memory-update.mdc` và chính spec này.
- [x] **Dependencies + SDK** (đo bằng `flutter pub outdated` 2026-10-10) — ⏭️ nâng SDK + major để commit riêng (xem Kết quả):
  - **Lệch phiên bản Flutter:** local 3.29.3 · CI 3.27.4 · `sdk: ^3.6.2` → chốt một phiên bản cho cả local lẫn CI (`flutter-version` trong CI; tuỳ chọn `.fvmrc`), nâng `environment.sdk` theo.
  - Nâng được ngay (minor/patch): `dio` 5.9.2 → 5.11.1, `get_it` 9.2.1 → 9.3.0, `shared_preferences` 2.5.2 → 2.5.3.
  - Major, đọc changelog trước: `equatable` 2 → 3, `cupertino_icons` 1 → 2, `flutter_lints` 5 → 6 (cần SDK mới — xem #15). `intl` 0.20 bị `flutter_localizations` ghim → đi theo SDK.
  - ⚠️ SDK ≥ 3.7 đổi style `dart format` (tall style) → format lại gần như mọi file: làm **commit riêng chỉ format**, sau khi các mục khác đã merge.
- [x] **Dọn code chết:**
  - ~~`AuthLocalDataSource`~~ — đã dùng từ #11.
  - `HomeCubit` rỗng (`loadData()` chỉ emit success): sau #14 Home lấy user từ `AppAuthCubit`, không cần nó; `LoginCubit` đã là mẫu Cubit đầy đủ → **đề xuất xoá**.
  - `PlatformUtils` (`core/utils/platform_utils.dart`) và `CustomButton` (`core/widget/custom_button.dart`) **không được import ở đâu** → đưa `CustomButton` vào showcase Buttons của Dev Tools (widget dùng chung nên có ví dụ); giữ `PlatformUtils` (tiện ích nhỏ, dự án nào cũng cần) + thêm test.
  - Comment đầu file "Module / Responsibility" ở **44 file** → xoá khi chỉ lặp lại tên thư mục, giữ khi giải thích *vì sao*.
- [x] **CI:** thêm `dart format --set-exit-if-changed lib test` (hiện chưa có), `flutter test --coverage` + upload `coverage/lcov.info` làm artifact, step `tool/check_architecture.sh` (#10/#15); `flutter-version` theo bước Dependencies.


> **Kết quả (2026-10-10):**
> - `NetworkClient`: `_withAuth` trả `Options` mới, 5 method gọn lại; timeout `Duration connectTimeout/receiveTimeout`; `dio` → `@visibleForTesting`. Test mới `test/core/network/network_client_test.dart` (cờ `requiresAuth`, không mutate `Options` của caller).
> - Equatable: `LoginState`, `AppAuthState`, `ThemeState`, `LocaleState` (+ `UserEntity` ở #14); rule `cubit-state-coupling` + `AI_RULE.md` §5 thêm mục **State equality**. Giữ `equatable` 2.x.
> - Feature mẫu theo rule: `LoginPage.newInstance()` gọi `LoginInjection.setup(sl)` (`feature/login/di/`, `LoginUseCase` rời khỏi `initDI`); `HomePage.newInstance()`; `home.dart` → `home_page.dart`; `AuthGate` dùng `newInstance()`. `ThemeCubit`/`LocaleCubit` (+ state) → `core/theme/cubit/`, `core/localization/cubit/`.
> - `test/`: 7 file gốc chuyển đúng chỗ (`error_handling_test` đã chuyển ở #13); helper mới `pump_app.dart` (thay 5 bản copy `_boot`) và `fake_http_adapter.dart` (thay 5 adapter giả tự viết). `CLAUDE.md` sửa lệnh test 1 file.
> - `PLAN.md`, `MEMORY.md` → `docs/` (sửa tham chiếu ở `CLAUDE.md`, `AI_RULE.md`, `README.md`, `memory-update.mdc`, spec); `docs/MEMORY.md` viết lại theo trạng thái hiện tại (bản cũ dừng ở 2026-07, 39 test).
> - Dependencies: `dio` ^5.11.1, `get_it` ^9.3.0, `shared_preferences` ^2.5.3; lock resolve lại theo Flutter 3.29.3. CI chốt `flutter-version: '3.29.3'` (= local), README prerequisites cập nhật.
> - Code chết: xoá `HomeCubit`/`HomeState`; `CustomButton` vào showcase Buttons; `PlatformUtils` giữ + `test/core/utils/platform_utils_test.dart` (4). Header "Module/Responsibility": xoá 8 header chung chung, cắt phần chung ở 2 file, giữ 33 header có giải thích.
> - CI: thêm `dart format --set-exit-if-changed lib test`, `flutter test --coverage` + upload `coverage/lcov.info`; `/coverage/` vào `.gitignore`.
> - ⏭️ **Để lại có chủ đích** (đúng thứ tự spec): nâng `environment.sdk` ≥ 3.7 (đổi style `dart format` gần như mọi file → commit riêng sau khi merge phần này); `flutter_lints` 6 (cần Dart ≥ 3.8 → Flutter mới hơn 3.29.3 cho cả local + CI); major `equatable` 3, `cupertino_icons` 2 (cần đọc changelog).
> - `flutter analyze` sạch, `./tool/check_architecture.sh` pass, `flutter test` 126/126; `flutter build apk --release -t lib/main_prod.dart` OK (23.6MB).

---

## ✅ Checklist nghiệm thu cuối

- [x] `dart format --set-exit-if-changed lib test` không đổi gì (110 file, 0 changed)
- [x] `flutter analyze` sạch với bộ lint mới (#15)
- [x] `tool/check_architecture.sh` pass (layer #10 + rule #15) và có step trong CI — ⚠️ workflow CI chưa chạy thật (cần push)
- [x] `flutter test` pass (126), gồm test hồi quy cho #1, #2, #3, #9, #13 (lỗi hiện đúng tiếng Việt; 401 → "sai thông tin đăng nhập"), #14 (khôi phục user khi mở lại app)
- [ ] Chạy app thật (dev): login sai mật khẩu → thông báo đúng ngôn ngữ → login đúng → Home hiện tên → tắt hẳn app mở lại → vẫn hiện tên → Logout về Login — **chưa chạy trên thiết bị**; toàn bộ luồng này đã được phủ bằng widget test full-app (`login_error_message_test`, `session_user_test`)
- [ ] `flutter build apk --release -t lib/main_prod.dart` thành công **với signing release** — build OK (2026-10-10, 23.6MB, R8 bật) nhưng máy local không có `key.properties` nên ký bằng debug key (fallback của #7); signing release đã được kiểm ở #7
- [x] Local và CI dùng cùng một phiên bản Flutter (3.29.3) (#16)
- [x] `CLAUDE.md`, `AI_RULE.md`, `.cursor/rules/`, `README.md`, `CHANGELOG.md`, `docs/MEMORY.md` đã cập nhật đồng bộ
- [x] Bảng tiến độ ở đầu file này được cập nhật ✅
