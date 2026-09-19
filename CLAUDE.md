# CLAUDE.md

Guidance for Claude Code (or any future contributor) working in this repository.

## What this app is

**Bookmark** (package name `bookmark_new`) is a Flutter Bible-reading tracker built around
the **Horner Bible reading method**: each day the user reads one chapter from each of 10
independent book "lists" (`lib/data/bible_sections.dart`). Because each list has a different
total chapter count, they cycle at different rates — seeing a different book/chapter
combination every day is **expected behavior**, not a bug (locked in by
`test/chapter_utils_test.dart`). The app also tracks a reading **streak** and **highest day
reached** (`lib/utils/streak_utils.dart`) — see "Community features" below.

The app supports two usage modes:
- **Signed-in** — data lives in Supabase (Postgres + Auth).
- **Guest** — data lives entirely in on-device `SharedPreferences`, never leaves the phone.

## Architecture

- **State management**: `flutter_riverpod` (2.x). Providers live in `lib/providers/`, almost
  all as `AsyncNotifier` subclasses that branch on `guestModeProvider` to pick a backend.
- **Routing**: `go_router`, single source of truth in `lib/core/router/router.dart`. Auth
  gating happens in the `redirect:` callback (checks `Supabase.instance.client.auth.currentUser`
  and `guestModeProvider`), not per-screen.
- **Backend**: Supabase. All Postgres access is centralized in
  `lib/services/supabase_service.dart` (reading plans, book groups) and
  `lib/services/verse_highlight_service.dart` (highlights) — both static-method service
  classes, no repository/DI layer.
- **Local storage**: `lib/services/local_data_service.dart` mirrors `SupabaseService`'s API
  for guest mode. `lib/services/shared_prefs_service.dart` is scoped to device-local
  notification prefs only.
- **Bible text**: a single bundled KJV JSON asset (`assets/bibles/en_kjv.json`, ~4.3MB) is
  parsed into memory at startup by `lib/services/bible_service.dart`.

## The dual-mode storage pattern — follow it exactly

Every provider that touches user data (`reading_plan_provider.dart`,
`book_groups_provider.dart`, `chapter_progress_provider.dart`) follows this shape:

```dart
if (ref.read(guestModeProvider)) {
  await LocalDataService.someMethod(...);
} else {
  await SupabaseService.someMethod(...);
}
```

**When adding any new piece of user-facing state, both branches must be implemented and
kept in sync.** Mutating methods should also roll `state` back to its pre-edit value and
rethrow if the persistence call fails (see `book_groups_provider.dart`'s `_applyAndSave` for
the pattern) — otherwise the UI can show an edit as saved when it wasn't. See `PROGRESS.md`
#3 for why this matters.

## Security boundary: RLS, not the client

The Supabase anon key in `app_constants.dart` is public by design — **every** access-control
decision (who can read/write which row) must be enforced by Postgres Row Level Security
policies, not by the client only sending scoped queries. Those policies are version-controlled
in `supabase/migrations/` — read `supabase/README.md` before changing any table's shape or
assuming a query is "private" just because the Dart code filters it. If you add a new table
that stores per-user data, add an RLS migration for it in the same PR.

**Anonymized aggregate pattern**: when a feature needs to show something derived from *all*
users' data (not just the caller's own), don't relax RLS on the underlying table — write a
`SECURITY DEFINER` Postgres function that aggregates internally but only ever returns the
specific, non-identifying fields the feature needs. Two examples to copy from:
`get_trending_highlights` (`0003_trending_highlights.sql`, verse highlight counts) and
`get_leaderboard` (`0004_reading_stats.sql`, opt-in streak rankings) — both return counts/opted-
in display data only, never a `user_id`, real name, or email.

## Community features

`lib/screens/leaderboard_screen.dart` and `lib/screens/supporters_screen.dart` are opt-in/
public-facing: the leaderboard only ever shows what a user explicitly opted in to share (a
chosen `leaderboard_display_name`, kept separate from the private `name` field, plus streak
stats) via `get_leaderboard`. Supporters is a read-only credit list — that table has no client
write policy at all; rows are added by hand via the Supabase dashboard. Both are documented in
`PROGRESS.md`'s 2026-09-19 entry, along with the `docs/policies.md` draft that's meant to be
handed off to the user's separate `gamelogic` repo for publishing at
`gamelogic.dev/bookmark/privacy-policy` — don't try to host it from this repo. As of 2026-09-19
the live page there is a generic/boilerplate policy that doesn't yet reflect this app's actual
Leaderboard/Supporters/highlights content — see `PROGRESS.md`'s 2026-09-19 entry.

## Dev setup

```bash
flutter pub get --dart-define-from-file=dart_defines/dev.json
flutter run --dart-define-from-file=dart_defines/dev.json
```

`dart_defines/dev.json` holds `SUPABASE_URL` / `SUPABASE_ANON_KEY` / `SENTRY_DSN` and is
gitignored — ask the project owner for a copy rather than recreating it. Do not remove the
gitignore entry. Note `lib/core/constants/app_constants.dart` also bakes the Supabase values
in as `String.fromEnvironment` **default values**, so they end up in every committed build
regardless of the dart-define file — this is normal for a Supabase anon/publishable key
(app security relies on server-side Row Level Security, not on hiding this key), but never
add a *service-role* or other privileged key this way. `SENTRY_DSN` defaults to empty, which
disables Sentry entirely — see `PROGRESS.md` #14.

## CI and tests

`.github/workflows/ci.yml` runs `flutter analyze` and `flutter test` on every push/PR to
`main`. `flutter analyze` is clean and the test suite (`test/chapter_utils_test.dart`,
`test/book_groups_provider_test.dart`, `test/streak_utils_test.dart`, `test/widget_test.dart`)
passes — keep both green; don't merge past a red CI run.

## Full audit

See `PROGRESS.md` for the complete security and code-quality audit and fix log (dated
2026-09-18). Most findings were fixed in that pass; a few need action outside this repo —
most importantly, **the RLS migrations in `supabase/migrations/` are not yet applied to the
live database** (see `supabase/README.md`). Until they are, the client-side ownership checks
in `verse_highlight_service.dart` are defense-in-depth only, not the real security boundary.
