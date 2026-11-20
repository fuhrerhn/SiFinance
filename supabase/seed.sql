-- Local demo accounts, seeded by Supabase CLI on start/reset.
insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
  confirmation_token, recovery_token, email_change_token_new, email_change
)
select
  '00000000-0000-0000-0000-000000000000', id, 'authenticated', 'authenticated',
  email, extensions.crypt('SiFinanceDemo123!', extensions.gen_salt('bf')), now(),
  '{"provider":"email","providers":["email"]}'::jsonb,
  jsonb_build_object('full_name', full_name), now(), now(), '', '', '', ''
from (values
  ('10000000-0000-4000-8000-000000000001'::uuid, 'demo-a@example.com', 'Demo A'),
  ('10000000-0000-4000-8000-000000000002'::uuid, 'demo-b@example.com', 'Demo B')
) as demo(id, email, full_name)
on conflict (id) do nothing;

insert into auth.identities (provider_id, user_id, identity_data, provider, created_at, updated_at)
select id::text, id, jsonb_build_object('sub', id::text, 'email', email), 'email', now(), now()
from auth.users where id in (
  '10000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000002'
)
on conflict (provider_id, provider) do nothing;

delete from public.transactions where user_id in (
  '10000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000002'
);

insert into public.transactions (user_id, category_id, type, transaction_date, amount)
select demo.user_id, c.id, c.group_name,
  (date_trunc('month', current_date) - make_interval(months => demo.months_ago))::date,
  demo.amount
from (values
  ('10000000-0000-4000-8000-000000000001'::uuid, 'makanan', 0, 450000.00),
  ('10000000-0000-4000-8000-000000000001'::uuid, 'transportasi', 0, 250000.00),
  ('10000000-0000-4000-8000-000000000001'::uuid, 'tagihan', 0, 550000.00),
  ('10000000-0000-4000-8000-000000000001'::uuid, 'gaji', 0, 5200000.00),
  ('10000000-0000-4000-8000-000000000001'::uuid, 'belanja', 1, 960000.00),
  ('10000000-0000-4000-8000-000000000001'::uuid, 'tagihan', 2, 1320000.00),
  ('10000000-0000-4000-8000-000000000001'::uuid, 'makanan', 4, 830000.00),
  ('10000000-0000-4000-8000-000000000001'::uuid, 'hiburan', 5, 670000.00),
  ('10000000-0000-4000-8000-000000000002'::uuid, 'kesehatan', 0, 875000.00)
) as demo(user_id, slug, months_ago, amount)
join public.categories c using (slug);
