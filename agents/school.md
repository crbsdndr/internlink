# agents/school.md

Schools are managed globally by developers. Records live in `app.schools` and expose the realm code used throughout the application. Controller: `App\Http\Controllers\SchoolController`.

---

## Access Rights
- **Developer**: full CRUD.
- **Other roles**: blocked by middleware.

---

## List — `/schools`
- Toolbar: search (`q`), `Create School`, and filter off-canvas.
- Filters: Name, Email, Phone, Has Website (`true/false/any`), Sort (Newest, Oldest, Name A–Z/Z–A, Recently/Least recently updated).
- Table columns: Name, Phone, Email, Website (`Visit` link or `—`), Updated At, Actions.
- Actions include **Realm** (opens `/{code}`), Read, Update, Delete.
- Pagination: 10 rows per page, total count, `Page X of N` indicator.

---

## Create — `/schools/create`
- Inputs: Name, Address, City, Postal Code, Phone, Email, Website, Principal Name, Principal NIP.
- Phone accepts digits/spaces/punctuation; validation enforces the regex `^[0-9+().\-\s]{7,30}$` and uniqueness.
- Email must be unique, lowercased before save.
- Website optional URL; blanks stored as `null`.
- Save redirects to the detail page with a success flash.

---

## Read — `/schools/{id}/read`
- Shows Name, Address, City, Postal Code, Phone, Email, Website, Principal Name/NIP, Created At, Updated At.
- Realm code is not explicitly rendered but is available via the list page (Realm button) and API responses.
- Actions: Update, Delete, Back to list.

---

## Update — `/schools/{id}/update`
- Form matches Create with values prefilled.
- Phone/email uniqueness rules ignore the current record.
- Cancel returns to the detail page; Save persists updates and redirects to Read.

---

## Delete
- Delete buttons (list + read) prompt for confirmation then remove the school. Deleting a school cascades to dependent data via foreign keys; confirm migrations before using in production.

---

## Validation Summary
- Name (required, ≤150), Address (required, ≤1000), City (optional, ≤100), Postal Code (optional, ≤20).
- Phone: required, trimmed, unique, regex validated.
- Email: required, unique, trimmed/lowercased.
- Website: optional URL (trimmed), Principal Name (optional ≤150), Principal NIP (optional ≤50).
- `code` is generated automatically (see `School` model) and should not be edited manually.

---

## Data Source Notes
- Table: `app.schools` with triggers for timestamp maintenance.
- View: `school_details_view` backs list and read endpoints.
- Realm linkage: controllers and middleware rely on `schools.code`; ensure every new record has a unique code.
