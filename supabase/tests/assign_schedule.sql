-- assign_schedule checks against the seeded database (non-destructive transaction).
begin;

set local role authenticated;
set local request.jwt.claims = '{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated"}';

do $$
declare
  s public.collection_schedules;
  n integer;
begin
  -- Assign both workers and the truck to the Kebele 01 schedule and mark it assigned.
  s := public.assign_schedule(
    'dddddddd-dddd-4ddd-8ddd-ddddddddddd2',
    'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb1',
    array['22222222-2222-4222-8222-222222222221', '22222222-2222-4222-8222-222222222222']::uuid[],
    null,
    true
  );
  if s.status <> 'assigned' then raise exception 'expected assigned, got %', s.status; end if;
  if s.truck_id is distinct from 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb1' then raise exception 'truck not set'; end if;

  select count(*) into n from public.schedule_workers where schedule_id = s.id;
  if n <> 2 then raise exception 'expected 2 workers, got %', n; end if;

  select count(*) into n from public.schedule_history where schedule_id = s.id and action = 'assignment';
  if n <> 1 then raise exception 'assignment history missing'; end if;

  select count(*) into n from public.notifications where schedule_id = s.id and type = 'assignment';
  if n <> 2 then raise exception 'expected 2 assignment notices, got %', n; end if;

  if (select availability from public.trucks where id = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb1') <> 'assigned' then
    raise exception 'truck availability not synced';
  end if;

  -- Remove one worker: the removed worker is told, the remaining one is kept.
  s := public.assign_schedule(s.id, s.truck_id, array['22222222-2222-4222-8222-222222222221']::uuid[], 'Swap crew', false);
  select count(*) into n from public.notifications where schedule_id = s.id and type = 'unassignment';
  if n <> 1 then raise exception 'expected 1 unassignment notice, got %', n; end if;

  -- An assigned schedule cannot be left without workers.
  begin
    perform public.assign_schedule(s.id, null, '{}'::uuid[], null, false);
    raise exception 'empty crew should be rejected';
  exception when others then
    if sqlerrm not like 'At least one worker%' then raise; end if;
  end;

  -- Residents and admins cannot be assigned as workers.
  begin
    perform public.assign_schedule(s.id, null, array['11111111-1111-4111-8111-111111111111']::uuid[], null, false);
    raise exception 'non-worker should be rejected';
  exception when others then
    if sqlerrm not like 'Only active worker%' then raise; end if;
  end;
end $$;

-- Non-admins (here a worker) cannot call assign_schedule.
set local request.jwt.claims = '{"sub":"22222222-2222-4222-8222-222222222221","role":"authenticated"}';
do $$
begin
  perform public.assign_schedule('dddddddd-dddd-4ddd-8ddd-ddddddddddd1', null, '{}'::uuid[], null, false);
  raise exception 'worker must not assign schedules';
exception when others then
  if sqlerrm not like 'Administrator access%' then raise; end if;
end $$;

rollback;
