# AI Rules for Flutter Project

This file contains custom architectural and coding rules for the project. Always follow these rules when making changes or generating new code.

This document is the human-readable mirror of the machine rules in `.cursor/rules/`. Every rule here has a matching `.mdc` file; keep the two in sync — when you add or change a rule in one place, update the other.

## 1. Class and Model Initialization
_Source: `.cursor/rules/class-initialization.mdc`_

**Rule:** Use named parameters when initializing ANY class, model, entity, exception, or failure. This applies to all constructors across the project.

### ✅ Good Example
```dart
class UserModel {
  final String id;
  final String email;

  const UserModel({required this.id, required this.email});
}

class ServerException implements Exception {
  final String message;
  ServerException({this.message = 'Server Exception'});
}
```

### ❌ Bad Example
```dart
class UserModel {
  final String id;
  final String email;

  const UserModel(this.id, this.email);
}
```

## 2. Model and Entity Separation
_Source: `.cursor/rules/model-entity-separation.mdc`_

**Rule:** Models should NOT extend Entities. Models must be independent and include a `toEntity()` method to convert them to their corresponding Domain Entities.

### ✅ Good Example
```dart
class UserModel {
  final String id;
  final String email;

  const UserModel({required this.id, required this.email});

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(id: json['id'], email: json['email']);
  }

  UserEntity toEntity() => UserEntity(id: id, email: email);
}
```

### ❌ Bad Example
```dart
class UserModel extends UserEntity {
  const UserModel({required super.id, required super.email});
}
```

## 3. Standardized Feature Status
_Source: `.cursor/rules/feature-status.mdc`_

**Rule:** Use a common `FeatureStatus` enum for state management across all screens. Do NOT create abstract status classes for each feature (like `AuthLoading`, `AuthSuccess`, etc.).

### ✅ Good Example
```dart
enum FeatureStatus { init, loading, success, failure, empty }

class AuthState {
  final FeatureStatus status;
  final UserEntity? user;
  const AuthState({this.status = FeatureStatus.init, this.user});
}
```

### ❌ Bad Example
```dart
abstract class AuthState {}
class AuthLoading extends AuthState {}
class AuthSuccess extends AuthState { final UserEntity user; AuthSuccess(this.user); }
```

## 4. Main Screen Folder Placement
_Source: `.cursor/rules/main-screen-placement.mdc`_

**Rule:** The main screen file of a feature should be placed directly inside the feature's root folder. Do not create a separate `view` folder for it if it is the main screen.

### ✅ Good Example
```text
lib/feature/login/
├── login_page.dart       <-- Main screen directly in the feature root folder
├── cubit/
├── widget/
└── di/
```

### ❌ Bad Example
```text
lib/feature/login/
├── view/
│   └── login_page.dart   <-- Placed inside a view folder
```

## 5. Cubit and State Files Coupling
_Source: `.cursor/rules/cubit-state-coupling.mdc`_

**Rule:** Use `part` and `part of` to link Cubit and State files. The Cubit file declares `part 'feature_state.dart';` and holds all imports; the State file declares `part of 'feature_cubit.dart';` and has no imports of its own.

### ✅ Good Example
```dart
// feature_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entity/user_entity.dart';

part 'feature_state.dart';

class FeatureCubit extends Cubit<FeatureState> { ... }

// feature_state.dart
part of 'feature_cubit.dart';

class FeatureState { ... }
```

## 6. Custom Logging
_Source: `.cursor/rules/custom-logging.mdc`_

**Rule:** Never use `print()` or `dart:developer`'s `log()` directly in feature or domain code. Always use the custom `AppLogger` utility in `lib/core/utils/app_logger.dart`.

### ✅ Good Example
```dart
AppLogger.info('This is an info message', name: 'SomeFeature');
AppLogger.error('This is an error', error: e, name: 'SomeFeature');
```

### ❌ Bad Example
```dart
print('This is a print message');
log('This is a log message', name: 'SomeFeature');
```

## 7. Code Formatting
_Source: `.cursor/rules/code-formatting.mdc`_

**Rule:** Always format Dart code after creating or modifying it (trailing commas for multiline formatting, standard Dart style). Ensure code is formatted before considering a task complete.

## 8. BlocBuilder / BlocListener Optimization
_Source: `.cursor/rules/bloc-optimization.mdc`_

**Rule:** Always use `buildWhen` and `listenWhen` with `BlocBuilder`, `BlocListener`, or `BlocConsumer` to prevent unnecessary rebuilds or side-effects when unrelated parts of the state change.

### ✅ Good Example
```dart
BlocBuilder<AuthCubit, AuthState>(
  buildWhen: (previous, current) => previous.status != current.status,
  builder: (context, state) => Text(state.status.toString()),
)
```

### ❌ Bad Example
```dart
BlocBuilder<AuthCubit, AuthState>(
  builder: (context, state) => Text(state.status.toString()),
)
```

## 9. Enum Mapping
_Source: `.cursor/rules/enum-mapping.mdc`_

**Rule:** When mapping enums to values (strings, integers, assets), do not use constructor parameters. Use a getter with an exhaustive `switch` inside the enum.

### ✅ Good Example
```dart
enum NetworkErrorCode {
  timeout,
  badResponse;

  String get errorCode {
    switch (this) {
      case NetworkErrorCode.timeout:
        return 'timeout';
      case NetworkErrorCode.badResponse:
        return 'bad_response';
    }
  }
}
```

### ❌ Bad Example
```dart
enum NetworkErrorCode {
  timeout('timeout'),
  badResponse('bad_response');
  final String code;
  const NetworkErrorCode(this.code);
}
```

## 10. Enum Boolean Getters
_Source: `.cursor/rules/enum-boolean-getters.mdc`_

**Rule:** Do not compare an enum value against a specific case with `==` at the call site. Define `bool get isX` getters inside the enum and compare through them.

### ✅ Good Example
```dart
enum AppAuthStatus {
  initial,
  authenticated,
  unauthenticated;

  bool get isInitial => this == AppAuthStatus.initial;
  bool get isAuthenticated => this == AppAuthStatus.authenticated;
  bool get isUnauthenticated => this == AppAuthStatus.unauthenticated;
}

final loggedIn = authCubit.state.status.isAuthenticated;
```

### ❌ Bad Example
```dart
final loggedIn = authCubit.state.status == AppAuthStatus.authenticated;
```

## 11. Navigation via Coordinator
_Source: `.cursor/rules/navigation-coordinator.mdc`_

**Rule:** Screen navigation is declared in one place — `lib/core/coordinator/coordinator.dart`. `Navigator.` and `MaterialPageRoute` may appear only inside `lib/core/coordinator/`. Features, pages and widgets express intent by calling a `Coordinator` method.

### ✅ Good Example
```dart
onTap: () => Coordinator.openDevTools(context),
onPressed: () => Coordinator.pop(context),
```

### ❌ Bad Example
```dart
Navigator.of(context).push(
  MaterialPageRoute(builder: (_) => const DevToolsGalleryPage()),
);
```

Overlay helpers (`showDialog`, `showModalBottomSheet`) are allowed in widgets, but dismiss them with `Coordinator.pop(context)`.

## 12. Repository JSON Parsing
_Source: `.cursor/rules/repository-json-parsing.mdc`_

**Rule:** Repositories must not parse raw JSON with `Map` keys directly (e.g. `response['key']`). Delegate JSON parsing to Data Models via `.fromJson`, keeping mapping logic in the model layer.

## 13. Memory Update
_Source: `.cursor/rules/memory-update.mdc`_

**Rule:** After completing a task or significant feature, update the `MEMORY.md` file to reflect the current state of the project so context is maintained for future tasks.

## 14. Minimize Unnecessary Changes
_Source: `.cursor/rules/minimize-unnecessary-changes.mdc`_

**Rule:** When code is already working and stable, do not rewrite or restructure the original flow unless the new requirement truly requires it. Prefer additive, targeted changes over "clean rewrites" that risk breaking dependent features.

## 15. Avoid UI Workarounds
_Source: `.cursor/rules/avoid-ui-workarounds.mdc`_

**Rule:** Do not use hacks such as constantly changing a `ValueKey` to force a full rebuild, or abusing Bloc/Cubit state to smuggle navigation parameters. Use proper mechanisms (navigation/router, real state fields).

### ❌ Bad Example
```dart
SizedBox(key: ValueKey('${type.code}_${state.triggerId}'), height: h)
```

### ✅ Good Example
```dart
SizedBox(key: ValueKey(type.code), height: h)
```

## 16. State Management Folder Naming
_Source: `.cursor/rules/state-folder-naming.mdc`_

**Rule:** Separate UI, Bloc/Cubit and State into their own files. Name the folder holding the state-management classes `cubit/` when using a `Cubit` and `bloc/` when using a `Bloc`. Never name a folder `bloc/` while it contains a Cubit.

## 17. Type Safety and Linter Cleanliness
_Source: `.cursor/rules/type-safety.mdc`_

**Rule:** Do not access properties or call methods on a `dynamic` value without a type check. Cast explicitly, check null, use safe parse methods, and resolve linter warnings (including redundant casts).

### ❌ Bad Example
```dart
final id = raw['to']['id']; // method invocation on dynamic
```

### ✅ Good Example
```dart
final to = raw['to'] as Map?;
final id = to != null ? to['id'] : '';
```

## 18. Do Not Pass Instance Data Back Into Its Own Methods
_Source: `.cursor/rules/instance-data-no-redundant-params.mdc`_

**Rule:** When a method formats or computes something from the object's own fields, use the instance variables directly (ideally as a `get` property) rather than accepting them as parameters. If the data belongs to the instance, the caller should not pass it back.

### ✅ Good Example
```dart
String get departureDateDisplay => '${departureDate.day}/${departureDate.month}';
// caller
final display = item.departureDateDisplay;
```

## 19. Handle Widget Visibility in newInstance
_Source: `.cursor/rules/widget-visibility-newinstance.mdc`_

**Rule:** When a section can be fully hidden based on Bloc/Cubit state, decide whether to build it inside the `newInstance` factory (using `Builder` + `context.watch`) instead of always building the widget and returning `SizedBox.shrink()` from `build`.

## 20. Granular BlocBuilders
_Source: `.cursor/rules/granular-bloc-builders.mdc`_

**Rule:** When a large widget depends on several state fields, do not wrap the whole UI in a single `BlocBuilder` with a meaningless `buildWhen`. Split the UI into smaller widgets, each with its own `BlocBuilder` and a `buildWhen` comparing only the field it cares about.

## 21. Use Entities (Not Hardcoded Enums) for Dynamic UI Lists
_Source: `.cursor/rules/dynamic-list-use-entity.mdc`_

**Rule:** When rendering a list of options that depends on the API or can change over time, do not model it as a hardcoded `enum`. Create an Entity in `domain/`, store a `List<Entity>` in state, and render from that list. Reserve enums for genuinely fixed, client-known sets.

## 22. Keep Display Logic in State, Not in the Widget
_Source: `.cursor/rules/ui-logic-in-state.mdc`_

**Rule:** Functions that format data or compute a display/fallback value belong in the `State` (or Model/Entity) as getters, not as helper methods inside the Widget. The widget's only job is to build UI.

### ✅ Good Example
```dart
class MyState extends Equatable {
  final ItemEntity? selectedItem;
  String get displayName => selectedItem?.name ?? 'Not selected';
}
// widget: Text(state.displayName)
```

## 23. Declare Function Types With void
_Source: `.cursor/rules/void-function-type.mdc`_

**Rule:** When a function type returns nothing, put `void` before `Function`. A bare `Function(...)` returns `dynamic`.

### ✅ Good Example
```dart
final void Function(TransportCode?)? onNavigate;
void doSomething(void Function(String) callback) {}
```

## 24. Prefer Private Build Methods for Tiny UI Pieces
_Source: `.cursor/rules/small-ui-use-methods.mdc`_

**Rule:** When a small UI component serves only the current widget and is not reused, prefer a private `_buildX(...)` method returning a `Widget` inside the parent rather than extracting a separate `StatelessWidget`. (Non-widget helper classes still follow the one-class-per-file rule.)

## 25. Append New Locale Keys at the End
_Source: `.cursor/rules/append-locale-keys.mdc`_

**Rule:** When adding a new localization key, always append it at the end of the file (before the closing `}`) instead of inserting between existing keys. This minimizes merge conflicts.

## 26. Screen Initialization With Injection
_Source: `.cursor/rules/screen-newinstance-injection.mdc`_

**Rule:** Do not use the legacy `static Route route()` pattern. Expose screens through `static Widget newInstance()`, and call the feature's DI setup at the start of that method, before creating the `BlocProvider`.

### ✅ Good Example
```dart
static Widget newInstance() {
  MyFeatureInjection.setup(GetIt.instance);
  return BlocProvider(
    create: (_) => MyCubit(GetIt.I<MyUseCase>()),
    child: const MyScreen._(),
  );
}
```

## 27. Use Gap Instead of SizedBox for Spacing
_Source: `.cursor/rules/use-gap-not-sizedbox.mdc`_

**Rule:** Use `Gap(...)` (from the `gap` package) for spacing between widgets in a `Column`/`Row` instead of `SizedBox(height/width: ...)`. `Gap` infers the parent's axis automatically.

### ✅ Good Example
```dart
Column(children: [Text('Title'), Gap(16), Text('Description')])
```

## 28. Explicit Types for Non-Obvious Local Variables
_Source: `.cursor/rules/explicit-local-types.mdc`_

**Rule:** When a local variable's type is not obvious from the right-hand side (conditionals, `.first`, `.firstWhere`, nullable expressions), declare the type explicitly (including `?` when nullable) instead of relying on `final`/`var` inference.

### ✅ Good Example
```dart
final TicketModel? firstTicket =
    (tickets != null && tickets!.isNotEmpty) ? tickets!.first : null;
```

## 29. Pass Only What a Method Needs
_Source: `.cursor/rules/pass-only-needed-data.mdc`_

**Rule:** A helper method should accept exactly the data it uses (e.g. `List<TicketEntity> tickets`) instead of the whole Bloc/Cubit `State`. Passing the entire state couples the method to the full state shape and hurts reuse/testability. If another field is needed, read it from `context.read<Cubit>().state` inside the method.

## 30. One Top-level Class Per File
_Source: `.cursor/rules/one-class-per-file.mdc`_

**Rule:** Do not put multiple top-level classes in one file. Non-widget helper classes (`CustomClipper`, `CustomPainter`, `Delegate`, plain helpers) must live in their own file.

**Exception:** If the helper serves only one widget and is not reused, it may stay `private` (`_`-prefixed) in the same file as that widget. Extract it to its own public file only once it is reused elsewhere.

## 31. Use MapParser Extension for Safe JSON Parsing
_Source: `.cursor/rules/map-parser-json.mdc`_

**Rule:** When parsing values out of a JSON/`Map` (typically in a Model's `fromJson`), always use the `MapParser` extension in `lib/core/utils/map_ext.dart` instead of raw bracket access with manual casts (`json['key'] as int? ?? 0`). The helpers handle type coercion, null safety and edge cases in one place. Available: `parseInt`, `parseDouble`, `parseString`, `parseBool` (+ `*OrNull` variants), `parseDate`/`parseDateISO8601`/`parseSecondToDate`, `parseMap`/`parseMapOrNull`, `parseList<T>`/`parseListOrNull<T>`/`parseListMap`/`parseListString`, and `tryParseRaw<T>`.

### ❌ Bad Example
```dart
id: json['id'] as int? ?? 0,
email: json['email']?.toString() ?? '',
```

### ✅ Good Example
```dart
id: json.parseInt('id'),
email: json.parseString('email'),
tags: json.parseListOrNull<String>('tags'),
```

This complements rule #12: repositories delegate parsing to Models via `.fromJson`, and inside those `fromJson` methods the parsing itself goes through `MapParser`.
