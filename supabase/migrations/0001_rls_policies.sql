-- Row Level Security policies for existing tables.
--
-- Why this file exists: PROGRESS.md #1 (IDOR on verse_highlights delete) and
-- #4 (RLS is the app's entire data-isolation boundary but wasn't
-- version-controlled anywhere). The Supabase anon key shipped in the app is
-- public by design — every access-control decision must be enforced here,
-- server-side, not by the client only sending scoped queries.
--
-- Apply via the Supabase SQL editor, or `supabase db push` if this project
-- is linked (`supabase link --project-ref <ref>`).
--
-- Safe to re-run: each policy is dropped before being recreated.

-- ── reading_plans ────────────────────────────────────────────────────────────
alter table public.reading_plans enable row level security;

-- Live DB (pre-2026-09-19) used a single FOR ALL policy. Postgres ORs
-- overlapping policies, so leaving the old name in place would mean the
-- new owner-only policies do not actually restrict anything.
drop policy if exists "Users manage own plan" on public.reading_plans;

drop policy if exists "reading_plans_select_own" on public.reading_plans;
create policy "reading_plans_select_own" on public.reading_plans
  for select using (auth.uid() = user_id);

drop policy if exists "reading_plans_insert_own" on public.reading_plans;
create policy "reading_plans_insert_own" on public.reading_plans
  for insert with check (auth.uid() = user_id);

drop policy if exists "reading_plans_update_own" on public.reading_plans;
create policy "reading_plans_update_own" on public.reading_plans
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "reading_plans_delete_own" on public.reading_plans;
create policy "reading_plans_delete_own" on public.reading_plans
  for delete using (auth.uid() = user_id);

-- ── book_groups ──────────────────────────────────────────────────────────────
alter table public.book_groups enable row level security;

drop policy if exists "Users manage own groups" on public.book_groups;

drop policy if exists "book_groups_select_own" on public.book_groups;
create policy "book_groups_select_own" on public.book_groups
  for select using (auth.uid() = user_id);

drop policy if exists "book_groups_insert_own" on public.book_groups;
create policy "book_groups_insert_own" on public.book_groups
  for insert with check (auth.uid() = user_id);

drop policy if exists "book_groups_update_own" on public.book_groups;
create policy "book_groups_update_own" on public.book_groups
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "book_groups_delete_own" on public.book_groups;
create policy "book_groups_delete_own" on public.book_groups
  for delete using (auth.uid() = user_id);

-- ── verse_highlights ─────────────────────────────────────────────────────────
-- This is the table behind PROGRESS.md #1 (IDOR) and #2 (cross-user
-- exposure). The app now only ever queries/deletes its own rows
-- (verse_highlight_service.dart), but that's client-side behavior — these
-- policies are the actual enforcement boundary.
alter table public.verse_highlights enable row level security;

-- The live SELECT was "Authenticated users can read all highlights".
-- Leaving it would OR with verse_highlights_select_own and keep the
-- cross-user leak even after this file is applied.
drop policy if exists "Authenticated users can read all highlights" on public.verse_highlights;
drop policy if exists "Users can delete own highlights" on public.verse_highlights;
drop policy if exists "Users can insert own highlights" on public.verse_highlights;

drop policy if exists "verse_highlights_select_own" on public.verse_highlights;
create policy "verse_highlights_select_own" on public.verse_highlights
  for select using (auth.uid() = user_id);

drop policy if exists "verse_highlights_insert_own" on public.verse_highlights;
create policy "verse_highlights_insert_own" on public.verse_highlights
  for insert with check (auth.uid() = user_id);

drop policy if exists "verse_highlights_update_own" on public.verse_highlights;
create policy "verse_highlights_update_own" on public.verse_highlights
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "verse_highlights_delete_own" on public.verse_highlights;
create policy "verse_highlights_delete_own" on public.verse_highlights
  for delete using (auth.uid() = user_id);

-- ── Verify before relying on this file ──────────────────────────────────────
-- This migration assumes each table already has a `user_id uuid` column
-- referencing auth.users(id), matching what lib/services/supabase_service.dart
-- and lib/services/verse_highlight_service.dart read/write today. Check your
-- actual column names/types in the Supabase dashboard before applying — if
-- they differ, adjust the `user_id` references above to match.
