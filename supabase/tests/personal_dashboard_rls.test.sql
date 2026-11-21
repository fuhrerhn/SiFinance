begin;

create extension if not exists pgtap with schema extensions;
set local search_path = public, extensions;
select no_plan();

insert into auth.users (id, email, raw_user_meta_data) values
  ('20000000-0000-4000-8000-000000000001', 'rls-a@example.com', '{"full_name":"RLS A"}'),
  ('20000000-0000-4000-8000-000000000002', 'rls-b@example.com', '{"full_name":"RLS B"}');

insert into public.transaksi (id, user_id, category_id, type, transaction_date, amount)
select '20000000-0000-4000-8000-000000000003',
  '20000000-0000-4000-8000-000000000001', id, 'expense', current_date, 10000
from public.kategori where slug = 'makanan';

insert into public.budget (id, user_id, category_id, limit_amount, period_type, start_date, end_date)
select '20000000-0000-4000-8000-000000000004',
  '20000000-0000-4000-8000-000000000001', id, 50000, 'monthly', current_date, current_date + 30
from public.kategori where slug = 'makanan';

select ok(relrowsecurity, format('%s has RLS enabled', relname))
from pg_class
where relnamespace = 'public'::regnamespace
  and relname in ('akun', 'kategori', 'transaksi', 'budget');

set local role anon;
select throws_ok(format('select * from public.%I', table_name),
  '42501', format('permission denied for table %s', table_name),
  format('anon cannot read %s', table_name))
from unnest(array['akun', 'kategori', 'transaksi', 'budget']) as tables(table_name);
select ok(not has_table_privilege(current_user, 'public.' || table_name, 'INSERT, UPDATE, DELETE'),
  format('anon cannot write %s', table_name))
from unnest(array['akun', 'kategori', 'transaksi', 'budget']) as tables(table_name);

reset role;
set local role authenticated;
set local request.jwt.claim.sub = '20000000-0000-4000-8000-000000000001';

select is((select full_name from public.akun), 'RLS A', 'signup trigger and profile owner read');
select is((select count(*) from public.transaksi), 1::bigint, 'owner reads own transaksi');
select is((select count(*) from public.budget), 1::bigint, 'owner reads own budget');
select ok((select count(*) > 0 from public.kategori), 'authenticated reads global kategori');
select ok(not has_table_privilege(current_user, 'public.kategori', 'INSERT, UPDATE, DELETE'),
  'authenticated cannot write kategori');
select lives_ok($$update public.akun set full_name = 'Updated A'$$, 'owner can update profile');
select is((select full_name from public.akun), 'Updated A', 'profile update persisted');

select throws_ok($$update public.transaksi set user_id = '20000000-0000-4000-8000-000000000002'$$,
  '42501', 'new row violates row-level security policy for table "transaksi"', 'owner cannot reassign transaction');
select throws_ok($$update public.budget set user_id = '20000000-0000-4000-8000-000000000002'$$,
  '42501', 'new row violates row-level security policy for table "budget"', 'owner cannot reassign budget');
select throws_ok($$update public.akun set id = '20000000-0000-4000-8000-000000000002'$$,
  '42501', 'permission denied for table akun', 'owner cannot reassign profile');

set local request.jwt.claim.sub = '20000000-0000-4000-8000-000000000002';

select is((select full_name from public.akun), 'RLS B', 'other user sees their own profile only');
select is_empty($$select * from public.transaksi$$, 'other user cannot read transaksi');
select is_empty($$select * from public.budget$$, 'other user cannot read budget');
select is_empty($$update public.akun set full_name = 'Changed' where id = '20000000-0000-4000-8000-000000000001' returning id$$,
  'other user cannot update owner profile');
select is_empty($$update public.transaksi set user_id = '20000000-0000-4000-8000-000000000002' returning id$$,
  'other user cannot take ownership of a transaction');
select is_empty($$delete from public.transaksi returning id$$, 'other user cannot delete transaksi');
select is_empty($$update public.budget set limit_amount = 1 returning id$$, 'other user cannot update budget');
select is_empty($$delete from public.budget returning id$$, 'other user cannot delete budget');
select throws_ok($$insert into public.akun (id) values ('20000000-0000-4000-8000-000000000001')$$,
  '42501', 'new row violates row-level security policy for table "akun"', 'other user cannot insert owner profile');
select throws_ok($$insert into public.transaksi (user_id, category_id, type, transaction_date, amount)
  select '20000000-0000-4000-8000-000000000001', id, 'expense', current_date, 1
  from public.kategori where slug = 'makanan'$$,
  '42501', 'new row violates row-level security policy for table "transaksi"', 'cannot insert transaction for another user');
select throws_ok($$insert into public.budget (user_id, category_id, limit_amount, period_type, start_date, end_date)
  select '20000000-0000-4000-8000-000000000001', id, 1, 'monthly', current_date, current_date
  from public.kategori where slug = 'makanan'$$,
  '42501', 'new row violates row-level security policy for table "budget"', 'cannot insert budget for another user');

set local request.jwt.claim.sub = '20000000-0000-4000-8000-000000000001';
select is((select amount from public.transaksi), 10000::numeric, 'owner transaction remains intact');
select is((select limit_amount from public.budget), 50000::numeric, 'owner budget remains intact');
select results_eq($$update public.transaksi set amount = 20000 returning amount$$,
  $$values (20000::numeric)$$, 'owner can update transaction');
select results_eq($$delete from public.transaksi returning amount$$,
  $$values (20000::numeric)$$, 'owner can delete transaction');
select results_eq($$update public.budget set limit_amount = 60000 returning limit_amount$$,
  $$values (60000::numeric)$$, 'owner can update budget');
select results_eq($$delete from public.budget returning limit_amount$$,
  $$values (60000::numeric)$$, 'owner can delete budget');

reset role;
select * from finish();
rollback;
