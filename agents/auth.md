# agents/auth.md

Auth agents cover Register, Login, and Logout. Routes are global (no school prefix) but the flows seed the realm session keys that other controllers expect.

---

## Access Rights
- **Register (`/signup`)**: Students and supervisors only. Existing accounts should use Settings → Security for password changes.
- **Login (`/login`)**: All roles. Developers land on the global dashboard, others are redirected into their school realm.
- **Logout (`/logout`)**: Any authenticated user via POST.

---

## Register — `/signup`
1. **Step 1** (user + school): Full Name, Email, Password (min 8), Phone, School Code, Role (`student` or `supervisor`).
   - School code match is case-insensitive against `app.schools.code`.
   - Email must be unique within the matched school.
2. **Step 2** (role-specific profile):
   - **Student**: Student Number, National Student Number, Major (free text), Batch (year), optional Photo URL.
   - **Supervisor**: Supervisor Number, Department (text), Photo URL (required).
3. Data is stored in `core.users` plus the role profile table (`app.students` / `app.supervisors`) inside a transaction-like sequence. Password hashes automatically via the `hashed` cast on the User model.
4. On success the session receives `user_id`, `role`, `school_id`, and `school_code`, and the user is redirected to `/` (which routes into the realm dashboard for non-developers).
5. Users can navigate back to Step 1; the form preserves entered data via session caches.

---

## Login — `/login`
- Inputs: Email, Password.
- Developer accounts skip the school lookup; other roles must have a school associated or the form returns “Account not linked to a school”.
- Successful login writes the same session keys as registration and regenerates the session id.

---

## Logout — `/logout`
- POST route with CSRF token.
- Calls `Auth::logout()`, invalidates the session, regenerates the token, and redirects to `/login` with a flash message.

---

## Session & Realm Notes
- Middleware `auth.session` protects post-login routes and expects `user_id`, `role`, and realm information in the session.
- If a non-developer reaches `/` without `school_code`, the root route resolves it from `school_id` and stores it instantly.
- Developers can enter any realm via `/schools` → **Realm** button; the code is stored in session for the duration of that visit.

---

## Validation & Security
- Phone inputs are validated as `numeric` during registration but stored as strings; reuse the same trimming when editing profiles.
- Supervisor numbers use a regex guard (`^[A-Za-z0-9_-]+$`, max 64 chars).
- Student batch must pass `date_format:Y`.
- Read `agents/security.md` before altering these flows: CSRF tokens, password hashing, and session regeneration are mandatory.
