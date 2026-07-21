import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/data/keluhan_repository.dart';
import '../../../../core/services/onesignal_service.dart';
import 'reports_shared_widgets.dart';
import 'reports_dialogs.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Modal detail laporan — dibuka saat sebuah baris tabel diklik.
//
// Kontennya "live": memakai StreamBuilder yang sama dengan sumber data tabel
// (KeluhanRepository.watchAllKeluhan), jadi begitu status/penugasan berubah
// di Firestore, modal ini otomatis memperbarui tampilannya sendiri tanpa
// perlu ditutup dulu. Admin menutup modal secara manual lewat tombol X atau
// tap di luar area modal.
// ─────────────────────────────────────────────────────────────────────────────

Future<void> showReportDetailDialog(
  BuildContext context, {
  required KeluhanItem initialReport,
}) {
  return showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.4),
    builder: (_) => _ReportDetailDialog(initialReport: initialReport),
  );
}

class _ReportDetailDialog extends StatefulWidget {
  const _ReportDetailDialog({required this.initialReport});
  final KeluhanItem initialReport;

  @override
  State<_ReportDetailDialog> createState() => _ReportDetailDialogState();
}

class _ReportDetailDialogState extends State<_ReportDetailDialog> {
  bool _assigning = false;

  Future<void> _showAssignDialog(KeluhanItem item) async {
    List<SatpamInfo> satpamList;
    try {
      satpamList = await KeluhanRepository.getSatpamList();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Gagal memuat daftar satpam: $e',
            style: GoogleFonts.inter(fontSize: 13)),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
      return;
    }
    if (!mounted) return;

    if (satpamList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          'Tidak ada satpam terdaftar. Pastikan akun satpam di Firestore memiliki field role = "satpam".',
          style: GoogleFonts.inter(fontSize: 13),
        ),
        backgroundColor: Colors.orange.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
      return;
    }

    SatpamInfo? chosen;
    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: Text('Tugaskan ke Satpam',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pilih satpam yang akan menangani laporan ini:',
                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.textGrey)),
                const SizedBox(height: 12),
                ...satpamList.map((s) => RadioListTile<SatpamInfo>(
                  value: s,
                  groupValue: chosen,
                  onChanged: (v) => setSt(() => chosen = v),
                  title: Text(s.nama,
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500)),
                  activeColor: AppColors.primary,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                )),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Batal',
                  style: GoogleFonts.inter(color: AppColors.textGrey)),
            ),
            ElevatedButton(
              onPressed: chosen == null ? null : () => Navigator.pop(ctx, chosen),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary, elevation: 0,
                minimumSize: Size.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('Tugaskan',
                  style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    ).then((result) async {
      if (result is SatpamInfo) {
        setState(() => _assigning = true);
        await KeluhanRepository.assignKeluhan(
          keluhanId  : item.id,
          satpamUid  : result.uid,
          satpamNama : result.nama,
        );
        // Notifikasi ke satpam yang ditugaskan (fire-and-forget).
        OneSignalService.instance.sendKeluhanAssigned(docId: item.id);
        if (mounted) {
          setState(() => _assigning = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Laporan ditugaskan ke ${result.nama}',
                style: GoogleFonts.inter(fontSize: 13)),
            backgroundColor: const Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ));
        }
      }
    });
  }

  Future<void> _updateStatus(KeluhanItem item, StatusKeluhan s) async {
    await KeluhanRepository.updateStatus(keluhanId: item.id, status: s);
    // Notifikasi ke warga pemilik keluhan (fire-and-forget).
    OneSignalService.instance.sendKeluhanUpdate(docId: item.id);
  }

  // _statusLabelFor() dihapus — label status kini disusun server notifikasi
  // dari status yang dibacanya sendiri di Firestore, sehingga tidak perlu lagi
  // dikirim dari sini.

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 860,
          maxHeight: screenSize.height * 0.85,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 32,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              Flexible(
                child: StreamBuilder<List<KeluhanItem>>(
                  stream: KeluhanRepository.watchAllKeluhan(),
                  initialData: [widget.initialReport],
                  builder: (context, snapshot) {
                    final list = snapshot.data ?? const <KeluhanItem>[];
                    KeluhanItem current = widget.initialReport;
                    for (final it in list) {
                      if (it.id == widget.initialReport.id) {
                        current = it;
                        break;
                      }
                    }
                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: _detailBody(current),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text('Detail Laporan',
                style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark)),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, size: 20),
            color: AppColors.textGrey,
            splashRadius: 18,
          ),
        ],
      ),
    );
  }

  Widget _detailBody(KeluhanItem r) {
    final tgl = DateFormat('dd MMMM yyyy, HH:mm', 'id_ID').format(r.createdAt);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Kiri: info + action buttons ─────────────────────────────
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(children: [
                Expanded(child: Text(r.judul,
                    style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textDark))),
                const SizedBox(width: 12),
                StatusBadgeRow(r.status),
              ]),
              const SizedBox(height: 12),

              // Info
              _detailRow('Pelapor', '${r.namaWarga} — Blok ${r.blok} – Unit ${r.nomorUnit}'),
              _detailRow('Kategori', r.kategori),
              _detailRow('Tanggal', tgl),
              if (r.assignedName != null)
                _detailRow('Ditugaskan ke', r.assignedName!, valueColor: AppColors.primary),

              const SizedBox(height: 10),
              Divider(color: Colors.grey.shade100),
              const SizedBox(height: 10),

              // Deskripsi
              Text('Deskripsi', style: GoogleFonts.inter(
                  fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textGrey)),
              const SizedBox(height: 6),
              Text(r.deskripsi, style: GoogleFonts.inter(
                  fontSize: 13, color: AppColors.textDark, height: 1.6)),

              // Admin note
              if (r.adminNote != null && r.adminNote!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                  ),
                  child: Text(r.adminNote!,
                      style: GoogleFonts.inter(fontSize: 13, color: AppColors.primary, height: 1.5)),
                ),
              ],

              const SizedBox(height: 20),

              // Action buttons
              if (_assigning)
                const CircularProgressIndicator(strokeWidth: 2)
              else
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    if (r.status == StatusKeluhan.menunggu ||
                        r.status == StatusKeluhan.diproses)
                      ElevatedButton.icon(
                        onPressed: () => _showAssignDialog(r),
                        icon: const Icon(Icons.person_add_outlined, size: 16, color: Colors.white),
                        label: Text(
                          r.assignedName == null ? 'Tugaskan Satpam' : 'Ganti Satpam',
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary, elevation: 0,
                          minimumSize: Size.zero,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    if (r.status == StatusKeluhan.diproses)
                      ElevatedButton.icon(
                        onPressed: () => _updateStatus(r, StatusKeluhan.selesai),
                        icon: const Icon(Icons.check_circle_outline, size: 16, color: Colors.white),
                        label: Text('Selesai',
                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32), elevation: 0,
                          minimumSize: Size.zero,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    if (r.status == StatusKeluhan.menunggu)
                      OutlinedButton.icon(
                        onPressed: () => _updateStatus(r, StatusKeluhan.ditolak),
                        icon: Icon(Icons.cancel_outlined, size: 16, color: Colors.red.shade400),
                        label: Text('Tolak',
                            style: GoogleFonts.inter(fontSize: 12, color: Colors.red.shade400)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.red.shade200),
                          minimumSize: Size.zero,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),

        // ── Kanan: foto ──────────────────────────────────────────────
        const SizedBox(width: 24),
        SizedBox(
          width: 260,
          child: FotoPanel(fotoUrls: r.fotoUrls),
        ),
      ],
    );
  }

  Widget _detailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(children: [
        SizedBox(width: 120, child: Text(label,
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textGrey))),
        Expanded(child: Text(value,
            style: GoogleFonts.inter(fontSize: 13,
                color: valueColor ?? AppColors.textDark,
                fontWeight: valueColor != null ? FontWeight.w600 : FontWeight.normal))),
      ]),
    );
  }
}

class FotoPanel extends StatelessWidget {
  const FotoPanel({super.key, required this.fotoUrls});
  final List<String> fotoUrls;

  void _openFullscreen(BuildContext context, String url, int index, List<String> all) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => FotoFullscreen(urls: all, initialIndex: index),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(Icons.photo_library_outlined, size: 14, color: AppColors.textGrey),
          const SizedBox(width: 6),
          Text(
            'Foto Lampiran (${fotoUrls.length})',
            style: GoogleFonts.inter(
                fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textGrey),
          ),
        ]),
        const SizedBox(height: 10),

        if (fotoUrls.isEmpty)
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.image_not_supported_outlined,
                      size: 28, color: Colors.grey.shade400),
                  const SizedBox(height: 6),
                  Text('Tidak ada foto',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppColors.textGrey)),
                ],
              ),
            ),
          )
        else
          ...fotoUrls.asMap().entries.map((entry) {
            final i   = entry.key;
            final url = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () => _openFullscreen(context, url, i, fotoUrls),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Stack(
                    children: [
                      ReportFotoImage(
                        url: url,
                        width: double.infinity,
                        height: 160,
                        fit: BoxFit.cover,
                      ),
                      // Overlay: zoom icon
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.zoom_in,
                              size: 16, color: Colors.white),
                        ),
                      ),
                      // Label nomor jika lebih dari 1
                      if (fotoUrls.length > 1)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${i + 1} / ${fotoUrls.length}',
                              style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }
}
