# Prompt: Perbaikan Verifikasi Pembayaran Pakasir (Server-Side Webhook)

> Simpan file ini dan gunakan sebagai prompt/brief saat siap mengerjakan perbaikan ini
> (bisa ditempel langsung ke sesi Claude/agent baru — sudah berisi semua konteks yang
> dibutuhkan tanpa perlu menjelaskan ulang dari awal).

## 1. Masalah yang Diperbaiki

Aplikasi Smart Residence (Flutter + Firebase) punya fitur pembayaran iuran via **Pakasir**
(payment gateway QRIS). Alur saat ini **100% ditentukan oleh klien**:

1. `lib/features/pembayaran/pakasir_payment_page.dart` membuka URL pembayaran Pakasir
   di browser, lalu **polling** status pembayaran tiap 4 detik lewat
   `PakasirService.getTransactionStatus()`.
2. Begitu klien melihat status `completed`, method `_handleSuccess()` di halaman yang
   sama **langsung memanggil** `PaymentRepository.markManyAsLunas()` dari Flutter client
   untuk menandai tagihan lunas di Firestore.
3. `lib/core/services/pakasir_service.dart` menyimpan `PAKASIR_API_KEY` di file `.env`
   yang di-bundle ke dalam aplikasi (`flutter_dotenv`) dan dipakai langsung dari client
   untuk memanggil API `transactiondetail` Pakasir.

**Risiko:** tidak ada pihak server yang independen memverifikasi pembayaran. Karena
logika "tandai lunas" ada di klien dan `api_key` Pakasir ikut ter-bundle di APK, secara
teori seseorang yang mem-reverse-engineer app atau intercept traffic bisa memicu
`markManyAsLunas` tanpa benar-benar membayar. Ini murni soal *trust boundary*
(klien tidak boleh dipercaya untuk keputusan yang berdampak finansial), bukan soal ACID.

## 2. Solusi yang Disepakati

Pindahkan **keputusan "lunas atau tidak"** dari klien ke **server terpisah** yang menerima
webhook resmi dari Pakasir, memverifikasi ulang, baru menulis ke Firestore.

Constraint penting dari pemilik project: **tidak mau upgrade Firebase ke plan Blaze**,
jadi solusinya **BUKAN** Firebase Cloud Functions. Server verifikasi ini di-host di
platform lain yang punya free tier tanpa kartu kredit.

**Rekomendasi hosting: Vercel** (serverless function Node.js/TypeScript).
Alasan (sudah dianalisis, lihat referensi di bagian 7): gratis selamanya tanpa kartu
kredit, tidak ada cold-start/sleep (beda dengan Render yang tidur setelah 15 menit idle
dan butuh 30–60 detik bangun — berisiko webhook Pakasir timeout menunggu respons).
Railway per 2026 sudah mewajibkan kartu pembayaran, jadi tidak dipakai.

> Kalau saat mengerjakan ini ternyata preferensi hosting berubah, konfirmasi dulu ke user
> sebelum mulai — jangan asumsikan Vercel kalau belum dikonfirmasi ulang di sesi tsb.

## 3. Arsitektur Target

```
Pakasir (setelah user scan QRIS & bayar)
   │  POST webhook: {amount, order_id, project, status, payment_method, completed_at}
   ▼
Server webhook (Vercel serverless function, endpoint baru, mis. /api/pakasir-webhook)
   │  1. Terima payload webhook
   │  2. Verifikasi ULANG ke Pakasir API transactiondetail pakai api_key
   │     (api_key HANYA hidup di server, sebagai env var — TIDAK ADA di app Flutter lagi)
   │     GET https://app.pakasir.com/api/transactiondetail
   │         ?project={slug}&amount={amount}&order_id={order_id}&api_key={api_key}
   │  3. Kalau status benar-benar "completed" DAN amount cocok →
   │     tulis ke Firestore pakai Firebase Admin SDK (service account, bukan client SDK)
   ▼
Firestore collection `tagihan`
   status: 'lunas', tanggalBayar, metodeBayar, orderId  ← ditulis SERVER, bukan client

Flutter client (pakasir_payment_page.dart)
   - Tetap boleh polling untuk keperluan UI ("menunggu" → "berhasil"), TAPI
   - Polling ke Firestore (watchUserTagihan / snapshot), BUKAN memutuskan sendiri lalu
     menulis status. Client hanya "membaca" hasil yang sudah ditulis server.
   - `markManyAsLunas()` dari client TIDAK dipanggil lagi dari halaman ini.
```

## 4. Kode yang Relevan (existing, jangan diasumsikan berubah tanpa dicek ulang)

- `lib/features/pembayaran/pakasir_payment_page.dart`
  - `_initPayment()` (baris ~63): generate `orderId`, panggil
    `PaymentRepository.setOrderIdForMany()`, buka URL pembayaran.
  - `_startPolling()` (baris ~100): `Timer.periodic` 4 detik, cek
    `PakasirService.getTransactionStatus()` → kalau `isPaid()` panggil `_handleSuccess()`.
  - `_handleSuccess()` (baris ~117): **inilah yang harus diubah** — saat ini langsung
    `PaymentRepository.markManyAsLunas(...)`. Setelah perbaikan, method ini seharusnya
    cukup **menunggu Firestore ter-update oleh server** (misal lewat stream listener ke
    dokumen tagihan, bukan polling API Pakasir untuk menentukan lunas).
- `lib/core/services/pakasir_service.dart`
  - `buildPaymentUrl()` — tetap dipakai client (aman, tidak sensitif, cuma slug+amount).
  - `getTransactionStatus()` — pakai `PAKASIR_API_KEY` dari `.env` client. **Setelah
    perbaikan, API key ini harus DIHAPUS dari app** (client tidak boleh lagi punya akses
    langsung ke `transactiondetail` API dengan api_key). Kalau UI masih butuh cek status
    untuk keperluan tampilan "menunggu", ganti sumbernya jadi Firestore listener, bukan
    panggilan langsung ke Pakasir.
- `lib/features/pembayaran/data/payment_repository.dart`
  - `markManyAsLunas()`, `setOrderIdForMany()` — method ini boleh tetap ada untuk dipakai
    ADMIN (mis. tandai lunas manual via `setStatusManual`), tapi jalur otomatis dari hasil
    pembayaran Pakasir harus pindah ke server, bukan lagi dipanggil dari
    `pakasir_payment_page.dart`.
  - Koleksi Firestore: `tagihan`. Field terkait: `status`, `tanggalBayar`, `metodeBayar`,
    `orderId`, `userId`, `jumlah`.
- **Firestore Security Rules**: file `firestore.rules` TIDAK ada di dalam repo ini (kemungkinan
  dikelola langsung lewat Firebase Console). Sebelum mengerjakan, ambil rules yang aktif
  dari Firebase Console dulu (Firestore Database → Rules), supaya tahu persis client saat
  ini punya akses tulis apa saja ke collection `tagihan`.
- `.env` (tidak ada di repo, dikelola lokal via `flutter_dotenv`, berisi `PAKASIR_SLUG`
  dan `PAKASIR_API_KEY`).

## 5. Daftar Pekerjaan (Definition of Done)

1. **Buat project server baru** (folder terpisah, di luar `lib/`, mis. `server/pakasir-webhook/`
   atau repo terpisah) — Node.js/TypeScript, deploy ke Vercel sebagai serverless function.
2. Endpoint `POST /api/pakasir-webhook`:
   - Terima payload sesuai format Pakasir: `{ amount, order_id, project, status,
     payment_method, completed_at }`.
   - Panggil ulang `GET /api/transactiondetail` ke Pakasir pakai `api_key` (env var server,
     **jangan** commit ke git — pakai Vercel Environment Variables).
   - Validasi `amount` & `order_id` dari webhook **cocok** dengan hasil verifikasi API
     (jangan percaya begitu saja payload webhook mentah — ini poin penting yang juga
     ditekankan di dokumentasi Pakasir sendiri).
   - Kalau valid & `completed`: cari semua dokumen `tagihan` dengan `orderId` tsb, update
     `status: 'lunas'`, `tanggalBayar`, `metodeBayar` pakai **Firebase Admin SDK**
     (service account JSON, disimpan sebagai env var, bukan file yang di-commit).
3. **Daftarkan URL webhook** di dashboard project Pakasir (Edit Project → Webhook URL)
   supaya mengarah ke endpoint Vercel di atas.
4. **Perketat Firestore Security Rules** untuk collection `tagihan`: client (role warga)
   tidak boleh lagi menulis field `status`, `tanggalBayar`, `metodeBayar`, `orderId` secara
   langsung (kecuali lewat jalur admin manual yang memang disengaja tetap ada, mis.
   `setStatusManual` yang dipakai admin di `billing_dialogs.dart` — perlu dicek ulang apakah
   itu tetap dari client dengan role admin, atau ini pun sebaiknya lewat server juga).
5. **Ubah `pakasir_payment_page.dart`**:
   - Hapus pemanggilan `PaymentRepository.markManyAsLunas()` dari `_handleSuccess()`.
   - Ganti mekanisme "tahu kapan pembayaran selesai" dari polling API Pakasir jadi
     **listen ke Firestore** (stream dokumen tagihan dengan `orderId` tsb, tunggu sampai
     `status` berubah jadi `lunas` yang ditulis server).
   - Polling ke `PakasirService.getTransactionStatus()` bisa dihapus total dari client,
     atau kalau tetap dipakai untuk UX ("menunggu"), pastikan **tidak** memicu tulis data,
     hanya menampilkan teks status.
6. **Hapus `PAKASIR_API_KEY` dari `.env` client** dan dari `pakasir_service.dart` (kalau
   fungsi yang memakainya sudah tidak dipanggil dari client). `PAKASIR_SLUG` boleh tetap
   di client karena hanya dipakai untuk membangun URL pembayaran (tidak sensitif).
7. Testing: gunakan mode Sandbox Pakasir (payment simulation) untuk memicu webhook dan
   pastikan alur end-to-end: bayar → webhook masuk → server verifikasi → Firestore
   ter-update → Flutter otomatis pindah ke halaman sukses lewat stream listener.

## 6. Yang TIDAK Perlu Diubah

- Alur pembuatan tagihan bulanan (`ensureCurrentMonthTagihan`, `ensureAllMissingTagihan`,
  `createTagihanForMonth`) — di luar scope masalah ini.
- Admin manual mark lunas tunai (`setStatusManual`) — tetap boleh ditulis langsung oleh
  admin (perannya beda dari warga; ini keputusan manusia admin, bukan klaim otomatis dari
  klien warga), **kecuali** nanti diputuskan untuk ikut dipindah ke server juga demi
  konsistensi arsitektur — didiskusikan lagi saat implementasi.
- Refactor struktur file yang sedang berjalan terpisah (pemecahan halaman-halaman besar di
  `lib/features/...`) — tidak berkaitan dengan topik ini.

## 7.5. Status Implementasi

**Sudah dikerjakan** (sesi ini):

- `server/pakasir-webhook/` — project Node.js/TypeScript siap deploy ke Vercel
  (`api/pakasir-webhook.ts`, verifikasi ulang ke Pakasir API, tulis Firestore
  via Admin SDK). Lihat `server/pakasir-webhook/README.md` untuk cara deploy.
- `PaymentRepository.watchTagihanByIds()` — stream baru untuk listen status
  tagihan by ID.
- `pakasir_payment_page.dart` — tidak lagi memanggil `markManyAsLunas` dari
  client; sekarang listen `watchTagihanByIds` dan menunggu server menulis
  status lunas.
- `pakasir_service.dart` — `getTransactionStatus()`/`isPaid()` (butuh api_key)
  dihapus total dari client.
- `.env` / `.env.example` (root project) — `PAKASIR_API_KEY` dihapus.
  `PAKASIR_SLUG` tetap ada (aman, tidak sensitif).

**Belum dikerjakan / perlu dilakukan MANUAL oleh pemilik project** (bukan
sesuatu yang bisa dikerjakan dari sesi coding ini):

1. **Deploy `server/pakasir-webhook/` ke Vercel** — ikuti
   `server/pakasir-webhook/README.md`.
2. **Set environment variables di Vercel** (`PAKASIR_SLUG`, `PAKASIR_API_KEY`,
   `FIREBASE_SERVICE_ACCOUNT_JSON`) — lihat README di folder yang sama.
3. **Daftarkan webhook URL** di dashboard Pakasir (Edit Project → Webhook URL).
4. **Rotasi PAKASIR_API_KEY di dashboard Pakasir** — API key lama sempat
   ter-bundle di APK yang sudah pernah di-build/didistribusikan sebelum
   perbaikan ini. Meskipun sekarang sudah dihapus dari kode, key LAMA itu
   tetap ada di APK-APK lama yang mungkin masih terinstal. Paling aman:
   generate API key baru di Pakasir, lalu pakai yang baru itu HANYA di env
   var Vercel (bukan di app).
5. **Update Firestore Security Rules** untuk collection `tagihan` — lihat
   draft di bagian 7.6 di bawah. File `firestore.rules` tidak ada di repo ini
   (dikelola langsung di Firebase Console → Firestore Database → Rules), jadi
   perlu ditempel manual di sana.
6. **Testing end-to-end** pakai mode Sandbox Pakasir sebelum dipakai untuk
   pembayaran asli.

## 7.6. Draft Firestore Security Rules — collection `tagihan`

Karena rules aktif saat ini tidak ada di repo, ini draft yang perlu
DIGABUNG (bukan asal timpa) ke rules yang sudah ada di Firebase Console.
Sesuaikan nama helper function (`isAdmin`, dst) kalau sudah ada helper serupa
di rules existing:

```
function isOwner(uid) {
  return request.auth != null && request.auth.uid == uid;
}

function isAdmin() {
  return request.auth != null &&
    get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
}

match /tagihan/{tagihanId} {
  allow read: if isOwner(resource.data.userId) || isAdmin();

  // Warga hanya boleh membuat tagihan miliknya sendiri, status awal belumBayar
  // (dipakai ensureCurrentMonthTagihan/ensureAllMissingTagihan).
  allow create: if isAdmin()
    || (isOwner(request.resource.data.userId)
        && request.resource.data.status == 'belumBayar');

  // Warga HANYA boleh mengubah field orderId pada tagihan miliknya sendiri
  // (dipakai setOrderIdForMany saat memulai pembayaran). Field status /
  // tanggalBayar / metodeBayar TIDAK BOLEH diubah warga sama sekali — itu
  // sekarang eksklusif tugas admin (manual, lewat billing_dialogs.dart) atau
  // server webhook (Firebase Admin SDK, otomatis bypass rules ini).
  allow update: if isAdmin()
    || (isOwner(resource.data.userId)
        && request.resource.data.diff(resource.data).affectedKeys().hasOnly(['orderId']));

  allow delete: if isAdmin();
}
```

Catatan: server webhook menulis lewat **Firebase Admin SDK** (service account),
yang secara desain **selalu bypass Firestore Security Rules** — jadi rule di
atas tidak akan menghalangi server webhook menulis `status: 'lunas'`, hanya
menghalangi klien (app Flutter warga) melakukannya secara langsung.

## 7. Referensi

- Dokumentasi Pakasir (webhook & payload format): https://pakasir.com/p/docs
- Format payload webhook Pakasir (dari dokumentasi): `amount`, `order_id`, `project`,
  `status`, `payment_method`, `completed_at`.
- API verifikasi transaksi: `GET https://app.pakasir.com/api/transactiondetail`.
- Perbandingan hosting gratis (per riset 2026): Vercel Hobby gratis selamanya tanpa kartu
  kredit, tanpa cold start, timeout function 5 menit; Render gratis tanpa kartu kredit
  tapi sleep setelah 15 menit idle (cold start 30–60 detik); Railway mewajibkan kartu
  pembayaran sejak 2026.
