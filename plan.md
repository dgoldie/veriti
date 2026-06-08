# Veriti — Action Plan

Elixir/Phoenix web app for validating vehicle titles.

---

## Status Legend
- [x] Complete
- [ ] Not started

---

## 1. Foundation
- [x] Scaffold Phoenix 1.8.7 app (Ecto, LiveView, Tailwind, DaisyUI)
- [x] Create PostgreSQL database
- [x] Initial git commit

## 2. Authentication
- [x] Generate auth with `mix phx.gen.auth` (LiveView-based)
- [x] `users` and `users_tokens` tables migrated
- [x] Register, log in, log out, settings, password reset flows
- [x] Nav in root layout reflects auth state
- [x] 111 tests passing

## 3. Tidewave (MCP Dev Tooling)
- [x] Add `tidewave` to `mix.exs` deps (dev only)
- [x] Mount Tidewave plug in `lib/veriti_web/endpoint.ex` (dev env guard)
- [x] Verify MCP server available for AI-assisted testing and inspection

## 4. Title Submission
- [x] `TitleSubmissions` Ecto schema and migration
  - Fields: file_path, original_filename, content_type, status, user_id, timestamps
- [x] LiveView form with image file upload (Phoenix LiveView `allow_upload`)
  - Accept JPG, PNG, PDF; enforce max file size
  - Show upload preview before submission
- [x] Store uploaded file (local for dev, object storage for prod)
- [x] Route protected behind authenticated scope

## 5. Home Page
- [x] Replace Phoenix default home page with branded Veriti landing page
- [x] Hero section with value proposition and call-to-action
- [x] "Submit a Title" CTA links to `/submissions/new` (or register if logged out)
- [x] Brief explainer of the validation process (upload → OCR → results)

## 6. Title Validation Engine
- [x] OCR extraction via `tesseract_ocr` hex package (wraps Tesseract)
  - Run OCR on uploaded image to extract raw text
  - Parse extracted text into structured fields (VIN, title number, owner, odometer, lienholder, state)
- [x] `Veriti.Validation` context with pure validation logic
- [x] VIN checksum validation (ISO 3779)
- [x] State-specific title number format rules (16 states implemented)
- [x] Lien detection logic
- [x] Validation result schema (pass / fail / warning + reason codes)
- [x] Associate results with submission (async via Task.Supervisor)

## 7. Validation Results UI
- [x] Results page showing pass/fail per field with reasons
- [x] Submission history list (index) per user — live spinner + PubSub update when validation completes
- [x] Detail view for a past submission (`/submissions/:id`)

## 8. Admin / Reporting
- [ ] Admin role on `users` (boolean flag or separate table)
- [ ] Admin-only route scope
- [ ] Submissions dashboard (all users, filterable by status/date)
- [ ] CSV export of submissions

## 9. Polish & Hardening
- [ ] Branded layout (replace Phoenix defaults)
- [ ] Error pages (404, 500) styled
- [ ] Rate limiting on submission endpoint
- [ ] Pagination on history list
- [ ] End-to-end test coverage for happy path

---

## Next Up
**Admin / Reporting** — Admin role, dashboard, CSV export (section 8)
