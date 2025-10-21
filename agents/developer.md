# agents/developer.md

Developers are global users (`role = 'developer'`). The controller (`App\Http\Controllers\DeveloperController`) only exposes self-service endpoints—no one can create additional developers from the UI.

---

## Access Rights
- **Developer**: may list (effectively only their row), view, edit, and delete their own account.
- **Other roles**: blocked.

---

## List — `/developers`
- Search form (name/email/phone) and filter sidebar mirror other list pages, but the query is scoped to `session('user_id')`.
- Table columns: Name, Email, Phone, Email Verified?, Actions.
- Pagination still shows (10/page) but only one record is expected.

---

## Create
- Not available. Hitting `/developers/create` returns HTTP 401.
- New developer accounts must be provisioned outside the UI.

---

## Read — `/developers/{id}/read`
- Shows Name, Email, Phone (or `—`), Email Verified At, Created At, Updated At.
- Access denied if `{id}` != current developer id.

---

## Update — `/developers/{id}/update`
- Inputs: Name, Email, Phone (text), Password (optional).
- Password left blank keeps the current hash.
- Validation enforces global email uniqueness across all users.
- Redirects to `/developers` with a flash message.

---

## Delete — `/developers/{id}` (DELETE)
- Deletes the account and invalidates the session when removing self.
- Any attempt to delete a different developer id returns HTTP 401.

---

## Data & Validation Notes
- Table: `core.users`. Developers must keep `school_id = null` (database check constraint).
- The list view queries `developer_details_view` for consistent column casing.
- Password hashing uses the `hashed` cast on `User`.
- All routes sit behind `auth.session`; there is no realm middleware because developers operate globally.
