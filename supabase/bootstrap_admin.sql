-- Promote the first administrator after they register.
-- 1. Run migrations/20261121120000_profiles_and_areas.sql.
-- 2. Register with a real phone number.
-- 3. Replace the phone below, then run this once.
-- Signup always creates a resident. This is the appointment step until
-- the admin-create-user Edge Function is deployed.

update public.profiles
set role = 'admin'
where phone = '+251900000000';
