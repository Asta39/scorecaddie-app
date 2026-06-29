create table if not exists public.club_posts (
    id uuid default gen_random_uuid() primary key,
    club_id text not null references public."Course"(id) on delete cascade,
    author_id uuid not null references public."User"(id) on delete cascade,
    title text not null,
    content text not null,
    post_type text not null, -- 'announcement', 'fixture', 'result'
    image_url text,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- RLS
alter table public.club_posts enable row level security;

-- Everyone can read posts
create policy "Public can view club posts"
    on public.club_posts
    for select
    using (true);

-- Authenticated admins can create posts (Assuming club_admins table or similar role logic exists, but since auth is standard, we'll allow authenticated users for now)
create policy "Authenticated users can create posts"
    on public.club_posts
    for insert
    to authenticated
    with check (true);

create policy "Authenticated users can update posts"
    on public.club_posts
    for update
    to authenticated
    using (true);

create policy "Authenticated users can delete posts"
    on public.club_posts
    for delete
    to authenticated
    using (true);
