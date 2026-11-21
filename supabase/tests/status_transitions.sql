-- Run after the migration. Raises if a transition rule is wrong.
do $$
begin
  if not public.can_transition('draft', 'published') then
    raise exception 'draft should publish';
  end if;
  if public.can_transition('draft', 'completed') then
    raise exception 'draft must not jump to completed';
  end if;
  if not public.can_transition('published', 'assigned') then
    raise exception 'published should assign';
  end if;
  if not public.can_transition('assigned', 'on_the_way') then
    raise exception 'assigned should go on the way';
  end if;
  if not public.can_transition('on_the_way', 'in_progress') then
    raise exception 'on the way should start collection';
  end if;
  if not public.can_transition('in_progress', 'completed') then
    raise exception 'in progress should complete';
  end if;
  if not public.can_transition('published', 'delayed') then
    raise exception 'published should allow delay';
  end if;
  if not public.can_transition('delayed', 'assigned') then
    raise exception 'delayed should return to the main path';
  end if;
  if public.can_transition('completed', 'published') then
    raise exception 'completed is terminal';
  end if;
  if public.can_transition('cancelled', 'published') then
    raise exception 'cancelled is terminal';
  end if;
  if public.can_transition('draft', 'on_the_way') then
    raise exception 'draft must not skip publish';
  end if;
end $$;
