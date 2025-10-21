# agents/application.md

Applications connect students to institutions and periods. The controller is `App\Http\Controllers\ApplicationController`; it relies heavily on the `application_details_view` read model and the staff assignment map from `major_staff_assignments`.

---

## Access Rights
- **Developers / Admins / Supervisors**: full CRUD within the active school realm.
- **Students**: may create exactly one application (if none exists), view their own records, and edit/delete only when `student_access = true`. Routes emit HTTP 401 when the guard fails.
- **Other roles**: blocked.

---

## List — `/{school_code}/applications`
- Controls: search box (`q`), `Print All` (downloads a PDF for applications in `under_review`/`draft`), `Filter` off-canvas, `Create Application` button.
- Filter inputs: Student Name, Institution Name, Period (Tom Select fed by `periodOptions`), Status (enum), Student Access (`true/false/any`), Submitted At (date), Has Notes (`true/false/any`). Applied filters appear as removable chips.
- Table columns: `#`, Student, Institution, Year, Term, Status, Student Access, Planned Start, Planned End, Submitted At, Actions (Read/Update/Delete).
- Pagination: 10 rows/page with total count and `Page X of N` summary.

---

## Create — `/{school_code}/applications/create`
- **Students** see only their own name and cannot use bulk helpers.
- **Non-student roles** may:
  - Pick one or more students (Tom Select). Additional selects appear via the `+` button; all selections must share the same major.
  - Use `Apply to all students who do not yet have the application` to auto-include every student (without an application) in the same major.
- Institution pick plus planned start date auto-detect the internship period (Term 1 = Jan–Jun, Term 2 = Jul–Dec). If the required `(institution, period)` quota is missing, the form blocks submission and surfaces an inline modal to create it before continuing.
- Inputs: Students[], Institution, Status (enum), Student Access (`True/False/Any` radio visible to privileged roles), Planned Start Date, Planned End Date, Submitted At (date), Notes (textarea). The detected period is displayed read-only.
- Validation before save ensures: selected students exist in the school, share a major, have a staff contact, and do not already have an application for the chosen institution/period.

---

## Read — `/{school_code}/applications/{id}/read`
- Card layout showing student profile, institution snapshot, assigned staff contact, and application metadata (status, student access, planned dates, submitted at, notes).
- Links out to the related Student and Institution detail pages.
- Actions: Back, Download PDF (`/{id}/pdf/print`), Update.

---

## Update — `/{school_code}/applications/{id}/update`
- Student select is prefilled; non-student roles can include additional students from the same institution (enforced by the controller).
- Checkbox **Apply to all applications with the same institution** updates every matching application for the selected students.
- Non-students may toggle `student_access`; students cannot.
- Planned dates follow the same rules as create (end date cannot precede start date).

---

## Delete
- Button on the table row. Students may delete only when `student_access` is true.
- Soft restrictions: controller denies deletion if the student is unauthorised.

---

## Validation Summary
- `student_ids`: required array; each id must exist in `students` for the active school. Student actors are restricted to `[current_student_id]`.
- `(student_id, institution_id, period_id)` must stay unique (`uq_application_unique_per_period`). Controller pre-checks duplicates before insert/update.
- Status enum: `submitted | under_review | accepted | rejected | cancelled` (the print-all helper still checks for `draft` but normal forms do not expose it).
- `student_access`: boolean flag. Students never see the control; non-students choose `true` or `false` (default `false`).
- `submitted_at`: required ISO date; stored as timestamp.
- `planned_start_date`: required; determines the target period (Term 1 = Jan–Jun, Term 2 = Jul–Dec). `planned_end_date`: optional, but end must be ≥ start and does not alter the period binding.
- Period records are auto-created for the active school when missing; a matching institution quota must exist (use the inline modal helper from the create/update forms when needed).
- Major coverage: every selected student must have a major and there must be a matching entry in `major_staff_assignments`.
- Trigger safeguards (see migration):
  - Active statuses require matching institution quotas and enforce a max of 3 active applications per student per period.
  - Audit rows are written to `application_status_history` with the acting user id (students are prevented by the trigger).

---

## Data Source Notes
- Table: `app.applications` with FKs to students, institutions, periods, and schools.
- Views: `application_details_view` (primary list/read source) plus `school_details_view` for PDF header data.
- Auxiliary tables: `app.major_staff_assignments`, `app.institution_quotas`, `app.application_status_history`.
- PDF generation: Browsershot renders `resources/views/application/pdf.blade.php`; `printAll` concatenates groups by institution & period.
