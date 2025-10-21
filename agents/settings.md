# agents/settings.md

Realm settings provide self-service for profile updates, password changes, and (for privileged roles) major/department maintenance. Controller: `App\Http\Controllers\SettingController`.

---

## Access Rights
- `/{school_code}/settings/profile` & `/security`: all authenticated roles inside a realm.
- `/{school_code}/settings/environments`: admin and developer only. Students and supervisors receive HTTP 403.
- Major management actions (`storeMajor`, `updateMajor`, `destroyMajor`) inherit the same admin/developer guard.

---

## Navigation
- Settings link appears once a realm is active. Developers must enter a school first via `/schools` → **Realm**.
- Each settings page renders the shared sidebar (Profile, Security, Environments when authorised).

---

## Profile — `/{school_code}/settings/profile`
- Uses the same validation rules as the main CRUD modules.
- Inputs by role:
  - **Student**: Name, Email, Phone, Student Number, National Student Number, Major (Tom Select of active `school_majors`), Class, Batch, Notes, Photo URL.
  - **Supervisor**: Name, Email, Phone, Supervisor Number, Department (Tom Select of active `school_majors`), Notes, Photo URL.
  - **Admin**: Name, Email, Phone (scoped uniqueness to the current school).
  - **Developer**: Name, Email, Phone (global uniqueness).
- Submits update both the `users` table and the role profile table inside a transaction.
- Flash message: “Profile updated.”

### Profile Overview
- Right-hand column summarises key fields (name, identifiers, major/department) pulled from the `*_details_view`.

---

## Security — `/{school_code}/settings/security`
- Form inputs: Old Password, New Password (min 8), Confirm New Password.
- Old password mismatch returns validation error without changing anything.
- Success path hashes the new password, saves, and redirects back with “Password updated successfully.”
- Security overview card shows Role, Email verification state, profile updated time, and account creation time (formatted via Carbon).

---

## Environments — `/{school_code}/settings/environments`
- Admin/Developer dashboard for majors/departments (`app.school_majors`).
- Table displays Major name, Active toggle, and usage counts (`students_count`, `supervisors_count`).
- Actions:
  - Add Major: Name (required, ≤150), Active flag.
  - Edit Major: same fields; toggling Active hides/shows the major in Tom Select lists.
  - Delete Major: blocked via validation if students/supervisors still reference it.
- Routes: `POST /settings/environments/majors`, `PUT /settings/environments/majors/{id}`, `DELETE /settings/environments/majors/{id}`.
- Flash messages communicate create/update/delete success; deletion errors return `withErrors` explaining the constraint.

---

## Implementation Notes
- All forms reuse the `schoolRoute()` helper to stay realm-scoped.
- Profile and security pages rely on `resolveUser()` which reads `session('user_id')`; ensure auth middleware keeps the session hydrated.
- Major data powers multiple modules (students, supervisors, institutions, applications, monitoring). Keep this documentation plus `agents/staff.md` updated when the schema changes.
