create schema if not exists private;

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null default '',
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.categories (
  id bigint generated always as identity primary key,
  name text not null,
  slug text not null unique,
  group_name text not null check (group_name in ('expense', 'income')),
  icon_name text,
  color_hex text check (color_hex ~ '^#[0-9a-fA-F]{6}$'),
  is_active boolean not null default true
);

create table public.transactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  category_id bigint not null references public.categories(id),
  type text not null check (type in ('expense', 'income')),
  transaction_date date not null,
  amount numeric(14,2) not null check (amount > 0 and amount <> 'NaN'::numeric),
  description text,
  location text,
  payment_account text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.budgets (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  category_id bigint not null references public.categories(id),
  limit_amount numeric(14,2) not null check (limit_amount > 0 and limit_amount <> 'NaN'::numeric),
  period_type text not null check (period_type in ('monthly', 'weekly', 'custom')),
  start_date date not null,
  end_date date not null check (end_date >= start_date),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index transactions_user_id_idx on public.transactions(user_id);
create index transactions_user_date_idx on public.transactions(user_id, transaction_date desc);
create index transactions_user_type_date_idx on public.transactions(user_id, type, transaction_date desc, id);
create index transactions_category_id_idx on public.transactions(category_id);
create index budgets_user_id_idx on public.budgets(user_id);
create index budgets_category_id_idx on public.budgets(category_id);

create function private.create_profile()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  insert into public.profiles (id, full_name)
  values (new.id, coalesce(new.raw_user_meta_data ->> 'full_name', ''));
  return new;
end;
$$;

create function private.set_updated_at()
returns trigger language plpgsql set search_path = '' as $$
begin
  new.updated_at := pg_catalog.now();
  return new;
end;
$$;

revoke all on function private.create_profile() from public, anon, authenticated;
revoke all on function private.set_updated_at() from public, anon, authenticated;

create trigger create_profile_after_signup after insert on auth.users
for each row execute function private.create_profile();

insert into public.profiles (id, full_name)
select id, coalesce(raw_user_meta_data ->> 'full_name', '') from auth.users
on conflict (id) do nothing;

create trigger profiles_updated_at before update on public.profiles
for each row execute function private.set_updated_at();
create trigger transactions_updated_at before update on public.transactions
for each row execute function private.set_updated_at();
create trigger budgets_updated_at before update on public.budgets
for each row execute function private.set_updated_at();

alter table public.profiles enable row level security;
alter table public.categories enable row level security;
alter table public.transactions enable row level security;
alter table public.budgets enable row level security;

revoke all on table public.profiles, public.categories, public.transactions, public.budgets
from public, anon, authenticated;

grant select, insert, update on public.profiles to authenticated;
grant select on public.categories to authenticated;
grant select, insert, update, delete on public.transactions, public.budgets to authenticated;
grant select, insert, update, delete on public.profiles, public.categories, public.transactions, public.budgets
to service_role;

create policy profiles_select_own on public.profiles for select to authenticated
using ((select auth.uid()) = id);
create policy profiles_insert_own on public.profiles for insert to authenticated
with check ((select auth.uid()) = id);
create policy profiles_update_own on public.profiles for update to authenticated
using ((select auth.uid()) = id) with check ((select auth.uid()) = id);

create policy categories_select_authenticated on public.categories for select to authenticated
using (true);

create policy transactions_manage_own on public.transactions for all to authenticated
using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);

create policy budgets_manage_own on public.budgets for all to authenticated
using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
