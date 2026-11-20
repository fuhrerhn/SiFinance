begin;

create extension if not exists pgtap with schema extensions;
set local search_path = public, extensions;
select no_plan();

insert into auth.users (id, email, raw_user_meta_data) values
  ('20000000-0000-4000-8000-000000000001', 'rls-a@example.com', '{"full_name":"RLS A"}'),
  ('20000000-0000-4000-8000-000000000002', 'rls-b@example.com', '{"full_name":"RLS B"}');

insert into public.transactions (id, user_id, category_id, type, transaction_date, amount)
select '20000000-0000-4000-8000-000000000003',
  '20000000-0000-4000-8000-000000000001', id, 'expense', current_date, 10000
from public.categories where slug = 'makanan';

insert into public.budgets (id, user_id, category_id, limit_amount, period_type, start_date, end_date)
select '20000000-0000-4000-8000-000000000004',
  '20000000-0000-4000-8000-000000000001', id, 50000, 'monthly', current_date, current_date + 30
from public.categories where slug = 'makanan';

select ok(relrowsecurity, format('%s has RLS enabled', relname))
from pg_class
where relnamespace = 'public'::regnamespace
  and relname in ('profiles', 'categories', 'transactions', 'budgets');

set local role anon;
select throws_ok(format('select * from public.%I', table_name),
  '42501', format('permission denied for table %s', table_name),
  format('anon cannot read %s', table_name))
from unnest(array['profiles', 'categories', 'transactions', 'budgets']) as tables(table_name);
select ok(not has_table_privilege(current_user, 'public.' || table_name, 'INSERT, UPDATE, DELETE'),
  format('anon cannot write %s', table_name))
from unnest(array['profiles', 'categories', 'transactions', 'budgets']) as tables(table_name);

reset role;
set local role authenticated;
set local request.jwt.claim.sub = '20000000-0000-4000-8000-000000000001';

select is((select full_name from public.profiles), 'RLS A', 'signup trigger and profile owner read');
select is((select count(*) from public.transactions), 1::bigint, 'owner reads own transactions');
select is((select count(*) from public.budgets), 1::bigint, 'owner reads own budgets');
select ok((select count(*) > 0 from public.categories), 'authenticated reads global categories');
select ok(not has_table_privilege(current_user, 'public.categories', 'INSERT, UPDATE, DELETE'),
  'authenticated cannot write categories');
select lives_ok($$update public.profiles set full_name = 'Updated A'$$, 'owner can update profile');
select is((select full_name from public.profiles), 'Updated A', 'profile update persisted');

select throws_ok($$update public.transactions set user_id = '20000000-0000-4000-8000-000000000002'$$,
  '42501', 'new row violates row-level security policy for table "transactions"', 'owner cannot reassign transaction');
select throws_ok($$update public.budgets set user_id = '20000000-0000-4000-8000-000000000002'$$,
  '42501', 'new row violates row-level security policy for table "budgets"', 'owner cannot reassign budget');
select throws_ok($$update public.profiles set id = '20000000-0000-4000-8000-000000000002'$$,
  '42501', 'new row violates row-level security policy for table "profiles"', 'owner cannot reassign profile');

set local request.jwt.claim.sub = '20000000-0000-4000-8000-000000000002';

select is((select full_name from public.profiles), 'RLS B', 'other user sees their own profile only');
select is_empty($$select * from public.transactions$$, 'other user cannot read transactions');
select is_empty($$select * from public.budgets$$, 'other user cannot read budgets');
select is_empty($$update public.profiles set full_name = 'Changed' where id = '20000000-0000-4000-8000-000000000001' returning id$$,
  'other user cannot update owner profile');
select is_empty($$update public.transactions set user_id = '20000000-0000-4000-8000-000000000002' returning id$$,
  'other user cannot take ownership of a transaction');
select is_empty($$delete from public.transactions returning id$$, 'other user cannot delete transactions');
select is_empty($$update public.budgets set limit_amount = 1 returning id$$, 'other user cannot update budgets');
select is_empty($$delete from public.budgets returning id$$, 'other user cannot delete budgets');
select throws_ok($$insert into public.profiles (id) values ('20000000-0000-4000-8000-000000000001')$$,
  '42501', 'new row violates row-level security policy for table "profiles"', 'other user cannot insert owner profile');
select throws_ok($$insert into public.transactions (user_id, category_id, type, transaction_date, amount)
  select '20000000-0000-4000-8000-000000000001', id, 'expense', current_date, 1
  from public.categories where slug = 'makanan'$$,
  '42501', 'new row violates row-level security policy for table "transactions"', 'cannot insert transaction for another user');
select throws_ok($$insert into public.budgets (user_id, category_id, limit_amount, period_type, start_date, end_date)
  select '20000000-0000-4000-8000-000000000001', id, 1, 'monthly', current_date, current_date
  from public.categories where slug = 'makanan'$$,
  '42501', 'new row violates row-level security policy for table "budgets"', 'cannot insert budget for another user');

set local request.jwt.claim.sub = '20000000-0000-4000-8000-000000000001';
select is((select amount from public.transactions), 10000::numeric, 'owner transaction remains intact');
select is((select limit_amount from public.budgets), 50000::numeric, 'owner budget remains intact');
select results_eq($$update public.transactions set amount = 20000 returning amount$$,
  $$values (20000::numeric)$$, 'owner can update transaction');
select results_eq($$delete from public.transactions returning amount$$,
  $$values (20000::numeric)$$, 'owner can delete transaction');
select results_eq($$update public.budgets set limit_amount = 60000 returning limit_amount$$,
  $$values (60000::numeric)$$, 'owner can update budget');
select results_eq($$delete from public.budgets returning limit_amount$$,
  $$values (60000::numeric)$$, 'owner can delete budget');

reset role;
select * from finish();
rollback;
