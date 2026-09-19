-- Anonymized "trending highlights" aggregate, backing the redesigned home
-- screen Highlights carousel (own highlights first, then popular ones from
-- the wider community).
--
-- Why SECURITY DEFINER: verse_highlights has owner-only RLS (see
-- 0001_rls_policies.sql) so any one user can only ever SELECT their own
-- rows directly. This function runs with elevated privilege to aggregate
-- across *all* users' rows, but only ever returns a count and public-domain
-- Bible text — never a user_id, never which specific user highlighted
-- something. No caller can use this to enumerate other users' data.
--
-- Restricted to verses within the chapters the caller passes in (their
-- current day's reading), not a global leaderboard — see
-- lib/providers/verse_highlights_provider.dart for why (different users can
-- have different book-group layouts, so "day 5" isn't the same content for
-- everyone; matching on actual chapters is what makes this comparable).
--
-- Apply via the Supabase SQL editor, or `supabase db push` (see supabase/README.md).

create or replace function public.get_trending_highlights(
  p_chapters jsonb,
  p_limit integer default 5
)
returns table (
  book text,
  chapter integer,
  verse integer,
  verse_text text,
  translation text,
  highlight_count bigint
)
language sql
security definer
set search_path = public
stable
as $$
  select
    vh.book,
    vh.chapter,
    vh.verse,
    (array_agg(vh.verse_text order by vh.created_at desc))[1] as verse_text,
    (array_agg(vh.translation order by vh.created_at desc))[1] as translation,
    count(distinct vh.user_id) as highlight_count
  from public.verse_highlights vh
  join lateral jsonb_to_recordset(p_chapters) as c(book text, chapter integer)
    on vh.book = c.book and vh.chapter = c.chapter
  group by vh.book, vh.chapter, vh.verse
  order by highlight_count desc, max(vh.created_at) desc
  limit greatest(p_limit, 0);
$$;

-- Only signed-in users can call this — guests have no community data anyway
-- (see LocalDataService, which never contributes to this table).
revoke all on function public.get_trending_highlights(jsonb, integer) from public;
grant execute on function public.get_trending_highlights(jsonb, integer) to authenticated;
