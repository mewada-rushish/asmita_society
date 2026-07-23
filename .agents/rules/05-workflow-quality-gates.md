# Workflow, Git & Quality Gates — asmita_society
Activation: Always On
Scope: Workspace rule for `asmita_society`. This is a Flutter-only repo — the global file's React/Node.js-specific items (`eslint`, `tsc`, Node dependency notes) don't apply here; everything else in the global `05-workflow-quality-gates.md` still applies. This file adds what's specific to this repo.

## Before writing code
- This repo already has real conventions to match — feature-first folders, Bloc, `AsmitaDioClient`, `AsmitaTheme` — check `03-flutter-mobile-standards.md` and `04-ui-design-system.md` (workspace versions) before assuming a global default applies.
- Branch is `dev` — treat it as the active integration branch; still don't commit directly to it for anything beyond trivial fixes, per the global branching rule.

## Definition of Done — this repo's checklist
In addition to the global checklist (builds clean, `flutter analyze` clean, sound null safety, manually verified, no debug prints/dead code, responsive/adaptive check, accessibility spot-check):
- [ ] New/changed Bloc logic has `bloc_test` coverage (currently only a single smoke test exists in `test/widget_test.dart` — don't let that stay the only test as features grow)
- [ ] Any new authenticated network call goes through `AsmitaDioClient`, not a bare `Dio()`
- [ ] Any new sensitive value goes through `SecureStorageService`/`EncryptionService`, not a new storage/crypto path
- [ ] Any new color/text style is added to `AsmitaPalette`/`AsmitaTheme` rather than hardcoded inline
- [ ] Firebase Crashlytics still captures new error paths — don't let a new `try/catch` swallow an exception silently instead of surfacing it the way `AsmitaDioClient`'s `onError` interceptor does

## Firebase & config
- `firebase.json` targets project `society-app-ceb4d`. `android/app/google-services.json` is currently committed to the repo — per `01-security-standards.md`, this should move to `.gitignore` with per-environment injection instead of staying tracked.
- `EnvConfig` currently hard-switches `production`/`development` via a source constant (`currentEnvironment`), not a build flavor or `--dart-define`. Until that's migrated, be explicit in your summary about which environment a change was tested against, since flipping it requires a code change + rebuild, not a config flag.

## Git & commit discipline
Same conventional-commits, feature-branch, no-`node_modules`-equivalent discipline as the global file — for this repo that means never committing `.dart_tool/`, `build/`, `.env*`, keystores, or (per the finding above) live `google-services.json`.

## Dependency additions
- `get_it` is already a dependency but unused — prefer wiring it up over adding a second DI mechanism.
- Check `pubspec.yaml` before adding a package with overlapping functionality (e.g. don't add a second HTTP client, a second secure-storage package, or a second crypto library — this repo already has `dio`, `flutter_secure_storage`, and `pointycastle` covering those needs).
- Run `flutter pub outdated` after any dependency change and note in the summary if it introduces a new advisory.
