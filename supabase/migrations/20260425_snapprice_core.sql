create extension if not exists pgcrypto;

create table if not exists public.users (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null,
  credits integer not null default 15 check (credits >= 0),
  plan text not null default 'free' check (plan in ('free', 'starter', 'pro', 'trader', 'money_printer')),
  created_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.analyses (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  image_url text not null,
  result jsonb not null,
  created_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.subscriptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references public.users(id) on delete cascade,
  stripe_customer_id text,
  stripe_subscription_id text unique,
  plan text not null default 'free' check (plan in ('free', 'starter', 'pro', 'trader', 'money_printer')),
  status text not null default 'inactive',
  current_period_end timestamptz,
  last_credit_refill_at timestamptz,
  created_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.credit_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  change integer not null,
  reason text not null,
  created_at timestamptz not null default timezone('utc', now())
);

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.users (id, email)
  values (new.id, coalesce(new.email, ''))
  on conflict (id) do update set email = excluded.email;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure public.handle_new_user();

insert into storage.buckets (id, name, public)
values ('uploads', 'uploads', false)
on conflict (id) do nothing;

alter table public.users enable row level security;
alter table public.analyses enable row level security;
alter table public.subscriptions enable row level security;
alter table public.credit_logs enable row level security;

drop policy if exists "Users can view own profile" on public.users;
create policy "Users can view own profile"
on public.users for select
to authenticated
using (auth.uid() = id);

drop policy if exists "Users can update own profile" on public.users;
create policy "Users can update own profile"
on public.users for update
to authenticated
using (auth.uid() = id)
with check (auth.uid() = id);

drop policy if exists "Users can view own analyses" on public.analyses;
create policy "Users can view own analyses"
on public.analyses for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists "Users can insert own analyses" on public.analyses;
create policy "Users can insert own analyses"
on public.analyses for insert
to authenticated
with check (auth.uid() = user_id);

drop policy if exists "Users can view own subscription" on public.subscriptions;
create policy "Users can view own subscription"
on public.subscriptions for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists "Users can view own credit logs" on public.credit_logs;
create policy "Users can view own credit logs"
on public.credit_logs for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists "Authenticated users can upload own files" on storage.objects;
create policy "Authenticated users can upload own files"
on storage.objects for insert
to authenticated
with check (
  bucket_id = 'uploads'
  and auth.uid()::text = split_part(name, '/', 1)
);

drop policy if exists "Authenticated users can view own files" on storage.objects;
create policy "Authenticated users can view own files"
on storage.objects for select
to authenticated
using (
  bucket_id = 'uploads'
  and auth.uid()::text = split_part(name, '/', 1)
);

drop policy if exists "Authenticated users can update own files" on storage.objects;
create policy "Authenticated users can update own files"
on storage.objects for update
to authenticated
using (
  bucket_id = 'uploads'
  and auth.uid()::text = split_part(name, '/', 1)
)
with check (
  bucket_id = 'uploads'
  and auth.uid()::text = split_part(name, '/', 1)
);

create or replace function public.apply_credit_pack(
  p_user_id uuid,
  p_amount integer,
  p_reason text
)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  updated_credits integer;
begin
  update public.users
  set credits = credits + p_amount
  where id = p_user_id;

  select credits
  into updated_credits
  from public.users
  where id = p_user_id;

  insert into public.credit_logs (user_id, change, reason)
  values (p_user_id, p_amount, p_reason);

  return updated_credits;
end;
$$;

create or replace function public.consume_credits_for_analysis(
  p_user_id uuid,
  p_image_url text,
  p_result jsonb,
  p_cost integer default 10
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  current_credits integer;
  updated_credits integer;
  analysis_id uuid;
begin
  select credits
  into current_credits
  from public.users
  where id = p_user_id
  for update;

  if current_credits is null then
    raise exception 'User profile not found';
  end if;

  if current_credits < p_cost then
    raise exception 'Insufficient credits';
  end if;

  update public.users
  set credits = credits - p_cost
  where id = p_user_id;

  select credits
  into updated_credits
  from public.users
  where id = p_user_id;

  insert into public.analyses (user_id, image_url, result)
  values (p_user_id, p_image_url, p_result)
  returning id
  into analysis_id;

  insert into public.credit_logs (user_id, change, reason)
  values (p_user_id, -p_cost, 'analysis');

  return jsonb_build_object(
    'analysis_id', analysis_id,
    'remaining_credits', updated_credits
  );
end;
$$;

create or replace function public.upsert_subscription_from_stripe(
  p_user_id uuid,
  p_customer_id text,
  p_subscription_id text,
  p_plan text,
  p_status text,
  p_current_period_end timestamptz,
  p_last_credit_refill_at timestamptz default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.subscriptions (
    user_id,
    stripe_customer_id,
    stripe_subscription_id,
    plan,
    status,
    current_period_end,
    last_credit_refill_at
  )
  values (
    p_user_id,
    p_customer_id,
    p_subscription_id,
    p_plan,
    p_status,
    p_current_period_end,
    p_last_credit_refill_at
  )
  on conflict (user_id) do update
  set stripe_customer_id = excluded.stripe_customer_id,
      stripe_subscription_id = excluded.stripe_subscription_id,
      plan = excluded.plan,
      status = excluded.status,
      current_period_end = excluded.current_period_end,
      last_credit_refill_at = coalesce(excluded.last_credit_refill_at, public.subscriptions.last_credit_refill_at);

  update public.users
  set plan = p_plan
  where id = p_user_id;
end;
$$;

create or replace function public.refill_due_subscription_credits()
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  row_record record;
  refill_amount integer;
  processed_count integer := 0;
begin
  for row_record in
    select *
    from public.subscriptions
    where status = 'active'
      and current_period_end > timezone('utc', now())
      and (
        last_credit_refill_at is null
        or last_credit_refill_at <= timezone('utc', now()) - interval '7 days'
      )
  loop
    refill_amount := case row_record.plan
      when 'starter' then 125
      when 'pro' then 250
      when 'trader' then 525
      when 'money_printer' then 925
      else 0
    end;

    if refill_amount > 0 then
      perform public.apply_credit_pack(
        row_record.user_id,
        refill_amount,
        'weekly_refill:' || row_record.plan
      );

      update public.subscriptions
      set last_credit_refill_at = timezone('utc', now())
      where id = row_record.id;

      processed_count := processed_count + 1;
    end if;
  end loop;

  return processed_count;
end;
$$;

grant execute on function public.apply_credit_pack(uuid, integer, text) to service_role;
grant execute on function public.consume_credits_for_analysis(uuid, text, jsonb, integer) to service_role;
grant execute on function public.upsert_subscription_from_stripe(uuid, text, text, text, text, timestamptz, timestamptz) to service_role;
grant execute on function public.refill_due_subscription_credits() to service_role;
