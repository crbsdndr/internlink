# agents/staff.md

Major Staff Contacts map a school major to a supervisor who acts as the primary contact for that track. Controller: `App\Http\Controllers\MajorStaffAssignmentController`.

---

## Access Rights
- **Developers & Admins**: full CRUD.
- **Other roles**: 403.

---

## List — `/{school_code}/major-contacts`
- Table columns: Major, Staff Name, Email, Phone, Department, Supervisor Number, Actions.
- 10 records per page with `Page X of N` and total count. No filters/search currently exposed.
- Create button in header for new assignments.

---

## Create — `/{school_code}/major-contacts/create`
- Inputs:
  - Major (Tom Select of active `school_majors` — required).
  - Supervisor (Tom Select of supervisors within the school — required).
- Save stores `major`, `major_id`, and `supervisor_id`.

---

## Update — `/{school_code}/major-contacts/{id}/update`
- Same form as Create with values prefilled.
- Major select allows switching to a different `school_major` as long as no other assignment uses it.

---

## Delete
- Delete action on the list removes the assignment. Applications will fail validation if a major loses its staff contact, so ensure replacements exist before deleting.

---

## Validation Summary
- `major_id`: required; must exist in `school_majors` for the current school and not already be assigned (`unique` per school enforced manually in controller).
- `supervisor_id`: required; must exist in `supervisors` for the school.
- Each school can assign only one supervisor per major (`uq_major_staff_school_major`).

---

## Data Source Notes
- Table: `app.major_staff_assignments` (FKs to `school_majors` and `supervisors`).
- View: `major_staff_details_view` joins supervisor contact details for listing.
- Trigger `trg_major_staff_assignments_updated_at` maintains timestamps.
- Downstream dependencies: `agents/application.md` and `agents/monitoring.md` enforce the presence of a staff contact before creating records.
