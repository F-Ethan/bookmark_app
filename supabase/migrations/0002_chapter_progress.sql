-- New table backing per-chapter "read" checkmarks for signed-in users.
--
-- Why this file exists: PROGRESS.md #9 — chapter_progress_provider.dart
-- previously stored daily reading checkmarks only in on-device
-- SharedPreferences, even for signed-in users, unlike every other piece of
-- user state in the app. The Dart code (lib/services/supabase_service.dart
-- `fetchChapterProgress` / `setChapterRead`) now expects this table to exist.
--
-- Apply via the Supabase SQL editor, or `supabase db push` if this project
-- is linked.

create table if not exists public.chapter_progress (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  day integer not null,
  chapter_index integer not null,
  created_at timestamptz not null default now(),
  unique (user_id, day, chapter_index)
);

create index if not exists chapter_progress_user_day_idx
  on public.chapter_progress (user_id, day);

alter table public.chapter_progress enable row level security;

drop policy if exists "chapter_progress_select_own" on public.chapter_progress;
create policy "chapter_progress_select_own" on public.chapter_progress
  for select using (auth.uid() = user_id);

drop policy if exists "chapter_progress_insert_own" on public.chapter_progress;
create policy "chapter_progress_insert_own" on public.chapter_progress
  for insert with check (auth.uid() = user_id);

drop policy if exists "chapter_progress_delete_own" on public.chapter_progress;
create policy "chapter_progress_delete_own" on public.chapter_progress
  for delete using (auth.uid() = user_id);
