# agents/internship.md

Internships are derived from accepted applications. The controller (`App\Http\Controllers\InternshipController`) validates that every internship maps back to an application, student, institution, and period in the same school.

---

## Access Rights
- **Developers / Admins / Supervisors**: full CRUD.
- **Students**: list and read only; records are auto-filtered to their own internships. Create/Update/Delete return HTTP 401.

---

## List — `/{school_code}/internships`
- Filters: Student (Tom Select), Institution (Tom Select), Period (Tom Select `{year} - {term}`), Start Date (range), End Date (range), Status (enum). Chips display active filters.
- Search (`q`) scans student, institution, period, dates, and status text.
- Table columns: Student, Institution, Period Year, Period Term, Start Date, End Date, Status, Actions.
- Pagination: 10 rows/page plus total count and `Page X of N` indicator.
- **Create Internship** button hidden from students.

---

## Create — `/{school_code}/internships/create`
- Available to non-student roles only.
- Application selector (Tom Select) lists accepted applications without an existing internship (`status = accepted`).
- `+` button adds additional applications; all selected entries must belong to the same institution (enforced by the controller and JS).
- Checkbox **Apply this to all company IDs that match the selected Application** auto-selects every remaining accepted application for that institution.
- Inputs: Application(s), Start Date (required), End Date (required, ≥ start), Status (`planned|ongoing|completed|terminated`).
- Save creates one internship per selected application; duplicates and conflicting students are rejected before insert.

---

## Read — `/{school_code}/internships/{id}/read`
- Pulls from `internship_details_view` joined with `application_details_view` to show student profile, institution snapshot, latest application data, and internship dates/status.
- Students can open only their own record; others see any internship inside the realm.

---

## Update — `/{school_code}/internships/{id}/update`
- Base application is locked; additional applications list other internships from the same institution.
- Checkbox behaviour mirrors Create (`Apply this to all…` updates every internship tied to the institution if possible).
- Start/End Date and Status can be edited for all targeted internships.
- Validation blocks updating to applications whose students already have internships elsewhere or whose underlying application status is not `accepted`.

---

## Delete
- Non-student roles can delete from the list/detail page. Deletion removes the internship row and cascades to `internship_supervisors`.

---

## Validation Summary
- `application_ids[]`: required, each id must exist in `applications` with `school_id = realm`. All selected applications must have `status = accepted` and share the same institution.
- `start_date` and `end_date`: required ISO dates; `end_date >= start_date` (`chk_dates_valid`).
- Status enum: `planned`, `ongoing`, `completed`, `terminated`.
- Each application can own only one internship (`uq_internships_application`) and each `(student_id, period_id)` combo must stay unique (`uq_internships_student_period`).
- Controller prevents adding duplicate students in the same request and rejects students who already have internships (besides the rows being updated).

---

## Data Source Notes
- Table: `app.internships` with FK to `app.applications` (composite with period), students, institutions, periods, schools.
- Pivot: `app.internship_supervisors` (not exposed in the current UI but persists supervisor assignments).
- View: `internship_details_view` drives list/show; it already joins student/institution data.
- Trigger `app.enforce_internship_from_accepted_application()` keeps denormalised columns in sync with the linked application and ensures only accepted applications spawn internships.
