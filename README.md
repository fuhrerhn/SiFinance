# SiFinance
> **Spend wise. life nice.**

SiFinance adalah aplikasi pengelolaan keuangan pribadi dan keluarga yang dikembangkan menggunakan **Flutter**. Aplikasi ini bertujuan mempermudah pencatatan transaksi, pengaturan anggaran, dan pemantauan arus kas sehari-hari dalam satu tempat.

Repositori ini berisi pengembangan aplikasi Flutter berdasarkan [prototipe desain SiFinance](https://sifinance.framer.website/).

> **Status pengembangan:** Tahap awal. Repositori ini dibuat menggunakan `flutter create sifinance`. Halaman AI Chat sudah diimplementasikan. Pengembangan fitur lainnya mengikuti rencana di bawah.

## Fitur yang Direncanakan

| Fitur | Deskripsi | Status |
| --- | --- | --- |
| **Dashboard** | Menampilkan ringkasan kondisi keuangan dan arus kas. | Direncanakan |
| **Pengelolaan Anggaran** | Menetapkan anggaran pengeluaran dan memantau penggunaannya. | Direncanakan |
| **Pencatatan Transaksi Manual** | Mencatat pemasukan dan pengeluaran beserta detail transaksinya. | Direncanakan |
| **Pencatatan Berbantuan AI** | Mempermudah pencatatan transaksi dengan bantuan kecerdasan buatan. | Direncanakan |
| **AI Chat** | Balasan cepat, percakapan keuangan, dan lampiran gambar sesuai desain SiFinance. | Diimplementasikan |

## Teknologi

- **Flutter** = Framework untuk pengembangan aplikasi lintas platform.
- **Dart** = Bahasa pemrograman yang digunakan.

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


### Menjalankan Aplikasi
Lihat perangkat yang tersedia:
```bash
flutter devices
```
Jalankan aplikasi:
```bash
flutter run
```

Untuk menjalankan pada perangkat tertentu, gunakan `flutter run -d <device-id>`.

> Aplikasi membuka halaman AI Chat. Tanpa `API_BASE_URL`, aplikasi berjalan dalam mode demo dengan balasan contoh.
### AI Chat
Tampilan meliputi sapaan, empat balasan cepat, bubble pesan, avatar, waktu pesan, menu lampiran, preview gambar, retry, dan reset percakapan. Font Poppins dan aset Figma disimpan di `assets/`. Kode halaman tersedia di `lib/features/chat/`.
Preview dapat dijalankan melalui browser.
```bash
flutter run -d chrome
```

Untuk memakai model AI, gunakan Node.js 22+, buat API key pada Google AI Studio, lalu salin konfigurasi berikut dan isi `GEMINI_API_KEY` di `server/.env`.
```powershell
Copy-Item server/.env.example server/.env
cd server
npm start
```

Jalankan Flutter dari root proyek pada terminal lain.

```bash
flutter run -d chrome --web-port 5173 --dart-define=API_BASE_URL=http://localhost:8080
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
- [ ] Mengimplementasikan sistem desain dan navigasi.
- [ ] Membuat dashboard keuangan.
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

