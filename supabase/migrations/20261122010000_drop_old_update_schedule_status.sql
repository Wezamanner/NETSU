-- Remove the legacy 3-argument overload of update_schedule_status so PostgREST
-- never hits PGRST203 ("Could not choose the best candidate function").
drop function if exists public.update_schedule_status(uuid, public.schedule_status, text);
