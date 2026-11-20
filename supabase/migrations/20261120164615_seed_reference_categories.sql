insert into public.categories (name, slug, group_name, icon_name, color_hex) values
  ('Makanan', 'makanan', 'expense', 'restaurant', '#004CFF'),
  ('Transportasi', 'transportasi', 'expense', 'directions_bus', '#008979'),
  ('Belanja', 'belanja', 'expense', 'shopping_bag', '#9647D6'),
  ('Tagihan', 'tagihan', 'expense', 'receipt', '#CD6816'),
  ('Hiburan', 'hiburan', 'expense', 'movie', '#D64072'),
  ('Kesehatan', 'kesehatan', 'expense', 'medical_services', '#5366AA'),
  ('Gaji', 'gaji', 'income', 'payments', null),
  ('Bonus', 'bonus', 'income', 'redeem', null),
  ('Freelance', 'freelance', 'income', 'work', null),
  ('Lainnya', 'lainnya', 'income', 'more_horiz', null)
on conflict (slug) do nothing;
