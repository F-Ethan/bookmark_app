-- Supporters (Patreon backers), credited in-app.
--
-- Rows are managed directly via the Supabase dashboard table editor by the
-- app owner — deliberately no insert/update/delete policy for any client
-- role, so nothing in the app itself can write to this table.
--
-- Apply via the Supabase SQL editor, or `supabase db push` (see supabase/README.md).

create table if not exists public.supporters (
  id uuid primary key default gen_random_uuid(),
  display_name text not null,
  logo_url text,
  link_url text,
  tier text,               -- e.g. 'monthly' | 'one_time' — free-form, display-only
  active boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

alter table public.supporters enable row level security;

drop policy if exists "supporters_select_active" on public.supporters;
create policy "supporters_select_active" on public.supporters
  for select using (active = true);

-- Readable by anyone, including guests — a supporters list isn't sensitive.
grant select on public.supporters to anon, authenticated;
