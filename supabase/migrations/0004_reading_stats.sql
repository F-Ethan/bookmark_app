-- Reading-streak stats and opt-in leaderboard support.
--
-- Adds streak/highest-day columns directly to reading_plans (reuses its
-- existing owner-only RLS from 0001_rls_policies.sql — no new table needed
-- for storage), plus leaderboard opt-in fields kept deliberately separate
-- from `name` (which may be the user's real name and stays private).
--
-- get_leaderboard mirrors the SECURITY DEFINER pattern from
-- 0003_trending_highlights.sql: it aggregates across all users but only
-- ever returns what someone explicitly opted in to share — a chosen
-- display name and two counts. Never a user_id, real name, or email.
--
-- Apply via the Supabase SQL editor, or `supabase db push` (see supabase/README.md).

alter table public.reading_plans
  add column if not exists current_streak integer not null default 0,
  add column if not exists longest_streak integer not null default 0,
  add column if not exists highest_day_reached integer not null default 0,
  add column if not exists last_active_date date,
  add column if not exists leaderboard_opt_in boolean not null default false,
  add column if not exists leaderboard_display_name text;

create or replace function public.get_leaderboard(
  p_sort_by text default 'longest_streak', -- 'longest_streak' | 'highest_day_reached'
  p_limit integer default 50
)
returns table (
  display_name text,
  current_streak integer,
  longest_streak integer,
  highest_day_reached integer,
  is_me boolean
)
language sql
security definer
set search_path = public
stable
as $$
  select
    leaderboard_display_name as display_name,
    current_streak,
    longest_streak,
    highest_day_reached,
    user_id = auth.uid() as is_me
  from public.reading_plans
  where leaderboard_opt_in = true and leaderboard_display_name is not null
  order by
    case when p_sort_by = 'highest_day_reached'
      then highest_day_reached
      else longest_streak
    end desc
  limit greatest(p_limit, 0);
$$;

-- p_sort_by only ever selects between two hardcoded columns via CASE above —
-- never interpolated into SQL — so this is safe against injection regardless
-- of what a caller passes.

revoke all on function public.get_leaderboard(text, integer) from public;
grant execute on function public.get_leaderboard(text, integer) to authenticated;
