-- "Enable automatic RLS" (chosen when the project was made) adds the event-trigger function
-- public.rls_auto_enable(). The security advisor flags it as callable through the Data API.
-- It only runs as an event trigger, so nobody needs to call it directly.
revoke execute on function public.rls_auto_enable() from public, anon, authenticated;
