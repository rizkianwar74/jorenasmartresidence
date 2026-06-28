import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../models/warga_model.dart';
import 'warga_shared_widgets.dart';

class WargaTable extends StatelessWidget {
  const WargaTable({
    super.key,
    required this.wargaList,
    required this.onEdit,
    required this.onHapus,
  });
  final List<AdminWargaModel> wargaList;
  final ValueChanged<AdminWargaModel> onEdit;
  final ValueChanged<AdminWargaModel> onHapus;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          color: const Color(0xFFF8FAFC),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Expanded(flex: 4, child: ThWidget('Warga')),
              Expanded(flex: 2, child: ThWidget('Unit')),
              Expanded(flex: 2, child: ThWidget('No. HP')),
              Expanded(flex: 2, child: ThWidget('Jabatan')),
              const SizedBox(width: 160, child: ThWidget('Aksi')),
            ],
          ),
        ),

        // Rows
        if (wargaList.isEmpty)
          Padding(
            padding: const EdgeInsets.all(40),
            child: Center(
              child: Text(
                'Tidak ada data warga.',
                style: GoogleFonts.inter(
                    fontSize: 14, color: AppColors.textGrey),
              ),
            ),
          )
        else
          ...wargaList.map(
            (w) => WargaRow(
              warga  : w,
              onEdit : () => onEdit(w),
              onHapus: () => onHapus(w),
            ),
          ),
      ],
    );
  }
}

class WargaRow extends StatelessWidget {
  const WargaRow({
    super.key,
    required this.warga,
    required this.onEdit,
    required this.onHapus,
  });
  final AdminWargaModel warga;
  final VoidCallback onEdit;
  final VoidCallback onHapus;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          // ── Warga (avatar + nama + email) ──────────────────────────────
          Expanded(
            flex: 4,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                  child: Text(
                    warga.initials,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        warga.namaLengkap,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        warga.email,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textGrey,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Unit ───────────────────────────────────────────────────────
          Expanded(
            flex: 2,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                warga.unitLabel,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),

          // ── No. HP ─────────────────────────────────────────────────────
          Expanded(
            flex: 2,
            child: Text(
              warga.nomorHp,
              style: GoogleFonts.inter(
                  fontSize: 12, color: AppColors.textDark),
            ),
          ),

          // ── Jabatan ────────────────────────────────────────────────────
          Expanded(
            flex: 2,
            child: warga.komunitasRole != null
                ? Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      warga.komunitasRole!,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        letterSpacing: 0.3,
                      ),
                    ),
                  )
                : Text(
                    '—',
                    style: GoogleFonts.inter(
                        fontSize: 13, color: Colors.grey.shade400),
                  ),
          ),

          // ── Aksi ───────────────────────────────────────────────────────
          SizedBox(
            width: 160,
            child: Row(
              children: [
                OutlinedButton(
                  onPressed: onEdit,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade300),
                    foregroundColor: AppColors.textDark,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text('Edit',
                      style: GoogleFonts.inter(
                          fontSize: 12, fontWeight: FontWeight.w500)),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: onHapus,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFFCA5A5)),
                    foregroundColor: const Color(0xFFDC2626),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text('Hapus',
                      style: GoogleFonts.inter(
                          fontSize: 12, fontWeight: FontWeight.w500)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
