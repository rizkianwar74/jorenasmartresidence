import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../models/satpam_insiden_model.dart';
import 'satpam_insiden_shared_widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Bottom sheet detail insiden + tombol update status
// ─────────────────────────────────────────────────────────────────────────────
class SatpamInsidenDetailSheet extends StatelessWidget {
  const SatpamInsidenDetailSheet({
    super.key,
    required this.item,
    required this.onUpdateStatus,
  });
  final SatpamInsidenItem item;
  final Future<void> Function(SatpamInsidenItem, String) onUpdateStatus;

  static const _statusFlow = {
    'BARU'      : 'DITANGANI',
    'DITANGANI' : 'SELESAI',
  };

  static const _statusColor = {
    'BARU'      : Color(0xFFD32F2F),
    'DITANGANI' : Color(0xFFE65100),
    'SELESAI'   : Color(0xFF2E7D32),
  };
  static const _statusBg = {
    'BARU'      : Color(0xFFFFEBEE),
    'DITANGANI' : Color(0xFFFFF3E0),
    'SELESAI'   : Color(0xFFE8F5E9),
  };

  @override
  Widget build(BuildContext context) {
    final nextStatus = _statusFlow[item.status];
    final sc  = _statusColor[item.status] ?? AppColors.primary;
    final sb  = _statusBg[item.status]    ?? const Color(0xFFE3F0FF);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // ── Header ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.kategori,
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: sb,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      item.status,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: sc,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Info rows ───────────────────────────────────────────────
            SatpamInfoSection(children: [
              SatpamInfoRow(
                icon  : Icons.location_on_outlined,
                label : 'Lokasi',
                value : item.lokasiLabel,
              ),
              SatpamInfoRow(
                icon  : Icons.shield_outlined,
                label : 'Dilaporkan oleh',
                value : item.namaSatpam,
              ),
              SatpamInfoRow(
                icon  : Icons.access_time_rounded,
                label : 'Waktu kejadian',
                value : DateFormat('dd MMM yyyy, HH:mm', 'id_ID')
                    .format(item.waktuKejadian),
              ),
              SatpamInfoRow(
                icon  : Icons.upload_file_outlined,
                label : 'Dilaporkan pada',
                value : DateFormat('dd MMM yyyy, HH:mm', 'id_ID')
                    .format(item.createdAt),
              ),
            ]),

            // ── Deskripsi ───────────────────────────────────────────────
            if (item.deskripsi.isNotEmpty) ...[
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Deskripsi',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    item.deskripsi,
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textDark,
                        height: 1.6),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // ── Tombol update status ─────────────────────────────────────
            if (nextStatus != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    icon: Icon(
                      nextStatus == 'DITANGANI'
                          ? Icons.directions_run_rounded
                          : Icons.check_circle_rounded,
                      size: 18,
                    ),
                    label: Text(
                      nextStatus == 'DITANGANI'
                          ? 'Tandai Sedang Ditangani'
                          : 'Tandai Selesai',
                      style: GoogleFonts.inter(
                          fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: nextStatus == 'DITANGANI'
                          ? const Color(0xFFE65100)
                          : const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      Navigator.pop(context);
                      await onUpdateStatus(item, nextStatus);
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
