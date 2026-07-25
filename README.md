# Jorena Smart Residence

Aplikasi manajemen perumahan berbasis Flutter dan Firebase. Mendukung tiga peran pengguna: **Warga**, **Satpam**, dan **Admin**.

---

## Fitur Utama

- Autentikasi berbasis **email** + password (login, register, lupa password). `username` tetap dikumpulkan saat registrasi sebagai field profil, tapi login memakai email, bukan username.
- Dashboard warga — berita, layanan, keluhan, tagihan, komunitas
- Dashboard satpam — patroli, catat tamu, laporan insiden, keluhan warga
- Dashboard admin — manajemen warga, keamanan, laporan, berita, tamu, billing
- Pembayaran iuran via **Pakasir** (QRIS) — status lunas diverifikasi oleh server webhook terpisah, bukan client, lihat [Server Backend (Vercel)](#server-backend-vercel)
- SOS & Bantuan Satpam realtime via Firestore
- Notifikasi push via **OneSignal** + notifikasi lokal untuk SOS — pengiriman notifikasi dilakukan oleh **server tepercaya** (Vercel), bukan langsung dari app, sehingga REST API Key OneSignal tidak ikut terkemas ke APK (lihat [Server Backend (Vercel)](#server-backend-vercel))
- Aplikasi **tidak menyimpan satu pun kredensial rahasia** — seluruh secret (`PAKASIR_API_KEY`, `ONESIGNAL_REST_API_KEY`, service account Firebase) hanya hidup sebagai environment variable di server Vercel. App **tidak lagi memakai file `.env`/`flutter_dotenv`**
- Foto (bukti keluhan, bantuan, patroli, berita, profil) disimpan sebagai **base64 data URI langsung di field Firestore** (mis. `fotoUrls`, `imageUrl`, `photoUrl`) — project ini **tidak** memakai Firebase Storage sama sekali (tidak ada paket `firebase_storage` di `pubspec.yaml`)

---

## Prasyarat

Pastikan semua tools berikut sudah terpasang di komputer Anda:

| Tool | Versi Minimum | Link |
|------|---------------|------|
| Flutter SDK | 3.10.0 | https://docs.flutter.dev/get-started/install |
| Dart SDK | 3.0.0 | (bundled dengan Flutter) |
| Android Studio / VS Code | terbaru | https://developer.android.com/studio |
| Node.js | 18.x | https://nodejs.org (untuk Firebase CLI & server webhook) |
| Firebase CLI | terbaru | `npm install -g firebase-tools` |
| Git | terbaru | https://git-scm.com |

Verifikasi instalasi Flutter:
```bash
flutter doctor
```
Pastikan tidak ada tanda ✗ pada Android toolchain dan connected device.

---

## Instalasi

### 1. Clone Repository

```bash
git clone https://github.com/<username>/aplikasismartresidence.git
cd aplikasismartresidence
```

### 2. Install Dependencies Flutter

```bash
flutter pub get
```

### 3. Konfigurasi Client (tidak perlu `.env`)

App **tidak lagi memakai file `.env`** — paket `flutter_dotenv` sudah dilepas. Semua nilai yang tidak sensitif ditulis langsung sebagai konstanta di kode, dan semua nilai rahasia sudah dipindah ke server (lihat [Server Backend (Vercel)](#server-backend-vercel)). Jadi `flutter pub get` lalu `flutter run` sudah cukup, **tidak ada langkah `cp .env.example .env`**.

Kalau perlu mengganti konfigurasi client (mis. untuk deployment sendiri), ubah konstanta berikut langsung di kode:

| Nilai | Lokasi | Keterangan |
|-------|--------|------------|
| Slug Pakasir | `PakasirService._slug` di `lib/core/services/pakasir_service.dart` | Nama proyek Pakasir; bukan rahasia (ikut tampil di URL pembayaran) |
| OneSignal App ID | `OneSignalService.appId` di `lib/core/services/onesignal_service.dart` | ID publik, aman di client |
| Endpoint notifikasi | `OneSignalService.notificationEndpoint` di file yang sama | URL server Vercel, perbarui bila nama project Vercel berubah |

> `PAKASIR_API_KEY` dan `ONESIGNAL_REST_API_KEY` **tidak ada di client sama sekali** — keduanya sensitif dan hanya hidup sebagai environment variable di server (`server/.env` untuk dev lokal / Vercel Environment Variables untuk production). Lihat [Server Backend (Vercel)](#server-backend-vercel).

### 4. Firebase

> **Tidak perlu setup Firebase tambahan.**
> File `google-services.json` sudah disertakan di repository sehingga aplikasi langsung terhubung ke backend Firebase yang sudah berjalan.

Jika Anda ingin menggunakan **Firebase project milik sendiri** (misalnya untuk deployment terpisah), ikuti langkah berikut:

<details>
<summary>Setup Firebase project sendiri (opsional)</summary>

1. Buka [Firebase Console](https://console.firebase.google.com) → buat proyek baru
2. Aktifkan: **Authentication** (Email/Password) dan **Firestore**
   (Cloud Functions **tidak** dipakai di project ini — lihat catatan di `functions/index.js` untuk alasannya. **Storage** juga tidak dipakai — semua foto disimpan sebagai base64 langsung di dokumen Firestore, lihat [Fitur Utama](#fitur-utama))
3. Daftarkan app Android dengan package name `com.example.aplikasismartresidence`
4. Download `google-services.json` dan letakkan di `android/app/`
5. Deploy Firestore Rules dari repo (sudah di-versionkan di `firestore.rules`, bukan lagi diatur manual lewat Console):
   ```bash
   firebase login
   firebase use <project-id-anda>
   firebase deploy --only firestore:rules
   ```

</details>

### 5. Struktur Koleksi Firestore

Buat koleksi berikut secara manual atau melalui aplikasi:

| Koleksi | Keterangan |
|---------|------------|
| `users` | Data pengguna. Field: `uid`, `username`, `namaLengkap`, `email`, `role` (`"user"` = warga, `"satpam"`, `"admin"`), `blok`, `nomorUnit`, `isOnDuty` |
| `tagihan` | Tagihan iuran bulanan warga (status `belumBayar`/`lunas`, `orderId` Pakasir, dll.) |
| `keluhan` | Laporan keluhan warga |
| `bantuanrequest` | Permintaan bantuan satpam |
| `sosalert` | Alert SOS darurat |
| `patroli` | Log patroli satpam |
| `insiden` | Laporan insiden satpam |
| `catatantamu` | Data tamu masuk |
| `beritaacara` | Berita & pengumuman perumahan (nama koleksi aktual, bukan `berita`) |
| `settings` | Konfigurasi (kontak pengelola, dll.) |

Untuk menambah admin pertama, buat dokumen di koleksi `users` dengan field `role: "admin"` setelah registrasi.

---

## Cara Menjalankan

### Mode Development (Emulator / Device)

```bash
# Jalankan di device/emulator yang terhubung
flutter run

# Jalankan di Chrome (web)
flutter run -d chrome

# Pilih device secara manual
flutter devices          # lihat daftar device
flutter run -d <device-id>
```

### Build APK (Android)

```bash
# Debug APK
flutter build apk --debug

# Release APK (perlu signing key)
flutter build apk --release
```

File APK tersimpan di:
```
build/app/outputs/flutter-apk/app-release.apk
```

### Build App Bundle (untuk Google Play)

```bash
flutter build appbundle --release
```

---

## Server Backend (Vercel)

Semua logika yang butuh kredensial rahasia berjalan di satu server serverless (Node.js/TypeScript) di folder `server/`, deploy ke Vercel. App Flutter tidak memegang satu pun secret. Ada dua endpoint:

| Endpoint | File | Fungsi |
|----------|------|--------|
| `/api/pakasir-webhook` | `server/api/pakasir-webhook.ts` | Menerima webhook pembayaran Pakasir, verifikasi ulang, tandai tagihan lunas di Firestore |
| `/api/send-notification` | `server/api/send-notification.ts` | Mengirim push OneSignal setelah memverifikasi Firebase ID Token & peran pemanggil |

Kode bersama ada di `server/lib/` (`firebase.ts`, `notifications.ts`, `onesignal.ts`). Cara deploy & set environment variables ada di `server/README.md`.

### Verifikasi pembayaran

Verifikasi status pembayaran Pakasir **tidak** dilakukan oleh app Flutter (client tidak bisa dipercaya untuk keputusan finansial). Alurnya:

```
Pakasir → webhook → server/api/pakasir-webhook.ts (Vercel) → verifikasi ulang ke Pakasir
        → tulis status:'lunas' ke Firestore via Firebase Admin SDK
        → app Flutter listen perubahan itu lewat Firestore stream
```

- Latar belakang masalah, keputusan arsitektur, dan status implementasi ada di `docs/payment_webhook_fix_prompt.md`.
- Firestore Security Rules untuk collection `tagihan` (di `firestore.rules`) membatasi warga hanya boleh mengubah field `orderId` miliknya sendiri — field `status`/`tanggalBayar`/`metodeBayar` eksklusif ditulis admin (manual) atau server webhook (Admin SDK, bypass rules).
- Project ini **tidak** menggunakan Firebase Cloud Functions/Blaze plan untuk apa pun, termasuk seed tagihan bulanan otomatis — lihat catatan di `functions/index.js` (disimpan sebagai referensi, tidak di-deploy) dan `PaymentRepository.ensureAllMissingTagihan()` sebagai gantinya yang jalan dari client.

### Pengiriman notifikasi

Dulu app memanggil REST API OneSignal langsung memakai `ONESIGNAL_REST_API_KEY` yang dibaca dari `.env` — dan karena `.env` ikut dikemas sebagai asset, key itu bocor ke setiap APK. Sekarang app hanya mengirim jenis kejadian + ID dokumen Firestore ke `server/api/send-notification.ts`; server memverifikasi Firebase ID Token pemanggil, membaca dokumennya, lalu menyusun sendiri isi pesan dan daftar penerima. REST API Key hanya hidup di server.

---

## Struktur Folder

```
lib/
├── core/
│   ├── data/              # Repository lintas-fitur (keluhan, SOS, bantuan)
│   ├── router/             # AppRouter (named routes)
│   ├── services/           # Pakasir, OneSignal, SOS notification
│   ├── theme/              # AppColors, AppTheme, AppSpacing, AppTextStyles, AppConstants
│   └── utils/               # Helper (responsive, dll.)
├── features/
│   ├── admin/             # Dashboard admin: berita, billing, fasilitas, insiden,
│   │                       #   payment_detail, reports, security, tamu, warga_user
│   ├── auth/               # data/ (AuthRepository), pages/ (login, register, lupa
│   │                       #   password), widgets/
│   ├── berita/             # Berita untuk warga (list & detail)
│   ├── home/                # Home warga (satpam home ada di features/satpam/home)
│   ├── komunitas/           # Direktori warga
│   ├── layanan/             # Layanan: fasilitas, kantin, lapor keluhan, pusat bantuan
│   ├── pembayaran/          # Tagihan & halaman pembayaran Pakasir
│   ├── profile/              # Profil & pengaturan akun
│   ├── satpam/               # Dashboard satpam: home, insiden, laporan, patroli, tamu
│   ├── security/              # Sisa modul security bersama: bantuan, sos, helpers
│   └── splash/                 # Splash screen
└── shared/
    └── widgets/                # Widget reusable (bottom nav, empty state, loading, dll.)

assets/
├── images/                 # Logo dan gambar
└── sounds/                  # Ringtone SOS & notifikasi

server/                      # Server serverless (Vercel) — terpisah dari app Flutter
├── api/
│   ├── pakasir-webhook.ts   # Endpoint verifikasi pembayaran Pakasir
│   └── send-notification.ts # Endpoint pengiriman push OneSignal
└── lib/                      # Kode bersama (firebase, notifications, onesignal)

functions/                   # Cloud Functions — TIDAK di-deploy (project tidak pakai Blaze), disimpan sebagai referensi
```

---

## Akun Role untuk Testing

Buat akun melalui fitur Register di aplikasi (default role saat registrasi adalah warga), lalu ubah field `role` di Firestore kalau perlu akun satpam/admin:

| Role | Field di Firestore |
|------|-------------------|
| Warga (default) | `role: "user"` |
| Satpam | `role: "satpam"` |
| Admin | `role: "admin"` |

---

## Troubleshooting

**`google-services.json` not found**
→ Pastikan file berada di `android/app/google-services.json`

**Gradle build failed**
```bash
cd android && ./gradlew clean
flutter clean && flutter pub get
```

**Flutter doctor menunjukkan masalah Android SDK**
→ Buka Android Studio → SDK Manager → install Android SDK 33+

**Notifikasi push tidak muncul**
→ Pengiriman notifikasi dilakukan server (`server/api/send-notification.ts`), bukan app. Pastikan server sudah di-deploy ke Vercel, `ONESIGNAL_APP_ID` + `ONESIGNAL_REST_API_KEY` sudah diset di Environment Variables, dan `OneSignalService.notificationEndpoint` di app menunjuk ke URL Vercel yang benar. Lihat `server/README.md`.

**APK ter-install tapi macet di splash screen**
→ Biasanya mismatch nama resource icon (`@mipmap/ic_launcher` vs `@mipmap/launcher_icon` dari `flutter_launcher_icons`). Cek `lib/core/services/sos_notification_service.dart` dan `lib/main.dart`.

**Firestore permission denied**
→ Periksa `firestore.rules` sudah ter-deploy (`firebase deploy --only firestore:rules`) dan sesuai dengan operasi yang dilakukan (mis. warga tidak boleh menulis field `status` di `tagihan`, lihat bagian Pembayaran & Webhook Server).

**Status tagihan tidak berubah jadi lunas setelah bayar**
→ Ini ditulis oleh server webhook, bukan app. Pastikan `server/` sudah di-deploy ke Vercel, environment variables sudah diset, dan webhook URL sudah didaftarkan di dashboard Pakasir. Lihat `server/README.md`.

**Foto gagal tersimpan / error saat kirim keluhan-bantuan-patroli**
→ Foto disimpan sebagai base64 di field Firestore (bukan Firebase Storage), jadi ukurannya ikut menambah ukuran dokumen. Firestore membatasi ukuran dokumen maksimal ±1 MiB — kalau foto terlalu besar/banyak dalam satu laporan, penyimpanan bisa gagal. Kompres/batasi resolusi foto di `image_picker` kalau ini terjadi.

---

## Teknologi yang Digunakan

- [Flutter](https://flutter.dev) — UI framework
- [Firebase Auth](https://firebase.google.com/docs/auth) — Autentikasi
- [Cloud Firestore](https://firebase.google.com/docs/firestore) — Database realtime (termasuk foto, disimpan sebagai base64 — **tidak** ada Firebase Storage di project ini)
- [Pakasir](https://pakasir.com) — Payment gateway QRIS untuk iuran warga
- [Vercel](https://vercel.com) — Hosting server serverless: verifikasi pembayaran + pengiriman notifikasi (`server/`)
- [OneSignal](https://onesignal.com) — Push notification (dikirim dari server, bukan client)
- [Google Fonts](https://pub.dev/packages/google_fonts) — Tipografi
- [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications) — Notifikasi lokal

> Firebase Cloud Functions **tidak dipakai** (project sengaja tidak upgrade ke plan Blaze) — lihat `functions/index.js` dan bagian Pembayaran & Webhook Server di atas.
