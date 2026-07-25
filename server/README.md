# Server Backend — Smart Residence

Server serverless (Node.js/TypeScript, deploy ke Vercel) yang memegang semua
kredensial rahasia sistem, supaya app Flutter (klien) **tidak menyimpan satu pun
secret**. Ada dua tugas utama:

1. **Verifikasi pembayaran** — menerima webhook Pakasir, memverifikasi ulang ke
   API resmi Pakasir, lalu menandai tagihan lunas di Firestore lewat Firebase
   Admin SDK. Keputusan "pembayaran sukses atau tidak" **tidak lagi ditentukan
   oleh app Flutter**, melainkan oleh server ini.
2. **Pengiriman notifikasi** — mengirim push OneSignal setelah memverifikasi
   Firebase ID Token & peran pemanggil, supaya `ONESIGNAL_REST_API_KEY` tidak
   ikut terkemas ke dalam APK.

Lihat `docs/payment_webhook_fix_prompt.md` di root project untuk konteks
lengkap kenapa perubahan ini diperlukan.

## Struktur

```
server/
├── api/
│   ├── pakasir-webhook.ts    ← handler webhook pembayaran (endpoint)
│   └── send-notification.ts  ← handler pengiriman push OneSignal (endpoint)
├── lib/
│   ├── firebase.ts           ← inisialisasi Firebase Admin SDK
│   ├── notifications.ts      ← penyusunan isi & penerima notifikasi
│   └── onesignal.ts          ← wrapper REST API OneSignal
├── package.json
├── tsconfig.json
├── .env.example
└── README.md (file ini)
```

Vercel otomatis mendeteksi setiap file di `api/` sebagai satu endpoint:

```
https://<nama-project-vercel>.vercel.app/api/pakasir-webhook
https://<nama-project-vercel>.vercel.app/api/send-notification
```

## 1. Deploy ke Vercel

Prasyarat: akun Vercel (gratis, tanpa kartu kredit — https://vercel.com/signup),
dan Vercel CLI:

```bash
npm install -g vercel
```

Dari dalam folder `server/`:

```bash
cd server
vercel login
vercel
```

Ikuti prompt-nya (pilih scope akun, nama project bebas, jangan link ke project
lain). Setelah selesai, `vercel` akan memberi URL preview. Untuk deploy ke
production URL (yang stabil, dipakai di webhook Pakasir):

```bash
vercel --prod
```

## 2. Set Environment Variables di Vercel

Buka **Vercel Dashboard → project ini → Settings → Environment Variables**,
tambahkan variabel berikut (isi persis seperti di `.env.example`):

| Key | Isi |
|---|---|
| `PAKASIR_SLUG` | Slug project Pakasir kamu |
| `PAKASIR_API_KEY` | API Key dari dashboard Pakasir → Settings → API Key |
| `FIREBASE_SERVICE_ACCOUNT_JSON` | Seluruh isi file JSON service account Firebase |
| `ONESIGNAL_APP_ID` | App ID dari dashboard OneSignal → Settings → Keys & IDs |
| `ONESIGNAL_REST_API_KEY` | REST API Key OneSignal (regenerate dulu jika sempat bocor ke APK lama) |

Cara dapat `FIREBASE_SERVICE_ACCOUNT_JSON`:
Firebase Console → Project Settings (ikon gerigi) → Service Accounts →
**Generate new private key** → file JSON akan ter-download. Buka file itu,
copy SELURUH isinya, paste sebagai value env var ini di Vercel (boleh
multi-baris apa adanya).

Setelah menambah/mengubah env var, **redeploy** supaya terbaca:

```bash
vercel --prod
```

## 3. Daftarkan Webhook URL di Pakasir

Buka dashboard Pakasir → project kamu → **Edit Project** → isi field
**Webhook URL** dengan:

```
https://<nama-project-vercel>.vercel.app/api/pakasir-webhook
```

## 4. Testing

Pakasir punya mode Sandbox dengan fitur simulasi pembayaran — pakai itu dulu
sebelum coba dengan pembayaran QRIS asli. Setelah simulasi berhasil, cek:

- **Vercel Dashboard → project ini → Logs** — harus muncul log
  `[pakasir-webhook] OK — N tagihan ditandai lunas untuk orderId=...`
- **Firestore Console → collection `tagihan`** — dokumen dengan `orderId`
  yang sesuai harus berubah `status` jadi `lunas`.
- **App Flutter** — halaman `PakasirPaymentPage` harus otomatis pindah ke
  halaman sukses (lewat Firestore listener, bukan lagi polling ke Pakasir).

Kalau ada masalah, cek dulu Vercel Logs — semua `console.error` di
`pakasir-webhook.ts` akan muncul di sana dengan detail payload & hasil
verifikasi, memudahkan debugging tanpa perlu akses device manapun.

## Development lokal (opsional)

```bash
cd server
npm install
cp .env.example .env   # isi manual
vercel dev
```

`vercel dev` menjalankan endpoint ini secara lokal di `http://localhost:3000`.
Untuk test webhook dari Pakasir ke localhost, perlu tunnel (mis. `ngrok http 3000`)
supaya Pakasir bisa menjangkau URL lokal kamu dari internet.
