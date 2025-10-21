# agents/admin.md

CRUD Admin manages `core.users` rows with `role = 'admin'` inside a school realm. The controller is `App\Http\Controllers\AdminUserController` and relies on the `schoolRoute()` helper for navigation.

---

## Access Rights
- **Developer**: full CRUD for admins in the active realm (or all schools when no realm is selected).
- **Admin**: may list, read, update, and delete only their own account inside their school. They cannot create new admins.
- **Other roles**: blocked with HTTP 403.

---

## List — `/{school_code}/admins`
- Shows one admin for self-service or multiple when accessed by a developer.
- Filters (rendered as chips above the table): Name, Email, Phone, Email Verified (`true/false`), Email Verified At (exact date), free-text search `q` across name/email/phone.
- Table columns: Name, Email, Phone, Email Verified?, Actions.
- Pagination: 10 rows per page with `Back` / `Next`, plus `Page X of N` and total count.
- **Create Admin** button visible only to developers.

---

## Create — `/{school_code}/admins/create`
- **Developer-only** form.
- Inputs: Name (text), Email (email), Phone (text — accepts digits/symbols), Password (password).
- Cancel returns to the admin list within the same realm.
- Save redirects back with a success flash.

---

## Read — `/{school_code}/admins/{id}/read`
- Displays: Name, Email, Phone (or `—`), Email Verified At (or `Not verified`), Created At, Updated At.
- Admins can only open their own record; developers can open any scoped admin.

---

## Update — `/{school_code}/admins/{id}/update`
- Same inputs as Create.
- Password field is optional; leaving it blank keeps the current password.
- Role and school cannot be changed; attempts are rejected at the controller.

---

## Delete
- Available from the list/detail actions.
- Prevents removing the final admin for a school (`Cannot delete the last admin account`).
- When an admin deletes their own account, the session is invalidated and the user is redirected to `/login`.

---

## Validation Summary
- Email uniqueness is enforced per school via `Rule::unique('users')->where('school_id', …)`.
- Phone is optional, stored as a trimmed string; no numeric validation beyond presence.
- Passwords hash through the `User` model `hashed` cast.
- Developer requests may target any school by entering the realm first; admins must match `session('school_id')`.

---

## Data Source Notes
- Table: `core.users` (admin rows carry a non-null `school_id`).
- Views: no additional view layer—list queries read directly from `users` with select projections.
- Middleware: `auth.session`, `school`, and `admin.self`/`developer` guard each route.
