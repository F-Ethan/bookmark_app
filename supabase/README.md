# Supabase migrations

Versioned SQL for the Supabase project this app talks to (see `lib/core/constants/app_constants.dart`
for the project URL). These files did not exist before 2026-09-18's security audit — see
`PROGRESS.md` #1, #4, and #9 for why each one exists.

## Applying

None of these have been applied to the live project yet — apply them yourself via one of:

**Supabase SQL editor** (simplest): open the project dashboard → SQL Editor, paste the contents
of each file in numeric order, run.

**Supabase CLI**, if you link this repo to the project:
```bash
supabase login
supabase link --project-ref <your-project-ref>
supabase db push
```

## Files

- `0001_rls_policies.sql` — enables Row Level Security and adds owner-only
  policies on `reading_plans`, `book_groups`, and `verse_highlights`. **Check
  the column names in the "Verify before relying on this file" note inside it
  against your actual schema before applying** — this was written from how the
  Dart client queries these tables, not from a direct look at the live schema.
- `0002_chapter_progress.sql` — creates the new `chapter_progress` table that
  `lib/services/supabase_service.dart` now reads/writes for signed-in users,
  with the same owner-only RLS policy pattern.
- `0003_trending_highlights.sql` — adds a `SECURITY DEFINER` function,
  `get_trending_highlights`, that returns anonymized counts of how many
  distinct users highlighted each verse in a given set of chapters. It backs
  the home screen's Highlights carousel (own highlights first, then "N people
  also highlighted this"). It never returns a `user_id` or any other
  per-user identity — only a verse reference, its (public-domain) text, and
  a count — so it's safe to grant `authenticated` users execute access even
  though the underlying `verse_highlights` table stays owner-only.
- `0004_reading_stats.sql` — adds streak/highest-day columns directly to
  `reading_plans` (reuses its existing owner-only RLS — no new table for
  storage) plus opt-in leaderboard fields (`leaderboard_opt_in`,
  `leaderboard_display_name`, kept separate from the private `name` column).
  Also adds `get_leaderboard`, a `SECURITY DEFINER` function following the
  same pattern as `get_trending_highlights` — it only ever returns a chosen
  display name and stats for users who explicitly opted in, never a
  `user_id`, real name, or email.
- `0005_supporters.sql` — creates the `supporters` table backing the
  Supporters screen. Publicly readable (including by guests/anon — it's not
  sensitive data); no insert/update/delete policy for any client role, so
  entries are managed only via the Supabase dashboard table editor, by
  design (see the file's own comment).

## Keeping this in sync

Going forward, whenever you change RLS policies or table shape in the Supabase
dashboard, add a new numbered migration file here describing the change,
rather than leaving the dashboard as the only record — that's the whole point
of this folder (see PROGRESS.md #4).
