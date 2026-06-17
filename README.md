# Jorena Smart Residence

Aplikasi manajemen perumahan berbasis Flutter dan Firebase. Mendukung tiga peran pengguna: **Warga**, **Satpam**, dan **Admin**.

---

## Fitur Utama

- Autentikasi berbasis username (login, register, lupa password)
- Dashboard warga — berita, layanan, keluhan, tagihan, komunitas
- Dashboard satpam — patroli, catat tamu, laporan insiden, keluhan warga
- Dashboard admin — manajemen warga, keamanan, laporan, berita, tamu
- SOS & Bantuan Satpam realtime via Firestore
- Upload foto bukti keluhan ke Firebase Storage
- Notifikasi lokal untuk SOS

---

## Prasyarat

Pastikan semua tools berikut sudah terpasang di komputer Anda:

| Tool | Versi Minimum | Link |
|------|---------------|------|
| Flutter SDK | 3.10.0 | https://docs.flutter.dev/get-started/install |
| Dart SDK | 3.0.0 | (bundled dengan Flutter) |
| Android Studio / VS Code | terbaru | https://developer.android.com/studio |
| Node.js | 18.x | https://nodejs.org (untuk Firebase CLI) |
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

### 3. Firebase

> **Tidak perlu setup Firebase tambahan.**
> File `google-services.json` sudah disertakan di repository sehingga aplikasi langsung terhubung ke backend Firebase yang sudah berjalan.

Jika Anda ingin menggunakan **Firebase project milik sendiri** (misalnya untuk deployment terpisah), ikuti langkah berikut:

<details>
<summary>Setup Firebase project sendiri (opsional)</summary>

1. Buka [Firebase Console](https://console.firebase.google.com) → buat proyek baru
2. Aktifkan: **Authentication** (Email/Password), **Firestore**, **Storage**, **Cloud Functions**
3. Daftarkan app Android dengan package name `com.example.aplikasismartresidence`
4. Download `google-services.json` dan letakkan di `android/app/`
5. Set Firestore Rules:
   ```
   match /{document=**} {
     allow read, write: if request.auth != null;
   }
   ```
6. Set Storage Rules:
   ```
   match /{allPaths=**} {
     allow read, write: if request.auth != null;
   }
   ```

</details>

### 4. Struktur Koleksi Firestore

Buat koleksi berikut secara manual atau melalui aplikasi:

| Koleksi | Keterangan |
|---------|------------|
| `users` | Data pengguna (warga, satpam, admin). Field: `uid`, `username`, `namaLengkap`, `email`, `role`, `blok`, `nomorUnit`, `isOnDuty` |
| `keluhan` | Laporan keluhan warga |
| `bantuanrequest` | Permintaan bantuan satpam |
| `sosalert` | Alert SOS darurat |
| `patroli` | Log patroli satpam |
| `insiden` | Laporan insiden satpam |
| `catatantamu` | Data tamu masuk |
| `berita` | Berita perumahan |
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

## Struktur Folder

```
lib/
├── core/
│   ├── router/          # AppRouter (named routes)
│   ├── services/        # Keluhan, SOS, Bantuan service
│   └── theme/           # AppColors
├── features/
│   ├── admin/           # Halaman & logika admin
│   ├── auth/            # Login, register, lupa password
│   ├── home/            # Home warga & satpam
│   ├── komunitas/       # Direktori warga
│   ├── layanan/         # Layanan, keluhan, darurat
│   ├── pembayaran/      # Tagihan
│   ├── profile/         # Profil & pengaturan
│   ├── security/        # Satpam: patroli, tamu, insiden
│   └── splash/          # Splash screen
└── shared/
    └── widgets/         # Widget reusable (bottom nav, dll.)

assets/
├── images/              # Logo dan gambar
└── sounds/              # Ringtone SOS & notifikasi
```

---

## Akun Role untuk Testing

Buat akun melalui fitur Register di aplikasi, lalu ubah field `role` di Firestore:

| Role | Field di Firestore |
|------|-------------------|
| Warga (default) | `role: "warga"` |
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

**Firestore permission denied**
→ Periksa Security Rules di Firebase Console, pastikan user sudah login

**Foto tidak terupload**
→ Periksa Storage Rules di Firebase Console, pastikan path `keluhan/` diizinkan

---

## Teknologi yang Digunakan

- [Flutter](https://flutter.dev) — UI framework
- [Firebase Auth](https://firebase.google.com/docs/auth) — Autentikasi
- [Cloud Firestore](https://firebase.google.com/docs/firestore) — Database realtime
- [Firebase Storage](https://firebase.google.com/docs/storage) — Penyimpanan foto
- [Cloud Functions](https://firebase.google.com/docs/functions) — Backend logic
- [Google Fonts](https://pub.dev/packages/google_fonts) — Tipografi
- [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications) — Notifikasi lokal
