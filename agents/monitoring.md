# agents/monitoring.md

Monitoring logs capture internship progress notes. Controller: `App\Http\Controllers\MonitoringLogController`, using the views `v_monitoring_log_summary` and `v_monitoring_log_detail`.

---

## Access Rights
- **Developers / Admins / Supervisors**: full CRUD inside a realm.
- **Students**: list and read only (records limited to their internships). Create/Update/Delete return HTTP 401.

---

## List — `/{school_code}/monitorings`
- Toolbar: search (`q`), filter off-canvas, and `Create Monitoring` button (hidden from students).
- Filters: Title contains, Student (Tom Select), Institution (Tom Select), Log Date range, Has Content (`true/false/any`), Type (enum `weekly|issue|final|other`). Applied filters render as chips.
- Table columns (from summary view): Title, Log Date, Type, Student, Institution, Excerpt of content, Actions.
- Pagination: 10 rows per page with total count and `Page X of N` indicator.

---

## Create — `/{school_code}/monitorings/create`
- Fields:
  - Internship (Tom Select). Options show `Student – Institution` for all internships in the school.
  - Additional internships (`+` button) – limited to the same institution as the base selection.
  - Checkbox **Apply this to all company IDs that match the selected Internship** to clone the log across every internship for that institution.
  - Log Date (required date), Type (enum select), Title (optional, max 150), Content (required textarea).
- Controller skips inserts for duplicates (same internship + date + type) when cloning.

---

## Read — `/{school_code}/monitorings/{id}/read`
- Shows the full log content plus student, institution, supervisor details, and related application data pulled from `v_monitoring_log_detail`.
- Students can open only their own logs.

---

## Update — `/{school_code}/monitorings/{id}/update`
- Base internship cannot change; attempting to submit a different `internship_id` raises a validation error.
- Additional internships + **Apply to all…** behave the same as Create, cloning new rows where necessary (skipping duplicates).
- Editable fields: Log Date, Type, Title, Content.

---

## Delete
- Non-student roles can delete from list/detail. Deletion removes the log row; no cascading side effects beyond that.

---

## Validation Summary
- `internship_id`: required; must exist in `internships` for the active school.
- Additional internships: optional array, ids must exist in the same school and share the institution id with the base internship.
- `log_date`: required date.
- `type`: required enum (`weekly`, `issue`, `final`, `other`).
- `title`: optional string ≤ 150 chars; trimmed to `null` when blank.
- `content`: required non-empty string.
- When cloning (`apply_to_all` or extra ids) the controller automatically removes duplicates (same internship, date, type) to keep `monitoring_logs` unique per combination.

---

## Data Source Notes
- Table: `app.monitoring_logs` (FK to internships, supervisors (nullable), schools).
- Views: `v_monitoring_log_summary` for lists (pre-joins student/institution names) and `v_monitoring_log_detail` for the read page.
- Indexes: `(internship_id, log_date)` and `(supervisor_id, log_date)` support listing/filtering.
- Trigger `trg_monitoring_logs_updated_at` keeps timestamps current.
