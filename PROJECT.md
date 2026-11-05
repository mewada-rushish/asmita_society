# Project: Asmita Industrial Property Roles, Employee Flow, Theme & Real-Time Sync

## Architecture
- **Mobile Client**: Flutter application (`asmita_society`) with BLoC state management, Hive & SecureStorage local caching, Material 3 theming (light/dark), Firebase Messaging (FCM).
- **Backend API**: Express.js + Prisma ORM (`my_asmita_n`) backed by MySQL database. Handles user authentication, employee/resident provisioning, property role hierarchies, visitor management, delegation rules, and FCM push notifications.
- **Data Flow & Coordination**:
  - Web Admin Portal / Mobile Top-Level Admins create employees -> Express `userController` & `authRoutes` provision user records, hash passwords, create `user_property_links` & `floor_receptionist_mappings` -> FCM broadcasts settings/role updates.
  - Mobile client logs in -> `authRoutes` returns `role_details` and `property_type` -> `AuthResponse` & `PropertyRoleResolver` route user directly to industrial dashboard (Director, Employee, Facility Staff/Guard, Receptionist, Admin/Manager).
  - Colleague delegation queries match company/property users with allowable power rules (`candidatePower <= currentUserPower` or peer delegation enabled).
  - Theme state persists in local storage synchronously; toggles apply optimistically without network lag; cold starts render without theme flash.
  - All hardcoded tokens and exposed secrets scrubbed and purged from git history with pre-commit prevention.

## Feature Inventory
| # | Feature | Description | Milestone | Source |
|---|---------|-------------|-----------|--------|
| F1 | Secrets Scrubbing & Git History Purging | Remove exposed invite token `mock_invite_token_fixture_777` (redacted 4f8b...) and Setu BBPS production credentials; amend commits and purge history; install leak prevention | M1 | User Follow-up / R6 |
| F2 | Backend Employee & User Provisioning | Accept & hash passwords, insert `user_property_links`, insert `floor_receptionist_mappings`, provision for all 5 industrial roles | M2 | R1 |
| F3 | Backend Auth Role Details & Property Context | Include `role_details` and `society.property_type` in login/OTP verification responses | M2 | R1 |
| F4 | Backend Admin Portal Push Dispatch | Dispatch FCM push notifications to property topics when settings, roles, or users are updated | M2 | R5 |
| F5 | Colleague Delegation List Resolution | Allow peer delegation (`power = 100`), fix `property_id` parameter handling, prevent 500 crash in candidate delegates | M3 | R3 |
| F6 | Visit Delegation Transitive Reassignment | Ensure reassigned visits resolve active delegatee instead of direct assignment | M3 | R3 |
| F7 | Mobile Industrial Role Resolution & Routing | Resolve Director, Employee, Guard, Receptionist, Admin to their designated industrial campus dashboards without residential misrouting | M4 | R1, R2 |
| F8 | Mobile App Lifecycle & Real-Time Cache Refresh | Fix `globalNavigatorKey` in `main.dart`; listen to FCM silent refresh to invalidate `PropertyConfigService` and reload state | M4 | R2, R5 |
| F9 | Synchronous Theme Cold-Start & Optimistic Switching | Persist theme in local storage synchronously; eliminate cold-start white flash; optimistic toggle in `PreferencesBloc` | M5 | R4 |
| F10 | UI Theme Consistency & Dark Mode Contrast | Eliminate hardcoded colors (`Colors.white`, `Colors.black`, `deepNavy`) in dialogs, choice chips, and bottom sheets | M5 | R2, R4 |
| F11 | Comprehensive E2E Verification & Hardening | Pass 100% of opaque-box test suite (Tiers 1-4) and adversarial coverage hardening (Tier 5) | M6 | Acceptance Criteria |

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| M1 | Secrets Scrubbing, Git History Purge & Leak Prevention | Scrub exposed tokens/keys from tests and services, purge commit `7c7ea84` on dev/main, add pre-commit scan | none | DONE |
| M2 | Backend Employee Provisioning, Auth Payloads & Push Dispatch | Fix user schema, password hashing, links, floor mappings, auth select fields, and admin push triggers | none | DONE |
| M3 | Visit Delegation Flow Colleague List Resolution | Fix peer power checks, query parameters, candidate delegates null safety, and visit reassign in backend & mobile | M2 | DONE |
| M4 | Mobile Industrial Role Navigation, Dashboards & Real-Time Refresh | Fix `AuthResponse.role`, `PropertyRoleResolver`, `main.dart` navigator key, and FCM cache invalidation | M2 | DONE |
| M5 | Mobile Theme Switching Latency, Cold-Start & Contrast | Synchronous local cache in `PreferencesBloc`, optimistic toggle, fix dialog/sheet hardcoded colors | none | DONE |
| M6 | Final Milestone: 100% E2E Test Suite & Adversarial Hardening | Pass all Tier 1-4 E2E tests published in `TEST_READY.md`, followed by Tier 5 adversarial testing | M1, M2, M3, M4, M5 | PLANNED |

## Interface Contracts
### Express Auth Login / OTP Verify ↔ Mobile `UserModel`
- **Endpoint**: `POST /app-api/auth/login`, `POST /app-api/auth/verify-otp`
- **Response Payload**:
  ```json
  {
    "token": "...",
    "user": {
      "id": 227,
      "full_name": "...",
      "email": "...",
      "phone": "...",
      "role_name": "Employee",
      "society_id": 115,
      "role_details": {
        "department_id": 1,
        "department_name": "Engineering",
        "cabin_number": "CAB-402",
        "desk_number": "DESK-12",
        "assigned_floors": ["Floor 1", "Floor 2"]
      },
      "society": {
        "id": 115,
        "name": "Industrial Campus A",
        "property_type": "industrial"
      }
    }
  }
  ```

### Backend Delegation Colleague API ↔ Mobile `DepartmentDelegationScreen`
- **Endpoint**: `GET /app-api/visitor/colleagues?property_id=115&department_id=1`
- **Parameters**: `property_id` (integer), `department_id` (integer, optional)
- **Response**:
  ```json
  {
    "success": true,
    "data": [
      {
        "id": 228,
        "full_name": "Teammate Name",
        "role_name": "Employee",
        "power": 100,
        "department_id": 1
      }
    ]
  }
  ```
- **Rule**: `currentUserPower` and `colleaguePower` comparison allows peers (`colleaguePower <= currentUserPower` allowed for employees).

### Backend Admin Portal FCM Event ↔ Mobile `FirebaseMessagingService`
- **FCM Data Payload**:
  ```json
  {
    "type": "PROPERTY_SETTINGS_UPDATED",
    "society_id": "115",
    "timestamp": "1730784000"
  }
  ```
- **Mobile Action**: `PropertyConfigService.invalidateCache(societyId)`, trigger profile refresh.

## Code Layout
### Flutter Mobile App (`asmita_society`)
- `lib/core/utils/property_role_resolver.dart`: Maps raw role strings and property types to dashboard keys.
- `lib/core/services/property_config_service.dart`: Society settings and feature flags cache.
- `lib/core/services/firebase_messaging_service.dart`: FCM foreground and background message handler.
- `lib/features/auth/data/models/auth_response.dart`: Role extraction hierarchy (`primaryRole` vs `systemRole`).
- `lib/features/dashboard/presentation/main_dashboard_screen.dart`: Campus dashboard navigation and tab indexing.
- `lib/features/visitor_management/presentation/screens/department_delegation_screen.dart`: Colleague delegation UI.
- `lib/features/menu/bloc/preferences_bloc.dart`: Theme and user preferences management.
- `lib/features/bbps/data/services/bbps_payment_session_service.dart`: Delegated token BBPS payment integration.
- `test/core/services/deep_link_handler_test.dart`: Deep link handler tests with mock fixtures.

### Backend API (`my_asmita_n`)
- `validators/userSchema.js`: Request validation for user creation/updates.
- `controllers/userController.js`: User provisioning, password hashing, and property links.
- `routes/authRoutes.js`: Login and OTP authentication controllers with role selection.
- `controllers/visitor/employeeDelegationController.js`: Colleague listing and delegation creation.
- `services/visitor/delegationHierarchyService.js`: Delegation hierarchy and power validation.
- `controllers/masterEntitiesController.js`: Department candidate delegates endpoint.
- `controllers/settingsController.js`: Admin settings update and FCM broadcast.
