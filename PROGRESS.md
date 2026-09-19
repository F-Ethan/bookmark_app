# Progress

Working notes for Bookmark. Agents must record anything discovered but left unfixed under **Known gaps**.

## Known gaps

- **README is stale.** It still describes a SharedPreferences-only, iOS-only tracker. The app now has Supabase auth, guest mode, an in-app reader, book-group editing, verse highlights, optional BBE download, appearance settings, a leaderboard, and a supporters list.
- **`dart_defines/dev.json` is required for local `--dart-define-from-file` launches and is gitignored.** The file is not in the repo; new machines need a local copy. Do not commit it.
- **Guest data is not migrated on sign-up.** Creating an account after guest use does not copy the local plan, groups, or highlights into Supabase.
- **README roadmap vs code.** Android embeddings, local notifications, and in-app Bible text already exist in some form. Export (PDF/CSV), audio, and a home-screen widget are still absent. Screenshots are still marked "still to come."
- **No `LICENSE` file**, though the README claims MIT.
- **Live privacy page is still generic.** `gamelogic.dev/bookmark/privacy-policy` does not yet reflect Leaderboard display names, Supporters, or verse highlights. Replace with `docs/policies.md`.
- **Sentry is scaffolded but off** until `SENTRY_DSN` is set. Major dependency upgrades (`go_router`, `riverpod`, `flutter_local_notifications`) are still deferred — see #14 / #15 below.
- **Patreon URL is empty.** `AppConstants.patreonUrl` stays unset until a page exists; add supporter rows in the Supabase dashboard as people sign up.
- **`supabase/migrations/0006_supporter_note.sql` is not yet applied to the live project.** Adds the `supporter_note` table backing the Supporters screen's editable note (see 2026-09-19 leaderboard/supporter-note entry below). Apply it via the SQL editor or `supabase db push`, then edit the seeded row's `note` column from the dashboard whenever the wording needs to change — no app release required.

---

## 2026-09-19 — Leaderboard join prompt, supporter note moved to DB

Two small requested changes:

**Leaderboard opt-in prompt.** `lib/screens/leaderboard_screen.dart` now shows a banner above
the list when the visitor isn't part of the leaderboard: guests get "create a free account",
signed-in users who haven't opted in get "opt in from Settings" — both link to `/settings`
(`context.push`, since Leaderboard itself is reached via `push` from Home). Driven by
`readingPlanProvider`'s `leaderboardOptIn` + `guestModeProvider`, the same state Settings' own
toggle already uses; banner is suppressed while the plan is still loading to avoid a flash for
users who are actually already opted in.

**Supporters "note from Ethan" moved to the database.** Previously hardcoded in
`_DeveloperNote` (`lib/screens/supporters_screen.dart`). New singleton table
`supabase/migrations/0006_supporter_note.sql`, same dashboard-managed pattern as `supporters`
(0005) — publicly readable, no client write policy, edited via the Supabase table editor. The
tappable email address and "…and I'll add you here" sign-off stay fixed in app code; only the
lead paragraph is DB-driven. Falls back to the original wording if the fetch fails (offline, or
the row is missing) so the screen never breaks. **Not yet applied to the live project** — see
Known gaps above.

---

## 2026-09-19 — Live migrations applied

`supabase/migrations/0001`–`0005` were applied to the live Supabase project on 2026-09-19.

- **0001** closed the `verse_highlights` cross-user SELECT by dropping the old live policy names (`Users manage own plan`, `Users manage own groups`, `Authenticated users can read all highlights`, `Users can delete own highlights`, `Users can insert own highlights`) before recreating owner-only `*_own` policies. Postgres ORs policies — leaving the old SELECT would keep the leak.
- **0002** `chapter_progress` includes `chapter_progress_update_own` (`auth.uid() = user_id`) so signed-in upserts-on-conflict succeed.
- **0003–0005** match what is live: `get_trending_highlights`, `reading_plans` streak/leaderboard columns + `get_leaderboard`, and the `supporters` table.

Repo SQL files are aligned with production. New schema/RLS changes should be a new numbered migration, not a silent dashboard edit.

---

## 2026-09-19 — Supporters, Leaderboard, Terms/Privacy, review prompt

Full plan at the time of implementation: `~/.claude/plans/merry-foraging-scone.md` (also
summarized here). Four features, one shared foundation:

**Streak & highest-day tracking (new, foundational).** `lib/utils/streak_utils.dart`
(`computeStreakUpdate`, unit-tested in `test/streak_utils_test.dart`) is pure calendar-day logic:
marking a day read same-day is a no-op, next-calendar-day extends the streak, any bigger gap
resets it. `ReadingPlanNotifier.recordDayCompleted()` (`lib/providers/reading_plan_provider.dart`)
is the single choke point that updates it — `daily_screen.dart`'s `_markAsRead` now calls this
instead of `setCurrentDay` directly. Deliberately **not** wired into Settings' manual day-number
edit (that still calls `setCurrentDay` alone) — a manual edit isn't real reading progress and
shouldn't inflate stats. Dual-mode as usual: guest → new `LocalDataService` keys (cleared by
"Start Over"/`clearAll`); signed-in → four new columns directly on `reading_plans`
(`supabase/migrations/0004_reading_stats.sql`).

**Leaderboard (opt-in).** Two more `reading_plans` columns, `leaderboard_opt_in` and
`leaderboard_display_name` — deliberately separate from the existing `name` field (which may be
a real name and is never shown publicly). Public read via `get_leaderboard`, a `SECURITY
DEFINER` function mirroring `get_trending_highlights`'s pattern (0003) — returns only an
opted-in display name, two stat counts, and a server-computed `is_me` flag; never a `user_id`,
real name, or email. New `lib/screens/leaderboard_screen.dart` (two tabs: Longest Streak /
Highest Day), reached from a new Home screen tile. Settings screen gets the opt-in toggle +
display-name field (signed-in only; guests see a prompt).

**Supporters.** New `supporters` table (`0005_supporters.sql`), publicly readable, **no
insert/update/delete policy for any role** — by design, entries are added manually via the
Supabase dashboard, per your plan to add Patreon backers yourself. New
`lib/screens/supporters_screen.dart` + a Settings tile; a second "Become a Supporter" tile only
appears once `AppConstants.patreonUrl` is set (empty for now — no dead link before you have a
Patreon page).

**Review prompt.** `lib/services/review_prompt_service.dart` wraps `in_app_review` (native
`SKStoreReviewController`/Play In-App Review — the OS itself decides whether it actually shows).
Triggers at streak milestones (7/30/100 days), reusing the streak tracking above, with a local
throttle (max 3 prompts ever, ≥60 days apart) on top of the OS's own rate-limiting so it's never
naggy. Hooked into `daily_screen.dart`'s `_markAsRead`, right after `recordDayCompleted` returns
the new streak.

**Terms/Privacy.** Confirmed via grep this app had *zero* ToS/Privacy Policy anywhere before
this — overdue given it already collects email, more so now with public display names. Per your
direction, content lives in `docs/policies.md` (draft, not legal advice) for your `gamelogic`
repo's own agent to publish (matching the existing `support@gamelogic.dev` pattern).
`sign_up_screen.dart` now links to it inline under the password field; Settings links to it too,
near the new Community section.

**2026-09-19 (later same day) — link verified, found wrong.** Fetched
`gamelogic.dev/bookmark/policies` (what was originally assumed) — 404. The actual published path
is **`gamelogic.dev/bookmark/privacy-policy`** (linked from that page's own footer nav).
`AppConstants.policiesUrl` and the references in `CLAUDE.md`/`docs/policies.md` are now
corrected to that path.

**More importantly: the live page's *content* doesn't match this app yet.** What's published at
that URL right now reads as a generic/boilerplate privacy policy (guest mode, basic account
registration, "we don't sell your data," standard sections) — it does **not** mention the
Leaderboard's public display name/stats, the Supporters list, or verse highlights at all. This
is presumably a template shared across your other apps rather than the specific content drafted
in `docs/policies.md`. Since the Leaderboard's whole opt-in consent story depends on the policy
actually disclosing what becomes public, **this still needs to be replaced with the content from
`docs/policies.md`**, not just linked to correctly.

**Still needed from you:**
1. ~~Apply `supabase/migrations/0004_reading_stats.sql` and `0005_supporters.sql`~~ — applied
   live 2026-09-19 with 0001–0003.
2. Hand `docs/policies.md` to your gamelogic repo's agent to **replace** the current generic
   content at `gamelogic.dev/bookmark/privacy-policy` — the link now points to the right page,
   but the page itself still needs updating.
3. Set `AppConstants.patreonUrl` once your Patreon page exists.
4. Add supporter rows via the Supabase dashboard as people sign up.

---

## 2026-09-18 (follow-up) — Home screen Highlights carousel redesign

Follow-up request: the old "Today's Highlights" strip got crowded and the user wanted their
own highlight shown first, then popular ones from other users, auto-advancing every ~7s, and a
more polished look.

This directly touched the #2 privacy decision above ("make private"). Resolved by asking: the
"popular ones from other users" part is now an **anonymized aggregate** — a new
`get_trending_highlights` Postgres function (`supabase/migrations/0003_trending_highlights.sql`)
returns "N people also highlighted this verse" counts, scoped to the chapters in the *viewer's*
current day's reading, with no user identity ever returned. Individual highlight rows remain
owner-only per #2/#1's RLS.

**Fix applied:**
- `trendingHighlightsProvider` (`lib/providers/verse_highlights_provider.dart`) — empty in guest
  mode (local data never contributes to or benefits from the aggregate).
- `_HighlightsSection` (`lib/screens/home_screen.dart`) rebuilt as a `PageView` carousel: own
  highlights first, then trending (de-duplicated against own by verse reference), auto-advancing
  every 7 seconds via `Timer.periodic`, pausing while the user is manually swiping and resuming
  after. Redesigned cards use a gradient background (brand color for own, amber for trending), a
  decorative quote mark, italic verse text, and a heart (own, tap to remove) or flame+count
  (trending) badge, with a page-dot indicator matching the style already used in `daily_screen.dart`.

**0003 applied live 2026-09-19.**

---

## 2026-09-18 — fix pass summary

All 18 findings below were addressed in-repo where that was possible from a code-only session
(no live Supabase credentials, no Sentry account — see the two 🟡 items). `flutter analyze` is
clean and `flutter test` passes (9 tests) as of this pass.

Migrations **0001–0005 are applied** on the live project (2026-09-19). Remaining manual items:
Sentry DSN, deferred major dependency upgrades (#15), and publishing `docs/policies.md`.

---

## Your original question: "the book layout is different every time I start a new day"

Traced end-to-end (`daily_screen.dart` → `chapter_utils.dart#getChaptersForDay` →
`bible_sections.dart`). **This part is working as designed, not a bug**: the Horner method
assigns one chapter per day from each of 10 book lists, and each list is a different total
length, so they cycle at different rates — the exact book/chapter combination is different
every day by definition of the method itself. This is now locked in by `test/chapter_utils_test.dart`.

What *was* real, and adjacent to what you noticed, both now fixed in code (#9, #10 below):
- Per-chapter "read" checkmarks now sync to Supabase for signed-in users (`0002_chapter_progress.sql`,
  applied live 2026-09-19, including UPDATE for upsert).
- Resetting book groups to defaults now actually saves the defaults, not an empty row.

---

## Security findings

### 1. 🟢 CRITICAL — IDOR on verse highlight deletion
**File:** `lib/services/verse_highlight_service.dart`.
**Code fix applied:** `remove(id)` now also filters `.eq('user_id', userId)` client-side.
**Live RLS applied 2026-09-19** (`0001_rls_policies.sql`): owner-only `*_own` policies after
dropping the old live names. This is now enforced server-side.

### 2. 🟢 HIGH — Cross-user verse highlight exposure, undisclosed
**Files:** `lib/services/verse_highlight_service.dart`, `lib/providers/verse_highlights_provider.dart`.
**Decision (yours):** made private — highlights are scoped to their owner.
**Code fix applied:** `fetchForDay(day)` now also filters `.eq('user_id', userId)` and returns
`[]` if no user is signed in, instead of returning every user's highlights for that day.
**Live RLS applied 2026-09-19:** old `Authenticated users can read all highlights` was dropped
before creating `verse_highlights_select_own`. Postgres ORs policies — leaving that SELECT
would have kept the leak.

### 3. 🟢 HIGH — Optimistic local writes with no rollback on backend failure
**Files:** `lib/providers/book_groups_provider.dart`, `lib/providers/reading_plan_provider.dart`,
`lib/providers/chapter_progress_provider.dart`.
**Fix applied:** every mutating method now wraps its persistence call in `try/catch`, rolls
`state` back to the pre-edit value on failure, and rethrows so the calling screen can show an
error. Screens (`book_groups_screen.dart`, `settings_screen.dart`, `daily_screen.dart`) now
catch those and show a SnackBar instead of silently reverting on next launch.

### 4. 🟢 MEDIUM — Row Level Security is the entire security boundary and is unauditable here
**Fix applied:** `supabase/migrations/0001_rls_policies.sql` and `0002_chapter_progress.sql` now
version-control the intended RLS policies for `reading_plans`, `book_groups`,
`verse_highlights`, and the new `chapter_progress` table.
**Applied live 2026-09-19.** Keep this folder matching production; add a new numbered file
rather than editing the dashboard silently.

### 5. 🟢 LOW — No client-side validation on auth screens
**Files:** `lib/screens/auth/sign_in_screen.dart`, `sign_up_screen.dart`.
**Fix applied:** inline email-format and password validation before hitting the network, with
the existing error banner reused to show the message.

### 6. 🟢 LOW — Router calls a protected `ChangeNotifier` method from outside the class
**File:** `lib/core/router/router.dart`.
**Fix applied:** added a public `refresh()` method on `_AppStateNotifier`; the router now calls
that instead of `notifyListeners()` directly.

---

## Bugs / glitches

### 7. 🟢 Test suite does not compile — effectively zero test coverage
**Fix applied:** replaced the broken `test/widget_test.dart` (referenced a removed `MyApp`
constructor, asserted on stale SharedPreferences keys) with:
- `test/chapter_utils_test.dart` — pure unit tests locking in the Horner cycling logic.
- `test/book_groups_provider_test.dart` — regression test for #10 (defaults are actually saved).
- `test/widget_test.dart` — widget smoke tests for `HomeScreen` (guest mode) and `SignInScreen`.

`flutter test` passes (9 tests) as of this pass.

### 8. 🟢 No CI/CD
**Fix applied:** `.github/workflows/ci.yml` runs `flutter analyze` and `flutter test` on every
push/PR to `main`.

### 9. 🟢 Signed-in chapter-read progress never synced to Supabase
**Files:** `lib/providers/chapter_progress_provider.dart`, `lib/services/supabase_service.dart`,
`lib/services/local_data_service.dart`.
**Fix applied:** the provider now branches on `guestModeProvider` like every other piece of user
state. New `SupabaseService.fetchChapterProgress`/`setChapterRead` methods back it for signed-in
users, matched by the new `chapter_progress` table.
**Applied live 2026-09-19**, including `chapter_progress_update_own` so upsert-on-conflict works.

### 10. 🟢 `resetToDefaults()` saved an empty row, not the defaults
**File:** `lib/providers/book_groups_provider.dart`.
**Fix applied:** `resetToDefaults()` now persists `defaultBookGroups` directly through the same
rollback-safe `_applyAndSave` path used by every other mutation, for both guest and signed-in
modes — no more relying on empty-list-means-defaults fallback logic.

### 11. 🟢 Settings name/day fields could snap back mid-edit
**File:** `lib/screens/settings_screen.dart`.
**Fix applied:** controllers are now seeded from the loaded plan exactly once
(`_profileControllersInitialized` flag) instead of on every rebuild where the field is empty.

### 12. 🟢 Bible JSON parse had no error handling, could crash startup
**Files:** `lib/services/bible_service.dart`, `lib/main.dart`.
**Fix applied:** a parse failure on a downloaded translation now falls back to the bundled KJV;
a parse failure on the bundled KJV itself (nothing left to fall back to) is caught in `main.dart`
and shown as a minimal in-app error screen instead of crashing before any UI renders.

### 13. 🟢 Dead file
**Fix applied:** `lib/models/section.dart` deleted (confirmed unreferenced first).

---

## Code quality / enterprise readiness

### 14. 🟡 No crash reporting or structured logging
**Fix applied:** `sentry_flutter` added and wired in `main.dart`, gated on a `SENTRY_DSN`
dart-define that defaults to empty — `Sentry.init` is skipped entirely when it's unset, so this
is currently a no-op.
**Still needed from you:** create a Sentry project, set `SENTRY_DSN` in
`dart_defines/dev.json` (and your release build config) to activate it.

### 15. 🟡 Dependencies — safe bumps done, majors deliberately deferred
**Fix applied:** ran `flutter pub upgrade` (patch/minor only, no `--major-versions`) —
`supabase_flutter` 2.12.0 → 2.17.2, `shared_preferences` and ~60 other transitive packages
bumped within their existing major-version constraints. Fixed the `anonKey` → `publishableKey`
and `activeColor` → `activeThumbColor` deprecations that surfaced from this.
**Deliberately not done (your call):** `flutter_local_notifications` (19→22), `go_router`
(14→18), `flutter_riverpod`/`riverpod` (2→3) remain on their current majors — each has breaking
API changes touching routing, all providers, or notification setup, and doing them together
with everything else in this pass would have made it much harder to isolate what broke if
something did. Do this as its own dedicated pass, one package at a time, with the app actually
running on a device between each.

### 16. 🟢 `analysis_options.yaml` used only stock `flutter_lints`
**Fix applied:** added `avoid_print`, `cancel_subscriptions`, `close_sinks`,
`prefer_final_locals`, and `unawaited_futures` (the last one directly targets the class of bug
behind #3). `flutter analyze` is clean with these enabled — no existing code triggered them.
Also added explicit casts to `BibleGroup.fromJson`/`BibleBook.fromJson`
(`lib/models/book_group.dart`) which were silently accepting `dynamic` before.

### 17. 🟢 No offline/connectivity handling strategy
**Fix applied:** added a shared `ErrorRetryView` widget (`lib/core/utils/supabase_error.dart`)
with a Retry button that re-invalidates the relevant provider; wired into `home_screen.dart`,
`daily_screen.dart`, `settings_screen.dart`, and `book_groups_screen.dart`, replacing the bare
`Text('Error: $e')` in each. This is a UI-level improvement, not retry/backoff on the network
calls themselves — a fuller offline-queue strategy is still open if you want it later.

### 18. 🟢 No accessibility review evident
**Fix applied:** audited every `IconButton` in `lib/screens/` for a missing `tooltip`; found and
fixed two (the back buttons in `daily_screen.dart` and `bible_browse_screen.dart`). Text-scaling
behavior under system accessibility settings still hasn't been verified on-device — that needs
manual testing with a simulator/device, not something fixable by reading code.

**Ruled out this pass (checked, not found):** no hardcoded non-Supabase secrets, no `http://`
cleartext URLs, no stray `print()` statements, no TODO/FIXME/HACK markers, no iOS ATS
exceptions, Android manifest requests only `INTERNET` (no overreaching permissions).

---

## What's left for you specifically

1. ~~Apply `supabase/migrations/0001`–`0005`~~ — done live 2026-09-19.
2. **Create a Sentry project and set `SENTRY_DSN`** whenever you're ready for crash reporting.
3. **Schedule the deferred major dependency upgrades** (#15) as their own pass.
4. Publish `docs/policies.md` to `gamelogic.dev/bookmark/privacy-policy`.
5. Run the app on a real device/simulator and click through it once.

---
*Audit performed and fix pass completed 2026-09-18. Migrations applied live 2026-09-19.
Re-run this pass after major changes and update statuses above rather than starting a new log file.*
