---
trigger: always_on
---

# Workspace rules for asmita_society — what this is and how to use it

These 5 files are tailored specifically to `mewada-rushish/asmita_society` (branch `dev`), based on reading the actual repo (pubspec, `lib/` structure, existing Bloc/repository/theme code). They **override** the equivalent global rule files for this project only.

## Where to put them
```
asmita_society/.agents/rules/
  00-core-identity.md
  01-security-standards.md
  03-flutter-mobile-standards.md
  04-ui-design-system.md
  05-workflow-quality-gates.md
```
Set activation modes the same way as the global set (Always On for 00/01/05, Glob `**/*.dart` for 03, Model Decision for 04).

**`02-react-frontend-standards.md` is intentionally left out.** This repo has no web frontend (no `package.json`, no React) — nothing in it would ever fire, so it doesn't need to be copied in. If a companion web/admin project shows up as a separate repo, tailor `02` for that repo instead.

## What's different from the global rules, and why
The global rules assume a greenfield-friendly default (Riverpod, Claymorphism/Bento or iOS-native UI). This repo isn't greenfield — it already has real, working conventions, so the workspace files point at those instead:

| Area | Global default | This repo, actually |
|---|---|---|
| State management | Riverpod | **flutter_bloc** + `equatable` + `bloc_test` (already used in `auth`/`community`) |
| UI design system | Claymorphism/Bento, or iOS-native for new projects | **Material 3**, `AsmitaTheme`/`AsmitaPalette`, Montserrat + Poppins, flat bordered cards |
| Networking | dio with interceptors (general guidance) | Same, and it's already built: `AsmitaDioClient` — new code should use it, not a bare `Dio()` |
| DI | Not specified globally | `get_it` is a declared dependency but currently unused anywhere in `lib/` |

## Repo audit findings worth knowing about
While reading the code to write these rules, a few concrete things stood out — captured in the relevant workspace file (mostly `01-security-standards.md` and `03-flutter-mobile-standards.md`) so they surface naturally during future work rather than getting fixed all at once right now:

1. **`android/app/google-services.json` is committed to git**, not `.gitignore`'d — worth moving to per-environment injection.
2. **`EnvConfig` hardcodes environment/base-URL as a Dart source constant** rather than a build flavor or `--dart-define`, so switching environments needs a rebuild.
3. **`AuthRepository` and `ApiCommunityRepository` construct/accept a bare `Dio()`** instead of the interceptor-wired `AsmitaDioClient`, so those calls don't get automatic JWT attachment or Crashlytics logging the way other calls do.
4. **`get_it` is unused** — declared in `pubspec.yaml`, never registered or read anywhere in `lib/`.
5. **`visitor_management` and `services` features have only a `presentation/` layer** — no `bloc/` or `data/` yet. `visitor_history_screen.dart` currently renders from a hardcoded `_mockHistory` list inside the widget itself, which is a reasonable placeholder but should graduate to the repository+Bloc shape `auth`/`community` already use.
6. **`ApiCommunityRepository` has a hardcoded, non-functional "encryption" key** (comment-acknowledged as a placeholder) — the chat feature isn't actually end-to-end encrypted yet despite the `EncryptionService` plumbing existing.
7. Only one test exists in the whole repo (`test/widget_test.dart`, a smoke test) — `bloc_test` is a dev dependency but nothing uses it yet.

None of these are blockers to keep building — they're flagged so they get addressed as you touch that code, not lost.
