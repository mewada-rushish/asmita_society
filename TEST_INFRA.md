# E2E & Unit Test Infra: Invite Deep Link & Team Member Onboarding

## Test Philosophy
- Requirement-driven opaque-box and unit testing.
- Test both Flutter client integration and Next.js backend endpoint handling.
- Verify security, role restrictions, delegation inheritance, and error states.

## Feature Inventory Test Mapping
| # | Feature | Requirement Source | Unit Test | Widget Test | Integration / API Test |
|---|---------|-------------------|:---------:|:-----------:|:---------------------:|
| 1 | Backend Token-Info GET Endpoint | R1 (Next.js route) | ✓ | — | ✓ |
| 2 | Backend Invite Payload Merging | R1 / R2 | ✓ | — | ✓ |
| 3 | Deep Link Token Extraction | R1 (`deep_link_handler.dart`) | ✓ | — | — |
| 4 | Registration Pre-fill & Locking | R1 (`registration_screen.dart`) | — | ✓ | — |
| 5 | Invite Sheet Permission & Delegation | R2 (Director, HOD, TL, Delegatee) | — | ✓ | — |
| 6 | Multi-Channel Sharing (WhatsApp, Share) | R2 (DLT SMS, `url_launcher`, `share_plus`) | — | ✓ | — |
| 7 | Dashboard Entry Points | R2 (`director_dashboard_view.dart`, etc.) | — | ✓ | — |

## Test Architecture
- **Backend Test**:
  - Test script `D:\NextJS\my_asmita_n\test\verify_token_info.js`
  - Validates: 400 for empty token, 404 for non-existent token, 410 for expired/revoked/exceeded token, and 200 OK with correct schema for valid token.
- **Flutter Tests**:
  - `test/core/services/deep_link_handler_test.dart`: Validates URI parsing and token argument passing.
  - `test/features/auth/presentation/registration_screen_invite_test.dart`: Validates pre-filling, locking of society/department/role, and phone population.
  - `test/features/visitor_management/presentation/invite_team_member_sheet_test.dart`: Validates role permission gating, department locking, DLT template display, and share triggers.
- **Analysis**:
  - `flutter analyze` zero error gate.

