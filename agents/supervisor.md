# agents/supervisor.md

Supervisors are counsellors/teachers who oversee internships. Account data resides in `core.users`, profile data in `app.supervisors`. Controller: `App\Http\Controllers\SupervisorController`.

---

## Access Rights
- **Developers / Admins**: full CRUD.
- **Supervisors**: list/read/update/delete only their own account; cannot create new supervisors.
- **Students** and other roles: blocked.

---

## List — `/{school_code}/supervisors`
- Filters: Name, Email, Phone, Email Verified (`true/false`), Email Verified At (date), Department (text match), Has Notes (`true/false`), Has Photo (`true/false`).
- Search (`q`) spans all visible columns.
- Table columns: Name, Email, Phone, Department, Actions.
- Pagination: 10 rows per page, total count, `Page X of N`.
- **Create Supervisor** button hidden when the active role is supervisor.

---

## Create — `/{school_code}/supervisors/create`
- Inputs: Name, Email, Phone (optional), Password, Supervisor Number, Department (Tom Select of active `school_majors`), Notes (optional), Photo URL (optional).
- Save creates both the user (`role = supervisor`) and the supervisor profile row.

---

## Read — `/{school_code}/supervisors/{id}/read`
- Displays: Photo, Name, Email, Phone, Email Verified At (`True/False`), Supervisor Number, Department, Notes, Created/Updated timestamps.
- Supervisors are limited to their own record.

---

## Update — `/{school_code}/supervisors/{id}/update`
- Same form as Create; password optional when editing.
- Department selector remains linked to `school_majors`.

---

## Delete
- Delete button on list/detail. When a supervisor deletes themselves, the session is invalidated and redirected to `/login` with a status message.

---

## Validation Summary
- Email: required, unique per school.
- Supervisor Number: required, unique per school (`Rule::unique('supervisors')->where('school_id', …)`).
- Department: required `department_id` referencing `school_majors`.
- Notes & Photo: optional text fields.
- Phone: optional string.

---

## Data Source Notes
- Tables: `core.users` (`role = supervisor`), `app.supervisors` (FKs to users, schools, school majors).
- View: `supervisor_details_view` powers listing and read pages.
- Triggers: `trg_supervisors_role` enforces the role; `trg_supervisors_updated_at` maintains timestamps.
