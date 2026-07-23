# Flutter Standards — asmita_society
Activation: Glob — `**/*.dart` (this repo only)
Scope: Replaces the global `03-flutter-mobile-standards.md` defaults with this repo's actual, already-established conventions. Where this file is silent, the global file's platform/testing/CI guidance still applies unmodified.

## Architecture — already established, keep matching it
Feature-first, exactly as `lib/features/auth/` and `lib/features/community/` already do:
```
lib/features/<feature>/
  bloc/            # <feature>_bloc.dart, <feature>_event.dart, <feature>_state.dart
  data/
    models/        # plain Dart / equatable models
    repositories/  # abstract interface + concrete implementation(s)
  presentation/
    screens/
    widgets/
```
`lib/core/` holds cross-feature infrastructure: `config/` (env), `network/` (Dio client), `security/` (storage + encryption), `widgets/` (shared `Asmita*` components), `utils/`.

**Gap to close, not repeat:** `lib/features/visitor_management/` and `lib/features/services/` currently have only a `presentation/` layer — no `bloc/` or `data/` folders. `visitor_history_screen.dart` embeds a `_mockHistory` list directly as a widget-level constant. When extending either feature, bring it up to the same shape as `auth`/`community`: define a repository interface (mirror `CommunityRepository`/`ApiCommunityRepository` in `lib/features/community/data/repositories/community_repository.dart` — it's the canonical example of interface + swappable implementation in this codebase), back it with a mock implementation using the same data currently hardcoded in the screen, wire it through a bloc, and have the screen consume bloc state instead of a literal.

## State management — Bloc, not Riverpod
This project has already standardized on `flutter_bloc` (+ `equatable` for value equality, `bloc_test` for testing) across `auth` and `community`. Continue that:
- One Bloc per feature, `Event`/`State` classes extending `Equatable`.
- Widgets read state via `BlocBuilder`/`BlocConsumer` and dispatch via `context.read<XyzBloc>().add(...)` — no direct repository calls from widgets.
- Keep Blocs free of `BuildContext`/widget concerns; they depend on repository interfaces, not concrete API classes, so a mock repository can be swapped in for tests or for a feature still running on local data.
- Gap to close: `get_it` is a declared dependency but nothing is currently registered with it (`GetIt`/`getIt`/`sl<>` don't appear anywhere in `lib/`). Repositories and the Bloc layer should be wired through it going forward — register `SecureStorageService`, `AsmitaDioClient`, and each feature's repository as lazy singletons — rather than each screen/bloc constructing its own dependencies inline (as `AuthRepository()` currently does in `main.dart`/`widget_test.dart`).

## Networking
Use `AsmitaDioClient` (`lib/core/network/dio_client.dart`) for any repository that calls an authenticated endpoint — it auto-attaches the bearer token from `SecureStorageService` and routes failures to Crashlytics. Don't construct a bare `Dio()` in a new repository (see the gap noted for `AuthRepository`/`ApiCommunityRepository` in `01-security-standards.md`) — accept the shared client instance instead.

## Design system
This project already has an established visual identity — see `04-ui-design-system.md` for the full token set. The global ruleset's generic defaults (Claymorphism/Bento for existing Flutter apps, or iOS-native/Cupertino for brand-new ones) **do not apply here**: this is neither greenfield nor using either of those languages. Build against `AsmitaTheme`/`AsmitaPalette` in `lib/core/constants/design_system.dart`.

## Data workflow for unfinished features (visitor_management, services)
For any screen in these features still running on inline mock data:
1. Define the model shape based on what the screen already displays (e.g. `visitor_history_screen.dart`'s `_mockHistory` map keys — name, company, category, entryTime, exitTime, duration, gate, date, status — map directly to a `VisitorEntry` model).
2. Move that data behind a repository interface (mock implementation first, matching the `CommunityRepository` pattern), consumed via a new Bloc.
3. Keep the screen's current visual output identical during this refactor — it's a data-layer change, not a redesign.
4. When the real visitor-management API endpoints exist, add an `Api*Repository` implementation of the same interface; screens and Blocs shouldn't need to change.
5. Call out explicitly in your summary which features are still mock-backed vs. live — per the "no placeholder logic presented as done" principle.

## Roles
Three user roles exist in the UI already: **Owner**, **Tenant**, **Security guard** (`owner_dashboard_view.dart`, `tenant_dashboard_view.dart`, `asmita_security_wizard.dart`). Any new visitor-management flow should be built with role branching in mind from the start (a guard's verification/entry-logging view is a materially different flow from a resident's pass-creation view), not hardcoded to one persona and retrofitted later.

## Testing
- Only one smoke test currently exists (`test/widget_test.dart`). As Blocs are built out for `visitor_management`/`services`, add `bloc_test` coverage for them — `bloc_test` is already a dev dependency and used as the intended pattern (via `auth`/`community`'s Bloc structure), just not yet applied beyond the smoke test.
- `flutter_lints` + `flutter analyze` clean is still the bar before calling anything done, per the global workflow file.

## Everything else
Mobile security (secure storage, cert pinning consideration, permission justification), performance (`ListView.builder`, `const` constructors, image caching), and store-compliance rules from the global `03-flutter-mobile-standards.md` apply unmodified — this file only overrides architecture, state management, networking, and design-system defaults where this repo has already made a different, established choice.
