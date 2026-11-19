-- ZhekaFitness schema setup / repair script.
-- Safe to run more than once: preserves table rows, recreates named policies/triggers.
-- No demo rows, user accounts, memberships, or bookings are inserted.

begin;
create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  first_name text not null default '',
  last_name text not null default '',
  phone text,
  birth_date date,
  avatar_path text,
  training_preferences text[] not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
alter table public.profiles add column if not exists id uuid;
do $$ begin
  if exists(select 1 from information_schema.columns where table_schema='public' and table_name='profiles' and column_name='user_id' and data_type='uuid') then
    execute 'update public.profiles set id = user_id where id is null and user_id is not null';
  end if;
  if exists(select 1 from information_schema.columns where table_schema='public' and table_name='profiles' and column_name='auth_user_id' and data_type='uuid') then
    execute 'update public.profiles set id = auth_user_id where id is null and auth_user_id is not null';
  end if;
end $$;
update public.profiles set id = gen_random_uuid() where id is null;
create unique index if not exists profiles_id_repair_uidx on public.profiles(id);
alter table public.profiles add column if not exists first_name text not null default '';
alter table public.profiles add column if not exists last_name text not null default '';
alter table public.profiles add column if not exists phone text;
alter table public.profiles add column if not exists birth_date date;
alter table public.profiles add column if not exists avatar_path text;
alter table public.profiles add column if not exists training_preferences text[] not null default '{}';
alter table public.profiles add column if not exists created_at timestamptz not null default now();
alter table public.profiles add column if not exists updated_at timestamptz not null default now();
alter table public.profiles alter column id set default gen_random_uuid();
alter table public.profiles alter column id set not null;

create table if not exists public.programs (
  id uuid primary key default gen_random_uuid(), slug text not null unique, title text not null,
  category text not null check(category in ('strength','cardio','functional','recovery','group')),
  level text not null check(level in ('beginner','intermediate','advanced','all')),
  duration_minutes smallint not null check(duration_minutes > 0), description text not null default '',
  audience text not null default '', equipment text[] not null default '{}', recommended_frequency text,
  image_path text, is_published boolean not null default false, sort_order integer not null default 0,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
alter table public.programs add column if not exists id uuid;
alter table public.programs add column if not exists slug text;
alter table public.programs add column if not exists title text not null default '';
alter table public.programs add column if not exists category text not null default 'strength';
alter table public.programs add column if not exists level text not null default 'all';
alter table public.programs add column if not exists duration_minutes smallint not null default 45;
alter table public.programs add column if not exists description text not null default '';
alter table public.programs add column if not exists audience text not null default '';
alter table public.programs add column if not exists equipment text[] not null default '{}';
alter table public.programs add column if not exists recommended_frequency text;
alter table public.programs add column if not exists image_path text;
alter table public.programs add column if not exists is_published boolean not null default false;
alter table public.programs add column if not exists sort_order integer not null default 0;
alter table public.programs add column if not exists created_at timestamptz not null default now();
alter table public.programs add column if not exists updated_at timestamptz not null default now();
update public.programs set id = gen_random_uuid() where id is null;
alter table public.programs alter column id set default gen_random_uuid();
alter table public.programs alter column id set not null;
update public.programs set slug = 'program-' || id::text where slug is null or btrim(slug) = '';
alter table public.programs alter column slug set not null;
create unique index if not exists programs_slug_repair_uidx on public.programs(slug);
create unique index if not exists programs_id_repair_uidx on public.programs(id);
create table if not exists public.trainers (
  id uuid primary key default gen_random_uuid(), slug text not null unique, full_name text not null,
  specialization text not null, experience_years smallint check(experience_years is null or experience_years >= 0),
  bio text not null default '', photo_path text, is_published boolean not null default false,
  sort_order integer not null default 0, created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
alter table public.trainers add column if not exists id uuid;
alter table public.trainers add column if not exists slug text;
alter table public.trainers add column if not exists full_name text not null default '';
alter table public.trainers add column if not exists specialization text not null default '';
alter table public.trainers add column if not exists experience_years smallint;
alter table public.trainers add column if not exists bio text not null default '';
alter table public.trainers add column if not exists photo_path text;
alter table public.trainers add column if not exists is_published boolean not null default false;
alter table public.trainers add column if not exists sort_order integer not null default 0;
alter table public.trainers add column if not exists created_at timestamptz not null default now();
alter table public.trainers add column if not exists updated_at timestamptz not null default now();
update public.trainers set id = gen_random_uuid() where id is null;
alter table public.trainers alter column id set default gen_random_uuid();
alter table public.trainers alter column id set not null;
update public.trainers set slug = 'trainer-' || id::text where slug is null or btrim(slug) = '';
alter table public.trainers alter column slug set not null;
create unique index if not exists trainers_slug_repair_uidx on public.trainers(slug);
create unique index if not exists trainers_id_repair_uidx on public.trainers(id);
create table if not exists public.program_trainers (
  program_id uuid not null references public.programs(id) on delete cascade,
  trainer_id uuid not null references public.trainers(id) on delete cascade,
  primary key(program_id, trainer_id)
);
alter table public.program_trainers add column if not exists program_id uuid;
alter table public.program_trainers add column if not exists trainer_id uuid;
create unique index if not exists program_trainers_pair_repair_uidx on public.program_trainers(program_id,trainer_id);
create table if not exists public.membership_plans (
  id uuid primary key default gen_random_uuid(), slug text not null unique, title text not null,
  description text not null default '', price_minor integer not null check(price_minor >= 0),
  currency char(3) not null default 'RUB', duration_days integer not null check(duration_days > 0),
  features jsonb not null default '[]'::jsonb, is_published boolean not null default false,
  sort_order integer not null default 0, created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
alter table public.membership_plans add column if not exists id uuid;
alter table public.membership_plans add column if not exists slug text;
alter table public.membership_plans add column if not exists title text not null default '';
alter table public.membership_plans add column if not exists description text not null default '';
alter table public.membership_plans add column if not exists price_minor integer not null default 0;
alter table public.membership_plans add column if not exists currency char(3) not null default 'RUB';
alter table public.membership_plans add column if not exists duration_days integer not null default 30;
alter table public.membership_plans add column if not exists features jsonb not null default '[]'::jsonb;
alter table public.membership_plans add column if not exists is_published boolean not null default false;
alter table public.membership_plans add column if not exists sort_order integer not null default 0;
alter table public.membership_plans add column if not exists created_at timestamptz not null default now();
alter table public.membership_plans add column if not exists updated_at timestamptz not null default now();
update public.membership_plans set id = gen_random_uuid() where id is null;
alter table public.membership_plans alter column id set default gen_random_uuid();
alter table public.membership_plans alter column id set not null;
update public.membership_plans set slug = 'plan-' || id::text where slug is null or btrim(slug) = '';
alter table public.membership_plans alter column slug set not null;
create unique index if not exists membership_plans_slug_repair_uidx on public.membership_plans(slug);
create unique index if not exists membership_plans_id_repair_uidx on public.membership_plans(id);
create table if not exists public.memberships (
  id uuid primary key default gen_random_uuid(), user_id uuid not null references public.profiles(id) on delete cascade,
  plan_id uuid not null references public.membership_plans(id),
  status text not null default 'pending' check(status in ('pending','active','paused','expired','cancelled')),
  starts_at timestamptz, ends_at timestamptz, created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(), check(ends_at is null or starts_at is null or ends_at > starts_at)
);
alter table public.memberships add column if not exists id uuid;
alter table public.memberships add column if not exists user_id uuid;
alter table public.memberships add column if not exists plan_id uuid;
alter table public.memberships add column if not exists status text not null default 'pending';
alter table public.memberships add column if not exists starts_at timestamptz;
alter table public.memberships add column if not exists ends_at timestamptz;
alter table public.memberships add column if not exists created_at timestamptz not null default now();
alter table public.memberships add column if not exists updated_at timestamptz not null default now();
update public.memberships set id = gen_random_uuid() where id is null;
alter table public.memberships alter column id set default gen_random_uuid();
alter table public.memberships alter column id set not null;
create unique index if not exists memberships_id_repair_uidx on public.memberships(id);
create table if not exists public.class_sessions (
  id uuid primary key default gen_random_uuid(), program_id uuid not null references public.programs(id),
  trainer_id uuid not null references public.trainers(id), starts_at timestamptz not null,
  duration_minutes smallint not null check(duration_minutes > 0), capacity smallint not null check(capacity > 0),
  room text, status text not null default 'scheduled' check(status in ('scheduled','cancelled','completed')),
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
alter table public.class_sessions add column if not exists id uuid;
alter table public.class_sessions add column if not exists program_id uuid;
alter table public.class_sessions add column if not exists trainer_id uuid;
alter table public.class_sessions add column if not exists starts_at timestamptz;
alter table public.class_sessions add column if not exists duration_minutes smallint not null default 45;
alter table public.class_sessions add column if not exists capacity smallint not null default 1;
alter table public.class_sessions add column if not exists room text;
alter table public.class_sessions add column if not exists status text not null default 'scheduled';
alter table public.class_sessions add column if not exists created_at timestamptz not null default now();
alter table public.class_sessions add column if not exists updated_at timestamptz not null default now();
update public.class_sessions set id = gen_random_uuid() where id is null;
alter table public.class_sessions alter column id set default gen_random_uuid();
alter table public.class_sessions alter column id set not null;
create unique index if not exists class_sessions_id_repair_uidx on public.class_sessions(id);
create table if not exists public.bookings (
  id uuid primary key default gen_random_uuid(), session_id uuid not null references public.class_sessions(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  status text not null default 'booked' check(status in ('booked','cancelled','attended','no_show')),
  booked_at timestamptz not null default now(), cancelled_at timestamptz, unique(session_id, user_id)
);
alter table public.bookings add column if not exists id uuid;
alter table public.bookings add column if not exists session_id uuid;
alter table public.bookings add column if not exists user_id uuid;
alter table public.bookings add column if not exists status text not null default 'booked';
alter table public.bookings add column if not exists booked_at timestamptz not null default now();
alter table public.bookings add column if not exists cancelled_at timestamptz;
update public.bookings set id = gen_random_uuid() where id is null;
alter table public.bookings alter column id set default gen_random_uuid();
alter table public.bookings alter column id set not null;
create unique index if not exists bookings_id_repair_uidx on public.bookings(id);
create unique index if not exists bookings_session_user_repair_uidx on public.bookings(session_id,user_id);

do $$ begin
  if not exists(select 1 from pg_constraint c where c.contype='f' and c.conrelid='public.profiles'::regclass and c.confrelid='auth.users'::regclass and cardinality(c.conkey)=1 and c.conkey[1]=(select attnum from pg_attribute where attrelid='public.profiles'::regclass and attname='id')) then
    alter table public.profiles add constraint profiles_auth_user_repair_fkey foreign key(id) references auth.users(id) on delete cascade not valid;
  end if;
  if not exists(select 1 from pg_constraint c where c.contype='f' and c.conrelid='public.program_trainers'::regclass and c.confrelid='public.programs'::regclass and cardinality(c.conkey)=1 and c.conkey[1]=(select attnum from pg_attribute where attrelid='public.program_trainers'::regclass and attname='program_id')) then
    alter table public.program_trainers add constraint program_trainers_program_repair_fkey foreign key(program_id) references public.programs(id) on delete cascade not valid;
  end if;
  if not exists(select 1 from pg_constraint c where c.contype='f' and c.conrelid='public.program_trainers'::regclass and c.confrelid='public.trainers'::regclass and cardinality(c.conkey)=1 and c.conkey[1]=(select attnum from pg_attribute where attrelid='public.program_trainers'::regclass and attname='trainer_id')) then
    alter table public.program_trainers add constraint program_trainers_trainer_repair_fkey foreign key(trainer_id) references public.trainers(id) on delete cascade not valid;
  end if;
  if not exists(select 1 from pg_constraint c where c.contype='f' and c.conrelid='public.memberships'::regclass and c.confrelid='public.profiles'::regclass and cardinality(c.conkey)=1 and c.conkey[1]=(select attnum from pg_attribute where attrelid='public.memberships'::regclass and attname='user_id')) then
    alter table public.memberships add constraint memberships_user_repair_fkey foreign key(user_id) references public.profiles(id) on delete cascade not valid;
  end if;
  if not exists(select 1 from pg_constraint c where c.contype='f' and c.conrelid='public.memberships'::regclass and c.confrelid='public.membership_plans'::regclass and cardinality(c.conkey)=1 and c.conkey[1]=(select attnum from pg_attribute where attrelid='public.memberships'::regclass and attname='plan_id')) then
    alter table public.memberships add constraint memberships_plan_repair_fkey foreign key(plan_id) references public.membership_plans(id) not valid;
  end if;
  if not exists(select 1 from pg_constraint c where c.contype='f' and c.conrelid='public.class_sessions'::regclass and c.confrelid='public.programs'::regclass and cardinality(c.conkey)=1 and c.conkey[1]=(select attnum from pg_attribute where attrelid='public.class_sessions'::regclass and attname='program_id')) then
    alter table public.class_sessions add constraint class_sessions_program_repair_fkey foreign key(program_id) references public.programs(id) not valid;
  end if;
  if not exists(select 1 from pg_constraint c where c.contype='f' and c.conrelid='public.class_sessions'::regclass and c.confrelid='public.trainers'::regclass and cardinality(c.conkey)=1 and c.conkey[1]=(select attnum from pg_attribute where attrelid='public.class_sessions'::regclass and attname='trainer_id')) then
    alter table public.class_sessions add constraint class_sessions_trainer_repair_fkey foreign key(trainer_id) references public.trainers(id) not valid;
  end if;
  if not exists(select 1 from pg_constraint c where c.contype='f' and c.conrelid='public.bookings'::regclass and c.confrelid='public.class_sessions'::regclass and cardinality(c.conkey)=1 and c.conkey[1]=(select attnum from pg_attribute where attrelid='public.bookings'::regclass and attname='session_id')) then
    alter table public.bookings add constraint bookings_session_repair_fkey foreign key(session_id) references public.class_sessions(id) on delete cascade not valid;
  end if;
  if not exists(select 1 from pg_constraint c where c.contype='f' and c.conrelid='public.bookings'::regclass and c.confrelid='public.profiles'::regclass and cardinality(c.conkey)=1 and c.conkey[1]=(select attnum from pg_attribute where attrelid='public.bookings'::regclass and attname='user_id')) then
    alter table public.bookings add constraint bookings_user_repair_fkey foreign key(user_id) references public.profiles(id) on delete cascade not valid;
  end if;
end $$;

create index if not exists class_sessions_starts_at_idx on public.class_sessions(starts_at);
create index if not exists class_sessions_program_starts_idx on public.class_sessions(program_id, starts_at);
create index if not exists bookings_user_status_idx on public.bookings(user_id, status);
create index if not exists bookings_session_status_idx on public.bookings(session_id, status);
create index if not exists memberships_user_status_idx on public.memberships(user_id, status);

create or replace function public.set_updated_at()
returns trigger language plpgsql set search_path = '' as $$
begin new.updated_at = now(); return new; end;
$$;
do $$
declare t text;
begin
  foreach t in array array['profiles','programs','trainers','membership_plans','memberships','class_sessions'] loop
    execute format('drop trigger if exists set_updated_at on public.%I', t);
    execute format('create trigger set_updated_at before update on public.%I for each row execute function public.set_updated_at()', t);
  end loop;
end;
$$;
create or replace function public.create_profile_for_new_user()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  insert into public.profiles(id, first_name, last_name)
  values(new.id, coalesce(new.raw_user_meta_data ->> 'first_name',''), coalesce(new.raw_user_meta_data ->> 'last_name',''))
  on conflict(id) do nothing;
  return new;
end;
$$;
drop trigger if exists create_profile_after_signup on auth.users;
create trigger create_profile_after_signup after insert on auth.users
for each row execute function public.create_profile_for_new_user();

alter table public.profiles enable row level security;
alter table public.programs enable row level security;
alter table public.trainers enable row level security;
alter table public.program_trainers enable row level security;
alter table public.membership_plans enable row level security;
alter table public.memberships enable row level security;
alter table public.class_sessions enable row level security;
alter table public.bookings enable row level security;

drop policy if exists "Own profile read" on public.profiles;
create policy "Own profile read" on public.profiles for select to authenticated using((select auth.uid()) = id);
drop policy if exists "Own profile insert" on public.profiles;
create policy "Own profile insert" on public.profiles for insert to authenticated with check((select auth.uid()) = id);
drop policy if exists "Own profile update" on public.profiles;
create policy "Own profile update" on public.profiles for update to authenticated using((select auth.uid()) = id) with check((select auth.uid()) = id);
drop policy if exists "Published programs read" on public.programs;
create policy "Published programs read" on public.programs for select to anon, authenticated using(is_published);
drop policy if exists "Published trainers read" on public.trainers;
create policy "Published trainers read" on public.trainers for select to anon, authenticated using(is_published);
drop policy if exists "Program trainer links read" on public.program_trainers;
create policy "Program trainer links read" on public.program_trainers for select to anon, authenticated using(
  exists(select 1 from public.programs p where p.id = program_id and p.is_published)
  and exists(select 1 from public.trainers t where t.id = trainer_id and t.is_published)
);
drop policy if exists "Published plans read" on public.membership_plans;
create policy "Published plans read" on public.membership_plans for select to anon, authenticated using(is_published);
drop policy if exists "Scheduled sessions read" on public.class_sessions;
create policy "Scheduled sessions read" on public.class_sessions for select to anon, authenticated using(
  status = 'scheduled'
  and exists(select 1 from public.programs p where p.id = program_id and p.is_published)
  and exists(select 1 from public.trainers t where t.id = trainer_id and t.is_published)
);
drop policy if exists "Own memberships read" on public.memberships;
create policy "Own memberships read" on public.memberships for select to authenticated using((select auth.uid()) = user_id);
drop policy if exists "Request published membership plan" on public.memberships;
create policy "Request published membership plan" on public.memberships for insert to authenticated with check(
  (select auth.uid()) = user_id and status = 'pending'
  and exists(select 1 from public.membership_plans p where p.id = plan_id and p.is_published)
);
drop policy if exists "Own bookings read" on public.bookings;
create policy "Own bookings read" on public.bookings for select to authenticated using((select auth.uid()) = user_id);
drop policy if exists "Book future session" on public.bookings;
drop policy if exists "Cancel own booking" on public.bookings;
create policy "Cancel own booking" on public.bookings for update to authenticated using(
  (select auth.uid()) = user_id and status = 'booked'
  and exists(select 1 from public.class_sessions s where s.id = session_id and s.status = 'scheduled' and s.starts_at > now())
) with check((select auth.uid()) = user_id and status = 'cancelled');

create or replace function public.book_class_session(p_session_id uuid)
returns uuid language plpgsql security definer set search_path = '' as $$
declare v_user uuid := auth.uid(); v_capacity integer; v_taken integer; v_booking uuid;
begin
  if v_user is null then raise exception 'Authentication required'; end if;
  select s.capacity into v_capacity from public.class_sessions s
  join public.programs p on p.id = s.program_id join public.trainers t on t.id = s.trainer_id
  where s.id = p_session_id and s.status = 'scheduled' and s.starts_at > now()
    and p.is_published and t.is_published for update of s;
  if not found then raise exception 'Session is unavailable'; end if;
  if exists(select 1 from public.bookings b where b.session_id = p_session_id and b.user_id = v_user and b.status = 'booked') then
    raise exception 'Already booked';
  end if;
  select count(*) into v_taken from public.bookings b where b.session_id = p_session_id and b.status = 'booked';
  if v_taken >= v_capacity then raise exception 'Session is full'; end if;
  insert into public.bookings(session_id,user_id,status,booked_at,cancelled_at)
  values(p_session_id,v_user,'booked',now(),null)
  on conflict(session_id,user_id) do update set status='booked',booked_at=now(),cancelled_at=null
  returning id into v_booking;
  return v_booking;
end;
$$;
revoke all on function public.book_class_session(uuid) from public;
revoke all on function public.book_class_session(uuid) from anon;
grant execute on function public.book_class_session(uuid) to authenticated;

create or replace function public.get_class_session_availability()
returns table(id uuid, starts_at timestamptz, duration_minutes smallint, capacity integer, seats_available integer, program_title text, program_category text, trainer_name text)
language sql stable security definer set search_path = '' as $$
  select s.id,s.starts_at,s.duration_minutes,s.capacity::integer,
    greatest(s.capacity - count(b.id)::integer,0),p.title,p.category,t.full_name
  from public.class_sessions s join public.programs p on p.id=s.program_id join public.trainers t on t.id=s.trainer_id
  left join public.bookings b on b.session_id=s.id and b.status='booked'
  where s.status='scheduled' and s.starts_at>now() and p.is_published and t.is_published
  group by s.id,p.title,p.category,t.full_name order by s.starts_at;
$$;
revoke all on function public.get_class_session_availability() from public;
grant execute on function public.get_class_session_availability() to anon, authenticated;

grant usage on schema public to anon, authenticated;
revoke all on public.profiles, public.programs, public.trainers, public.program_trainers,
  public.membership_plans, public.memberships, public.class_sessions, public.bookings
  from public, anon, authenticated;
grant select on public.programs, public.trainers, public.program_trainers, public.membership_plans, public.class_sessions to anon, authenticated;
grant select, insert, update on public.profiles to authenticated;
grant select on public.memberships to authenticated;
grant insert on public.memberships to authenticated;
grant select on public.bookings to authenticated;
grant update(status, cancelled_at) on public.bookings to authenticated;
grant all on public.profiles, public.programs, public.trainers, public.program_trainers,
  public.membership_plans, public.memberships, public.class_sessions, public.bookings to service_role;

insert into storage.buckets(id, name, public, file_size_limit, allowed_mime_types)
values('club-media','club-media',true,10485760,array['image/jpeg','image/png','image/webp','image/avif'])
on conflict(id) do update set public=excluded.public, file_size_limit=excluded.file_size_limit, allowed_mime_types=excluded.allowed_mime_types;
drop policy if exists "Read public club media" on storage.objects;
create policy "Read public club media" on storage.objects for select to anon, authenticated using(bucket_id = 'club-media');
drop policy if exists "Users upload own profile photos" on storage.objects;
create policy "Users upload own profile photos" on storage.objects for insert to authenticated
  with check(bucket_id='club-media' and (storage.foldername(name))[1]='profiles' and (storage.foldername(name))[2]=(select auth.uid())::text);
drop policy if exists "Users update own profile photos" on storage.objects;
create policy "Users update own profile photos" on storage.objects for update to authenticated
  using(bucket_id='club-media' and (storage.foldername(name))[1]='profiles' and (storage.foldername(name))[2]=(select auth.uid())::text)
  with check(bucket_id='club-media' and (storage.foldername(name))[1]='profiles' and (storage.foldername(name))[2]=(select auth.uid())::text);

-- Booking capacity is enforced transactionally by book_class_session(); direct inserts are revoked.
commit;
