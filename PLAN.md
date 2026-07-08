# 📋 PLAN HOÀN THIỆN — Flutter Production Starter

> **Mục tiêu:** Starter demo cho khách hàng, thể hiện đẳng cấp **Senior Flutter Developer**.
> Giữ nguyên phần network/architecture (đã xuất sắc), bổ sung "mặt tiền" + chuẩn hóa.
>
> **Quyết định đã chốt:**
> - ~~Routing: **go_router**~~ → **đã gỡ (2026-07-08)**: dùng `Navigator` built-in của Flutter (imperative qua `Coordinator`) + `AuthGate` widget cho luồng auth top-level. Lý do: go_router không hợp mobile app, hot reload không được.
> - Error handling: **giữ try/catch**, nhưng map `Exception → Failure` trước khi tới UI (không thêm fpdart)

---

## 🧭 Cách dùng file này

- Mỗi bước là 1 checkbox `- [ ]`. Hoàn thành thì đổi thành `- [x]`.
- Cập nhật **Bảng tiến độ tổng quan** bên dưới mỗi khi xong 1 giai đoạn.
- Mục **👉 BƯỚC TIẾP THEO** luôn trỏ tới việc cần làm kế tiếp — cập nhật lại sau mỗi lần làm.

---

## 📊 Bảng tiến độ tổng quan

| Giai đoạn | Nội dung | Trạng thái | Tiến độ |
|-----------|----------|------------|---------|
| **GĐ 1** | Dọn dẹp & Mặt tiền | ✅ Hoàn thành | 4/4 |
| **GĐ 2** | Nâng cấp đẳng cấp senior | ✅ Hoàn thành | 5/5 |
| **GĐ 3** | Production polish | ✅ Hoàn thành | 4/4 |

**Chú thích trạng thái:** ⬜ Chưa bắt đầu · 🟡 Đang làm · ✅ Hoàn thành

> ### 👉 BƯỚC TIẾP THEO
> **🎉 Toàn bộ 3 giai đoạn đã hoàn thành — tất cả checkbox đã tick (0 mục `- [ ]` còn lại).** Việc còn lại nằm ngoài phạm vi plan (tùy chọn nâng cao): thay URL placeholder staging/prod bằng backend thật, thêm coverage/golden test, hoặc cấu hình flavor native (Android `productFlavors` / iOS schemes) nếu cần build store. Trạng thái xác nhận lại 2026-07-03: **39 test pass · analyze sạch**.

---

## ✅ GIAI ĐOẠN 1 — Dọn dẹp & Mặt tiền
> Impact/effort tốt nhất — sửa ngay những thứ khách hàng thấy đầu tiên.

### 1.1. Xóa file rác ✅
- [x] Xóa `test_dio.dart` (file nháp ở root, chứa `print`, không thuộc app)
- [x] Sửa `test/widget_test.dart` → smoke test "boots into LoginPage when unauthenticated" (đã pass `flutter test`)
- [x] `.gitignore`: thêm `.DS_Store` (`build/`, `.dart_tool/` đã có sẵn; xác nhận không file rác nào đang bị git track)

### 1.2. Đưa `flutter analyze` về 0 issue ✅
- [x] Sửa 17 lỗi `dangling_library_doc_comments`: đổi block header `///` → `//` ở đầu các file core/data/domain/feature
- [x] Sửa `unintended_html_in_doc_comment` ở `lib/core/error/failures.dart:4` (tự khắc phục khi header thành `//`)
- [x] Xác nhận 5 lỗi `avoid_print` biến mất sau khi xóa `test_dio.dart`
- [x] Chạy `flutter analyze` → **No issues found!** + `flutter test` vẫn pass

### 1.3. README.md chuyên nghiệp (file quan trọng nhất với KH) ✅
- [x] Giới thiệu + badges (Flutter, Dart, Architecture, License)
- [x] Section ✨ Features — chỉ liệt kê thứ ĐÃ có (Clean Arch, Dio + refresh concurrency-safe, BLoC/Cubit, get_it, SharedPrefs); go_router/Material3/formz/i18n chuyển sang 🗺️ Roadmap (chưa build, không quảng cáo vaporware)
- [x] Section 🏗️ Architecture — sơ đồ ASCII các layer + login flow
- [x] Section 🔐 Token Refresh Flow — diagram `Completer` queue (điểm bán hàng số 1)
- [x] Section 📁 Project Structure — tree thư mục có chú thích
- [x] Section 🚀 Getting Started (clone, pub get, cấu hình baseUrl, run, analyze/test)
- [x] Section 🧩 Coding Conventions — link tới `AI_RULE.md`
- [x] Thêm 🗺️ Roadmap cho các hạng mục GĐ2/GĐ3 chưa làm

### 1.4. Dọn metadata ✅
- [x] `pubspec.yaml`: đổi `description` thành mô tả thật
- [x] `constants.dart`: gỡ mâu thuẫn baseUrl → `AppConstants.apiBaseUrl = http://localhost:8080` là nguồn duy nhất; `di.dart` dùng `AppConstants.apiBaseUrl` (bỏ hardcode)

---

## ✅ GIAI ĐOẠN 2 — Nâng cấp đẳng cấp senior

### 2.1. Theme (Material 3 + Dark mode) ✅
- [x] Viết lại `app_theme.dart`: bỏ `primarySwatch`, dùng `ColorScheme.fromSeed`, bật `useMaterial3: true` (light + dark dùng chung component themes: AppBar, FilledButton, Input, Card, SnackBar)
- [x] Thêm `lightTheme` + `darkTheme`, `core/theme/app_colors.dart` (seed color + `AppSpacing`/`AppRadius` design tokens)
- [x] Tạo `ThemeCubit` + `ThemeState` (`core/theme/`, dùng `part`/`part of`) quản lý `ThemeMode`, lưu index vào `SharedPrefsManager` qua `StorageKeys.themeMode`; đăng ký lazy singleton trong `di.dart`
- [x] `main.dart`: `MultiBlocProvider` cấp `ThemeCubit`, `BlocBuilder` bọc `MaterialApp` với `darkTheme` + `themeMode`; widget tái sử dụng `ThemeToggleButton` (system → light → dark) đặt ở AppBar **cả Login lẫn Home**

### 2.2. Routing ✅ (~~go_router~~ → gỡ 2026-07-08, dùng Navigator + AuthGate)
> **Cập nhật 2026-07-08:** go_router đã bị gỡ (không hợp mobile app, hot reload không được). `app_router.dart` giờ chỉ chứa `AuthGate` widget — `BlocBuilder<AppAuthCubit>` swap `LoginPage`/`HomePage` theo status. `main.dart` dùng `MaterialApp(home: AuthGate())`. Dev-tools navigation vẫn imperative trong `Coordinator`. Bỏ dependency `go_router` khỏi `pubspec.yaml`. Các mục ✅ bên dưới là lịch sử (đã thực hiện trước khi gỡ).

- [x] Thêm `go_router: ^14.6.2` (resolved 14.8.1) vào `pubspec.yaml`
- [x] Tạo `lib/core/router/app_router.dart`: `AppRoutes` (`/`, `/login`) + `AppRouter(authCubit)` expose `GoRouter`
- [x] `redirect` auth guard (chưa auth → `/login`; đã auth ở `/login` → `/`) + `GoRouterRefreshStream` bridge `AppAuthCubit.stream` → `Listenable`
- [x] `main.dart`: `MyApp` thành `StatefulWidget`, tạo `authCubit`+`router` một lần, `MaterialApp.router(routerConfig:)`; bỏ `home:` BlocBuilder swap thủ công
- [x] `login_page.dart` chỉ gọi `loggedIn()` (lật status) → router tự redirect; logout tương tự
- [x] **Quyết định:** chỉ go_router cho màn chính; **dev tools giữ imperative push trong Coordinator** (theo yêu cầu) → Coordinator KHÔNG đổi, rule `navigation-coordinator.mdc` vẫn đúng
- [x] Test: thêm case "access token → HomePage" vào `widget_test.dart`; toàn bộ 4 test pass

### 2.3. Chuẩn hóa Error Handling (giữ try/catch, map → Failure) ✅
> Mục tiêu: **UI không bao giờ thấy `e.toString()` thô**.
- [x] `auth_repository_impl.dart`: `on ServerException` → `e.toFailure()` (ServerFailure); lỗi unknown → `UnknownFailure`
- [x] `LoginCubit`: `on Failure catch (e)` lấy `e.message` (bỏ `e.toString()`); fallback `UnknownFailure().message`
- [x] SnackBar (`login_page.dart`) hiển thị `state.errorMessage` = `Failure.message` thân thiện
- [x] `NetworkErrorCode` thêm `message` getter (friendly, không lộ status code/stacktrace) + `fromCode()`; extension `ServerException.toFailure()`; thêm `UnknownFailure` + `code` field cho `Failure`
- [x] Test `error_handling_test.dart` (5 case: fromCode, friendly message, toFailure, repo map ServerException→ServerFailure & other→UnknownFailure). Toàn bộ 9 test pass

### 2.4. Form validation bằng formz (đã có dependency) ✅
- [x] Tạo `form/email_input.dart` + `form/password_input.dart` (extends `FormzInput`, validator + `errorText` switch theo `enum-mapping`; email regex, password min 6)
- [x] `LoginState` thêm `EmailInput`, `PasswordInput`, `bool isValid`
- [x] `LoginCubit` thêm `emailChanged()`/`passwordChanged()` (cập nhật `isValid` bằng `Formz.validate`); `login()` dùng `state.email/password.value`, guard `!isValid`; **gỡ bypass hardcode `test@example.com`**
- [x] `login_form.dart`: **bỏ hardcode credentials**, tách `_EmailField`/`_PasswordField`/`_SubmitButton` (mỗi field `buildWhen` riêng theo `bloc-optimization`); `errorText` khi invalid & touched; nút Login disable khi `!isValid`/loading + spinner khi loading
- [x] Test `login_cubit_test.dart` (6 case validation/submit). **Analyze: No issues found!**, 15 test pass

### 2.5. Localization thật ✅
> **Quyết định:** KHÔNG dùng codegen/.arb. Thay bằng **abstract `AppLanguage` + `EnLanguage`/`ViLanguage` implement + `AppLanguage.current`** (static, không cần `BuildContext`), theo yêu cầu.
- [x] `core/localization/app_language.dart`: abstract `AppLanguage` (mọi string getter) + enum `AppLocale` (code/label/flutterLocale/fromCode) + `current`/`of`/`setCurrent`
- [x] `languages/en_language.dart` + `languages/vi_language.dart` implement `AppLanguage`
- [x] `LocaleCubit` (+`LocaleState`) persist `AppLocale` qua `SharedPrefsManager` (`StorageKeys.locale`) và đồng bộ `AppLanguage.current`; đăng ký DI; `LanguageToggleButton` (EN⇄VI) ở AppBar Login & Home
- [x] `main.dart`: `BlocBuilder<LocaleCubit>` bọc `MaterialApp.router` (rebuild khi đổi locale) + `locale`/`supportedLocales`/`localizationsDelegates` (Global delegates)
- [x] Thay string cứng (Login/Home/Email/Password/validation/loginFailed/toggleTheme) bằng `AppLanguage.current.*`; **xóa** placeholder `app_localizations.dart`
- [x] Test `localization_test.dart` (6 case). **Analyze: No issues found!**, 21 test pass

---

## ✅ GIAI ĐOẠN 3 — Production polish

### 3.1. Test suite (điểm cộng lớn cho senior) ✅
- [x] Thêm dev deps: `bloc_test: ^10.0.0`, `mocktail: ^1.0.4`
- [x] `login_cubit_test.dart`: thêm `blocTest` các case loading→success / loading→failure (kèm 6 case validation cũ). **Lưu ý:** mock throw phải dùng `thenAnswer((_) async => throw ...)` (async), KHÔNG `thenThrow` (throw đồng bộ lọt ra zone làm blocTest ghi `[]`)
- [x] `login_usecase_test.dart`: mock repository (mocktail) — verify delegate đúng args + propagate `Failure`
- [x] `token_management_test.dart`: test concurrency của `Completer` (điểm nhấn kỹ thuật) — nhiều `getToken()` xếp hàng resolve cùng token mới, network chỉ gọi 1 lần; `force:true` bypass; các nhánh lỗi (no refresh token / network fail → waiters resolve null)
- [x] `login_page_test.dart`: widget test render + nhập liệu (button gate theo validation, success → `AppAuthCubit.authenticated`, failure → SnackBar friendly). AppBar có Theme/Language toggle nên phải cấp `ThemeCubit`+`LocaleCubit` trong test
- [x] `flutter test` xanh toàn bộ (**35 test**, 21 → 35). **Analyze: No issues found!**

### 3.2. Flavors + Env config ✅
- [x] Tạo `lib/core/config/app_config.dart`: enum `Flavor { dev, staging, prod }` + `AppConfig.fromFlavor` (baseUrl/appName theo flavor, `switch` theo `enum-mapping`); `AppConfig.instance` (mặc định dev nếu chưa `init` → test không cần setup) + `AppConfig.init()`
- [x] Entry points: `main_dev.dart`, `main_staging.dart`, `main_prod.dart` — mỗi file gọi `bootstrap(Flavor.x)`. `main.dart` tách `bootstrap(Flavor)` dùng chung (pin `AppConfig` trước khi `initDI`); `main()` mặc định = dev để `flutter run` không cần target
- [x] Inject baseUrl vào `NetworkClient` qua DI từ `AppConfig.instance.baseUrl` (bỏ hardcode; `AppConstants.apiBaseUrl` → `devApiBaseUrl` chỉ còn là URL dev)
- [x] Test `app_config_test.dart` (4 case: map baseUrl, isProd, default dev, init pin). **Analyze: No issues found!**, 39 test pass
- [x] README: hướng dẫn `flutter run -t lib/main_dev.dart` (hoàn thành ở GĐ 3.4 — README §Flavors, dòng 160-168)

### 3.3. CI/CD ✅
- [x] `.github/workflows/ci.yml`: job `analyze-test-build` trên push (main) + mọi PR — `subosito/flutter-action@v2` (Flutter 3.27.4, cache) → `pub get` → `flutter analyze` → `flutter test` → `flutter build apk --debug -t lib/main_dev.dart`
- [x] Thêm badge CI (GitHub Actions) vào đầu README

### 3.4. Cập nhật tài liệu ✅
- [x] Cập nhật `MEMORY.md` + `PLAN.md` phản ánh trạng thái mới (song song mỗi giai đoạn)
- [x] Thêm `LICENSE` (MIT) + `CHANGELOG.md` (Keep a Changelog: Unreleased = tests/flavors/CI/license; 1.0.0 = core)
- [x] README: hướng dẫn chạy flavor (`flutter run -t lib/main_dev.dart` …), sửa mục config baseUrl → `app_config.dart`, tick Roadmap (Tests/Flavors/CI xong)

---

## 📝 Nhật ký tiến độ (cập nhật mỗi phiên làm việc)

| Ngày | Việc đã làm | Người làm |
|------|-------------|-----------|
| 2026-06-14 | Khởi tạo PLAN.md, khảo sát & đánh giá hiện trạng dự án | Claude + kiet.do |
| 2026-06-14 | ✅ GĐ 1.1: xóa `test_dio.dart`, viết lại `widget_test.dart` (test pass), thêm `.DS_Store` vào `.gitignore`. Analyze: 23 → 18 issue | Claude + kiet.do |
| 2026-06-14 | ✅ GĐ 1.2: đổi header `///` → `//` ở 17 file. **Analyze: No issues found!**, test vẫn pass | Claude + kiet.do |
| 2026-06-23 | ✅ GĐ 1.3: viết lại README.md chuyên nghiệp (badges, features, ASCII architecture, token refresh diagram, project tree, getting started, conventions, roadmap). Features chỉ liệt kê thứ đã build; go_router/Material3/formz/i18n đưa vào Roadmap. Đã đối chiếu PLAN vs code thực tế (DI refactor + AppAuthCubit + HomeCubit đã xong nhưng GĐ2 theme/routing/formz/l10n CHƯA) | Claude + kiet.do |
| 2026-06-23 | ✅ GĐ 1.4: pubspec description thật; gom baseUrl về 1 nguồn (`AppConstants.apiBaseUrl=localhost:8080`, di.dart tham chiếu). **Analyze: No issues found!**, test pass → **GĐ 1 HOÀN THÀNH** | Claude + kiet.do |
| 2026-06-23 | ✅ GĐ 2.1: Material 3 theme (`ColorScheme.fromSeed` + `useMaterial3`), light/dark + `app_colors.dart` (seed/spacing/radius); `ThemeCubit`+`ThemeState` lưu `ThemeMode` qua `SharedPrefsManager` (`StorageKeys.themeMode`); đăng ký DI; `main.dart` dùng `MultiBlocProvider`+`MaterialApp.darkTheme/themeMode`; nút toggle theme ở HomePage AppBar. **Analyze: No issues found!**, test pass | Claude + kiet.do |
| 2026-06-23 | ➕ (ngoài plan, theo yêu cầu) Dev Tool **Theme Gallery** (`lib/feature/dev_tools/`): home grid data-driven từ registry + 7 màn showcase (Scaffold/Colors/Typography/Buttons/Inputs/Cards/Feedback) để preview design system. `ThemeToggleButton` đặt ở cả Login & Home. **Phát hiện + sửa bug theme thật**: `Size.fromHeight(52)` ép button rộng vô hạn → vỡ trong `Row`; đổi sang `Size(64,52)`, login button full-width opt-in bằng `SizedBox`. Thêm `dev_tools_gallery_test.dart` (3 test toàn bộ pass). **Analyze: No issues found!** | Claude + kiet.do |
| 2026-06-24 | ➕ **Coordinator pattern**: gom toàn bộ navigation vào `lib/core/coordinator/coordinator.dart` (`openDevTools`/`openShowcase`/`pop`); gỡ `Navigator`/`MaterialPageRoute` khỏi mọi feature (dev_tools barrel, gallery, showcases). Nối entry dev tools từ HomePage. Thêm rule `.cursor/rules/navigation-coordinator.mdc`. Thiết kế context-based để go_router (GĐ 2.2) chỉ cần sửa Coordinator. **Analyze: No issues found!**, 3 test pass | Claude + kiet.do |
| 2026-06-24 | ✅ GĐ 2.2: go_router cho màn chính. `app_router.dart` (`AppRoutes` + `AppRouter` + `redirect` auth guard + `GoRouterRefreshStream`); `main.dart` → `MaterialApp.router`, bỏ swap thủ công. **Dev tools giữ nguyên imperative trong Coordinator** (Coordinator không đổi). Thêm test redirect "token→Home". **Analyze: No issues found!**, 4 test pass | Claude + kiet.do |
| 2026-06-24 | ✅ GĐ 2.3: map Exception→Failure. `NetworkErrorCode.message`(friendly)+`fromCode()`; `ServerException.toFailure()`; `UnknownFailure`+`code` field; repo `login` try/catch map; `LoginCubit` `on Failure`→`e.message` (bỏ `e.toString()`). Test `error_handling_test.dart` (5 case). **Analyze: No issues found!**, 9 test pass | Claude + kiet.do |
| 2026-06-24 | ✅ GĐ 2.4: formz validation. `EmailInput`/`PasswordInput` (`form/`); `LoginState`+`isValid`; `LoginCubit.emailChanged/passwordChanged` + gỡ bypass hardcode; `login_form.dart` viết lại stateless, field tách `buildWhen` riêng, `errorText`, nút disable theo `isValid`+spinner. Test `login_cubit_test.dart` (6 case). **Analyze: No issues found!**, 15 test pass | Claude + kiet.do |
| 2026-06-24 | ✅ GĐ 2.5 → **GĐ 2 HOÀN THÀNH**: localization thủ công (no codegen) theo yêu cầu — abstract `AppLanguage` + `En`/`ViLanguage` + `AppLanguage.current` static; `LocaleCubit` persist + `LanguageToggleButton` (EN⇄VI); `main.dart` thêm delegates/supportedLocales; thay string cứng; xóa placeholder. Test `localization_test.dart` (6 case). **Analyze: No issues found!**, 21 test pass | Claude + kiet.do |
| 2026-07-03 | ✅ GĐ 3.1: Test suite. Thêm dev deps `bloc_test`+`mocktail`. `login_usecase_test` (mock repo, mocktail), `token_management_test` (concurrency `Completer`: queue nhiều `getToken`, network 1 lần, `force` bypass, nhánh lỗi), `login_page_test` (widget: render/validation gate/success→auth/failure→SnackBar, cấp Theme+Locale cubit), `login_cubit_test` bổ sung `blocTest` loading→success/failure. **Bug tránh được:** mock throw phải `thenAnswer(async => throw)` chứ không `thenThrow` (đồng bộ → blocTest ghi `[]`). **Analyze: No issues found!**, 21 → **35 test pass** | Claude + kiet.do |
| 2026-07-03 | ✅ GĐ 3.2: Flavors + env. `core/config/app_config.dart` (`Flavor` enum + `AppConfig.fromFlavor`/`instance` default-dev/`init`); `bootstrap(Flavor)` dùng chung trong `main.dart` + 3 entry points `main_dev/staging/prod.dart`; DI đọc `AppConfig.instance.baseUrl` (bỏ hardcode, `AppConstants.apiBaseUrl`→`devApiBaseUrl`). Test `app_config_test.dart` (4 case). **Analyze: No issues found!**, 35 → **39 test pass**. (README flavor docs gộp vào GĐ 3.4) | Claude + kiet.do |
| 2026-07-03 | ✅ GĐ 3.3 + 3.4 → **GĐ 3 & TOÀN BỘ PLAN HOÀN THÀNH**: CI `.github/workflows/ci.yml` (analyze→test→build apk debug, Flutter 3.27.4) + badge README; `LICENSE` (MIT), `CHANGELOG.md`; README cập nhật (flavor run, config baseUrl→`app_config.dart`, Roadmap tick hết). **39 test pass · analyze sạch** | Claude + kiet.do |
| 2026-07-03 | ✅ Chốt checkbox cuối (GĐ 3.2 "README flavor docs") — nội dung đã có sẵn ở README §Flavors (dòng 160-168) từ GĐ 3.4, chỉ còn thiếu tick. Xác nhận lại toàn bộ: `flutter analyze` **No issues found!** · `flutter test` **39/39 pass**. **0 mục `- [ ]` còn lại trong plan.** | Claude + kiet.do |
| 2026-07-08 | 🔄 **Gỡ go_router** (theo yêu cầu: không hợp mobile app, hot reload không được). `app_router.dart` viết lại thành `AuthGate` widget (`BlocBuilder<AppAuthCubit>` swap `LoginPage`/`HomePage` theo status, `initial`→loading); `main.dart` `MaterialApp.router`→`MaterialApp(home: AuthGate())`, bỏ `GoRouter`/`AppRouter`/`GoRouterRefreshStream`/`AppRoutes`. Gỡ `go_router` khỏi `pubspec.yaml` (+`pub get`). Dev-tools navigation trong `Coordinator` không đổi. Cập nhật docs (README/CHANGELOG/CLAUDE/MEMORY/AI rule) + comment test. **Analyze: No issues found!**, **39/39 test pass** | Claude + kiet.do |

---

## 📌 Ghi chú đánh giá hiện trạng (baseline)

**Điểm mạnh (giữ nguyên):**
- Clean Architecture rõ ràng (`data / domain / feature / core`)
- Network layer xuất sắc: `NetworkClient` bọc Dio, `AuthInterceptor` retry native qua `dio.fetch()`, `TokenManagement` xử lý refresh-token concurrency bằng `Completer` (chống spam server)
- Pattern BLoC/Cubit + `FeatureStatus` enum thống nhất, DI bằng `get_it`
- Bộ `.cursor/rules` + `AI_RULE.md` chuyên nghiệp

**Khoảng trống cần lấp (đã đưa vào plan trên):**
- README boilerplate mặc định · file rác `test_dio.dart` · `widget_test.dart` fail
- 23 issue khi `flutter analyze`
- Theme sơ sài (deprecated `primarySwatch`, không dark mode)
- Chưa có routing · chưa map Exception→Failure · formz chưa dùng để validate
- Localization chỉ là placeholder · gần như không có test thật · chưa có flavor/CI
