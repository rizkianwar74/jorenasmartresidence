// ─────────────────────────────────────────────────────────────────────────────
// Pembungkus REST API OneSignal.
//
// ONESIGNAL_REST_API_KEY hanya hidup di file ini (lewat environment variable
// Vercel) dan TIDAK PERNAH dikirim ke app Flutter. Dokumentasi resmi OneSignal
// menyatakan REST API Key adalah kredensial privat yang tidak boleh diekspos
// pada kode sisi klien.
//
// App ID sebaliknya bersifat publik dan memang ikut disematkan di app Flutter —
// ID itu tidak bisa dipakai untuk mengirim notifikasi.
// ─────────────────────────────────────────────────────────────────────────────

const ONESIGNAL_ENDPOINT = 'https://api.onesignal.com/notifications';

/** Sasaran penerima notifikasi. */
export type Audience =
  /** Semua device dengan tag role=satpam DAN onDuty=true. */
  | { kind: 'satpamOnDuty' }
  /** Semua device dengan tag role=user (seluruh warga). */
  | { kind: 'semuaWarga' }
  /** Satu pengguna tertentu, ditarget lewat External ID = Firebase UID. */
  | { kind: 'pengguna'; uid: string };

export interface PushMessage {
  title: string;
  body: string;
  /** true untuk SOS/darurat — memaksa pengiriman prioritas tinggi. */
  urgent?: boolean;
}

function buildTargeting(audience: Audience): Record<string, unknown> {
  switch (audience.kind) {
    case 'satpamOnDuty':
      return {
        filters: [
          { field: 'tag', key: 'role', relation: '=', value: 'satpam' },
          { operator: 'AND' },
          { field: 'tag', key: 'onDuty', relation: '=', value: 'true' },
        ],
      };
    case 'semuaWarga':
      return {
        filters: [{ field: 'tag', key: 'role', relation: '=', value: 'user' }],
      };
    case 'pengguna':
      return { include_aliases: { external_id: [audience.uid] } };
  }
}

/**
 * Kirim push notification. Mengembalikan true bila OneSignal menerimanya.
 *
 * Kegagalan sengaja tidak dilempar sebagai exception — notifikasi bersifat
 * pelengkap, dan data utamanya sudah tersimpan di Firestore. Kegagalan cukup
 * dicatat di log Vercel supaya bisa ditelusuri.
 */
export async function sendPush(
  audience: Audience,
  message: PushMessage,
): Promise<boolean> {
  const appId = process.env.ONESIGNAL_APP_ID;
  const restKey = process.env.ONESIGNAL_REST_API_KEY;

  if (!appId || !restKey) {
    console.error('[onesignal] ONESIGNAL_APP_ID / ONESIGNAL_REST_API_KEY belum di-set.');
    return false;
  }

  const payload = {
    app_id: appId,
    headings: { en: message.title, id: message.title },
    contents: { en: message.body, id: message.body },
    target_channel: 'push',
    ...(message.urgent ? { priority: 10 } : {}),
    ...buildTargeting(audience),
  };

  try {
    const res = await fetch(ONESIGNAL_ENDPOINT, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        Accept: 'application/json',
        Authorization: `Key ${restKey}`,
      },
      body: JSON.stringify(payload),
    });

    if (res.status !== 200 && res.status !== 201) {
      console.error(`[onesignal] gagal ${res.status}:`, await res.text());
      return false;
    }
    return true;
  } catch (err) {
    console.error('[onesignal] error:', err);
    return false;
  }
}
