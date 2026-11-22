-- Signup always inserts a resident. An administrator appoints a worker or admin afterwards.
create or replace function public.appoint_staff(
  target_id uuid,
  next_role public.user_role,
  next_area uuid default null,
  next_name text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if public.auth_role() is distinct from 'admin' then
    raise exception 'Administrator access is required';
  end if;
  if next_role not in ('worker', 'admin') then
    raise exception 'Role must be worker or admin';
  end if;

  update public.profiles
  set
    role = next_role,
    area_id = next_area,
    full_name = coalesce(nullif(trim(next_name), ''), full_name)
  where id = target_id;

  if not found then
    raise exception 'Profile was not created';
  end if;
end;
$$;

revoke all on function public.appoint_staff(uuid, public.user_role, uuid, text) from public;
grant execute on function public.appoint_staff(uuid, public.user_role, uuid, text) to authenticated;
