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

delete from public.transaksi where user_id in (
  '10000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000002'
);

insert into public.transaksi (user_id, category_id, type, transaction_date, amount)
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
join public.kategori c using (slug);

insert into public.family_group (kode_qr, tautan_undangan)
values ('sifinance-demo-family', 'https://example.com/invite/sifinance-demo-family')
on conflict (kode_qr) do nothing;

update public.akun
set family_group_id = (select id from public.family_group where kode_qr = 'sifinance-demo-family')
where id in ('10000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000002');

insert into public.budget (id, user_id, category_id, limit_amount, period_type, start_date, end_date)
select demo.id, demo.user_id, c.id, demo.amount, 'monthly',
  date_trunc('month', current_date)::date,
  (date_trunc('month', current_date) + interval '1 month - 1 day')::date
from (values
  ('10000000-0000-4000-8000-000000000011'::uuid,
   '10000000-0000-4000-8000-000000000001'::uuid, 'makanan', 800000),
  ('10000000-0000-4000-8000-000000000012'::uuid,
   '10000000-0000-4000-8000-000000000002'::uuid, 'kesehatan', 1000000)
) as demo(id, user_id, slug, amount)
join public.kategori c using (slug)
on conflict (id) do nothing;

insert into public.sesi_ai_chatbot (sesi_id, akun_id) values
  ('10000000-0000-4000-8000-000000000021', '10000000-0000-4000-8000-000000000001'),
  ('10000000-0000-4000-8000-000000000022', '10000000-0000-4000-8000-000000000002')
on conflict (sesi_id) do nothing;

insert into public.chat (id, sesi_id, pesan, pengirim) values
  ('10000000-0000-4000-8000-000000000031', '10000000-0000-4000-8000-000000000021',
   'Berapa sisa anggaran makanan saya?', 'user'),
  ('10000000-0000-4000-8000-000000000032', '10000000-0000-4000-8000-000000000021',
   'Sisa anggaran makanan bulan ini Rp350.000.', 'assistant'),
  ('10000000-0000-4000-8000-000000000033', '10000000-0000-4000-8000-000000000022',
   'Berapa sisa anggaran kesehatan saya?', 'user')
on conflict (id) do nothing;
