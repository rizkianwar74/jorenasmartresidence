import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../models/insiden_model.dart';
import 'insiden_status_helpers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Dialog detail satu insiden + ubah status
// ─────────────────────────────────────────────────────────────────────────────

void showInsidenDetailDialog(
  BuildContext context,
  InsidenModel insiden, {
  required Future<void> Function(String id, String newStatus) onUpdateStatus,
}) {
  String currentStatus = insiden.status;
  bool   saving        = false;

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setS) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
        actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: insidenStatusBg(insiden.status),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.warning_amber_rounded,
                  color: insidenStatusColor(insiden.status), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    insiden.kategori,
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  Text(
                    'Laporan Insiden',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppColors.textGrey),
                  ),
                ],
              ),
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

                // Info rows
                _DetailRow(label: 'Dilaporkan oleh', value: insiden.namaSatpam),
                const SizedBox(height: 10),
                _DetailRow(label: 'Lokasi', value: insiden.lokasiLabel),
                const SizedBox(height: 10),
                _DetailRow(
                  label: 'Waktu Kejadian',
                  value: DateFormat('dd MMM yyyy, HH:mm', 'id_ID')
                      .format(insiden.waktuKejadian),
                ),
                const SizedBox(height: 10),
                _DetailRow(
                  label: 'Dilaporkan',
                  value: insiden.createdAt != null
                      ? DateFormat('dd MMM yyyy, HH:mm', 'id_ID')
                          .format(insiden.createdAt!)
                      : '-',
                ),
                const SizedBox(height: 16),

                // Deskripsi
                Text(
                  'Deskripsi',
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textGrey),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Text(
                    insiden.deskripsi.isNotEmpty
                        ? insiden.deskripsi
                        : '-',
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textDark,
                        height: 1.5),
                  ),
                ),

                const SizedBox(height: 20),

                // Update status
                Text(
                  'Update Status',
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textGrey),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: insidenStatusOptions.map((s) {
                    final isActive = s == currentStatus;
                    return GestureDetector(
                      onTap: saving ? null : () => setS(() => currentStatus = s),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isActive
                              ? insidenStatusColor(s).withValues(alpha: 0.12)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isActive
                                ? insidenStatusColor(s)
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Text(
                          s,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: isActive
                                ? FontWeight.bold
                                : FontWeight.w400,
                            color: isActive
                                ? insidenStatusColor(s)
                                : AppColors.textGrey,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: saving ? null : () => Navigator.pop(ctx),
            child: Text('Tutup',
                style: GoogleFonts.inter(color: AppColors.textGrey)),
          ),
          ElevatedButton(
            onPressed: (saving || currentStatus == insiden.status)
                ? null
                : () async {
                    setS(() => saving = true);
                    try {
                      await onUpdateStatus(insiden.id, currentStatus);
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  'Status diperbarui ke $currentStatus')),
                        );
                      }
                    } catch (_) {
                      setS(() => saving = false);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Gagal memperbarui status')),
                        );
                      }
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              minimumSize: Size.zero,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : Text('Simpan',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ),
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: GoogleFonts.inter(
                fontSize: 12, color: AppColors.textGrey),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textDark),
          ),
        ),
      ],
    );
  }
}
