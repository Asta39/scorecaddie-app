-- 1. Enable pg_net for outbound webhooks
create extension if not exists pg_net;

-- 2. Create the Admin Notifications table
create table if not exists public.admin_notifications (
    id uuid default gen_random_uuid() primary key,
    club_id text not null references public."Course"(id) on delete cascade,
    title text not null,
    message text not null,
    is_read boolean default false not null,
    link text,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- RLS for admin_notifications
alter table public.admin_notifications enable row level security;
create policy "Admins can view their club notifications"
    on public.admin_notifications for select to authenticated using (true);
create policy "Admins can update their club notifications"
    on public.admin_notifications for update to authenticated using (true);

-- 3. Database Webhook Trigger: New Competition
create or replace function public.trigger_new_competition_webhook()
returns trigger as $$
begin
  perform net.http_post(
      url := coalesce(current_setting('app.settings.supabase_url', true), 'https://your-project.supabase.co') || '/functions/v1/send-club-notification',
      headers := jsonb_build_object(
          'Content-Type', 'application/json',
          'Authorization', 'Bearer ' || coalesce(current_setting('app.settings.service_role_key', true), 'your-anon-key')
      ),
      body := jsonb_build_object(
          'trigger', 'new_competition',
          'club_id', NEW.club_id,
          'competition_id', NEW.id
      )
  );
  return NEW;
end;
$$ language plpgsql security definer;

create trigger on_new_competition
after insert on public.competitions
for each row execute function public.trigger_new_competition_webhook();


-- 4. Database Webhook Trigger: New Club Post
create or replace function public.trigger_new_post_webhook()
returns trigger as $$
begin
  perform net.http_post(
      url := coalesce(current_setting('app.settings.supabase_url', true), 'https://your-project.supabase.co') || '/functions/v1/send-club-notification',
      headers := jsonb_build_object(
          'Content-Type', 'application/json',
          'Authorization', 'Bearer ' || coalesce(current_setting('app.settings.service_role_key', true), 'your-anon-key')
      ),
      body := jsonb_build_object(
          'trigger', 'new_post',
          'club_id', NEW.club_id,
          'post_id', NEW.id
      )
  );
  return NEW;
end;
$$ language plpgsql security definer;

create trigger on_new_club_post
after insert on public.club_posts
for each row execute function public.trigger_new_post_webhook();


-- 5. Trigger to create Admin Notification for Underpaid Entries
create or replace function public.trigger_underpaid_admin_notification()
returns trigger as $$
begin
  -- If payment_status changes to 'underpaid'
  if (NEW.payment_status = 'underpaid' and (OLD is null or OLD.payment_status != 'underpaid')) then
    insert into public.admin_notifications (club_id, title, message, link)
    values (
      (select club_id from public.competitions where id = NEW.competition_id),
      'Underpaid Entry Detected',
      'Golfer ' || NEW.player_id || ' paid an insufficient amount for competition ' || NEW.competition_id,
      '/competitions/' || NEW.competition_id
    );
  end if;
  return NEW;
end;
$$ language plpgsql security definer;

create trigger on_underpaid_entry
after insert or update on public.competition_entries
for each row execute function public.trigger_underpaid_admin_notification();
