# agents/institution.md

Institutions represent partner companies plus their contact and quota metadata. The module spans three tables: `app.institutions`, `app.institution_contacts`, and `app.institution_quotas`. Controller: `App\Http\Controllers\InstitutionController`.

---

## Access Rights
- **Developers / Admins / Supervisors**: full CRUD inside a realm.
- **Students**: may list/read institutions that have hosted their applications or internships; all other operations are blocked (HTTP 401/403).
- **Unauthenticated**: blocked by middleware.

---

## List — `/{school_code}/institutions`
- Search box (`q`) scans Name, City, Province, Industry, Contact fields.
- Off-canvas filter includes: Name, Address, City, Province, Website, Industry, Contact (name/email/phone/position), Has Notes, Has Photo, Contact Primary (`true/false`), Period Year, Period Term, Quota, Quota Used.
- Sort query (`sort=column:direction`) covers displayed columns plus `created_at` and `updated_at`.
- Table columns mirror the view fields: Name, City, Province, Industry, Contact Name, Contact Email, Contact Phone, Contact Position, Period Year, Period Term, Quota, Used, Actions.
- Pagination: 10 rows per page, total count, `Page X of N` summary.
- **Create Institution** button hidden from students.

---

## Create — `/{school_code}/institutions/create`
- Inputs:
  - Name (text, required)
  - Photo URL (optional)
  - Address (required)
  - City / Province (Tom Select backed by `resources/data/cities.json` & `provinces.json`; custom values allowed)
  - Website (optional URL)
  - Industry For (Tom Select listing active `school_majors`)
  - Notes (optional)
  - Primary Contact block: Name (required), Email (optional), Phone (optional), Position (optional), `Is Primary?` checkbox.
  - Quota section: select existing Period (`{year}: {term}` drop-down) or create a new period inline (Year + Term fields appear after clicking **Create new period**), Quota (integer ≥ 0).
- Cancel returns to list; Save redirects with success flash.

---

## Read — `/{school_code}/institutions/{id}/read`
- Shows all columns provided by `institution_details_view`, including photo, contact, and the latest quota snapshot.
- Students can open a record only if they have an application/internship at that institution; otherwise a 401 is thrown.

---

## Update — `/{school_code}/institutions/{id}/update`
- Name is immutable (disabled input); other fields follow the Create form with existing values prefilled.
- Period selector again supports “create new” mode; quota updates apply to the selected period (creating the `(institution, period)` row if missing).
- Primary contact section updates or creates the top-priority contact (`is_primary` highest wins).
- Save returns to index with confirmation.

---

## Delete
- Delete button on list/detail removes the institution and cascades to contacts/quotas through FK constraints. Guarded by 403 for students.

---

## Validation Summary
- Name: required, unique per school (`uq_institutions_school_name`), max 150.
- City/Province: required strings (controller enforces presence even though selects allow custom strings).
- Industry: required, must reference an active `school_majors` row (`industry_for`).
- Contact Name is required; email/phone optional (email limited to 255). The first contact is stored in `app.institution_contacts` with cascade delete.
- Period selection: either a valid existing `period_id` for the school or `create_new` with Year (2000–2100) and Term (1–4). Quota must be ≥ 0.
- Phone, website, notes, and photo are optional text fields.

---

## Data Source Notes
- Tables: `app.institutions`, `app.institution_contacts`, `app.institution_quotas`, `app.periods`.
- View: `institution_details_view` joins the latest quota (`DISTINCT ON` by institution) and primary contact for read/list operations.
- Triggers: `app.validate_quota_not_over()` prevents quota underflow; `app.set_updated_at()` maintains timestamps.
- City/Province options are static JSON lists; keep them updated when geography requirements change.
