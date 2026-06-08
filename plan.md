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
- [x] Admin role on `users` (`is_admin` boolean flag; `Accounts.grant_admin/1` helper)
- [x] Admin-only route scope (`require_admin` on_mount + plug)
- [x] Submissions dashboard at `/admin` — stats cards, status/date filters, all-users table with VIN + validation status
- [x] CSV export at `/admin/submissions/export.csv` — filters respected, download attachment

## 9. Polish & Hardening
- [x] Branded layout — DaisyUI navbar with Veriti brand, My Submissions link, dropdown user menu, "· Veriti" title suffix
- [x] Error pages (404, 500) — styled full-page templates with DaisyUI, fallback for other codes
- [x] Rate limiting on submission endpoint — GenServer tracking max 10/hour per user
- [x] Pagination on history list — 20 per page, prev/next controls, live-updates after validation
- [x] End-to-end test coverage — 15 LiveView tests covering auth redirect, home CTA, list, upload+submit, show, admin guard

---

## Next Up
**All sections complete** ✓
