-- Sample directory for local development. Not for a production database.
-- Password for every sample account: SeedPass123
-- Phones are fake +2519110000xx numbers. Apply the migration first.
-- The signup trigger creates a resident profile; this script then sets roles.

create extension if not exists pgcrypto;

insert into public.service_areas (id, name, kebele_code, description, center_lat, center_lng)
values
  ('aaaaaaaa-0001-0001-0001-000000000001', 'Kebele 01', '01', 'Sample service area', 7.673, 36.834),
  ('aaaaaaaa-0004-0004-0004-000000000004', 'Kebele 04', '04', 'Sample service area', 7.661, 36.828),
  ('aaaaaaaa-0007-0007-0007-000000000007', 'Kebele 07', '07', 'Sample service area', 7.655, 36.845)
on conflict (kebele_code) do update
set name = excluded.name,
    center_lat = excluded.center_lat,
    center_lng = excluded.center_lng;

do $$
declare
  person record;
  new_id uuid;
begin
  for person in
    select *
    from (values
      ('11111111-1111-4111-8111-111111111111'::uuid, '+251911000001', 'Seed Admin', 'admin'::public.user_role, null::uuid),
      ('22222222-2222-4222-8222-222222222221'::uuid, '+251911000002', 'Seed Worker One', 'worker', 'aaaaaaaa-0004-0004-0004-000000000004'::uuid),
      ('22222222-2222-4222-8222-222222222222'::uuid, '+251911000003', 'Seed Worker Two', 'worker', 'aaaaaaaa-0001-0001-0001-000000000001'::uuid),
      ('33333333-3333-4333-8333-333333333331'::uuid, '+251911000011', 'Seed Resident One', 'resident', 'aaaaaaaa-0004-0004-0004-000000000004'::uuid),
      ('33333333-3333-4333-8333-333333333332'::uuid, '+251911000012', 'Seed Resident Two', 'resident', 'aaaaaaaa-0004-0004-0004-000000000004'::uuid),
      ('33333333-3333-4333-8333-333333333333'::uuid, '+251911000013', 'Seed Resident Three', 'resident', 'aaaaaaaa-0001-0001-0001-000000000001'::uuid),
      ('33333333-3333-4333-8333-333333333334'::uuid, '+251911000014', 'Seed Resident Four', 'resident', 'aaaaaaaa-0007-0007-0007-000000000007'::uuid),
      ('33333333-3333-4333-8333-333333333335'::uuid, '+251911000015', 'Seed Resident Five', 'resident', 'aaaaaaaa-0004-0004-0004-000000000004'::uuid)
    ) as seed(id, phone, full_name, role, area_id)
  loop
    select id into new_id from auth.users where email = replace(person.phone, '+', '') || '@jimma-waste.app';
    if new_id is null then
      new_id := person.id;
      insert into auth.users (
        instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
        raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
        confirmation_token, recovery_token, email_change_token_new, email_change
      ) values (
        '00000000-0000-0000-0000-000000000000',
        new_id,
        'authenticated',
        'authenticated',
        replace(person.phone, '+', '') || '@jimma-waste.app',
        crypt('SeedPass123', gen_salt('bf')),
        now(),
        '{"provider":"email","providers":["email"]}'::jsonb,
        jsonb_build_object(
          'full_name', person.full_name,
          'phone', person.phone,
          'area_id', person.area_id,
          'preferred_language', 'en'
        ),
        now(),
        now(),
        '', '', '', ''
      );
      insert into auth.identities (
        id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at
      ) values (
        gen_random_uuid(),
        new_id,
        jsonb_build_object('sub', new_id::text, 'email', replace(person.phone, '+', '') || '@jimma-waste.app'),
        'email',
        new_id::text,
        now(), now(), now()
      );
    end if;

    update public.profiles
    set role = person.role,
        full_name = person.full_name,
        area_id = person.area_id,
        active = true
    where id = new_id;
  end loop;
end $$;

insert into public.trucks (id, plate_number, capacity, availability, maintenance)
values ('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb1', 'OR-01-10001', 8, 'available', 'ok')
on conflict (plate_number) do nothing;

insert into public.routes (id, name, area_id, description, stops)
values (
  'cccccccc-cccc-4ccc-8ccc-ccccccccccc1',
  'Kebele 04 morning route',
  'aaaaaaaa-0004-0004-0004-000000000004',
  'Sample route. Stops are labels, not a live truck path.',
  '[
    {"name":"Stop A","lat":7.662,"lng":36.827,"order":1},
    {"name":"Stop B","lat":7.665,"lng":36.831,"order":2}
  ]'::jsonb
)
on conflict (id) do nothing;

insert into public.collection_schedules (
  id, area_id, collection_date, expected_start, expected_end, route_id, truck_id,
  status, published_at, created_by, version
)
values
  (
    'dddddddd-dddd-4ddd-8ddd-ddddddddddd1',
    'aaaaaaaa-0004-0004-0004-000000000004',
    (current_date + 1),
    ((current_date + 1)::timestamp + time '09:00') at time zone 'Africa/Addis_Ababa',
    ((current_date + 1)::timestamp + time '12:00') at time zone 'Africa/Addis_Ababa',
    'cccccccc-cccc-4ccc-8ccc-ccccccccccc1',
    'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb1',
    'published',
    now(),
    '11111111-1111-4111-8111-111111111111',
    1
  ),
  (
    'dddddddd-dddd-4ddd-8ddd-ddddddddddd2',
    'aaaaaaaa-0001-0001-0001-000000000001',
    (current_date + 2),
    ((current_date + 2)::timestamp + time '14:00') at time zone 'Africa/Addis_Ababa',
    null,
    null,
    null,
    'published',
    now(),
    '11111111-1111-4111-8111-111111111111',
    1
  )
on conflict (id) do nothing;

insert into public.schedule_workers (schedule_id, worker_id)
values
  ('dddddddd-dddd-4ddd-8ddd-ddddddddddd1', '22222222-2222-4222-8222-222222222221'),
  ('dddddddd-dddd-4ddd-8ddd-ddddddddddd2', '22222222-2222-4222-8222-222222222222')
on conflict do nothing;
