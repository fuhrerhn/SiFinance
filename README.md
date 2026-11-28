# SiFinance
> **Spend wise. life nice.**

SiFinance adalah aplikasi pengelolaan keuangan pribadi dan keluarga yang dikembangkan menggunakan **Flutter**. Aplikasi ini bertujuan mempermudah pencatatan transaksi, pengaturan anggaran, dan pemantauan arus kas sehari-hari dalam satu tempat.

Repositori ini berisi pengembangan aplikasi Flutter berdasarkan [prototipe desain SiFinance](https://sifinance.framer.website/).

## Fitur

| Menu | Implementasi |
| --- | --- |
| **Beranda** | Halaman utama setelah autentikasi atau masuk ke mode demo. Mode Supabase menyediakan akses cepat ke Dashboard Personal dan Budget. Mode demo menampilkan contoh ringkasan berlabel. |
| **Dashboard** | Total pengeluaran, tren dan rata-rata enam bulan, pembagian per kategori, dan filter periode. |
| **Catat** | Formulir pemasukan dan pengeluaran. Simpan transaksi untuk memperbarui Dashboard dan penggunaan Budget. |
| **Budget** | Tambah dan edit anggaran bulanan per kategori. Kartu menampilkan batas, pemakaian, sisa, dan persentase. |
| **AI Chat** | Percakapan keuangan, pertanyaan cepat, dan lampiran gambar. Memakai respons demo jika server AI belum dikonfigurasi. |
| **Transaksi** | Riwayat transaksi masih dalam pengembangan. Menu menampilkan pemberitahuan. |

## Teknologi

- **Flutter** = Framework untuk pengembangan aplikasi lintas platform.
- **Dart** = Bahasa pemrograman yang digunakan.
- **Supabase** = Autentikasi email/password, penyimpanan data, dan kontrol akses per akun.

AI Chat menggunakan HTTP, flutter_svg, image_picker, dan file_selector. Backend Node.js menghubungkan model Gemini dengan pemeriksaan topik khusus SiFinance dan keuangan.

## Memulai
### Prasyarat
- [Flutter SDK](https://docs.flutter.dev/get-started/install) sudah terpasang dan dikonfigurasi.
- Flutter 3.47+ dengan Dart 3.13+. Batas minimum Dart disesuaikan dengan kode AI Chat dan SDK pengembangan yang tersedia.
- Perangkat, emulator, atau browser yang mendukung Flutter.

Periksa lingkungan pengembangan:
```bash
flutter doctor
```

### Instalasi
```bash
git clone https://github.com/b4r1e/SIfinance.git sifinance/
cd sifinance
flutter pub get
```


### Mode demo di browser

```bash
flutter run -d web-server
```

Buka alamat yang dicetak Flutter. Alurnya dimulai dari splash dan onboarding, lalu formulir demo dan Beranda. Formulir demo menyimulasikan masuk dan pendaftaran. Anggaran serta transaksi baru tersimpan dalam memori selama Beranda terbuka. Data demo akan kembali kosong setelah keluar atau memuat ulang aplikasi.

### Mode Supabase di browser

1. Untuk backend lokal, pasang Supabase CLI, jalankan Docker, lalu jalankan `supabase start` dari root proyek. CLI menerapkan migrasi dan memuat data demo lokal.
2. Salin `config/supabase.example.json` ke `config/supabase.json`. Isi `SUPABASE_URL` dan `SUPABASE_PUBLISHABLE_KEY` dari proyek hosted atau keluaran `supabase status` untuk lingkungan lokal.
3. Jalankan Flutter dan buka `http://127.0.0.1:5173/`.

```bash
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 5173 --dart-define-from-file=config/supabase.json
```

Setelah splash dan onboarding, pilih **Masuk** atau **Daftar** jika sesi belum tersedia. Jika browser masih menyimpan sesi Supabase untuk origin tersebut, tombol **Lanjut** langsung membuka Beranda. Gunakan tombol keluar di Beranda untuk mengakhiri sesi. Pendaftaran hosted mengikuti pengaturan konfirmasi email proyek. Autentikasi yang terintegrasi menggunakan email dan kata sandi.

Dashboard, Catat, dan Budget menggunakan data Supabase milik akun yang masuk. Di **Budget**, gunakan **Tambah** untuk memilih kategori, menetapkan batas, dan memilih periode **Setiap Bulan**. Pemakaian dihitung dari pengeluaran kategori tersebut pada bulan berjalan. Grafik Dashboard selalu menampilkan enam bulan kalender terakhir, sedangkan filter mengubah total dan pembagian kategori.

Untuk Android Emulator dengan Supabase lokal, gunakan URL `http://10.0.2.2:54321`. Pada seed lokal, akun `demo-a@example.com` dan `demo-b@example.com` memakai kata sandi `SiFinanceDemo123!`. Total pengeluaran bulan berjalan masing-masing Rp1.250.000 dan Rp875.000.

Untuk Supabase hosted, terapkan seluruh migrasi ke proyek tujuan dan pastikan Data API mengekspos skema `public`. Gunakan URL HTTPS dan publishable key proyek pada konfigurasi Flutter. Tambahkan data demo secara terpisah dari migrasi jika proyek memang dipakai untuk pengembangan.

#### Pemetaan skema ke CDR

| Entitas CDR | Implementasi PostgreSQL |
| --- | --- |
| `akun` | `id` UUID merujuk ke Supabase Auth, `full_name` untuk nama, `family_group_id` opsional, dan tiga pengaturan privasi boolean. Email, kata sandi, dan kode verifikasi dikelola Supabase Auth. |
| `transaksi` | `user_id` dan `category_id` sebagai FK, `amount` sebagai `numeric(14,2)`, `transaction_date` sebagai `date`, serta tipe, keterangan, lokasi, akun pembayaran, dan `transaksi_pribadi`. |
| `kategori` | `name` dan `group_name` bertipe `text`, dengan ID `bigint` dan metadata tampilan. |
| `budget` | FK ke akun dan kategori, `limit_amount` bertipe `numeric(14,2)`, tipe periode, dan tanggal awal/akhir. Field API `total_terpakai` dihitung dari pengeluaran pada periode anggaran. Di SQL, gunakan `public.total_terpakai(b)` dengan `b` sebagai baris anggaran. |
| `family_group` | ID `bigint`, `kode_qr`, dan `tautan_undangan`. |
| `sesi_ai_chatbot` | `sesi_id` dan `akun_id` bertipe UUID, serta `waktu_mulai` bertipe `timestamptz`. |
| `chat` | ID dan FK sesi bertipe UUID, `waktu_kirim` bertipe `timestamptz`, serta `pesan`, `lampiran` opsional, dan `pengirim`. |

Seed lokal mengisi dua akun, sembilan transaksi, dua anggaran, satu grup keluarga, dua sesi AI, dan tiga pesan. Grup dan riwayat chat tersedia di database. Tab AI Chat yang ada masih menyimpan percakapan selama halaman terbuka, dan transaksi pribadi hanya terlihat oleh pemiliknya.

Jalankan verifikasi berikut saat stack lokal aktif.

```bash
flutter analyze
flutter test
supabase db lint --schema public,private --fail-on warning
supabase test db
flutter test test/supabase_integration_test.dart \
  --dart-define-from-file=config/supabase.colima.local.json \
  --dart-define=RUN_SUPABASE_INTEGRATION=true
```

Setelah migrasi skema berubah, buat ulang tipe Dart dari database lokal. Generator ini memakai `psql` dan Python 3 karena generator Supabase resmi membutuhkan pustaka Supabase Flutter v3.

```bash
python3 scripts/generate_supabase_types.py postgresql://postgres:postgres@127.0.0.1:54322/postgres
```

### AI Chat
Tampilan meliputi sapaan, empat balasan cepat, bubble pesan, avatar, waktu pesan, menu lampiran, preview gambar, retry, dan reset percakapan. Font Poppins dan aset Figma disimpan di `assets/`. Kode halaman tersedia di `lib/features/chat/`.
AI Chat tersedia dari navigasi bawah Beranda. Untuk membuka AI Chat saja, gunakan mode pengembangan berikut. Mode demo menampilkan balasan contoh saat `API_BASE_URL` kosong.
```bash
flutter run -d chrome --dart-define=CHAT_ONLY=true
```

Untuk memakai model AI, gunakan Node.js 22+, buat API key pada Google AI Studio, lalu salin konfigurasi berikut dan isi `GEMINI_API_KEY` di `server/.env`.
```powershell
Copy-Item server/.env.example server/.env
cd server
npm start
```

Jalankan Flutter dari root proyek pada terminal lain.

```bash
flutter run -d chrome --web-port 5173 --dart-define=CHAT_ONLY=true --dart-define=API_BASE_URL=http://localhost:8080
```

Android Emulator menggunakan `--dart-define=API_BASE_URL=http://10.0.2.2:8080`. HTTP lokal diizinkan pada build debug Android. Konfigurasi Android menggunakan NDK `30.0.16248370` dan `kotlin.incremental=false` untuk mengatasi cache Kotlin lintas drive Windows.

Backend memakai `gemini-3.5-flash-lite` dan free tier mengikuti kuota project Google. Nama model dapat diatur melalui `GEMINI_MODEL`. API key disimpan di server. Pemeriksaan topik dilakukan sebelum membuat jawaban dan sekali lagi sebelum jawaban ditampilkan. Respons pemeriksaan yang tidak valid menghasilkan penolakan tetap. Satu percakapan yang lolos memerlukan tiga panggilan model.

Konteks produk dari laporan tersedia pada `server/context.md`. Data transaksi akun belum terhubung. Pengguna dapat mengirimkan angka dan gambar transaksi untuk analisis. Chat tersimpan selama halaman terbuka. Mode demo menggunakan respons tetap. Perilaku model nyata memerlukan pengujian dengan API key aktif, dan pemeriksaan model bersifat probabilistik.

Gambar yang didukung adalah JPG, PNG, dan WebP dengan ukuran maksimal 4 MB. Ketersediaan kamera mengikuti platform. Riwayat yang dikirim pada pertanyaan lanjutan berisi teks. Lampirkan kembali gambar untuk analisis ulang.

Pemeriksaan kode dan alur chat dapat dijalankan dengan perintah berikut.
```bash
flutter analyze
flutter test
cd server
npm test
```

## Struktur Proyek
Struktur proyek mencakup aplikasi Flutter dan modul AI Chat pada `lib/features/chat/`, aset pada `assets/`, serta backend pada `server/`.
```text
sifinance/
├── android/          # Konfigurasi platform Android
├── ios/              # Konfigurasi platform iOS
├── lib/
│   └── main.dart     # Titik masuk aplikasi
├── test/              # Pengujian otomatis
├── pubspec.yaml      # Dependensi dan metadata proyek
└── README.md
```
Direktori platform lain mungkin tersedia, tergantung platform yang diaktifkan saat proyek dibuat.

## Rencana Pengembangan

- Menghubungkan ringkasan Beranda dengan saldo, transaksi terakhir, dan anggaran akun.
- Menambahkan riwayat transaksi dan pencatatan melalui perintah suara.
- Menambahkan Family Group dan pengaturan privasi dari antarmuka.
- Menghubungkan AI Chat dengan data akun dan penyimpanan riwayat percakapan.

## Referensi Desain
Pengembangan aplikasi mengacu pada prototipe desain SiFinance.
- [Website SiFinance](https://sifinance.framer.website/)

## Dokumentasi

- [Bab III · Implementasi SIFinance](BAB-3-SIFinance.md)
- Final Report: https://drive.google.com/file/d/1pF_tffor4AOPkYp6tAFZOXg8ML9j8Nlf/view
- Figma: https://www.figma.com/design/i80Wqb7FH7h5xENDJIqadd/Workspace?node-id=651-11523
- Logbook: https://docs.google.com/spreadsheets/d/1j2anqDvT69hO2wmlaCmWk45P5Fl-iSF7MAmQIiyRJ2k/edit?gid=179656092#gid=179656092
- ProposalSifinance: https://docs.google.com/document/d/1TwlXNP-6PDe-9W5qGp9p6KpwvoDlnpAWJMJwtfQgt64/edit?usp=sharing

