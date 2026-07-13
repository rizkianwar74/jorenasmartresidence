import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../models/insiden_model.dart';
import 'insiden_status_helpers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Tabel daftar insiden: header + baris
// ─────────────────────────────────────────────────────────────────────────────

class InsidenTable extends StatelessWidget {
  const InsidenTable({super.key, required this.items, required this.onDetail});
  final List<InsidenModel> items;
  final ValueChanged<InsidenModel> onDetail;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          color: const Color(0xFFF8FAFC),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: const Row(
            children: [
              Expanded(flex: 3, child: _ThText('Kategori')),
              Expanded(flex: 3, child: _ThText('Lokasi')),
              Expanded(flex: 2, child: _ThText('Satpam')),
              Expanded(flex: 2, child: _ThText('Waktu Kejadian')),
              Expanded(flex: 2, child: _ThText('Status')),
              SizedBox(width: 80, child: _ThText('Aksi')),
            ],
          ),
        ),
        // Rows
        ...items.map((i) => InsidenRow(item: i, onDetail: () => onDetail(i))),
      ],
    );
  }
}

class _ThText extends StatelessWidget {
  const _ThText(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.textGrey,
          letterSpacing: 0.4),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Satu baris insiden
// ─────────────────────────────────────────────────────────────────────────────

class InsidenRow extends StatelessWidget {
  const InsidenRow({super.key, required this.item, required this.onDetail});
  final InsidenModel item;
  final VoidCallback onDetail;

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('dd MMM, HH:mm', 'id_ID')
        .format(item.waktuKejadian);

    return Container(
      decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey.shade100))),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          // Kategori
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: insidenStatusBg(item.status),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.warning_amber_rounded,
                      color: insidenStatusColor(item.status), size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.kategori,
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

          // Lokasi
          Expanded(
            flex: 3,
            child: Text(
              item.lokasiLabel,
              style: GoogleFonts.inter(
                  fontSize: 12, color: AppColors.textDark),
              overflow: TextOverflow.ellipsis,
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

          // Waktu
          Expanded(
            flex: 2,
            child: Text(
              timeStr,
              style: GoogleFonts.inter(
                  fontSize: 12, color: AppColors.textGrey),
            ),
          ),

          // Status badge
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: insidenStatusBg(item.status),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                item.status,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: insidenStatusColor(item.status),
                ),
              ),
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
