# Project: Deep Link Invite Token Handling & In-App Team Member Invite

## Architecture
Cross-stack architecture integrating the Flutter mobile client (`d:\FlutterProjects\asmita_society`) with the Next.js / Express / Prisma backend (`D:\NextJS\my_asmita_n`).

```
[Deep Link: https://admin.myasmita.com/invite/join/:token]
       │
       ▼
[Flutter: DeepLinkHandler] ─── (inviteToken, verifiedMobile: null)
       │
       ▼
[Flutter: RegistrationScreen] ─── GET /api/invites/token-info/:token ───► [Backend: inviteRoutes.js]
       │                                                                         │
       ◄─────── Returns {society_id, society_name, target_role,                 ▼
       │                department_id, department_name, phone, name}    [Prisma: invite_tokens]
       ▼
[Auto-fill & Lock Society, Department, Role, Mobile]

─────────────────────────────────────────────────────────────────────────────────────────────

[Dashboard Entry Points]
(Director Dashboard / Employee-TL Dashboard / Industrial Directory)
       │
       ▼
[Flutter: InviteTeamMemberSheet] (Material 3, max 80% screen height)
       │
       ├── Delegation & Role Check:
       │     - Director / Active Delegatee -> Unlocked Dept, Roles: HOD, TL, Employee, Guard
       │     - HOD / Active Delegatee -> Locked Dept, Roles: TL, Employee
       │     - TL / Active Delegatee -> Locked Dept, Roles: Employee
       │
       ├── POST /api/invites/generate ──────────────────────────────────► [Backend: inviteRoutes.js]
       │                                                                         │
       │                                                                         ▼
       ◄─── Returns {inviteUrl, rawToken, smsSent, ...} ◄────────────── [Prisma: invite_tokens]
       │                                                                [DLT SMS: 1677100000000395667]
       ▼
[Post-Generation Actions]
 - DLT SMS Status Display
 - Share via WhatsApp (`url_launcher`)
 - Copy Link & Native Share (`share_plus`)
```

## Feature Inventory
| # | Feature | Description | Milestone | Source |
|---|---------|-------------|-----------|--------|
| 1 | Backend Token-Info GET Endpoint | Public GET `/token-info/:token` endpoint validating expiration, revocation, max usage, returning JSON with society, department, role, recipient details | M1 | Survey 2 (DONE) |
| 2 | Backend Invite Payload Merging | Ensure `POST /generate` embeds `department_id`, `recipient_phone`, `recipient_name` into `payload_json` | M1 | Survey 2 (DONE) |
| 3 | Flutter Deep Link Separation | Clean extraction of invite token in `deep_link_handler.dart` without passing token into `verifiedMobile` | M2 | Survey 1 (DONE) |
| 4 | Flutter Token-Info Resolution & Pre-Fill | Resolve token info upon navigation to `registration_screen.dart`, pre-fill & lock Society, Department, Role, Mobile; bypass residential requirement for corporate onboarding | M2 | Survey 1 (DONE) |
| 5 | "Invite Team Member" Sheet & Delegation | Material 3 bottom sheet (max 80% height) with role-based permissions for Director, HOD, TL, and active delegatees | M3 | Survey 3 (DONE) |
| 6 | Multi-Channel Sharing & DLT SMS Status | DLT SMS status display (DLT Template 1677100000000395667), WhatsApp share (`url_launcher`), and native copy/share (`share_plus`) | M3 | Survey 3 (DONE) |
| 7 | Dashboard Entry Points | Quick action entry points in Director Dashboard, Employee/TL Dashboard, and Industrial Directory | M4 | Survey 3 (DONE) |
| 8 | Automated Tests & Verification Gates | Unit/widget tests for deep link, token-info, registration pre-fill, invite sheet, backend tests, and `flutter analyze` clean gate | M5 | Surveys 1, 2, 3 |
| 9 | Safe Git Rollout & Clean Dev Push | Add `.agents/` to `.gitignore`, untrack from git history without deleting local files, rebase against origin/dev, push clean commits | M6 | Follow-up user request |

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| 1 | M1: Backend Token-Info & Invite Enhancements | `D:\NextJS\my_asmita_n\routes\inviteRoutes.js`, `server.js` | none | DONE |
| 2 | M2: Flutter Deep Link Token Resolver & Registration Auto-fill | `deep_link_handler.dart`, `registration_screen.dart`, `env_config.dart`, `dio_client.dart`, `auth_repository.dart` | M1 | DONE |
| 3 | M3: In-App "Invite Team Member" Modal Sheet & Sharing | `invite_team_member_sheet.dart`, `team_invite_repository.dart` | M1 | DONE |
| 4 | M4: Dashboard Integration & Entry Points | `director_dashboard_view.dart`, `employee_dashboard_view.dart`, `industrial_directory_screen.dart` | M3 | DONE |
| 5 | M5: Automated Tests & Verification Gate | Automated unit and widget tests, backend endpoint tests, `flutter analyze` | M1, M2, M3, M4 | IN_PROGRESS |
| 6 | M6: Safe Git Rollout & Clean Dev Push | Git ignore `.agents/`, untrack cached metadata, rebase origin/dev, push dev | M5 | PLANNED |

## Interface Contracts
### Flutter Client ↔ Backend: Token Info Resolution
- **Endpoint**: `GET /api/invites/token-info/:token` (and `/app-api/invites/token-info/:token`)
- **Headers**: Public (no Bearer token required)
- **Response**:
  ```json
  {
    "success": true,
    "society_id": 114,
    "society_name": "AsmitA House",
    "target_role": "Corporate Employee",
    "department_id": 3,
    "department_name": "Accounts",
    "recipient_phone": "9876543210",
    "recipient_name": "John Doe"
  }
  ```
- **Error Codes**:
  - `400`: `INVALID_TOKEN`
  - `404`: `TOKEN_NOT_FOUND`
  - `410`: `TOKEN_REVOKED`, `TOKEN_EXPIRED`, `TOKEN_USAGE_EXCEEDED`

### Flutter Client ↔ Backend: Invite Generation
- **Endpoint**: `POST /api/invites/generate`
- **Headers**: `Authorization: Bearer <JWT>`, `Content-Type: application/json`
- **Request Body**:
  ```json
  {
    "token_type": "ONBOARDING",
    "society_id": 114,
    "target_role": "Corporate Employee",
    "department_id": 3,
    "department_name": "Accounts",
    "recipient_name": "John Doe",
    "recipient_phone": "9876543210",
    "max_usage": 1,
    "validity_hours": 168
  }
  ```
- **Response Body**:
  ```json
  {
    "success": true,
    "rawToken": "...",
    "inviteUrl": "https://admin.myasmita.com/invite/join/...",
    "expiresAt": "...",
    "tokenType": "ONBOARDING",
    "smsSent": true,
    "smsResult": { "status": "success" }
  }
  ```

## Code Layout
- **Flutter Client (`d:\FlutterProjects\asmita_society`)**:
  - `lib/core/services/deep_link_handler.dart`: Deep link interceptor (DONE)
  - `lib/core/config/env_config.dart`: Endpoint definitions (DONE)
  - `lib/core/network/dio_client.dart`: Public path whitelist (DONE)
  - `lib/features/auth/presentation/registration_screen.dart`: Auto-fill and locked UI (DONE)
  - `lib/features/auth/data/models/invite_token_info.dart`: Token info model (DONE)
  - `lib/features/visitor_management/data/repositories/team_invite_repository.dart`: Invite generation and info repository (DONE)
  - `lib/features/visitor_management/presentation/widgets/invite_team_member_sheet.dart`: Modal bottom sheet (DONE)
  - `lib/features/dashboard/presentation/views/director_dashboard_view.dart`: Director quick action (DONE)
  - `lib/features/dashboard/presentation/views/employee_dashboard_view.dart`: Employee / TL quick action (DONE)
  - `lib/features/dashboard/presentation/screens/industrial_directory_screen.dart`: Directory quick action (DONE)
  - `test/core/services/deep_link_handler_test.dart`: Deep link unit test (DONE)
  - `test/features/auth/presentation/registration_screen_invite_test.dart`: Registration widget test (DONE)
  - `test/features/visitor_management/presentation/invite_team_member_sheet_test.dart`: Invite sheet widget test (DONE)
  - `test/features/dashboard/presentation/invite_entry_points_test.dart`: Dashboard entry points widget test (DONE)

- **Backend (`D:\NextJS\my_asmita_n`)**:
  - `server.js`: Route alias mounting (DONE)
  - `routes/inviteRoutes.js`: `GET /token-info/:token` and enhanced `POST /generate` (DONE)
  - `test_token_info.js`: Core route verification (41 tests, PASS)
  - `test_challenger_verification.js`: Boundary verification (16 tests, PASS)
  - `test_token_info_adversarial.js`: Adversarial stress tests (102 tests, PASS)
