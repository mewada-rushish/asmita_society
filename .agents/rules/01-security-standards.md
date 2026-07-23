# Security Standards — asmita_society (S-Class, TOP PRIORITY)
Activation: Always On
Scope: Workspace rule for `asmita_society`. The global `01-security-standards.md` S-class baseline applies in full here — this file adds what's specific to this repo: what's already built to reuse, and known gaps to close rather than repeat.

This app is a physical-access-control tool (guest passes, gate entry/exit, guard verification) handling real PII (visitor name, phone, vehicle, photos) under India's **DPDP Act** — treat visitor data with the same rigor as resident data, not as throwaway log entries.

## Reuse what's already built — don't roll a second version
- **Tokens/session:** `SecureStorageService` (`lib/core/security/secure_storage_service.dart`) — Keychain (`first_unlock`) on iOS, `EncryptedSharedPreferences` on Android. Any new sensitive value (tokens, PINs, cached role) goes through this service. Never add a second storage mechanism for secrets.
- **Payload encryption:** `EncryptionService` (`lib/core/security/encryption_service.dart`) — AES-256-CBC + PKCS7, random IV prefixed to ciphertext. Reuse this for any new field-level encryption need instead of adding another crypto library.
- **Network:** `AsmitaDioClient` (`lib/core/network/dio_client.dart`) auto-attaches the JWT bearer token (except the OTP public-path allowlist) and routes errors to Firebase Crashlytics. Any new repository that calls an authenticated endpoint must be constructed with this client — see gap below.
- **Root/jailbreak & emulator detection:** `safe_device` is already a dependency. For a physical-access app, actually call it (block or flag sensitive actions — pass generation, guard verification — on a compromised or emulated device) rather than leaving it declared but unused.

## Known gaps in the current `dev` branch — close these, don't repeat them
- **`android/app/google-services.json` is committed to git and not in `.gitignore`.** The global rule is explicit that this file is always git-ignored. Fix: add it to `.gitignore`, remove it from version control (`git rm --cached`), and provide it per-environment via CI secret injection or a local, ungit-tracked copy — even though Firebase client config isn't a traditional secret, keep the repo consistent with the stated policy.
- **`EnvConfig` hardcodes base URLs as Dart source constants** (`_devBaseUrlAndroid`, `_prodBaseUrl`, etc.) rather than build-time environment injection (`--dart-define`, flavors). Not a live secret, but it means environment switching requires a code change and a rebuild instead of config, and there's no "fail loudly if missing" behavior if a URL is ever wrong. Migrate toward flavor-based or `--dart-define` config per `05-workflow-quality-gates.md`'s environment-management rule.
- **Inconsistent Dio usage.** `AuthRepository` and `ApiCommunityRepository` currently accept/construct a bare `Dio()` rather than the interceptor-wired `AsmitaDioClient`. This means those repositories don't automatically get JWT attachment or Crashlytics error logging the way a request through `AsmitaDioClient` would. New and touched repositories should take `AsmitaDioClient.dio` (via `get_it`, see below), not a raw `Dio()`.
- **`get_it` is a declared dependency with no actual service-locator registration anywhere in `lib/`.** Repositories currently self-construct their own `Dio`/dependencies. Wire up `get_it` as intended (register `SecureStorageService`, `AsmitaDioClient`, and repositories as lazy singletons) so there's one source of truth for shared, security-relevant instances instead of each screen/bloc constructing its own.
- **`ApiCommunityRepository` has a hardcoded 32-byte encryption key** (`Uint8List.fromList(List.filled(32, 1))`) for the community chat's "end-to-end encryption," with a comment acknowledging it's a placeholder for a backend-issued key. This is good — it's flagged, not hidden — but per the "no placeholder logic presented as done" principle, this must be resolved (real per-group key fetched and decrypted from the backend) before this chat feature ships as encrypted; right now it provides no real confidentiality.
- **Hardcoded `society_id: 101`** in `ApiCommunityRepository` — same category as above, fine as an explicit interim value during single-society development, not fine to ship multi-tenant.

## Visitor-management-specific security requirements
Since this is the priority feature:
- Guest passes/QR codes must be time-boxed and single-use (or bounded-use) — never an indefinitely valid credential.
- Any pass/QR payload that encodes visitor or flat/unit identifying data should be signed or encrypted (reuse `EncryptionService`), not a plain, guessable ID a guard's scanner could be tricked with.
- Visitor entry/exit and guard-verification endpoints are exactly the kind of "protected route" the global security file requires server-side authorization checks for — resident-facing UI hiding a control is never sufficient.
- Rate-limit pass creation and OTP-adjacent guard actions the same way login/OTP endpoints are rate-limited, to blunt spam invite-pass generation or brute-forced guard PINs.
- Retain visitor logs only as long as the society's policy/DPDP Act requires, and support deletion/anonymization on request — don't let visitor history accumulate as permanent, unpurgeable PII.
