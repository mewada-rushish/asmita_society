---
trigger: always_on
---

# Core Agent Identity & Operating Principles — asmita_society

**Activation:** Always On  
**Scope:** Workspace rule for `mewada-rushish/asmita_society` (branch: `dev`) only.

This file overrides the global identity file for this repository. The global identity file still applies to every other project.

---

## Project Context

`asmita_society` is a **Flutter-only mobile client application**.

The project's `pubspec.yaml` describes it as:

> AsmitA - Secure Smart Home IoT & Society Operations Platform

The flagship and highest-priority feature is **visitor management**, including:

- Guest passes
- Visitor invitations
- Gate-wise entry and exit logs
- Security-guard verification
- Visitor approval/rejection flows
- Entry/exit alerts
- Security-related resident and guard workflows

The application also contains or is intended to support broader society-operations functionality, including:

- Authentication / OTP
- Community chat
- Service bookings
- Amenity bookings
- Owner dashboards
- Tenant dashboards
- Security-guard dashboards
- Resident/society operations
- Parking and vehicle-related functionality
- Utility/service-related functionality
- Other society-management capabilities already scaffolded in the project

### Primary Mobile User Roles

The primary roles observed in the application are:

- **Owner**
- **Tenant**
- **Security Guard**

These roles have distinct permissions, dashboards, workflows, and UI requirements.

Do not assume that all users have the same capabilities.

Authorization and role-aware behavior must be enforced consistently across:

- UI
- State management
- API requests
- Navigation
- Feature availability
- Error handling

Hiding a UI control is not sufficient authorization.

---

# Architecture Boundary

## Flutter Repository

This repository contains the **mobile client only**.

The Flutter project is responsible for:

- Presentation
- Navigation
- Local state
- Bloc/Cubit state management
- Client-side validation
- Secure local storage
- API consumption
- Repository abstractions
- Mobile-specific business behavior
- Error/loading/empty states
- Mobile permissions and device capabilities

This repository does **not** own the backend.

Do not assume Node.js, Express, database, API route, or server-side business logic belongs inside this Flutter repository.

---

## Backend / Admin Portal

The Flutter application communicates with the separate AsmitA backend/admin portal.

### Backend Base URL

The backend is currently:

`https://admin.myasmita.com`

The Flutter application references the backend through:

`lib/core/config/env_config.dart`

The backend/admin portal is maintained separately from this Flutter repository.

### Admin Portal Local Project

The corresponding Next.js admin/API project is located at:

`D:\Projects\NextJS Projects\my_asmita\n`

### API Route Location

The backend APIs used by the Flutter application are maintained in:

`D:\Projects\NextJS Projects\my_asmita_n\appRoutes`

Treat `/appRoutes` as the authoritative API route layer for the Flutter application's backend integration unless the backend project itself establishes a newer convention.

### Architectural Relationship

The intended architecture is:

Flutter App
    |
    | HTTPS / REST API
    v
Asmita Admin Portal / Backend
D:\Projects\NextJS Projects\my_asmita_n
    |
    v
/appRoutes
    |
    v
Database / Backend Services / Integrations