# agents/student.md

Students live across `core.users` (account data) and `app.students` (profile data). Controller: `App\Http\Controllers\StudentController`.

---

## Access Rights
- **Developers / Admins / Supervisors**: full CRUD for students within the active realm.
- **Students**: may list, read, update, and delete only their own record; create is blocked (401).
- **Other roles**: blocked.

---

## List — `/{school_code}/students`
- Filters & chips: Name, Email, Phone, Email Verified (`true/false`), Email Verified At (date), Student Number, National Student Number, Major, Class, Batch, Has Notes (`true/false`), Has Photo (`true/false`).
- Search (`q`) spans name/email/phone/student number/national SN/major/class/batch.
- Table columns: Name, Email, Phone, Student Number, National SN, Major, Class, Batch, Actions.
- Pagination: 10 rows per page, total count, `Page X of N` indicator.
- **Create Student** button hidden for role `student`.

---

## Create — `/{school_code}/students/create`
- Inputs: Name, Email, Phone (optional), Password, Student Number, National Student Number, Major (Tom Select from active `school_majors`), Class, Batch (numeric input but stored as string), Notes (optional), Photo URL (optional).
- Save creates a `users` row (`role = student`) and the related `students` row.

---

## Read — `/{school_code}/students/{id}/read`
- Shows: Photo, Name, Email, Phone, Email Verified At (`True/False`), Student Number, National SN, Major, Class, Batch, Notes, Created/Updated timestamps.
- Students can open only their own profile.

---

## Update — `/{school_code}/students/{id}/update`
- Same inputs as Create; password optional when editing (blank keeps existing hash).
- Major selector remains connected to `school_majors` so majors must exist before editing.

---

## Delete
- Delete button on list/detail. When a student deletes themselves the controller invalidates the session and redirects to `/login` with a status flash. Other role deletions redirect back to the list.

---

## Validation Summary
- Email: required, unique per school (`users` table). Students cannot change their school.
- Student Number & National SN: required, unique per school on both create and update (`Rule::unique(...)->where('school_id', …)`).
- Major: required `major_id` referencing `school_majors`.
- Class: required string ≤ 100 characters.
- Batch: required string (UI constrains to year but database stores `varchar(9)`).
- Notes & Photo: optional text fields.
- Phone: optional string (trimmed) shared with the `users` table.

---

## Data Source Notes
- Tables: `core.users` (`role = student`) and `app.students` (FKs to users, schools, school majors).
- View: `student_details_view` drives listings and read forms.
- Triggers: `trg_students_role` enforces the user role, `trg_students_updated_at` maintains timestamps.
- Deleting a user cascades to `app.students` (FK `ON DELETE CASCADE`).
