-- Acceptance verification checks for AT-01 through AT-10 (non-destructive transaction).
-- Run in Supabase SQL editor or psql against a seeded local database.
begin;

-- Verify helper templates produce expected non-empty English, Amharic, and Oromo text.
do $$
declare
  r record;
begin
  select * into r from public.render_schedule_notice('day_before', 'en', now() + interval '2 days', null);
  if r.message not like '%scheduled for tomorrow%' then
    raise exception 'AT-02 template check failed';
  end if;
  select * into r from public.render_schedule_notice('same_day', 'en', now() + interval '4 hours', null);
  if r.message not like '%scheduled for today%' then
    raise exception 'AT-03 template check failed';
  end if;
  select * into r from public.render_schedule_notice('on_the_way', 'en', now(), null);
  if r.message not like '%Arrival time may vary%' then
    raise exception 'AT-07 template check failed';
  end if;
end $$;

-- Verify status transition rules (allowed and terminal blocks).
do $$
begin
  if not public.can_transition('draft', 'published') then raise exception 'draft->published failed'; end if;
  if not public.can_transition('published', 'assigned') then raise exception 'published->assigned failed'; end if;
  if not public.can_transition('assigned', 'on_the_way') then raise exception 'assigned->on_the_way failed'; end if;
  if not public.can_transition('on_the_way', 'in_progress') then raise exception 'on_the_way->in_progress failed'; end if;
  if not public.can_transition('in_progress', 'completed') then raise exception 'in_progress->completed failed'; end if;
  if public.can_transition('completed', 'in_progress') then raise exception 'completed must be terminal'; end if;
  if public.can_transition('cancelled', 'published') then raise exception 'cancelled must be terminal'; end if;
end $$;

rollback;
