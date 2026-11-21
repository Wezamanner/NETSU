-- Netsu notification engine, reschedule RPC, completion notes, and report status notices.
-- Apply in the Supabase SQL editor after 20261121120000_profiles_and_areas.sql.

-- Allow admins to read all notifications for dashboard delivery metrics.
drop policy if exists "notifications admin read" on public.notifications;
create policy "notifications admin read"
on public.notifications for select to authenticated
using (public.auth_role() = 'admin');

-- Enable Realtime for the in-app notification inbox.
do $$
begin
  alter publication supabase_realtime add table public.notifications;
exception
  when duplicate_object then null;
  when undefined_object then null;
end $$;

-- Format a UTC timestamptz in Africa/Addis_Ababa (UTC+3) for notification templates.
create or replace function public.format_addis_datetime(ts timestamptz)
returns text
language sql
immutable
as $$
  select to_char(ts at time zone 'Africa/Addis_Ababa', 'YYYY-MM-DD HH24:MI') || ' EAT'
$$;

create or replace function public.format_addis_time(ts timestamptz)
returns text
language sql
immutable
as $$
  select to_char(ts at time zone 'Africa/Addis_Ababa', 'HH24:MI') || ' EAT'
$$;

create or replace function public.format_addis_date(ts timestamptz)
returns text
language sql
immutable
as $$
  select to_char(ts at time zone 'Africa/Addis_Ababa', 'YYYY-MM-DD')
$$;

-- Localized notification templates (en / am / om).
-- REVIEW: native speaker — Amharic and Afaan Oromo templates are drafts.
create or replace function public.render_schedule_notice(
  p_type text,
  p_lang text,
  p_expected_start timestamptz,
  p_reason text default null
)
returns table(title text, message text)
language plpgsql
immutable
as $$
declare
  v_time text := public.format_addis_time(p_expected_start);
  v_dt   text := public.format_addis_datetime(p_expected_start);
  v_date text := public.format_addis_date(p_expected_start);
  v_lang text := case when p_lang in ('am', 'om') then p_lang else 'en' end;
begin
  if p_type = 'day_before' then
    if v_lang = 'am' then
      return query select
        'የነገ ቆሻሻ መሰብሰብ ማስታወሻ'::text,
        format('የጅማ ቆሻሻ አስተዳደር፡ በአካባቢዎ የቤት ቆሻሻ መሰብሰብ ነገ በ %s ተይዟል። እባክዎ ቆሻሻዎን አዘጋጅተው መኪናው ከመድረሱ በፊት በተፈቀደው መሰብሰቢያ ቦታ ያስቀምጡ።', v_time);
    elsif v_lang = 'om' then
      return query select
        'Yaadachiisa walitti qabuu boruu'::text,
        format('Bulchiinsa Xurii Jimmaa: Walitti qabuun xurii mana keessaa naannoo keessanitti boru sa’aatii %s irratti karoorfameera. Maaloo xurii qopheessaa bakka eeyyamametti kaa’aa.', v_time);
    else
      return query select
        'Tomorrow''s garbage collection'::text,
        format('Jimma Waste Management: Household garbage collection in your area is scheduled for tomorrow, %s. Please prepare your household garbage and place it at the approved collection point before the truck arrives.', v_time);
    end if;
  elsif p_type = 'same_day' then
    if v_lang = 'am' then
      return query select
        'የዛሬ ቆሻሻ መሰብሰብ ማስታወሻ'::text,
        format('ማስታወሻ፡ በአካባቢዎ የቆሻሻ መሰብሰብ ዛሬ በ %s ተይዟል። እባክዎ የቤት ቆሻሻዎን ወደ ተፈቀደው መሰብሰቢያ ቦታ ያምጡ።', v_time);
    elsif v_lang = 'om' then
      return query select
        'Yaadachiisa walitti qabuu har’aa'::text,
        format('Yaadachiisa: Walitti qabuun xurii naannoo keessanitti har’a sa’aatii %s irratti karoorfameera. Maaloo xurii mana keessaa gara bakka eeyyamameetti fidaa.', v_time);
    else
      return query select
        'Today''s garbage collection'::text,
        format('Reminder: Garbage collection in your area is scheduled for today at %s. Please bring your household garbage to the approved collection point.', v_time);
    end if;
  elsif p_type = 'on_the_way' then
    if v_lang = 'am' then
      return query select
        'የመሰብሰቢያ ቡድኑ በመንገድ ላይ ነው'::text,
        'የመሰብሰቢያ ቡድኑ አካባቢዎን ማገልገል ጀምሯል። እባክዎ የተዘጋጀውን ቆሻሻ ወደ ተፈቀደው መሰብሰቢያ ቦታ ያምጡ። የመድረሻ ሰዓት እንደ መንገዱ ሊለያይ ይችላል።'::text;
    elsif v_lang = 'om' then
      return query select
        'Gareen walitti qabuu karaa irra jira'::text,
        'Gareen walitti qabuu naannoo keessan tajaajiluu eegaleera. Maaloo xurii qophaa’e gara bakka eeyyamameetti fidaa. Sa’aatni ga’umsaa akka karaatti garaagarummaa qabaachuu danda’a.'::text;
    else
      return query select
        'Collection team on the way'::text,
        'The collection team has started serving your area. Please bring your prepared garbage to the approved collection point. Arrival time may vary by route.'::text;
    end if;
  elsif p_type = 'delay' then
    if v_lang = 'am' then
      return query select
        'የቆሻሻ መሰብሰብ መዘግየት ማሳወቂያ'::text,
        format('ማሳወቂያ፡ በአካባቢዎ የቆሻሻ መሰብሰብ ዘግይቷል። አዲሱ የሚጠበቅ ሰዓት %s ነው።%s ለተፈጠረው ችግር ይቅርታ እንጠይቃለን።',
          v_dt, case when coalesce(trim(p_reason), '') <> '' then ' ምክንያት፡ ' || trim(p_reason) || '።' else '' end);
    elsif v_lang = 'om' then
      return query select
        'Beeksisa turtii walitti qabuu'::text,
        format('Beeksisa: Walitti qabuun xurii naannoo keessanitti tureera. Sa’aatni haarofame %s dha.%s Rakkoo uumameef dhiifama gaafanna.',
          v_dt, case when coalesce(trim(p_reason), '') <> '' then ' Sababa: ' || trim(p_reason) || '.' else '' end);
    else
      return query select
        'Collection delayed'::text,
        format('Notice: Garbage collection in your area has been delayed. The updated expected time is %s.%s We apologize for the inconvenience.',
          v_dt, case when coalesce(trim(p_reason), '') <> '' then ' Reason: ' || trim(p_reason) || '.' else '' end);
    end if;
  elsif p_type = 'cancellation' then
    if v_lang = 'am' then
      return query select
        'የቆሻሻ መሰብሰብ መሰረዝ ማሳወቂያ'::text,
        format('ማሳወቂያ፡ ለ %s የታቀደው የቆሻሻ መሰብሰብ ተሰርዟል። ማዘጋጃ ቤቱ ሲረጋገጥ ምትክ መርሐግብር ያሳውቃል።', v_date);
    elsif v_lang = 'om' then
      return query select
        'Beeksisa haqamuu sagantaa'::text,
        format('Beeksisa: Walitti qabuun xurii guyyaa %s karoorfame haqameera. Bulchiinsi magaalaa yeroo mirkanaa’u sagantaa bakka bu’u ni beeksisa.', v_date);
    else
      return query select
        'Collection cancelled'::text,
        format('Notice: The planned garbage collection for %s has been cancelled. The municipality will share the replacement schedule when confirmed.', v_date);
    end if;
  elsif p_type = 'reschedule' then
    if v_lang = 'am' then
      return query select
        'የቆሻሻ መሰብሰብ ቀን ተቀይሯል'::text,
        format('ማሻሻያ፡ የአካባቢዎ ቆሻሻ መሰብሰብ ወደ %s ተቀይሯል።', v_dt);
    elsif v_lang = 'om' then
      return query select
        'Sagantaan walitti qabuu jijjiirameera'::text,
        format('Fooyya’iinsa: Walitti qabuun xurii naannoo keessanii gara %s tti jijjiirameera.', v_dt);
    else
      return query select
        'Collection rescheduled'::text,
        format('Update: Your area''s garbage collection has been rescheduled to %s.', v_dt);
    end if;
  else
    -- completed
    if v_lang = 'am' then
      return query select
        'ቆሻሻ መሰብሰብ ተጠናቋል'::text,
        'በአካባቢዎ የቆሻሻ መሰብሰብ ተጠናቋል ተብሎ ተመዝግቧል። እናመሰግናለን።'::text;
    elsif v_lang = 'om' then
      return query select
        'Walitti qabuun xumurameera'::text,
        'Walitti qabuun xurii naannoo keessanitti xumurameera jedhamee galmaa’eera. Galatoomaa.'::text;
    else
      return query select
        'Collection completed'::text,
        'Garbage collection in your area has been marked completed. Thank you.'::text;
    end if;
  end if;
end;
$$;

-- Queue notifications for active residents of the schedule's area.
-- Deduplication key: schedule_id:version:type:recipient_id:channel.
create or replace function public.queue_schedule_notifications(
  p_schedule public.collection_schedules,
  p_type text,
  p_send_at timestamptz,
  p_reason text default null
)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_resident record;
  v_tpl record;
  v_essential boolean := p_type in ('delay', 'cancellation', 'reschedule');
  v_pref_ok boolean;
  v_inserted integer := 0;
  v_delivery public.delivery_status;
  v_sent_at timestamptz;
begin
  -- Do not schedule future reminders whose send time is already past the collection start.
  if p_type in ('day_before', 'same_day') and p_schedule.expected_start <= now() then
    return 0;
  end if;

  for v_resident in
    select id, preferred_language, notification_prefs, fcm_tokens
    from public.profiles
    where role = 'resident'
      and active = true
      and area_id = p_schedule.area_id
  loop
    v_pref_ok := v_essential or coalesce((v_resident.notification_prefs ->> p_type)::boolean, true);
    if not v_pref_ok then
      continue;
    end if;

    select * into v_tpl
    from public.render_schedule_notice(
      p_type,
      v_resident.preferred_language,
      p_schedule.expected_start,
      p_reason
    );

    -- Immediate in-app notices are delivered right away so the inbox updates via Realtime.
    if p_send_at <= now() then
      v_delivery := 'sent';
      v_sent_at := now();
    else
      v_delivery := 'pending';
      v_sent_at := null;
    end if;

    -- 1) Primary channel: in_app (essential notices always delivered).
    if v_essential or coalesce((v_resident.notification_prefs ->> 'in_app')::boolean, true) then
      insert into public.notifications (
        recipient_id, area_id, schedule_id, type, channel,
        title, message, scheduled_send_at, sent_at, delivery_status,
        schedule_version, dedup_key
      )
      values (
        v_resident.id, p_schedule.area_id, p_schedule.id, p_type, 'in_app',
        v_tpl.title, v_tpl.message, greatest(p_send_at, now()), v_sent_at, v_delivery,
        p_schedule.version,
        format('%s:v%s:%s:%s:in_app', p_schedule.id, p_schedule.version, p_type, v_resident.id)
      )
      on conflict (dedup_key) do nothing;
      if found then v_inserted := v_inserted + 1; end if;
    end if;

    -- 2) Optional channel: push (only if resident enabled push and has at least one token).
    if (v_essential or coalesce((v_resident.notification_prefs ->> 'push')::boolean, true))
       and coalesce(array_length(v_resident.fcm_tokens, 1), 0) > 0 then
      insert into public.notifications (
        recipient_id, area_id, schedule_id, type, channel,
        title, message, scheduled_send_at, delivery_status,
        schedule_version, dedup_key
      )
      values (
        v_resident.id, p_schedule.area_id, p_schedule.id, p_type, 'push',
        v_tpl.title, v_tpl.message, greatest(p_send_at, now()), 'pending',
        p_schedule.version,
        format('%s:v%s:%s:%s:push', p_schedule.id, p_schedule.version, p_type, v_resident.id)
      )
      on conflict (dedup_key) do nothing;
      if found then v_inserted := v_inserted + 1; end if;
    end if;
  end loop;

  return v_inserted;
end;
$$;

-- Queue standard day-before and same-day reminders using app_settings lead times.
create or replace function public.queue_schedule_reminders(p_schedule public.collection_schedules)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_day_before_hours numeric := 24;
  v_same_day_hours numeric := 3;
  v_total integer := 0;
begin
  select coalesce((value::text)::numeric, 24) into v_day_before_hours
  from public.app_settings where key = 'day_before_lead_hours';

  select coalesce((value::text)::numeric, 3) into v_same_day_hours
  from public.app_settings where key = 'same_day_hours_before';

  v_total := v_total + public.queue_schedule_notifications(
    p_schedule,
    'day_before',
    p_schedule.expected_start - make_interval(hours => greatest(v_day_before_hours::int, 1)),
    null
  );
  v_total := v_total + public.queue_schedule_notifications(
    p_schedule,
    'same_day',
    p_schedule.expected_start - make_interval(hours => greatest(v_same_day_hours::int, 1)),
    null
  );
  return v_total;
end;
$$;

-- Update status RPC: now supports optional completion_note, updates collection_tasks,
-- cancels pending reminders on cancellation, and queues resident notices automatically.
drop function if exists public.update_schedule_status(uuid, public.schedule_status, text);

create or replace function public.update_schedule_status(
  target_schedule uuid,
  next_status public.schedule_status,
  reason text default null,
  completion_note text default null
)
returns public.collection_schedules
language plpgsql
security definer
set search_path = public
as $$
declare
  current_row public.collection_schedules;
  actor_role public.user_role;
  assigned boolean;
  clean_reason text := nullif(trim(coalesce(reason, '')), '');
  clean_note text := nullif(trim(coalesce(completion_note, '')), '');
begin
  actor_role := public.auth_role();
  if actor_role is null then
    raise exception 'Not signed in';
  end if;

  select * into current_row
  from public.collection_schedules
  where id = target_schedule
  for update;

  if not found then
    raise exception 'Schedule not found';
  end if;

  select exists (
    select 1 from public.schedule_workers
    where schedule_id = target_schedule and worker_id = auth.uid()
  ) into assigned;

  if actor_role <> 'admin' and not (actor_role = 'worker' and assigned) then
    raise exception 'Not allowed to change this schedule';
  end if;

  if actor_role = 'worker' and next_status not in ('on_the_way', 'in_progress', 'completed', 'delayed') then
    raise exception 'Workers cannot set this status';
  end if;

  if not public.can_transition(current_row.status, next_status) then
    raise exception 'Status change from % to % is not allowed', current_row.status, next_status;
  end if;

  if next_status in ('delayed', 'cancelled') and clean_reason is null then
    raise exception 'A reason is required';
  end if;

  insert into public.schedule_history (schedule_id, changed_by, action, previous, "new", reason)
  values (
    current_row.id,
    auth.uid(),
    'status',
    jsonb_build_object('status', current_row.status, 'version', current_row.version),
    jsonb_build_object('status', next_status, 'version', current_row.version, 'completion_note', clean_note),
    clean_reason
  );

  update public.collection_schedules
  set status = next_status,
      updated_by = auth.uid(),
      change_reason = coalesce(clean_reason, change_reason),
      published_at = case when next_status = 'published' and published_at is null then now() else published_at end
  where id = current_row.id
  returning * into current_row;

  -- Keep collection_tasks synchronized for field lifecycle states.
  if next_status in ('assigned', 'on_the_way', 'in_progress', 'completed', 'delayed') then
    insert into public.collection_tasks (schedule_id, status, started_at, completed_at, delay_reason, completion_note)
    values (
      current_row.id,
      next_status,
      case when next_status in ('on_the_way', 'in_progress') then now() else null end,
      case when next_status = 'completed' then now() else null end,
      case when next_status = 'delayed' then clean_reason else null end,
      case when next_status = 'completed' then clean_note else null end
    )
    on conflict (schedule_id) do update
    set status = excluded.status,
        started_at = coalesce(public.collection_tasks.started_at, excluded.started_at),
        completed_at = coalesce(excluded.completed_at, public.collection_tasks.completed_at),
        delay_reason = coalesce(excluded.delay_reason, public.collection_tasks.delay_reason),
        completion_note = coalesce(excluded.completion_note, public.collection_tasks.completion_note);
  end if;

  -- Notification side-effects.
  if next_status = 'published' then
    perform public.queue_schedule_reminders(current_row);
  elsif next_status = 'on_the_way' then
    perform public.queue_schedule_notifications(current_row, 'on_the_way', now(), null);
  elsif next_status = 'delayed' then
    perform public.queue_schedule_notifications(current_row, 'delay', now(), clean_reason);
  elsif next_status = 'cancelled' then
    update public.notifications
    set delivery_status = 'cancelled'
    where schedule_id = current_row.id
      and delivery_status = 'pending';
    perform public.queue_schedule_notifications(current_row, 'cancellation', now(), clean_reason);
  elsif next_status = 'completed' then
    perform public.queue_schedule_notifications(current_row, 'completed', now(), null);
  end if;

  return current_row;
end;
$$;

revoke all on function public.update_schedule_status(uuid, public.schedule_status, text, text) from public;
grant execute on function public.update_schedule_status(uuid, public.schedule_status, text, text) to authenticated;

-- Admin-only RPC to reschedule a collection: bumps version, cancels stale pending reminders,
-- records audit history, and queues reschedule + updated reminders for non-draft schedules.
create or replace function public.reschedule_collection(
  target_schedule uuid,
  new_date date,
  new_expected_start timestamptz,
  new_expected_end timestamptz default null,
  reason text default null
)
returns public.collection_schedules
language plpgsql
security definer
set search_path = public
as $$
declare
  current_row public.collection_schedules;
  clean_reason text := nullif(trim(coalesce(reason, '')), '');
begin
  if public.auth_role() <> 'admin' then
    raise exception 'Administrator access is required';
  end if;

  if clean_reason is null then
    raise exception 'A reason is required to reschedule';
  end if;

  if new_expected_end is not null and new_expected_end <= new_expected_start then
    raise exception 'End time must be after start time';
  end if;

  select * into current_row
  from public.collection_schedules
  where id = target_schedule
  for update;

  if not found then
    raise exception 'Schedule not found';
  end if;

  if current_row.status in ('completed', 'cancelled') then
    raise exception 'Terminal schedules cannot be rescheduled';
  end if;

  insert into public.schedule_history (schedule_id, changed_by, action, previous, "new", reason)
  values (
    current_row.id,
    auth.uid(),
    'reschedule',
    jsonb_build_object(
      'collection_date', current_row.collection_date,
      'expected_start', current_row.expected_start,
      'expected_end', current_row.expected_end,
      'version', current_row.version
    ),
    jsonb_build_object(
      'collection_date', new_date,
      'expected_start', new_expected_start,
      'expected_end', new_expected_end,
      'version', current_row.version + 1
    ),
    clean_reason
  );

  -- Cancel obsolete pending reminders for the prior version.
  update public.notifications
  set delivery_status = 'cancelled'
  where schedule_id = current_row.id
    and delivery_status = 'pending';

  update public.collection_schedules
  set collection_date = new_date,
      expected_start = new_expected_start,
      expected_end = new_expected_end,
      change_reason = clean_reason,
      updated_by = auth.uid(),
      version = version + 1,
      status = case when status = 'delayed' then 'published' else status end
  where id = current_row.id
  returning * into current_row;

  if current_row.status <> 'draft' then
    perform public.queue_schedule_notifications(current_row, 'reschedule', now(), clean_reason);
    perform public.queue_schedule_reminders(current_row);
  end if;

  return current_row;
end;
$$;

revoke all on function public.reschedule_collection(uuid, date, timestamptz, timestamptz, text) from public;
grant execute on function public.reschedule_collection(uuid, date, timestamptz, timestamptz, text) to authenticated;

-- Notify the reporting resident whenever an administrator updates their garbage report status.
create or replace function public.notify_report_status_change()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_lang text := 'en';
  v_title text;
  v_msg text;
begin
  if new.status is not distinct from old.status then
    return new;
  end if;

  select preferred_language into v_lang
  from public.profiles
  where id = new.resident_id and active = true;

  if not found then
    return new;
  end if;

  if v_lang = 'am' then
    v_title := 'የቆሻሻ ሪፖርት ሁኔታ ተዘምኗል';
    v_msg := format('የሪፖርትዎ ሁኔታ ወደ "%s" ተቀይሯል።%s',
      new.status,
      case when coalesce(trim(new.admin_note), '') <> '' then ' ማስታወሻ፡ ' || trim(new.admin_note) else '' end);
  elsif v_lang = 'om' then
    v_title := 'Haalli gabaasa xurii haaromfameera';
    v_msg := format('Haalli gabaasa keessanii gara "%s" tti jijjiirameera.%s',
      new.status,
      case when coalesce(trim(new.admin_note), '') <> '' then ' Yaadannoo: ' || trim(new.admin_note) else '' end);
  else
    v_title := 'Garbage report status updated';
    v_msg := format('Your garbage report status is now "%s".%s',
      new.status,
      case when coalesce(trim(new.admin_note), '') <> '' then ' Note: ' || trim(new.admin_note) else '' end);
  end if;

  insert into public.notifications (
    recipient_id, area_id, schedule_id, type, channel,
    title, message, scheduled_send_at, sent_at, delivery_status, dedup_key
  )
  values (
    new.resident_id, new.area_id, null, 'report_status', 'in_app',
    v_title, v_msg, now(), now(), 'sent',
    format('report:%s:%s:%s', new.id, new.status, extract(epoch from now())::bigint)
  )
  on conflict (dedup_key) do nothing;

  return new;
end;
$$;

drop trigger if exists garbage_reports_notify_status on public.garbage_reports;
create trigger garbage_reports_notify_status
after update on public.garbage_reports
for each row execute function public.notify_report_status_change();

-- Claim due pending notifications safely for the process-notifications Edge Function.
create or replace function public.claim_due_notifications(batch_size integer default 50)
returns setof public.notifications
language sql
security definer
set search_path = public
as $$
  select *
  from public.notifications
  where delivery_status = 'pending'
    and scheduled_send_at <= now()
  order by scheduled_send_at asc
  limit greatest(1, least(batch_size, 200))
  for update skip locked
$$;

revoke all on function public.claim_due_notifications(integer) from public, anon, authenticated;
grant execute on function public.claim_due_notifications(integer) to service_role;
