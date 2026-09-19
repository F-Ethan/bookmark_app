# Audit & Enterprise-Readiness Progress Log

**Scope:** Full repo deep-dive — security, correctness/glitches, and "professional/enterprise
readiness" — requested 2026-09-18. Covers all of `lib/`, `pubspec.yaml`, `analysis_options.yaml`,
`test/`, iOS/Android platform config, and git history.

**Methodology:** Manual read of every Dart source file, `flutter analyze`, `flutter pub outdated`,
targeted greps (`print(`, `http://`, `TODO|FIXME|HACK`, `catch (e)`), and a git-history check
for committed secrets.

Status legend: 🔴 not started · 🟡 in progress / needs your action · 🟢 done.

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
1. Apply `supabase/migrations/0004_reading_stats.sql` and `0005_supporters.sql` (alongside
   0001–0003 if not already done) — the leaderboard and streak sync will error against the live
   database until you do (caught gracefully — no crash — but the features won't work).
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

**Still needed from you:** apply `supabase/migrations/0003_trending_highlights.sql` — until you
do, `trendingHighlightsProvider` will surface an error from the RPC call for signed-in users
(caught by the `AsyncValue.error` branch, so it just shows no trending cards rather than
crashing, but you won't see the feature until the migration is applied).

---

## 2026-09-18 — fix pass summary

All 18 findings below were addressed in-repo where that was possible from a code-only session
(no live Supabase credentials, no Sentry account — see the two 🟡 items). `flutter analyze` is
clean and `flutter test` passes (9 tests) as of this pass.

**You still need to do two things by hand:**
1. **Apply the SQL in `supabase/migrations/`** (see `supabase/README.md`) — this is the actual
   security fix for #1/#2/#4, and the schema change #9 depends on. The code changes alone are
   defense-in-depth; nothing is enforced server-side until you run these.
2. **Decide when to do the deferred major dependency upgrades** (#15) — go_router, riverpod,
   and flutter_local_notifications are still behind by design (see below); you chose to defer
   these as a separate, deliberate pass rather than bundle breaking changes into this one.

---

## Your original question: "the book layout is different every time I start a new day"

Traced end-to-end (`daily_screen.dart` → `chapter_utils.dart#getChaptersForDay` →
`bible_sections.dart`). **This part is working as designed, not a bug**: the Horner method
assigns one chapter per day from each of 10 book lists, and each list is a different total
length, so they cycle at different rates — the exact book/chapter combination is different
every day by definition of the method itself. This is now locked in by `test/chapter_utils_test.dart`.

What *was* real, and adjacent to what you noticed, both now fixed in code (#9, #10 below):
- Per-chapter "read" checkmarks now sync to Supabase for signed-in users instead of living only
  in local device storage — once you've applied `supabase/migrations/0002_chapter_progress.sql`.
- Resetting book groups to defaults now actually saves the defaults, not an empty row.

---

## Security findings

### 1. 🟡 CRITICAL — IDOR on verse highlight deletion
**File:** `lib/services/verse_highlight_service.dart`.
**Code fix applied:** `remove(id)` now also filters `.eq('user_id', userId)` client-side.
**Still needed from you:** this is defense-in-depth only — the real boundary is the RLS policy
in `supabase/migrations/0001_rls_policies.sql`, **which is not yet applied to your live
database**. Apply it (see `supabase/README.md`) to actually close this.

### 2. 🟢 HIGH — Cross-user verse highlight exposure, undisclosed
**Files:** `lib/services/verse_highlight_service.dart`, `lib/providers/verse_highlights_provider.dart`.
**Decision (yours):** made private — highlights are scoped to their owner.
**Code fix applied:** `fetchForDay(day)` now also filters `.eq('user_id', userId)` and returns
`[]` if no user is signed in, instead of returning every user's highlights for that day.

### 3. 🟢 HIGH — Optimistic local writes with no rollback on backend failure
**Files:** `lib/providers/book_groups_provider.dart`, `lib/providers/reading_plan_provider.dart`,
`lib/providers/chapter_progress_provider.dart`.
**Fix applied:** every mutating method now wraps its persistence call in `try/catch`, rolls
`state` back to the pre-edit value on failure, and rethrows so the calling screen can show an
error. Screens (`book_groups_screen.dart`, `settings_screen.dart`, `daily_screen.dart`) now
catch those and show a SnackBar instead of silently reverting on next launch.

### 4. 🟡 MEDIUM — Row Level Security is the entire security boundary and is unauditable here
**Fix applied:** `supabase/migrations/0001_rls_policies.sql` and `0002_chapter_progress.sql` now
version-control the intended RLS policies for `reading_plans`, `book_groups`,
`verse_highlights`, and the new `chapter_progress` table.
**Still needed from you:** these files describe intended policy, written from how the Dart
client queries each table — **verify the actual column names in the Supabase dashboard match**
before applying, then apply them (see `supabase/README.md`). Until you do, #1's client-side
filter is the only thing standing between a modified client and another user's data.

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
**Still needed from you:** apply `supabase/migrations/0002_chapter_progress.sql` — the table
doesn't exist in your live database yet, so signed-in chapter toggles will error until you do.

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

1. **Apply `supabase/migrations/0001_rls_policies.sql` and `0002_chapter_progress.sql`** — see
   `supabase/README.md`. Nothing above is actually enforced server-side until you do this, and
   signed-in chapter-progress sync will error without the new table.
2. **Create a Sentry project and set `SENTRY_DSN`** whenever you're ready for crash reporting.
3. **Schedule the deferred major dependency upgrades** (#15) as their own pass.
4. Run the app on a real device/simulator and click through it once — none of this session's
   fixes were verified against a running app (no Supabase credentials were available to do so).

---
*Audit performed and fix pass completed 2026-09-18. Re-run this pass after major changes and
update statuses above rather than starting a new log file.*
