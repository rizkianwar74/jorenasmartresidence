import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../models/tamu_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Dialog detail satu catatan tamu
// ─────────────────────────────────────────────────────────────────────────────

void showTamuDetailDialog(BuildContext context, TamuModel t) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.namaTamu,
            style: GoogleFonts.inter(
                fontWeight: FontWeight.bold, fontSize: 15),
          ),
          Text(
            t.kategoriKunjungan,
            style: GoogleFonts.inter(
                fontSize: 12, color: AppColors.textGrey),
          ),
        ],
      ),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Divider(height: 24),

              // ── Info tamu ────────────────────────────────────────
              const _SectionLabel('Informasi Tamu'),
              const SizedBox(height: 10),
              _DetailRow(label: 'Nama Tamu',       value: t.namaTamu),
              _DetailRow(label: 'Kategori',         value: t.kategoriKunjungan),
              _DetailRow(label: 'Kendaraan',        value: '${t.jenisKendaraan} · ${t.nomorPlat.isEmpty ? "Tidak ada" : t.nomorPlat}'),
              if (t.keterangan.isNotEmpty)
                _DetailRow(label: 'Keterangan', value: t.keterangan),

              const SizedBox(height: 16),

              // ── Tujuan ───────────────────────────────────────────
              const _SectionLabel('Tujuan Kunjungan'),
              const SizedBox(height: 10),
              _DetailRow(label: 'Blok',          value: t.blokTujuan),
              _DetailRow(label: 'Nomor Rumah',   value: t.nomorRumahTujuan),

              const SizedBox(height: 16),

              // ── Waktu ────────────────────────────────────────────
              const _SectionLabel('Catatan Waktu'),
              const SizedBox(height: 10),
              _DetailRow(
                label: 'Waktu Masuk',
                value: DateFormat('dd MMM yyyy, HH:mm', 'id_ID')
                    .format(t.waktuMasuk),
              ),
              _DetailRow(
                label: 'Waktu Keluar',
                value: t.waktuKeluar != null
                    ? DateFormat('dd MMM yyyy, HH:mm', 'id_ID')
                        .format(t.waktuKeluar!)
                    : '— Belum keluar',
                valueColor: t.waktuKeluar == null
                    ? AppColors.textGrey
                    : null,
              ),

              const SizedBox(height: 16),

              // ── Petugas ──────────────────────────────────────────
              const _SectionLabel('Petugas'),
              const SizedBox(height: 10),
              _DetailRow(label: 'Dicatat oleh', value: t.namaSatpam),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text('Tutup',
              style: GoogleFonts.inter(color: AppColors.textGrey)),
        ),
      ],
    ),
  );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
          letterSpacing: 0.5),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(
      {required this.label, required this.value, this.valueColor});
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: GoogleFonts.inter(
                    fontSize: 12, color: AppColors.textGrey)),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: valueColor ?? AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
