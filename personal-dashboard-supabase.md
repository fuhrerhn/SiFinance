# Rencana Implementasi Personal Dashboard SiFinance dengan Supabase

## Status

- **Mode:** Plan
- **Tanggal:** 20 November 2026
- **Repository:** `/Users/barie/work/sereinne/flutter/tekber`
- **Referensi utama:** `sifinace-cdr.pdf`
- **Referensi visual:** <https://sifinance.framer.website>
- **Referensi teknis:** Dokumentasi Supabase terbaru, termasuk changelog `supabase-flutter` v3.

## Tujuan

Mengimplementasikan **Personal Dashboard** SiFinance di Flutter denganSupabase sebagai sumber data dan batas keamanan, mencakup:

- Autentikasi pengguna.
- Ringkasan total pengeluaran pribadi.
- Grafik batang pengeluaran bulanan.
- Rata-rata pengeluaran enam bulan terakhir.
- Grafik lingkaran pengeluaran per kategori.
- Filter periode.
- Loading, empty, error, dan retry state.
- Row Level Security agar setiap pengguna hanya dapat mengakses data pribadinya.

## Sumber dan interpretasi requirement

Bagian utama dari `sifinace-cdr.pdf`:

- **FR-06:** Sistem harus dapat menampilkan dashboard personal berisi total pengeluaran, grafik batang pengeluaran bulanan beserta rata-rata 6 bulan terakhir, dan grafik lingkaran per kategori, dengan filter periode.
- **Storyboard 5.6:** Pengguna membuka Beranda, memilih tab Dashboard, lalu melihat total pengeluaran, grafik batang bulanan, dan grafik lingkaran per kategori.
- **Robustness diagram 5.6.1:** Dashboard mengambil data dari Akun, Transaksi, Budget, dan Kategori.
- **Sequence diagram 5.6.2:** Controller dashboard mengambil data akun, transaksi, budget, dan kategori sebelum menampilkan ringkasan.
- **ER-Diagram:** Domain model menggunakan `akun`, `family_group`, `transaksi`, `kategori`, `budget`, `sesi_ai_chatbot`, dan `chat`.

Adaptasi ini mengikuti kebutuhan personal dashboard dan_media_placeholder_ignored:

- `akun` dipecah menjadi data autentikasi di `auth.users` dan profil aplikasi di `public.profiles`.
- `transaksi` dan `kategori` diadaptasi ke naming Postgres/Supabase.
- `budget` tetap dipertahankan sebagai fondasi schema, tetapi UI/CRUD budget ditunda.
- Relasi keluarga tidak dibuat pada fase ini.

## Scope

### Termasuk

- Inisialisasi Supabase lokal dan konfigurasi environment.
- Dependency `supabase_flutter`, chart, dan format mata uang/tanggal.
- Migration tabel, index, trigger profil, RLS, grants, dan seed lokal.
- Generated Dart database types.
- Supabase client initialization.
- Minimal email/password authentication: sign-up, sign-in, session restoration, dan sign-out.
- Feature-first Personal Dashboard sesuai pola `lib/features/chat/`.
- Repository Supabase dan agregasi expenditure summary.
- Filter periode.
- Bar chart, pie chart, category list, dan currency formatting.
- App shell/navigation ringan.
- Unit, widget, RLS, dan integration testing.

### Tidak termasuk

- Family Dashboard.
- Family Group, anggota keluarga, undangan, QR code, dan link undangan.
- Privasi keluarga dan selective sharing.
- Pembuatan/bergabung dengan keluarga.
- Input transaksi manual.
- AI voice logging.
- CRUD dan UI Budget.
- Halaman lengkap Riwayat Transaksi dan Beranda.
- Penyimpanan riwayat AI chatbot di database.
- Sinkronisasi user lama ke Supabase Auth.

## Keputusan arsitektur

Rekomendasi yang dipakai dalam rencana ini:

1. Auth email/password masuk scope. Tanpa identitas `auth.uid()`, RLS tidak dapat diuji dengan benar.
2. `budgets` dibuat sebagai schema dasar, tetapi CRUD dan UI-nya ditunda.
3. Default filter adalah **Bulan ini**.
4. `categories` bersifat global dan dapat dibaca user terautentikasi.
5. `transactions` dan `budgets` dimiliki pengguna.
6. Family Group tidak dibuat sama sekali pada fase ini.
7. Agregasi awal dilakukan di Dart pada repository. Jika volume data meningkat, gunakan Postgres function `security invoker`.
8. Tidak ada fallback ke data dummy pada production. Data demo hanya melalui seed lokal.

---

# Rencana implementasi

## 1. Fondasi Supabase

### 1.1 Struktur repository Supabase

Tambahkan:

```text
supabase/
├── config.toml
├── migrations/
├── seed.sql
└── tests/
```

Tambahkan generated types:

```text
lib/core/supabase/generated/
```

Perintahinisialisasi yang direncanakan:

```bash
supabase init
supabase migration new create_personal_dashboard_schema
```

Repository belum memiliki declarative schema, sehingga gunakan imperative migrations.

### 1.2 Dependency Flutter

Tambahkan dan pin dependency yang dipakai:

- `supabase_flutter`
- `fl_chart` untuk bar chart dan pie chart.
- `intl` untuk format Rupiah, tanggal, dan periode.
- `supabase_typegen` sebagai dev dependency apabila versi dan toolchain-nya kompatibel.

Saat implementasi, periksa ulang pub.dev sebelum menetapkan versi. Saat referensi diperiksa, API pub.dev masih menunjukkan `supabase_flutter` `2.18.3` sebagai latest stable, walaupun changelog sudah menyiapkan v3. Jangan menggunakan v3 prerelease tanpa migrasi dan verifikasi kompatibilitas.

### 1.3 Konfigurasi client

Buat:

```text
lib/core/supabase/supabase_client.dart
lib/core/supabase/supabase_config.dart
```

Credential build-time:

```text
SUPABASE_URL=https://<project-ref>.supabase.co
SUPABASE_PUBLISHABLE_KEY=<publishable-key>
```

Contoh pemanggilan:

```bash
flutter run --dart-define-from-file=config/supabase.json
```

Jangan menyimpan `service_role`, secret key, atau token privileged di aplikasi/repository.

Inisialisasi sebelum `runApp`:

```dart
await Supabase.initialize(
  url: supabaseUrl,
  publishableKey: publishableKey,
);
```

---

## 2. Schema database

### 2.1 `profiles`

Menggantikan entity `akun` untuk data profil.

| Kolom | Tipe | Keterangan |
|---|---|---|
| `id` | `uuid` | PK, FK ke `auth.users.id` |
| `full_name` | `text` | Nama pengguna |
| `avatar_url` | `text` nullable | URL foto profil |
| `created_at` | `timestamptz` | Waktu pembuatan |
| `updated_at` | `timestamptz` | Waktu perubahan |

Tidak menyimpan `kata_sandi` atau `kode_verifikasi`; keduanya ditangani Supabase Auth.

Tidak membuat `family_group_id` atau privacy flags pada fase ini.

### 2.2 `categories`

| Kolom | Tipe | Keterangan |
|---|---|---|
| `id` | `bigint identity` | PK |
| `name` | `text` | Nama kategori |
| `slug` | `text` | Unik |
| `group_name` | `text` | `expense` atau `income` |
| `icon_name` | `text` nullable | Identitas ikon |
| `color_hex` | `text` nullable | Warna grafik |
| `is_active` | `boolean` | Status kategori |

Kategori global dan dapat dibaca semua pengguna terautentikasi. Client tidak memperoleh hak insert/update/delete.

### 2.3 `transactions`

Mengikuti entity `transaksi` PDF.

| Kolom | Tipe | Keterangan |
|---|---|---|
| `id` | `uuid` | PK |
| `user_id` | `uuid` | FK ke `auth.users.id` |
| `category_id` | `bigint` | FK ke `categories.id` |
| `type` | `text` | `income` atau `expense` |
| `transaction_date` | `date` | Tanggal transaksi |
| `amount` | `numeric(14,2)` | Nominal, selalu positif |
| `description` | `text` nullable | Keterangan |
| `location` | `text` nullable | Lokasi |
| `payment_account` | `text` nullable | Akun pembayaran |
| `created_at` | `timestamptz` | Waktu pembuatan |
| `updated_at` | `timestamptz` | Waktu perubahan |

`transaksi_pribadi` tidak diperlukan karena belum ada konsep keluarga. Semua transaksi otomatis merupakan data pribadi pemilik.

Constraint:

```sql
check (type in ('income', 'expense'))
check (amount > 0)
```

### 2.4 `budgets`

Schema fondasi sesuai PDF:

| Kolom | Tipe | Keterangan |
|---|---|---|
| `id` | `uuid` | PK |
| `user_id` | `uuid` | FK ke `auth.users.id` |
| `category_id` | `bigint` | FK ke `categories.id` |
| `limit_amount` | `numeric(14,2)` | Total anggaran |
| `period_type` | `text` | `monthly`, `weekly`, `custom` |
| `start_date` | `date` | Mulai periode |
| `end_date` | `date` | Selesai periode |
| `created_at` | `timestamptz` | Waktu pembuatan |
| `updated_at` | `timestamptz` | Waktu perubahan |

`total_terpakai` tidak disimpan sebagai sumber kebenaran karena mudah menjadi stale. Nilai tersebut dihitung dari transaksi atau query terkomputasi.

### 2.5 Tabel yang ditunda

- `family_groups`
- `family_group_members`
- `family_invitations`
- `ai_chat_sessions`
- `ai_chats`

Model keluarga pada masa depan sebaiknya memakai membership terpisah, bukan satu `family_group_id` langsung pada profil.

---

## 3. Index, trigger, RLS, dan grants

### 3.1 Index

```sql
create index transactions_user_id_idx
  on public.transactions(user_id);

create index transactions_user_date_idx
  on public.transactions(user_id, transaction_date desc);

create index transactions_user_type_date_idx
  on public.transactions(user_id, type, transaction_date desc);

create index transactions_category_id_idx
  on public.transactions(category_id);

create index budgets_user_id_idx
  on public.budgets(user_id);
```

### 3.2 Profile trigger

Tambahkan trigger pada `auth.users` yang membuat row `profiles` otomatis setelah signup.

Trigger function:

- Menggunakan `security definer`.
- Mematok `search_path`.
- Mengqualified-kan seluruh object reference.
- Eksekusinya direvoke dari public role.

Name profil dapat memakai metadata signup sebagai default, tetapi `user_metadata` tidak boleh dipakai untuk otorisasi.

### 3.3 RLS

Semua tabel exposed wajib memiliki RLS.

#### `profiles`

- `anon`: tidak mendapat akses.
- `authenticated`: dapat select dan update profil sendiri.
- Insert hanya mengizinkan `id = auth.uid()`.

Contoh select policy:

```sql
using ((select auth.uid()) = id)
```

#### `transactions`

Owner dapat:

- Select transaksi dengan `user_id = auth.uid()`.
- Insert transaksi dengan `user_id = auth.uid()`.
- Update transaksi miliknya tanpa reassign owner.
- Delete transaksi miliknya.

Update policy wajib mempunyai `USING` dan `WITH CHECK`.

#### `budgets`

Pengguna hanya dapat mengakses budget dengan `user_id = auth.uid()`.

#### `categories`

- `authenticated`: select only.
- `anon`: tidak mendapat akses.
- Client tidak mendapat insert/update/delete.

### 3.4 Grants

Untuk setiap tabel exposed:

```sql
revoke all on table public.<table> from anon, authenticated;
```

Kemudian berikan hanya privilege yang dibutuhkan:

- Signed-in user mendapat CRUD pada data pribasinya.
- `anon` tidak mendapat grant apa pun untuk data keuangan.
- `categories` hanya mendapat select untuk `authenticated`.

Karena perubahan Oktober 2026, jangan mengasumsikan tabel baru otomatis terekspos ke Data API. Verifikasi exposure dan grant pada project.

---

## 4. Autentikasi minimum

Buat:

```text
lib/features/auth/
├── data/
│   └── auth_repository.dart
├── domain/
│   └── auth_state.dart
└── presentation/
    ├── auth_page.dart
    ├── sign_in_page.dart
    └── sign_up_page.dart
```

Perilaku:

1. Aplikasi memeriksa session Supabase saat dibuka.
2. Belum login → sign-in/sign-up.
3. Sudah login → app shell dan Personal Dashboard.
4. Sign-out menghapus session dan kembali ke auth gate.
5. Register membuat Supabase Auth user; profile dibuat database trigger.
6. Error email sudah terdaftar, password lemah, kredensial salah, dan konfirmasi password harus ditampilkan dengan pesan yang jelas.

Google sign-in tidak masuk fase pertama. Email/password cukup untuk membuktikan fondasi Auth dan RLS.

---

## 5. Arsitektur dashboard

Gunakan feature-first structure yang selaras dengan `lib/features/chat/`:

```text
lib/features/dashboard/
├── data/
│   ├── dashboard_repository.dart
│   └── supabase_dashboard_repository.dart
├── domain/
│   ├── dashboard_summary.dart
│   ├── category_spending.dart
│   ├── monthly_spending.dart
│   └── dashboard_period.dart
└── presentation/
    ├── dashboard_page.dart
    ├── dashboard_controller.dart
    └── widgets/
        ├── total_expense_card.dart
        ├── period_filter.dart
        ├── monthly_expense_chart.dart
        ├── category_expense_chart.dart
        ├── category_spending_list.dart
        └── dashboard_state_views.dart
```

### 5.1 Domain model

`DashboardSummary`:

- `totalExpense`
- `averageMonthlyExpense`
- `monthlySpendings`
- `categorySpendings`
- `selectedPeriod`
- `startDate`
- `endDate`

`MonthlySpending`:

- bulan
- total pengeluaran
- penanda bulan tanpa data

`CategorySpending`:

- kategori
- total pengeluaran
- persentase
- warna

### 5.2 Controller

`DashboardController` menggunakan `ChangeNotifier`, tanpa menambah package state management besar pada fase ini.

Tanggung jawab:

- Memuat data.
- Menyimpan periode terpilih.
- Menghitung atau meminta agregasi.
- Mengubah loading/error/data state.
- Reload setelah filter berubah.
- Mengekspos state siap render.

Controller diuji dengan fake repository agar unit test tidak bergantung pada Supabase.

---

## 6. Repository dan perhitungan dashboard

Gunakan dua cakupan data agar filter periode dan rata-rata enam bulan tidak saling bertentangan.

### 6.1 Periode terpilih

Ambil transaksi:

```text
type = expense
transaction_date >= startDate
transaction_date <= endDate
```

Hitung:

- Total pengeluaran.
- Pengeluaran per kategori.
- Persentase setiap kategori.

### 6.2 Enam bulan terakhir

Secara terpisah ambil transaksi pengeluaran dari awal bulan ke-6 sampai akhir bulan berjalan.

Hitung:

- Total per bulan.
- Rata-rata enam bulan.

Rata-rata wajib memasukkan bulan tanpa transaksi sebagai `0`, bukan hanya membagi jumlah bulan yang memiliki transaksi.

### 6.3 Query strategy

Repository Supabase:

1. Query `transactions` dengan embedded `categories` melalui foreign key.
2. Agregasikan hasil di Dart.

Untuk dataset pribadi fase pertama, ini cukup sederhana. Jika volume meningkat, pindahkan agregasi ke Postgres function `security invoker` agar RLS tetap diterapkan.

### 6.4 Filter periode

Pilihan:

- Bulan ini — default.
- 3 bulan.
- 6 bulan.
- Tahun ini.
- Semua waktu.

Filter kategori ditambahkan setelah filter periode stabil.

---

## 7. Tampilan Personal Dashboard

### 7.1 Struktur UI

- App bar dengan judul **Dashboard**.
- Filter periode.
- Card **Total Pengeluaran**.
- Card grafik batang **Pengeluaran per bulan**.
- Card grafik lingkaran **Pengeluaran per kategori**.
- List total dan persentase per kategori.
- Bottom navigation; tab Dashboard aktif.
- Tab yang belum diimplementasikan tidak boleh menampilkan data palsu.

### 7.2 Bar chart

- Sumbu X: bulan.
- Sumbu Y: nominal pengeluaran.
- Bulan tanpa transaksi tetap terlihat sebagai `0`.
- Rata-rata enam bulan ditampilkan sebagai annotation atau informasi terpisah.
- Tooltip menampilkan bulan, nominal, dan format Rupiah.

### 7.3 Pie chart

- Slice per kategori.
- Warna konsisten dari `categories.color_hex`.
- Kategori tanpa pengeluaran tidak ditampilkan.
- Persentase dibulatkan konsisten.
- Sediakan legend/list sebagai fallback aksesibilitas.

### 7.4 Currency

Gunakan format Rupiah, misalnya:

```text
Rp1.250.000
```

Nominal disimpan sebagai `numeric`, bukan `float`, untuk menghindari kesalahan pembulatan.

### 7.5 State UI

- Loading: skeleton atau progress indicator.
- Empty: “Belum ada pengeluaran pada periode ini.”
- Error: pesan ringkas dan tombol coba lagi.
- Success: data visual.
- Filter kosong tetap mempertahankan filter aktif.

### 7.6 UI keluarga yang dikecualikan

Tidak merender:

- Kartu Family Dashboard.
- Tombol “Coba Sekarang”.
- QR undangan.
- Navigasi keluarga.

---

## 8. Navigasi aplikasi

Tambahkan shell ringan:

```text
lib/core/navigation/app_shell.dart
```

Behavior:

- Setelah auth berhasil, shell menjadi root.
- Tab Dashboard menampilkan Personal Dashboard.
- Tab AI Chat dapat membuka implementasi chat yang sudah ada.
- Tab lain yang belum memiliki fitur ditampilkan nonaktif atau sebagai placeholder yang jujur.
- Tidak membuat Beranda palsu dengan angka hard-coded.

---

## 9. Seed dan data pengembangan

`supabase/seed.sql` dapat berisi:

- Kategori pengeluaran: Makanan, Transportasi, Belanja, Tagihan, Hiburan, Kesehatan.
- Kategori pemasukan: Gaji, Bonus, Freelance, Lainnya.
- Contoh transaksi untuk user demo lokal.

Seed:

- Tidak berjalan otomatis pada production.
- Membersihkan data demo sebelum seeding ulang.
- Tidak menggunakan UUID production.
- Dipisahkan dari migration utama.

Empty state tetap wajib diuji karena pengguna baru tidak memiliki transaksi.

---

## 10. Pengujian

### 10.1 Unit test

- Perhitungan total pengeluaran.
- Transaksi `income` tidak masuk expenditure summary.
- Pengelompokan per kategori.
- Persentase kategori.
- Pembagian bulan dengan data dan tanpa data.
- Rata-rata enam bulan.
- Batas awal/akhir periode.
- Perubahan tanggal di sekitar tengah malam.
- Mapping error Supabase ke pesan UI.

### 10.2 Widget test

- Loading state.
- Error state dan retry.
- Empty state.
- Dashboard dengan data.
- Perubahan filter.
- Bar chart dan pie chart tampil.
- Nominal memakai format Rupiah.
- Kartu family tidak pernah muncul.

### 10.3 RLS test pgTAP

Untuk setiap tabel yang dilindungi:

- `anon` tidak dapat read/write.
- Signed-in owner dapat membaca data miliknya.
- Signed-in user lain tidak dapat membaca transaksi owner.
- User lain tidak dapat mengubah `user_id`.
- Update dan delete lintas pengguna ditolak.
- Insert dengan `user_id` milik orang lain ditolak.

### 10.4 Verifikasi akhir

```bash
flutter analyze
flutter test
supabase db lint
supabase test db
```

Jalankan local Supabase dan uji dengan dua user berbeda. Pastikan query user A tidak pernah menampilkan data user B.

---

## 11. Tahapan pengerjaan

### Tahap 1 — Supabase dan schema

- Inisialisasi project Supabase lokal.
- Migration tabel, index, trigger, RLS, dan grants.
- Seed kategori.
- RLS tests.
- Generate Dart database types.

### Tahap 2 — Supabase client dan auth

- Build-time configuration.
- `Supabase.initialize`.
- Auth repository.
- Sign-in/sign-up.
- Session state pada root application.

### Tahap 3 — Dashboard domain dan repository

- Domain models.
- Repository interface.
- Supabase repository implementation.
- Agregasi total, bulanan, dan per kategori.
- Unit test perhitungan.

### Tahap 4 — UI dashboard

- App shell dan Dashboard tab.
- Filter periode.
- Total expense card.
- Bar chart, pie chart, dan category list.
- Loading/error/empty/retry state.

### Tahap 5 — Integrasi dan hardening

- Uji dengan local data.
- Uji dua user untuk RLS.
- Analyzer, tests, db lint, dan Supabase test suite.
- Update README dengan setup Supabase dan cara menjalankan.
- Tambahkan seed transaksi demo khusus development.

---

# Acceptance criteria

Fitur selesai bila:

1. Pengguna dapat membuat akun dan masuk melalui Supabase.
2. Dashboard hanya menampilkan transaksi milik user aktif.
3. Total pengeluaran sesuai transaksi `expense` pada periode aktif.
4. Bar chart menampilkan tren bulanan.
5. Rata-rata enam bulan dihitung dengan benar.
6. Pie chart dan list menampilkan pengeluaran per kategori.
7. Filter periode bekerja dan dapat diganti.
8. Loading, empty, error, dan retry state tersedia.
9. User lain tidak dapat mengakses data melalui query, update, insert, atau delete.
10. Tidak ada Family Dashboard, undangan, QR, atau feature pembagian keluarga.
11. `flutter analyze`, `flutter test`, dan Supabase database tests lulus.
12. Tidak ada secret key dalam repository.

---

# Checklist implementasi

## Database

- [ ] `supabase init`
- [ ] Migration dibuat melalui `supabase migration new`
- [ ] Tabel `profiles`
- [ ] Tabel `categories`
- [ ] Tabel `transactions`
- [ ] Tabel `budgets`
- [ ] Constraint transaction
- [ ] Index dashboard
- [ ] Trigger pembuatan profil
- [ ] RLS seluruh tabel exposed
- [ ] Grants minimum
- [ ] Seed kategori
- [ ] pgTAP tests
- [ ] Dart types generated dan di-commit

## Flutter

- [ ] Dependency dikunci
- [ ] Supabase config via dart define
- [ ] Supabase client initialization
- [ ] Auth repository
- [ ] Sign-in/sign-up/sign-out
- [ ] Auth gate
- [ ] App shell
- [ ] Dashboard domain models
- [ ] Dashboard repository
- [ ] Dashboard controller
- [ ] Period filter
- [ ] Total expense card
- [ ] Monthly bar chart
- [ ] Category pie chart
- [ ] Category list
- [ ] Loading/error/empty/retry states
- [ ] Rupiah/date formatting

## Tests dan dokumentasi

- [ ] Unit test agregasi
- [ ] Widget test semua state dashboard
- [ ] RLS test owner/non-owner/anon
- [ ] Manual test dua user
- [ ] `flutter analyze`
- [ ] `flutter test`
- [ ] `supabase db lint`
- [ ] `supabase test db`
- [ ] README diperbarui

---

# Catatan risiko

1. **Versi Supabase Flutter:** changelog v3 mengubah API dan default sorting. Verifikasi versi stable dan migration guide saat implementasi.
2. **Data API exposure:** tabel public baru tidak otomatis diasumsikan terekspos. Grant dan exposure wajib diuji.
3. **RLS dan update:** policy update membutuhkan select policy serta `WITH CHECK`.
4. **Tanggal dan timezone:** gunakan `date` untuk tanggal transaksi dan tentukan batas periode berdasarkan zona waktu lokal pengguna.
5. **Kategori global:** kategori bukan data rahasia, tetapi hak write harus dibatasi.
6. **Budget drift:** jangan menyimpan total pemakaian budget sebagai sumber kebenaran.
7. **Data demo:** jangan masuk ke production atauخداع pengguna dengan angka hard-coded.
8. **Family extension:** model keluarga baru sebaiknya membership terpisah, bukan `family_group_id` langsung pada profil.
