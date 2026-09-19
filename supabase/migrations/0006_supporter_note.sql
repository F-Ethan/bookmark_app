-- Editable "note from Ethan" shown at the top of the Supporters screen.
--
-- Singleton row so the note can be changed from the Supabase dashboard table
-- editor without shipping an app update — same dashboard-managed pattern as
-- public.supporters (0005_supporters.sql): deliberately no insert/update/
-- delete policy for any client role.
--
-- Apply via the Supabase SQL editor, or `supabase db push` (see supabase/README.md).

create table if not exists public.supporter_note (
  id smallint primary key default 1,
  note text not null,
  updated_at timestamptz not null default now(),
  constraint supporter_note_singleton check (id = 1)
);

insert into public.supporter_note (id, note)
values (
  1,
  'Bookmark is a personal project I built and maintain myself — thank you for using it! If you''d like to support my work, reach out at'
)
on conflict (id) do nothing;

alter table public.supporter_note enable row level security;

drop policy if exists "supporter_note_select" on public.supporter_note;
create policy "supporter_note_select" on public.supporter_note
  for select using (true);

-- Readable by anyone, including guests — same as the supporters list itself.
grant select on public.supporter_note to anon, authenticated;
