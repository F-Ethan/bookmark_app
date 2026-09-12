# Bookmark — Agent working rules

Bookmark is a Flutter app for Professor Grant Horner's ten-list Bible reading system. Users track a daily ten-chapter plan, read chapters in-app, highlight verses, and customize book groups.

This file is the source of truth for coding agents (Claude Code, Cursor, and others). Do not invent a second rules file unless the repo already uses that convention.

## Working process

These rules are mandatory. Do not work around them.

1. **Never work or push to `main`.** Do not commit on `main`, rebase onto `main` in place, or push to `origin/main`. Create a feature branch first (`git checkout -b …` from an up-to-date `main`).
2. **Every new feature is a branch + pull request.** Bug fixes, refactors, and docs changes follow the same path. Do not land work by committing directly to `main` or `dev`.
3. **Document out-of-scope issues explicitly.** If you discover a bug, stale test, missing migration, or incomplete feature that is not part of the current task, add it to the **Known gaps** section in `PROGRESS.md`. Do not silently ignore it, and do not expand scope to fix it unless the user asked.
4. **Shipped features use real backend and device storage.** Signed-in flows must read and write Supabase (Auth, Postgres, Storage). Guest and device-preference flows must use real SharedPreferences / on-device files. Never ship mock, fixture, or hardcoded sample data as the live data source. Mocks and `SharedPreferences.setMockInitialValues` are fine in `test/` only.

## Stack

| Layer | Choice |
| --- | --- |
| App | Flutter (Dart SDK `^3.9.2`), package name `bookmark_new` |
| State | Riverpod (`flutter_riverpod`) — `Notifier` / `AsyncNotifier` |
| Routing | `go_router` via `routerProvider` |
| Auth + cloud DB | Supabase (`supabase_flutter`) — email/password Auth, Postgres, Storage |
| Guest / device prefs | `shared_preferences` |
| HTTP | `dio` (Bible translation downloads) |
| Notifications | `flutter_local_notifications` + `timezone` |
| Fonts | `google_fonts` (reader appearance) |
| UI | Material 3, tokens in `lib/core/theme/app_theme.dart` |

Platform folders (`android/`, `ios/`, `macos/`, `linux/`, `windows/`, `web/`) are the standard Flutter embeddings. Daily development has been iOS-first; keep Android and other targets building when you touch platform code.

## Layout

```
lib/
  main.dart                 # Supabase + notifications + BibleService init, ProviderScope
  core/
    constants/              # dart-define Supabase URL / anon key
    router/router.dart      # auth/guest redirects and routes
    theme/app_theme.dart
    utils/supabase_error.dart
  data/bible_sections.dart  # Horner lists, ordered lists, allBibleBooks
  models/                   # ReadingPlan, BibleGroup/BibleBook, VerseHighlight
  providers/                # Riverpod notifiers (auth, plan, groups, highlights, …)
  screens/                  # UI, including screens/auth/
  services/                 # Supabase, local guest storage, Bible text, highlights, notifications
  utils/chapter_utils.dart  # Day → chapter resolution for a plan
assets/bibles/en_kjv.json   # Bundled KJV (copied to app documents on first load)
test/                       # flutter_test only
```

Routes (see `lib/core/router/router.dart`):

| Path | Screen |
| --- | --- |
| `/sign-in`, `/sign-up` | Auth |
| `/onboarding` | First-time plan setup |
| `/` | Home |
| `/daily` | Today's (and nearby) readings |
| `/bookgroups` | Edit Horner lists |
| `/settings` | Profile, appearance, translation, notifications, account |
| `/reader` | In-app chapter reader (`ReaderArgs` via `state.extra`) |
| `/bible` | Free-read book/chapter picker |

Unauthenticated users are redirected to `/sign-in` unless they entered guest mode. Logged-in users are kept off the auth screens. Guests may open sign-up to create an account.

## Data layer

Two persistence paths. Providers choose based on `guestModeProvider` and `currentUserProvider`.

### Signed-in (Supabase)

Use `SupabaseService` and `VerseHighlightService` (non-local methods). Tables in use:

- `reading_plans` — one plan per user (`name`, `current_day`, `start_date`)
- `book_groups` — ordered groups; `books` stored as JSON
- `verse_highlights` — saved verses for a reading day

Also used: Supabase Auth, RPC `delete_user`, and public Storage bucket `bibles` for optional translation JSON (e.g. BBE).

Do not bypass these services with inline client calls in widgets except for Auth (`signInWithPassword`, `signUp`) and the Storage download URL already built in `BibleService`.

### Guest mode (on device)

Use `LocalDataService` and `VerseHighlightService` local methods. Data lives in SharedPreferences (`guest_plan_*`, `guest_book_groups`, `guest_verse_highlights`). Guest mode itself is the `guest_mode` bool.

### Device-local even when signed in

These are not cloud-backed today. Keep them on SharedPreferences unless the task is specifically to sync them:

- Appearance (`appearance_*`)
- Selected translation (`bible_translation`)
- Per-day chapter-read ticks (`chapter_read_day_*`)
- Notification enablement and time

### Defaults vs live data

`hornerBookGroups`, `orderedBookGroups`, `defaultBookGroups`, and `allBibleBooks` in `lib/data/bible_sections.dart` are **seed/fallback lists**, not a live user database. Use them to initialize onboarding or to fill an empty fetch. After the user has groups, persist and reload from Supabase (signed-in) or SharedPreferences (guest).

Bundled `assets/bibles/en_kjv.json` is the real KJV text. Extra translations are downloaded to the app documents directory through `BibleService`, not fabricated in UI.

`AppConstants.supabaseUrl` / `supabaseAnonKey` come from `--dart-define` (`SUPABASE_URL`, `SUPABASE_ANON_KEY`). Local launches use `--dart-define-from-file=dart_defines/dev.json` (gitignored). Never commit that file or other secrets.

## Flutter conventions

- Screens are `ConsumerWidget` / `ConsumerStatefulWidget`. Watch providers; do not cache Supabase rows in widget fields as the source of truth.
- Theme: reuse `AppTheme` tokens. Reader typography comes from `appearanceProvider`, not ad-hoc `TextStyle`s.
- Handle `isSupabasePaused` on plan/group loads the same way Home and Daily already do (`SupabasePausedScreen`).
- Routing: `context.go` for top-level tabs/flows, `context.push` when a back stack is needed (`/bible`, `/reader`). Pass reader/browse state through `extra` typed args, not query strings.
- Keep guest and signed-in writes on their existing service split. Do not write guest data into Supabase, or signed-in plan data only into prefs, unless you are implementing an explicit migration the user asked for.

## Tests

- Run `flutter test` and `flutter analyze` for Dart changes.
- Mocks belong in `test/` only.
- `test/widget_test.dart` is currently stale (see `PROGRESS.md`). Update or replace tests that you touch; do not "fix" them by pointing the app at fixture data.

## Commands

```bash
flutter pub get
flutter analyze
flutter test
flutter run --dart-define-from-file=dart_defines/dev.json
```

iOS simulator / Xcode workflows are recorded in `.claude/settings.json` from local Claude Code use. Prefer `flutter` commands unless you are debugging a native build.

## Out of scope

If work is blocked or you find something that is not the assigned task, record it under **Known gaps** in `PROGRESS.md` and stay on the requested change.
