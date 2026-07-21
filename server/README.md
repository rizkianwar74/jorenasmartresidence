# Pakasir Webhook — Smart Residence

Server kecil yang menerima webhook pembayaran dari Pakasir, memverifikasi ulang
ke API resmi Pakasir, lalu menandai tagihan lunas di Firestore lewat Firebase
Admin SDK. Dibuat supaya keputusan "pembayaran sukses atau tidak" **tidak lagi
ditentukan oleh app Flutter (klien)**, melainkan oleh server ini.

Lihat `docs/payment_webhook_fix_prompt.md` di root project untuk konteks
lengkap kenapa perubahan ini diperlukan.

## Struktur

```
server/pakasir-webhook/
├── api/
│   └── pakasir-webhook.ts   ← handler webhook (Vercel serverless function)
├── package.json
├── tsconfig.json
├── .env.example
└── README.md (file ini)
```

Vercel otomatis mendeteksi setiap file di `api/` sebagai satu endpoint. File
`api/pakasir-webhook.ts` akan menjadi endpoint:

```
https://<nama-project-vercel>.vercel.app/api/pakasir-webhook
```

## 1. Deploy ke Vercel

Prasyarat: akun Vercel (gratis, tanpa kartu kredit — https://vercel.com/signup),
dan Vercel CLI:

```bash
npm install -g vercel
```

Dari dalam folder `server/pakasir-webhook/`:

```bash
cd server/pakasir-webhook
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
tambahkan 3 variabel berikut (isi persis seperti di `.env.example`):

| Key | Isi |
|---|---|
| `PAKASIR_SLUG` | Slug project Pakasir kamu |
| `PAKASIR_API_KEY` | API Key dari dashboard Pakasir → Settings → API Key |
| `FIREBASE_SERVICE_ACCOUNT_JSON` | Seluruh isi file JSON service account Firebase |

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
cd server/pakasir-webhook
npm install
cp .env.example .env   # isi manual
vercel dev
```

`vercel dev` menjalankan endpoint ini secara lokal di `http://localhost:3000`.
Untuk test webhook dari Pakasir ke localhost, perlu tunnel (mis. `ngrok http 3000`)
supaya Pakasir bisa menjangkau URL lokal kamu dari internet.
