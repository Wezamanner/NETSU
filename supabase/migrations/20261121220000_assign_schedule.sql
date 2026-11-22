-- Assign or reassign the truck and workers of an existing schedule in one transaction.
create or replace function public.assign_schedule(
  target_schedule uuid,
  next_truck uuid default null,
  next_workers uuid[] default '{}',
  reason text default null,
  mark_assigned boolean default false
)
returns public.collection_schedules
language plpgsql
security definer
set search_path = public
as $$
declare
  current_row public.collection_schedules;
  truck_row public.trucks;
  clean_reason text := nullif(trim(coalesce(reason, '')), '');
  wanted uuid[] := coalesce((select array_agg(distinct w) from unnest(coalesce(next_workers, '{}')) w where w is not null), '{}');
  previous_workers uuid[];
  added uuid[];
  removed uuid[];
  valid_count integer;
  area_label text;
  when_label text;
  person record;
  v_title text;
  v_msg text;
begin
  if public.auth_role() <> 'admin' then
    raise exception 'Administrator access is required';
  end if;

  select * into current_row
  from public.collection_schedules
  where id = target_schedule
  for update;

  if not found then
    raise exception 'Schedule not found';
  end if;

  if current_row.status in ('completed', 'cancelled') then
    raise exception 'Completed or cancelled schedules cannot be reassigned';
  end if;

  if current_row.status in ('assigned', 'on_the_way', 'in_progress') and cardinality(wanted) = 0 then
    raise exception 'At least one worker must stay assigned while the schedule is %', current_row.status;
  end if;

  if mark_assigned and cardinality(wanted) = 0 then
    raise exception 'Select at least one worker to mark the schedule assigned';
  end if;

  if next_truck is not null then
    select * into truck_row from public.trucks where id = next_truck;
    if not found then
      raise exception 'Truck not found';
    end if;
    if truck_row.maintenance = 'in_maintenance' then
      raise exception 'Truck % is in maintenance', truck_row.plate_number;
    end if;
    if truck_row.availability = 'unavailable' and next_truck is distinct from current_row.truck_id then
      raise exception 'Truck % is unavailable', truck_row.plate_number;
    end if;
  end if;

  select count(*) into valid_count
  from public.profiles
  where id = any(wanted) and role = 'worker' and active = true;
  if valid_count <> cardinality(wanted) then
    raise exception 'Only active worker accounts can be assigned';
  end if;

  select coalesce(array_agg(worker_id order by worker_id), '{}') into previous_workers
  from public.schedule_workers
  where schedule_id = current_row.id;

  select coalesce(array_agg(w), '{}') into added
  from unnest(wanted) w where not (w = any(previous_workers));
  select coalesce(array_agg(w), '{}') into removed
  from unnest(previous_workers) w where not (w = any(wanted));

  if next_truck is not distinct from current_row.truck_id
     and cardinality(added) = 0 and cardinality(removed) = 0
     and not (mark_assigned and current_row.status = 'published') then
    return current_row;
  end if;

  insert into public.schedule_history (schedule_id, changed_by, action, previous, "new", reason)
  values (
    current_row.id,
    auth.uid(),
    'assignment',
    jsonb_build_object('truck_id', current_row.truck_id, 'worker_ids', to_jsonb(previous_workers)),
    jsonb_build_object('truck_id', next_truck, 'worker_ids', to_jsonb(wanted)),
    clean_reason
  );

  delete from public.schedule_workers
  where schedule_id = current_row.id and worker_id = any(removed);

  insert into public.schedule_workers (schedule_id, worker_id)
  select current_row.id, w from unnest(added) w
  on conflict do nothing;

  update public.collection_schedules
  set truck_id = next_truck,
      updated_by = auth.uid()
  where id = current_row.id
  returning * into current_row;

  -- Tell affected workers. Drafts are not yet visible work, so only notify once published.
  if current_row.status <> 'draft' then
    select format('%s — %s', kebele_code, name) into area_label
    from public.service_areas where id = current_row.area_id;
    when_label := to_char(current_row.expected_start at time zone 'Africa/Addis_Ababa', 'YYYY-MM-DD HH24:MI');

    for person in
      select p.id, p.preferred_language, (p.id = any(added)) as is_added
      from public.profiles p
      where p.id = any(array_cat(added, removed)) and p.active = true
    loop
      if person.is_added then
        if person.preferred_language = 'am' then
          v_title := 'አዲስ የስብሰባ ምደባ';
          v_msg := format('ለ %s የቆሻሻ ስብሰባ ተመድበዋል። የሚጠበቀው ሰዓት፦ %s።', area_label, when_label);
        elsif person.preferred_language = 'om' then
          v_title := 'Ramaddii walitti qabuu haaraa';
          v_msg := format('Walitti qabuu xurii %s irratti ramadamtaniittu. Yeroo eegamu: %s.', area_label, when_label);
        else
          v_title := 'New collection assignment';
          v_msg := format('You have been assigned to garbage collection in %s. Expected time: %s.', area_label, when_label);
        end if;
      else
        if person.preferred_language = 'am' then
          v_title := 'ምደባ ተነስቷል';
          v_msg := format('ከ %s የቆሻሻ ስብሰባ (%s) ምደባ ተነስተዋል።', area_label, when_label);
        elsif person.preferred_language = 'om' then
          v_title := 'Ramaddiin kaafameera';
          v_msg := format('Walitti qabuu xurii %s (%s) irraa ramaddiin keessan kaafameera.', area_label, when_label);
        else
          v_title := 'Assignment removed';
          v_msg := format('You are no longer assigned to garbage collection in %s (%s).', area_label, when_label);
        end if;
      end if;

      insert into public.notifications (
        recipient_id, area_id, schedule_id, type, channel, title, message,
        scheduled_send_at, sent_at, delivery_status, schedule_version, dedup_key
      )
      values (
        person.id, current_row.area_id, current_row.id,
        case when person.is_added then 'assignment' else 'unassignment' end,
        'in_app', v_title, v_msg, now(), now(), 'sent', current_row.version,
        format('assign:%s:%s:%s:%s', current_row.id, person.id,
          case when person.is_added then 'add' else 'remove' end,
          extract(epoch from clock_timestamp())::bigint)
      )
      on conflict (dedup_key) do nothing;
    end loop;
  end if;

  if mark_assigned and current_row.status = 'published' then
    current_row := public.update_schedule_status(current_row.id, 'assigned', clean_reason, null);
  end if;

  return current_row;
end;
$$;

revoke all on function public.assign_schedule(uuid, uuid, uuid[], text, boolean) from public;
grant execute on function public.assign_schedule(uuid, uuid, uuid[], text, boolean) to authenticated;

-- Keep trucks.availability in sync with live (published, not finished) schedules.
-- Trucks an admin marked 'unavailable' or that are in maintenance are left untouched.
create or replace function public.refresh_truck_availability(target_truck uuid)
returns void
language sql
security definer
set search_path = public
as $$
  update public.trucks t
  set availability = case
    when exists (
      select 1 from public.collection_schedules s
      where s.truck_id = t.id
        and s.status not in ('draft', 'completed', 'cancelled')
    ) then 'assigned'::public.truck_availability
    else 'available'::public.truck_availability
  end
  where t.id = target_truck
    and t.availability <> 'unavailable'
    and t.maintenance = 'ok'
$$;

revoke all on function public.refresh_truck_availability(uuid) from public, anon, authenticated;

create or replace function public.sync_truck_availability()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op in ('UPDATE', 'DELETE') and old.truck_id is not null then
    perform public.refresh_truck_availability(old.truck_id);
  end if;
  if tg_op in ('INSERT', 'UPDATE') and new.truck_id is not null
     and (tg_op = 'INSERT' or new.truck_id is distinct from old.truck_id or new.status is distinct from old.status) then
    perform public.refresh_truck_availability(new.truck_id);
  end if;
  return coalesce(new, old);
end;
$$;

drop trigger if exists collection_schedules_sync_truck on public.collection_schedules;
create trigger collection_schedules_sync_truck
after insert or update of truck_id, status or delete on public.collection_schedules
for each row execute function public.sync_truck_availability();

-- Tell a worker in-app when a garbage report is assigned to them.
create or replace function public.notify_report_assignment()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_lang text;
  v_title text;
  v_msg text;
  v_place text := coalesce(nullif(trim(coalesce(new.address, '')), ''), (select name from public.service_areas where id = new.area_id), '');
begin
  if new.assigned_worker_id is null or new.assigned_worker_id is not distinct from old.assigned_worker_id then
    return new;
  end if;

  select preferred_language into v_lang
  from public.profiles
  where id = new.assigned_worker_id and role = 'worker' and active = true;
  if not found then
    return new;
  end if;

  if v_lang = 'am' then
    v_title := 'አዲስ የቆሻሻ ሪፖርት ተመድቦልዎታል';
    v_msg := format('ያልተሰበሰበ ቆሻሻ ሪፖርት ተመድቦልዎታል፦ %s።', v_place);
  elsif v_lang = 'om' then
    v_title := 'Gabaasni xurii haaraan isiniif ramadameera';
    v_msg := format('Gabaasni xurii hin funaanamne isiniif ramadameera: %s.', v_place);
  else
    v_title := 'New garbage report assigned';
    v_msg := format('An uncollected garbage report has been assigned to you: %s.', v_place);
  end if;

  insert into public.notifications (
    recipient_id, area_id, schedule_id, type, channel,
    title, message, scheduled_send_at, sent_at, delivery_status, dedup_key
  )
  values (
    new.assigned_worker_id, new.area_id, null, 'report_assignment', 'in_app',
    v_title, v_msg, now(), now(), 'sent',
    format('report-assign:%s:%s:%s', new.id, new.assigned_worker_id, extract(epoch from clock_timestamp())::bigint)
  )
  on conflict (dedup_key) do nothing;

  return new;
end;
$$;

drop trigger if exists garbage_reports_notify_assignment on public.garbage_reports;
create trigger garbage_reports_notify_assignment
after update of assigned_worker_id on public.garbage_reports
for each row execute function public.notify_report_assignment();

-- Backfill current availability.
select public.refresh_truck_availability(id) from public.trucks;
