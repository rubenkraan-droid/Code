# Recraparcs Dashboard — CLAUDE.md

## Stack & structure

Static HTML/CSS/vanilla JS, no build step, no package.json. Hosted on GitHub Pages
(`rubenkraan-droid/Code`), custom domain `dashboard.recraparcs.nl` via `CNAME`.
Deploy = commit to `main`, GitHub Pages rebuilds automatically (~1 min).

- **`index.html`** — the live, current dashboard (Eigenaar/Makelaar/Ontwikkelaar role views). This is
  the file that matters. All active work happens here.
- `dashboard.html` — placeholder redirect only, not the real app despite the name.
- `makelaar-dashboard.html`, `wielsche-dreef-dashboard.html`, `notion-dashboard.html`, `vlees.html`,
  `*-proxy-flow.json` — superseded iterations / old n8n-Notion architecture, kept but not live. Don't
  edit expecting production impact.
- CDN deps inline in `index.html`: Chart.js 4.4.1, `@supabase/supabase-js@2`. No `node_modules`.
- No tests, no CI. "Verification" = push to `main`, wait for Pages (~1 min), curl the live URL, check
  Supabase RPCs directly via SQL.

The old root `CLAUDE.md` (Notion CSV-upload rules, n8n proxy warnings) describes a **previous**
architecture and no longer applies to `index.html`. Kept for historical n8n flows only.

## Supabase (project `ooqkpazyvohsrdvxfnug`)

**Data flow:** Pipedrive (CRM) + Meta Ads → Edge Functions → Postgres tables → SECURITY DEFINER RPCs →
`index.html` calls RPCs directly via supabase-js. No custom backend server.

**Tables that matter:**
- `deals` — the core table. One row per Pipedrive deal, denormalized with `park_id`, `market`,
  `stage_name`, `agent_id`, `ad_id`, financials, and *_derived date columns (see Gotchas).
- `pipeline_park_map` — maps Pipedrive `pipeline_id` → `park_id`/`market`. Riverte and Berkenstrand are
  deliberately set to `park_id=null, market=null` — excluded from the business, not a bug.
- `stage_map` — Pipedrive `stage_id` → `stage_name` text, joined in on every deals sync.
- `agents`, `agent_user_map` — agent roster and Pipedrive-user-id → agent linkage.
- `ads`, `ad_stats_daily` — advertising inventory + daily spend/click stats from Meta.
- `access_grants` — **the real ACL table**: `email`, `is_owner`, `park_id`. `park_members` and
  `profiles` tables exist but are unused legacy — don't reach for them.
- `call_activities` — bel-activiteiten (Gesprek/GGH/Ongelegen), synced from Pipedrive activities.
- Dead/legacy, unreferenced by any function: `ad_spend_daily` (NOT `ad_stats_daily`, which is live),
  `appointments`, `leads`, `sales`, `units`, `ops_*`. Grep `pg_proc.prosrc` before assuming a table live.

**Auth / RLS pattern:**
- All tables have RLS enabled with **zero policies** (deny-all). Every read goes through a
  `SECURITY DEFINER` RPC that does its own auth check — RLS itself is just a backstop.
- `is_owner()` → `auth.uid() is null OR access_grants.is_owner for current_email()`.
  **The `auth.uid() is null` branch is intentional preview-mode behavior**, not a bug: it lets the
  team click through owner/agent/park views without logging in. It also means margin data is *not*
  DB-level hidden while login is disabled (see Gotchas).
- `has_park_access(park_id)` → owner OR an `access_grants` row for that email+park.
- `current_email()` reads the email claim out of the PostgREST JWT.
- RPCs are `revoke`d from `anon`/`public` explicitly (defense in depth) — `grant ... to authenticated`
  only. **`CREATE OR REPLACE FUNCTION` does not reset `anon`'s implicit `PUBLIC` execute grant when
  you `DROP FUNCTION` first** — after any `drop function` + `create function` cycle, re-run the
  revoke-from-public/anon migration or `anon` silently regains access.

**Migrations:** applied via `apply_migration` (Supabase MCP tool) — no `supabase/migrations` directory
in this repo. `list_migrations` on the project is the source of truth, not git log.

**Edge Functions** (Deno, in the Supabase project, not in this repo):
- `sync-pipedrive` — pulls all deals hourly, upserts via `sync_deals_from_json`, then runs
  `stageChangelogBackfill()` (walks `/deals/{id}/flow` changelog to backfill appointment/sale dates)
  and `syncActiviteiten()` (call activities). Protected by a `key=` param checked against `SYNC_SECRET`
  or `internal_get_cron_key()`.
- `sync-meta` — pulls Meta ad-level insights for `act_1257993373041389` (France) for the last N days
  (default 7, max 90), upserts `ads`/`ad_stats_daily` via `sync_meta_stats`. Same key-auth pattern.
- Deployed via the Supabase MCP `deploy_edge_function` tool — no local copy of the source in this repo;
  the last-deployed version in Supabase is canonical, not any local scratch file.

## Conventions

- **All communication and all UI copy in Dutch.** Labels, KPI names, everything.
- **Financial fields are always four separate numbers, never derived inline in the UI:**
  Verkoopsom (`amount`, house price) → Omzet (total courtage Recraparcs invoices) → Courtage
  (makelaar's cut, `makelaar_uitbetaling`) → Marge Recraparcs (`recraparcs_marge`, the remainder).
  Ruben corrected this definition three times — do not conflate "omzet" with "marge" or with
  "verkoopsom" again. **Courtage formula is PER PARK** — table `park_commission(park_id, rate, cap)`.
  Only Wielsche Dreef (park 3) is configured: rate 0.015, cap 3500. `recalc_deal_margins()` applies
  each deal's park config (`makelaar_uitbetaling = LEAST(round(amount*rate), cap)`,
  `recraparcs_marge = GREATEST(round(amount*rate) - cap, 0)`); deals in a park WITHOUT a config row get
  `NULL` commission ("nog niet bekend"). A new park needs its own `park_commission` row before it shows
  any commission. Don't hardcode 0.015/3500 anywhere — read `park_commission`.
- **Makelaars never see `recraparcs_marge` or `marge_recraparcs`** in any query result or UI element
  reachable from the makelaar role. This is an AVG/privacy hard rule, not a style preference.
- **Resale deals (`pipeline_id = 8`) are excluded** from funnel/performance RPCs (`pipeline_id<>8`
  filters throughout). Don't remove these filters when refactoring a query.
- Riverte and Berkenstrand are excluded from `market`/`park` everywhere (`pipeline_park_map` has them
  set to null) — if new pipelines appear for them, leave them unmapped, don't add them back.
- Stage-name string arrays (which Pipedrive stages count as "an appointment happened", "a sale
  happened") are duplicated in **three places** that must be kept in sync: the edge function's
  `AFSPRAAK_NAMEN`/`VERKOOP_NAMEN` sets, `internal_deals_needing_appointment_backfill`'s `stage_name in
  (...)` filter, and `call_overview`'s `ingepland` filter. No single source of truth — changing the
  appointment/sale definition means editing all three.

## Gotchas (discovered the hard way)

- **Postgres won't let `CREATE OR REPLACE FUNCTION` change a return type.** Adding a column to an RPC's
  `TABLE(...)` return errors `42P13 cannot change return type of existing function`. Fix: `DROP
  FUNCTION` (exact arg types) then `CREATE FUNCTION` in the same migration — then re-apply `revoke ...
  from anon, public` (see RLS note), since the drop wipes the ACL.
- **PostgREST schema cache lags after DDL** — always end a migration with `notify pgrst, 'reload
  schema';`; if a fresh RPC 404s right after deploy, retry after a few seconds before assuming failure.
- **`pg_get_functiondef()` throws `42809: "array_agg" is an aggregate function`** on this project — use
  `p.prosrc` + `pg_get_function_identity_arguments`/`pg_get_function_result` instead.
- **The appointment/sale "derived date" backfill only processes deals whose *current* `stage_name` is
  in the matching set.** A deal that reaches "Afspraak gepland" and later gets moved to something
  outside that set before a sync run picks it up will never get backfilled from the Pipedrive
  changelog. This was the root cause of 4 real French appointments not showing up on the dashboard —
  the backfill's stage-name filter didn't include "Afspraak gepland" (only "Afspraak geweest" onward).
  Now fixed (see Current state), but if appointment counts look short again, check this filter first.
- **`no_show` is a generated column** (`stage_name = 'Klant niet geweest'`), not a synced/backfilled
  flag — it recalculates automatically on every deal upsert. If a deal is manually moved out of that
  stage later (rescheduled), `no_show` flips back to `false` with no extra logic needed. Don't build a
  separate backfill mechanism for it.
- **`sync-meta`'s insights-based ad-name update only sees ads with impressions in its lookback window**
  (default 7 days, from Meta's `/insights` endpoint) — an ad that generated Pipedrive leads weeks ago
  but has had no recent spend never reappears there. Fixed by a separate `adNameBackfill()` step
  (added in this session) that looks up each `name like 'Meta-advertentie %'` row directly via
  `GET /{ad_id}?fields=id,name,status` — this works regardless of recency or pause/archive state,
  unlike `/act_.../ads` list calls which silently omit some archived ads. Uses
  `internal_ads_needing_name_backfill`/`internal_set_ad_name`, same pattern as the Pipedrive stage
  changelog backfill.
- **Duplicate `ads` rows for what's conceptually the same ad exist** (e.g. id 28 `"Niet huren. Bezitten.
  - NH-AD2"` vs id 35 `"NH-AD2"`, different `external_id`s, both `park_id=1`). Root cause unconfirmed
  [unverified] — likely a mismatch between the manually-entered Pipedrive `ad_external_id` field and
  Meta's actual `ad_id`. Check `ad_stats_daily` spend on both before assuming one is canonical.
- **Preview mode (`is_owner()` returning true when logged out) means margin data is not database-level
  hidden from makelaars right now** — it's hidden in the UI (tab/column removed) but a direct RPC call
  from the browser console as any role still returns `marge_recraparcs`. This is acceptable only until
  Supabase Auth SMTP is configured and login is switched back on; don't treat the UI-level hiding as a
  real security boundary in the meantime.
- **Supabase Auth SMTP is not configured** — login emails still send from
  `noreply@mail.app.supabase.io`, not `dashboard@recraparcs.nl`, and the auth rate limit (429) has
  been hit at least once. Login is deliberately left off until this is fixed (see preview-mode note
  above). Brevo was discussed as the SMTP provider (host `smtp-relay.brevo.com:587`, needs SPF/DKIM
  for `recraparcs.nl` specifically, not whatever domain Golden Bricks already verified).

## Current state (bijgewerkt 2026-07-11, eind sessie)

Fullest handoff = Google Drive **Recraparcs / agent-dashboard** → doc "CONTEXT — RecraVas agent-dashboard".

**Done:** role-based views (Eigenaar/Makelaar/Ontwikkelaar); custom domain; Wielsche Dreef branding
(alleen WD, niet Frankrijk); hourly Pipedrive + 6-hourly Meta sync (France only); Financiën tab with
the 4-number courtage breakdown, margin hidden from makelaar; "Verlopen" badge; "Definitief" status;
appointment counting from "Afspraak gepland" + no-show via "Klant niet geweest" + "No-show %" KPI;
verkoop telt vanaf "Informeel akkoord ontvangen".
**Deze sessie toegevoegd:** volledige redesign (zijbalk-nav met hamburger-inklap, warme kleuren, serif
KPI's) + **mobiele layout** (compacte topbalk, horizontaal scrollbare tabs, tabellen scrollen binnen
paneel); UI-naam **RecraVas**; **Resale**-label i.p.v. Overig (pipeline 8); defaults op **all-time**;
**actieve tab onthouden bij refresh** (localStorage); **Show %** vóór Closing % + Leads/Sales in
per-makelaar tabel; **Gesprek→afspraak %** in beloverzicht; **Ongekwalificeerd %** per advertentie +
waarschuwingsvlag; advertentiegrafiek met **zwevende afspraak-bolletjes** + tooltip (kosten/lead,
leads, uitgaven, afspraken); **verloren-redenen klikbaar** (RPC `lost_deals` → deals + Pipedrive-links);
afspraken-no-show apart als **"Niet geweest"** (i.p.v. onterecht "Gehouden") in `appointments_detail`;
**makelaar ziet eigen commissie** (`agent_stats.mijn_commissie` = sum `makelaar_uitbetaling`; omzet/marge
blijven verborgen); `manual_ad_spend`-tabel (leeg); Meta-spend volledig herbouwd uit echte Meta-historie
(campagne-id-dubbeltellingen weg); WD demo-advertenties verwijderd.

**Bekend / open:**
- **Bel-activiteiten leeg**: `call_activities` = 0 rijen. In Pipedrive staan 45 activiteiten, ALLEMAAL
  type "Verkoopdag" — nul van type call/ggh/ongelegen. De pijplijn (sync → per makelaar tellen) werkt en
  vult zich zodra het team gesprekken als Gesprek/GGH/Ongelegen-activiteit logt. Niets kapot; er is enkel
  geen data. "Ingepland" komt uit deals, niet uit activiteiten.
- **Betrokken verkoper**: slechts ~10 van ~530 deals hebben dit veld ingevuld → per-makelaar cijfers
  (incl. commissie) grotendeels leeg. CRM-datakwaliteit, geen bug.
- Mogelijke dubbele `ads`-rijen (zie Gotchas).
- **SMTP** (Brevo) nog niet ingesteld → login uit → marge nog niet db-niveau afgeschermd.
- **Wielsche Dreef Meta-adaccount** koppelen zodra Ruben toegang heeft (nu alleen Frankrijk-account;
  tot dan handmatige spend mogelijk via `manual_ad_spend`).
