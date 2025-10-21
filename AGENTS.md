# AGENTS.md

This document is the quick-reference guide for every InternLink agent. Read it before touching any feature so changes stay aligned with the product goals and realm rules.

> This is a relevance guide, not a step-by-step manual. Actual instructions come from the active prompt.

InternLink helps schools coordinate industry internships. The entire back office is driven by AI agents; keep the docs in this folder current whenever behaviour changes.

## Core Principles
- Do not invent features or flows that are not present in the prompt or supporting agent docs.
- Respect the school realm system. Non-developer roles operate inside `/{school_code}/…`. Developers can access `/developers`, `/schools`, and may jump into any realm by code.
- Use `schoolRoute()` helpers whenever you build links or redirects inside a realm-aware view.

## Feature Map

### Foundation
- **Register** (`/signup`) – multi-step onboarding for students and supervisors. Requires the target school code.
- **Login** (`/login`) – session authentication. Non-developers land directly in their school realm; developers stay global until they choose a realm.
- **Logout** (`/logout`) – POST only.
- **Security** – password rotation and global hardening guidelines (see `agents/security.md`).

### Users
- **Developers** (`/developers`) – profile self-service only.
- **Schools** (`/schools`) – developer-only CRUD for school records and realm entry.
- **Admins** (`/{school_code}/admins`) – managed by developers, admins may only maintain their own account.
- **Supervisors** (`/{school_code}/supervisors`) – realm-scoped CRUD.
- **Students** (`/{school_code}/students`) – realm-scoped CRUD.

### Utilities
- **Institutions** (`/{school_code}/institutions`) – companies, contacts, quotas.
- **Applications** (`/{school_code}/applications`) – student applications, PDF exports, status management.
- **Internships** (`/{school_code}/internships`) – accepted placements derived from applications.
- **Monitoring Logs** (`/{school_code}/monitorings`) – internship activity notes; supports bulk application across the same institution.
- **Major Staff Contacts** (`/{school_code}/major-contacts`) – maps a school major to a supervisor point of contact.
- **Meta Endpoints** (`/{school_code}/meta/*`) – JSON helpers for front-end selects (monitor types, supervisors). Keep signatures stable.

### Settings
- **Profile** (`/{school_code}/settings/profile`) – per-role profile maintenance, using the same validation rules as the main CRUD modules.
- **Security** (`/{school_code}/settings/security`) – password change form with old/new/confirm inputs.
- **Environments** (`/{school_code}/settings/environments`) – admin/developer management for school majors (used by student/supervisor forms and staff assignments).

## Reference Material
- Database structure lives in `database/migrations/0001_01_01_000001_custom_tables.php` and supporting view definitions in `0001_01_01_000002_views.php`.
- Every read-heavy page consumes a view (`*_details_view`, `v_monitoring_log_*`) for consistency and easier debugging.
- Major-dependent logic (applications, monitoring, staff contacts) relies on `app.major_staff_assignments`—keep those docs synced when the flow changes.

## UI & Front-End Expectations
- Use Tom Select on dropdowns with dynamic data (students, institutions, majors, interns, etc.). Plain selects are acceptable only when the options are short and static.
- Buttons, spacing, and typography should stay consistent across modules (reuse the existing component partials when possible).
- Flash messages follow the existing Bootstrap styling; success feedback should always be provided after create/update/delete actions.

## Security Notes
- Follow `agents/security.md` before modifying authentication, sessions, or request handling.
- All mutations require CSRF protection and explicit role checks. The route middleware stack (`auth.session`, `developer`, `*.self`, `school`) reflects those constraints—keep controller logic in sync.

Keep this file and the specific agent docs up to date whenever features evolve. That prevents conflicting behaviours between code and documentation.
