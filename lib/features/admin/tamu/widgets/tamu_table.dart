import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../models/tamu_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Tabel daftar tamu: header + baris
// ─────────────────────────────────────────────────────────────────────────────

class TamuTable extends StatelessWidget {
  const TamuTable({super.key, required this.items, required this.onDetail});
  final List<TamuModel> items;
  final ValueChanged<TamuModel> onDetail;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          color: const Color(0xFFF8FAFC),
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: const Row(
            children: [
              Expanded(flex: 3, child: _Th('Nama Tamu')),
              Expanded(flex: 2, child: _Th('Tujuan')),
              Expanded(flex: 2, child: _Th('Kategori')),
              Expanded(flex: 2, child: _Th('Kendaraan')),
              Expanded(flex: 2, child: _Th('Satpam')),
              Expanded(flex: 2, child: _Th('Waktu Masuk')),
              SizedBox(width: 80, child: _Th('Aksi')),
            ],
          ),
        ),
        // Rows
        ...items.map(
          (t) => TamuRow(item: t, onDetail: () => onDetail(t)),
        ),
      ],
    );
  }
}

class _Th extends StatelessWidget {
  const _Th(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textGrey,
            letterSpacing: 0.4));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Satu baris tamu
// ─────────────────────────────────────────────────────────────────────────────

class TamuRow extends StatelessWidget {
  const TamuRow({super.key, required this.item, required this.onDetail});
  final TamuModel item;
  final VoidCallback onDetail;

  @override
  Widget build(BuildContext context) {
    final waktu =
        DateFormat('dd MMM, HH:mm', 'id_ID').format(item.waktuMasuk);

    return Container(
      decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey.shade100))),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          // Nama Tamu
          Expanded(
            flex: 3,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Text(
                    item.namaTamu.isNotEmpty
                        ? item.namaTamu[0].toUpperCase()
                        : '?',
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.namaTamu,
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Tujuan
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                item.tujuanLabel,
                style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),

          // Kategori
          Expanded(
            flex: 2,
            child: Text(
              item.kategoriKunjungan,
              style: GoogleFonts.inter(
                  fontSize: 12, color: AppColors.textGrey),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Kendaraan
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.jenisKendaraan,
                  style: GoogleFonts.inter(
                      fontSize: 12, color: AppColors.textDark),
                ),
                if (item.nomorPlat.isNotEmpty && item.nomorPlat != '-')
                  Text(
                    item.nomorPlat,
                    style: GoogleFonts.inter(
                        fontSize: 11, color: AppColors.textGrey),
                  ),
              ],
            ),
          ),

          // Satpam
          Expanded(
            flex: 2,
            child: Text(
              item.namaSatpam,
              style: GoogleFonts.inter(
                  fontSize: 12, color: AppColors.textGrey),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Waktu Masuk
          Expanded(
            flex: 2,
            child: Text(
              waktu,
              style: GoogleFonts.inter(
                  fontSize: 12, color: AppColors.textGrey),
            ),
          ),

          // Aksi
          SizedBox(
            width: 80,
            child: OutlinedButton(
              onPressed: onDetail,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.grey.shade300),
                foregroundColor: AppColors.textDark,
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('Detail',
                  style: GoogleFonts.inter(
                      fontSize: 12, fontWeight: FontWeight.w500)),
            ),
          ),
        ],
      ),
    );
  }
}
