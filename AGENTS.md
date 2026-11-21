# Jimma Solid Waste Management System

> Spec for the Cursor agent. Read fully, then build phase by phase (Section 11).
> Source: Redesigned SRS for Jimma City Administration (Nov 2026).

## 1. Summary

Connects **Residents**, **Workers/Drivers** and **Administrators**. Admins publish **area-based (Kebele) collection schedules**; the system automatically reminds residents of that area (day-before, same-day, on-the-way, delay, cancellation, completed). Residents also report uncollected garbage, track it, and give feedback. Workers update collection status in the field.

## 2. Stack

| Part | Tech |
|---|---|
| Mobile app (residents + workers) | **Flutter**, Dart 3, Riverpod, go_router, freezed |
| Admin dashboard | **HTML + CSS + vanilla JS** (no framework), `supabase-js` via CDN, Leaflet for maps |
| Backend / DB / Auth / Storage | **Supabase** (Postgres, Auth, RLS, Storage, Realtime, Edge Functions, `pg_cron`) |
| Maps / navigation | **OpenStreetMap**: `flutter_map` + OSM tiles (app), Leaflet (dashboard), **OSRM** (or OpenRouteService free tier) for route lines/directions, Nominatim for address search |
| Push | FCM (`firebase_messaging`) triggered from an Edge Function; in-app inbox is the primary channel |
| Localization | ARB files: `en`, `am`, `om` |
| Tests | `flutter_test`, `mocktail`, Supabase local (CLI) + SQL/RLS tests, Deno tests for functions |

**OSM rules:** the public tile server and public OSRM/Nominatim are for light use only. Set a proper User-Agent, cache tiles, never bulk-fetch, and keep tile/routing URLs in config so they can be swapped for a self-hosted or free-tier provider later.

## 3. Hard Rules

1. **No fake live tracking.** No truck live-location or "arriving in X minutes" shown to residents. Use "scheduled" / "expected"; arrival time may vary. Workers may use maps/directions to reach stops, but their position is not broadcast to residents in the MVP.
2. Enforce roles with **Postgres RLS**, not just UI hiding. Never use the service-role key in the app or dashboard; only in Edge Functions.
3. Residents never see other residents' phone numbers, addresses, or recipient lists.
4. **No duplicate reminders** (unique dedup key per resident + schedule + type + channel).
5. **Re-check schedule state and version before sending** any reminder.
6. Store timestamps as `timestamptz` (UTC); display in `Africa/Addis_Ababa`.
7. All UI text localized (en/am/om); mark am/om `REVIEW: native speaker`.
8. SMS is **not built** in MVP: interface + disabled stub only.
9. Business logic in domain/SQL/functions, not in widgets or inline dashboard HTML.
10. Run `flutter analyze` + tests before finishing each phase. Ambiguity → use defaults in Section 12 with `TODO(decision)`.

## 4. Roles

| Role | Access |
|---|---|
| `resident` | Own profile/reports/notifications/feedback; schedules **of own area only** (non-draft) |
| `worker` | Assigned schedules/tasks; update status within allowed transitions |
| `admin` | Everything: users, areas, routes, trucks, workers, schedules, reports, feedback, analytics |

Role lives in `profiles.role`; RLS uses a `security definer` helper `auth_role()` (avoid recursive policies).
**Admin = dashboard only.** Mobile app serves residents and workers (an admin logging into the app is redirected/blocked with a "use the dashboard" message).

## 5. Database (Postgres)

All tables: `id uuid pk default gen_random_uuid()`, `created_at`, `updated_at`.

- **service_areas**: name, kebele_code (unique), description, active, center_lat/lng (optional)
- **profiles** (1:1 `auth.users`): full_name, phone, role, area_id→service_areas, address, lat/lng?, active, preferred_language, notification_prefs jsonb `{in_app,push,sms,day_before,same_day,on_the_way,completed}`, fcm_tokens text[]
- **routes**: name, area_id, description, stops jsonb `[{name,lat,lng,order}]`, active
- **trucks**: plate_number, capacity?, availability (`available|assigned|unavailable`), maintenance (`ok|in_maintenance`)
- **collection_schedules**: area_id, collection_date, expected_start timestamptz, expected_end?, route_id?, truck_id?, status (enum below), published_at, created_by, updated_by, change_reason, `version int default 1`
- **schedule_workers**: schedule_id, worker_id (unique pair)
- **schedule_history** (audit): schedule_id, changed_by, changed_at, action, previous jsonb, new jsonb, reason
- **collection_tasks**: schedule_id, status, started_at, completed_at, delay_reason, completion_note
- **notifications**: recipient_id, area_id, schedule_id?, type, channel (`in_app|push|sms`), title, message, scheduled_send_at, sent_at, delivery_status (`pending|sent|failed|cancelled`), retry_count, provider_message_id, schedule_version, is_read, read_at, **dedup_key unique**
- **garbage_reports**: resident_id, area_id, address, lat/lng, description, image_path, status (`received|assigned|in_progress|completed|cancelled`), assigned worker/truck, admin_note, completed_at
- **feedback**: resident_id, related_type (`schedule|report|general`), related_id, rating 1–5, comment, type (`feedback|complaint`), status (`new|reviewed|resolved`), admin_response
- **app_settings**: key/value (reminder lead times, quiet hours, retries)

**Status enum:** `draft, published, assigned, on_the_way, in_progress, completed, delayed, cancelled`.
Main path: draft → published → assigned → on_the_way → in_progress → completed. `delayed`/`cancelled` are exceptions (reason required); `completed`/`cancelled` are terminal. Implement transitions once as a Postgres function/trigger (mirror in Dart for UI button enabling) and test all allowed/forbidden moves. Every change writes `schedule_history`.

**Indexes:** schedules (area_id, collection_date); schedule_workers (worker_id); notifications (recipient_id, created_at desc) and (delivery_status, scheduled_send_at); reports (resident_id, created_at desc).

**RLS (default deny):**
- profiles: read/update own (cannot change role/active); admin all.
- areas: any authenticated read; admin write.
- schedules: admin all; resident SELECT where `status <> 'draft'` and `area_id = own area`; worker SELECT where assigned.
- Worker status changes only through RPC `update_schedule_status()` (validates transition + assignment).
- notifications: user reads/updates `is_read` on own only; inserts only by service role.
- reports/feedback: resident insert + read own; admin all; assigned worker reads assigned reports.
- Storage bucket `report-images`: users upload only to `{uid}/...`, images only, ≤5 MB.

Write RLS tests for: resident can't create schedule (AT-08), resident can't read another area's schedule (AT-10), resident can't read others' notifications.

## 6. Notification Engine (Supabase)

- **DB trigger / RPC** on schedule publish: select active residents where `area_id` matches → insert `notifications` rows (`pending`, `schedule_version` stored, `dedup_key` unique, `ON CONFLICT DO NOTHING`) for `day_before` and `same_day`.
- On reschedule/delay/cancel: bump `version`, set old pending reminders `cancelled`, queue new reminders (if still active) and an immediate `reschedule`/`delay`/`cancellation` notice, write history.
- Status → `on_the_way` / `completed`: queue those notices (respecting prefs).
- **`pg_cron` every 5 min** calls Edge Function `process-notifications`:
  1. Pick due `pending` rows (`FOR UPDATE SKIP LOCKED`).
  2. Skip/cancel if schedule missing, draft/cancelled, `version` mismatch, collection time already passed, or recipient inactive.
  3. Respect prefs and quiet hours (essential notices: delay/cancel/reschedule always sent).
  4. `in_app` = the row itself (mark `sent`; Supabase Realtime updates the app inbox); `push` = FCM; `sms` = `SmsProvider` stub.
  5. On failure: `retry_count++`, backoff (5/15/60 min), max 3, then `failed`. Never delete the record.
  6. Overdue jobs after downtime are picked up automatically but re-validated (step 2).
- Defaults in `app_settings`: day-before ≈24h; same-day 3h before; quiet hours 21:00–06:00 (municipality to confirm).
- `SmsProvider` interface (`send(to, message)`) with `DisabledSmsProvider`.

**Templates** (en + am + om; use "scheduled/expected" wording):
- Day-before: "Jimma Waste Management: Household garbage collection in your area is scheduled for tomorrow, {time}. Please prepare your household garbage and place it at the approved collection point before the truck arrives."
- Same-day: "Reminder: Garbage collection in your area is scheduled for today at {time}. Please bring your household garbage to the approved collection point."
- On the way: "The collection team has started serving your area. Please bring your prepared garbage to the approved collection point. Arrival time may vary by route."
- Delay: "Notice: Garbage collection in your area has been delayed. The updated expected time is {newDateTime}. We apologize for the inconvenience."
- Cancellation: "Notice: The planned garbage collection for {date} has been cancelled. The municipality will share the replacement schedule when confirmed."
- Reschedule: "Update: Your area's garbage collection has been rescheduled to {newDateTime}."
- Completed: "Garbage collection in your area has been marked completed. Thank you."

## 7. Flutter App (residents + workers)

```
lib/
 core/ (config, router+role guards, theme, l10n, utils, shared widgets)
 features/ auth, profile, schedules, reports, notifications, feedback, tasks, map
   each: data/ domain/ presentation/
```
Widgets → Riverpod controllers → repository interfaces → Supabase datasources. Every screen handles loading/empty/error + pull-to-refresh.

**Resident** (tabs: Home | Calendar | Report | Notifications | Profile)
- Home: "Next Garbage Collection" card (date, expected time, area, status chip, "arrival time may vary"); quick actions.
- Calendar (`table_calendar`): collection days for own area, upcoming/previous, change notices.
- Report garbage: description, area (prefilled), photo (compressed), **location picker on OSM map** (`flutter_map`; "use my GPS" optional, manual Kebele/map pin fallback).
- My reports + status timeline; Notification center (read/unread, labels); Preferences (essential notices locked on; SMS "coming soon"); Feedback/complaint; Profile (area, language, logout).

**Worker** (tabs: Today | Schedule | Notifications | Profile)
- Today's assignments → task detail with **map of the route stops + OSRM route line / "open directions"** and big buttons: Start Route → On the Way → Start Collection → Completed → Report Delay (only valid next actions enabled; reason dialog for delay; optional completion note).

**Auth:** Supabase Auth, phone + password via synthetic email `<normalizedPhone>@jimma-waste.app` (phone OTP later if SMS budget exists). Residents self-register (name, phone, password, Kebele, address); worker/admin accounts are created by admin via Edge Function `admin-create-user`.

**Push:** permission rationale screen; register FCM token into `profiles.fcm_tokens`; tap → deep link; inbox works even if push is denied.

**UX:** simple language, targets ≥48dp, body ≥16sp, high contrast, light/dark, Noto Sans Ethiopic fallback, status shown by text+icon (not color only), pagination, low-end Android friendly (minSdk 24).

## 8. Admin Dashboard (HTML/CSS/JS)

```
dashboard/
 index.html (login) · app.html (shell)
 css/ styles.css
 js/ supabase-client.js, auth.js, router.js (hash routes), api/*.js, pages/*.js, ui/*.js (tables, modals, toasts), i18n.js, utils/time.js
```
- Plain ES modules, no build step. Supabase **anon key only**; admin-only actions go through RPC/Edge Functions. Block non-admin login. Escape all rendered user content (no raw `innerHTML` with user data). Responsive, accessible, en/am/om.
- **Pages:** Dashboard (today's schedules, pending reports, delivery summary: sent/failed/pending) · Schedules (list + calendar, area/status filters; create/edit with availability warnings; **resident message preview before publish**; publish/reschedule/cancel with required reason; change history) · Garbage Reports (list, **Leaflet/OSM map of report pins**, assign worker/truck, update status) · Areas, Routes (stops editable on map), Trucks, Workers, Users (add/edit/activate/deactivate) · Feedback & Complaints · Reports (weekly/monthly: reports received, collections completed, delays, truck usage; charts via Chart.js CDN; CSV export).

## 9. Non-Functional

Ordinary operations ≈ ≤3 s (indexes, pagination) · notifications persisted, recover after outages · modular/testable code · add Kebeles/users without redesign · input validation everywhere (phone `+2519…`/`09…` normalized) · no PII/tokens in release logs · collect minimum data, show consent text at registration · audit trail for schedule/assignment/status/user-active changes · comply with Ethiopian law and municipal policy.

## 10. Acceptance Tests (must pass)

| ID | Test |
|---|---|
| AT-01 | Published schedule for Kebele 04 → only **active** residents of Kebele 04 targeted |
| AT-02 | Day-before reminder → one notification per eligible resident+channel queued/sent and recorded |
| AT-03 | Same-day reminder has correct date, area, expected time |
| AT-04 | Reschedule → obsolete pending reminders cancelled; residents notified |
| AT-05 | Cancel → residents notified; no future reminders |
| AT-06 | Same job processed twice → no duplicate message |
| AT-07 | Worker sets On the Way → change recorded; configured alerts generated |
| AT-08 | Resident cannot create/edit schedules (RLS denies) |
| AT-09 | Provider failure → failure recorded, retried per policy, record kept |
| AT-10 | Resident calendar shows only own area's non-draft schedules |

Also unit-test: status machine, reminder-time calc (UTC↔Addis), dedup keys, templates.
**Done per feature:** tests pass, analyzer clean, 3-locale strings, empty/loading/error states, role guards, no PII leaks.

## 11. Roadmap (in order; check off)

- [ ] **P0 Foundations:** repo layout (`app/`, `dashboard/`, `supabase/`), Supabase CLI + migrations + local dev, Flutter scaffold (router, theme, l10n, Riverpod), time utils, seed script (3 Kebeles, 1 admin, 2 workers, 1 truck, 1 route, 5 residents, 2 schedules)
- [ ] **P1 Auth/roles/areas:** schema + RLS + tests; login/register; profiles; admin-create-user function; dashboard login + Areas + Users
- [ ] **P2 Scheduling:** trucks/workers/routes CRUD (dashboard); schedule CRUD, assignment warnings, status RPC, history; resident Home card + Calendar
- [ ] **P3 Notifications:** queue logic, `process-notifications` + `pg_cron`, dedup/retry/version checks, in-app inbox (Realtime), FCM push, preferences, SMS stub, dashboard delivery summary (AT-01–06, 09)
- [ ] **P4 Reports & feedback:** resident report with OSM location picker + photo; dashboard report map/assignment; feedback flow; resident status notices
- [ ] **P5 Worker progress:** Today/task detail, OSM route stops + OSRM line, status buttons, delay reason (AT-07)
- [ ] **P6 Analytics & hardening:** weekly/monthly reports, performance/accessibility pass, offline-friendly behavior, release config, pilot checklist (validate area records and phone numbers)
- [ ] **P7 Optional (only if asked):** live GPS truck tracking + proximity alerts, SMS provider, health/environment read-only role

## 12. Defaults for Open Decisions (`TODO(decision)`)

Kebele list: 3 sample, admin-editable · placement points: free-text note · collection days: admin-defined · reminders: 24h / 3h before, quiet 21:00–06:00 · languages: en, am, om (am/om pending review) · who may mark On the Way/Completed: assigned workers + admins · SMS provider: none yet · delay/cancel/reschedule notices are mandatory · map/routing provider: public OSM/OSRM for pilot, swap via config.

## 13. Limitations (reflect in app copy)

Scheduled time is expected, not guaranteed. SMS depends on a future provider and network. No live truck GPS in MVP. Public OSM services have usage limits. Wrong resident area data causes missed notices, so prompt residents to confirm their Kebele on first login.
