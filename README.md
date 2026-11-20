# SiFinance
> **Spend wise. life nice.**

SiFinance adalah aplikasi pengelolaan keuangan pribadi dan keluarga yang dikembangkan menggunakan **Flutter**. Aplikasi ini bertujuan mempermudah pencatatan transaksi, pengaturan anggaran, dan pemantauan arus kas sehari-hari dalam satu tempat.

Repositori ini berisi pengembangan aplikasi Flutter berdasarkan [prototipe desain SiFinance](https://sifinance.framer.website/).

> **Status pengembangan** — Dashboard Personal dan AI Chat tersedia.

## Fitur yang Direncanakan

| Fitur | Deskripsi | Status |
| --- | --- | --- |
| **Dashboard Personal** | Menampilkan total pengeluaran, tren enam bulan, dan rincian kategori, dengan filter periode. | Diimplementasikan |
| **Pengelolaan Anggaran** | Menetapkan anggaran pengeluaran dan memantau penggunaannya. | Direncanakan |
| **Pencatatan Transaksi Manual** | Mencatat pemasukan dan pengeluaran beserta detail transaksinya. | Direncanakan |
| **Pencatatan Berbantuan AI** | Mempermudah pencatatan transaksi dengan bantuan kecerdasan buatan. | Direncanakan |
| **AI Chat** | Balasan cepat, percakapan keuangan, dan lampiran gambar sesuai desain SiFinance. | Diimplementasikan |

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


### Menjalankan Dashboard Personal

1. Pasang [Supabase CLI](https://supabase.com/docs/guides/cli) v3 dan jalankan Docker.
2. Jalankan `supabase start` dari root proyek. CLI menerapkan migrasi dan memuat data demo lokal.
3. Salin `config/supabase.example.json` ke `config/supabase.json`. Isi URL API dan publishable key dari `supabase status`. Gunakan `http://10.0.2.2:54321` pada Android Emulator.

```bash
flutter run --dart-define-from-file=config/supabase.json
```

Masuk dengan `demo-a@example.com` atau `demo-b@example.com` dan kata sandi `SiFinanceDemo123!`. Total pengeluaran bulan ini untuk kedua akun masing-masing Rp1.250.000 dan Rp875.000. Buat akun baru untuk melihat kondisi ketika belum ada transaksi. Filter mengubah total dan pembagian kategori. Grafik batang selalu memakai enam bulan kalender terakhir, termasuk bulan berjalan dan bulan dengan pengeluaran nol.

Untuk Supabase hosted, terapkan kedua migrasi ke proyek tujuan dan pastikan Data API mengekspos skema `public`. Gunakan URL HTTPS dan publishable key proyek. Jika konfirmasi email aktif di Auth, pengguna perlu mengonfirmasi alamat sebelum masuk. Data kategori referensi berasal dari migrasi. Akun dan transaksi demo berasal dari seed lokal.

Jalankan verifikasi berikut saat stack lokal aktif.

```bash
flutter analyze
flutter test
supabase db lint --schema public,private --fail-on warning
supabase test db
flutter test test/supabase_integration_test.dart \
  --dart-define-from-file=config/supabase.json \
  --dart-define=RUN_SUPABASE_INTEGRATION=true
```

Setelah migrasi skema berubah, buat ulang tipe Dart dari database lokal. Generator ini memakai `psql` dan Python 3 karena generator Supabase resmi membutuhkan pustaka Supabase Flutter v3.

```bash
python3 scripts/generate_supabase_types.py postgresql://postgres:postgres@127.0.0.1:54322/postgres
```

### AI Chat
Tampilan meliputi sapaan, empat balasan cepat, bubble pesan, avatar, waktu pesan, menu lampiran, preview gambar, retry, dan reset percakapan. Font Poppins dan aset Figma disimpan di `assets/`. Kode halaman tersedia di `lib/features/chat/`.
AI Chat tersedia dari navigasi Dashboard. Untuk membuka AI Chat saja, gunakan mode pengembangan berikut. Mode demo menampilkan balasan contoh saat `API_BASE_URL` kosong.
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
- [x] Membuat proyek Flutter.
- [x] Menambahkan navigasi Dashboard dan AI Chat.
- [x] Membuat Dashboard Personal.
- [ ] Mengimplementasikan pencatatan transaksi manual.
- [ ] Menambahkan pembuatan dan pemantauan anggaran.
- [ ] Mengintegrasikan pencatatan transaksi berbantuan AI.
- [ ] Menambahkan penyimpanan data dan pengujian aplikasi


Rencana pengembangan ini dapat berubah sesuai kebutuhan proyek.

## Referensi Desain
Pengembangan aplikasi mengacu pada prototipe desain SiFinance.
- [Website SiFinance](https://sifinance.framer.website/)

## Sumber Penting lainnya
- Final Report: https://drive.google.com/file/d/1pF_tffor4AOPkYp6tAFZOXg8ML9j8Nlf/view
- Figma: https://www.figma.com/design/i80Wqb7FH7h5xENDJIqadd/Workspace?node-id=651-11523
- Logbook: https://docs.google.com/spreadsheets/d/1j2anqDvT69hO2wmlaCmWk45P5Fl-iSF7MAmQIiyRJ2k/edit?gid=179656092#gid=179656092
- ProposalSifinance: https://docs.google.com/document/d/1TwlXNP-6PDe-9W5qGp9p6KpwvoDlnpAWJMJwtfQgt64/edit?usp=sharing

