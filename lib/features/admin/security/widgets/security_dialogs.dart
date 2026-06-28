import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../models/security_models.dart';
import 'security_shared_widgets.dart';

class LogDetailDialog extends StatelessWidget {
  const LogDetailDialog({super.key, required this.item});
  final LogItem item;

  (Color, IconData, String) get _typeTheme => switch (item.type) {
    LogType.sos     => (const Color(0xFFDC2626), Icons.emergency_outlined,  'SOS / Darurat'),
    LogType.bantuan => (AppColors.primary,       Icons.support_agent_outlined, 'Bantuan Satpam'),
    LogType.patroli => (const Color(0xFF0D9488), Icons.shield_outlined,     'Patroli'),
  };

  @override
  Widget build(BuildContext context) {
    final d             = item.rawData;
    final (col, icon, typeLabel) = _typeTheme;
    final waktuFmt      = DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(item.waktu);
    final fotos         = item.fotoUrls;

    // Ambil field sesuai tipe
    final namaWarga = d['namaWarga']   as String? ?? '-';
    final blok      = d['blok']        as String? ?? '-';
    final unit      = d['nomorUnit']   as String? ?? '-';
    final kategori  = d['kategori']    as String? ?? '-';
    final catatan   = d['catatan']     as String?
                      ?? d['keterangan'] as String? ?? '';
    final satpam    = d['namaSatpam']  as String? ?? '-';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 80, vertical: 40),
      child: SizedBox(
        width: 700,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Kiri: info ──────────────────────────────────────────
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: col.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10)),
                        child: Icon(icon, color: col, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.judul, style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold, fontSize: 16,
                              color: AppColors.textDark)),
                          Text(typeLabel, style: GoogleFonts.inter(
                              fontSize: 12, color: AppColors.textGrey)),
                        ],
                      )),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Icon(Icons.close, color: Colors.grey.shade400, size: 20),
                      ),
                    ]),

                    const Divider(height: 28),

                    DRow('Warga',   namaWarga),
                    DRow('Blok',    '$blok – Unit $unit'),
                    if (kategori != '-') DRow('Kategori', kategori),
                    DRow('Waktu',   waktuFmt),
                    DRow('Status',  item.status),
                    if (satpam != '-') DRow('Satpam',  satpam),

                    if (catatan.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text('Catatan', style: GoogleFonts.inter(
                          fontSize: 12, fontWeight: FontWeight.w600,
                          color: AppColors.textGrey)),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Text(catatan, style: GoogleFonts.inter(
                            fontSize: 13, height: 1.5, color: AppColors.textDark)),
                      ),
                    ],
                  ],
                ),
              ),

              // ── Kanan: foto ─────────────────────────────────────────
              const SizedBox(width: 24),
              SizedBox(width: 220, child: FotoColumn(fotos: fotos)),
            ],
          ),
        ),
      ),
    );
  }
}

class PatroliDetailDialog extends StatelessWidget {
  const PatroliDetailDialog({super.key, required this.item});
  final PatroliItem item;

  @override
  Widget build(BuildContext context) {
    final fotos = item.fotoUrls;
    final d     = item.rawData;

    // Waktu kejadian dari createdAt atau jamMulai
    final createdAt = d['createdAt'] as Timestamp?;
    final tglFmt = createdAt != null
        ? DateFormat('dd MMM yyyy', 'id_ID').format(createdAt.toDate())
        : '-';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 80, vertical: 40),
      child: SizedBox(
        width: 700,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Kiri: info ──────────────────────────────────────────
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D9488).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.shield_outlined,
                            color: Color(0xFF0D9488), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Detail Patroli', style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold, fontSize: 16,
                              color: AppColors.textDark)),
                          Text('Log Patroli Harian', style: GoogleFonts.inter(
                              fontSize: 12, color: AppColors.textGrey)),
                        ],
                      )),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Icon(Icons.close, color: Colors.grey.shade400, size: 20),
                      ),
                    ]),

                    const Divider(height: 28),

                    DRow('Petugas',      item.petugas),
                    DRow('Blok / Area',  item.lokasi),
                    DRow('Tanggal',      tglFmt),
                    DRow('Jam Mulai',    item.jamMulai.isNotEmpty ? item.jamMulai : '-'),
                    DRow('Jam Selesai',  item.jamSelesai.isNotEmpty ? item.jamSelesai : '— Belum selesai'),
                    DRow('Status',       item.selesai ? 'Selesai' : 'Sedang Berjalan'),

                    if (item.quickTags.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text('Kondisi Ditemukan', style: GoogleFonts.inter(
                          fontSize: 12, fontWeight: FontWeight.w600,
                          color: AppColors.textGrey)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: item.quickTags.map((tag) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D9488).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: const Color(0xFF0D9488).withValues(alpha: 0.3)),
                          ),
                          child: Text(tag, style: GoogleFonts.inter(
                              fontSize: 12, color: const Color(0xFF0D9488),
                              fontWeight: FontWeight.w500)),
                        )).toList(),
                      ),
                    ],

                    if (item.catatan.isNotEmpty && item.catatan != '-') ...[
                      const SizedBox(height: 12),
                      Text('Keterangan', style: GoogleFonts.inter(
                          fontSize: 12, fontWeight: FontWeight.w600,
                          color: AppColors.textGrey)),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Text(item.catatan, style: GoogleFonts.inter(
                            fontSize: 13, height: 1.5, color: AppColors.textDark)),
                      ),
                    ],
                  ],
                ),
              ),

              // ── Kanan: foto ─────────────────────────────────────────
              const SizedBox(width: 24),
              SizedBox(width: 220, child: FotoColumn(fotos: fotos)),
            ],
          ),
        ),
      ),
    );
  }
}

class FotoColumn extends StatefulWidget {
  const FotoColumn({super.key, required this.fotos});
  final List<String> fotos;

  @override
  State<FotoColumn> createState() => _FotoColumnState();
}

class _FotoColumnState extends State<FotoColumn> {
  int _selected = 0;

  void _open(BuildContext ctx, int index) {
    showDialog(
      context: ctx,
      barrierColor: Colors.black87,
      builder: (_) => FullscreenViewer(urls: widget.fotos, initial: index),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fotos = widget.fotos;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(Icons.photo_library_outlined, size: 14, color: AppColors.textGrey),
          const SizedBox(width: 6),
          Text('Foto Bukti (${fotos.length})', style: GoogleFonts.inter(
              fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textGrey)),
        ]),
        const SizedBox(height: 10),

        if (fotos.isEmpty)
          Container(
            height: 140,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Center(child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.image_not_supported_outlined,
                    size: 28, color: Colors.grey.shade400),
                const SizedBox(height: 6),
                Text('Tidak ada foto', style: GoogleFonts.inter(
                    fontSize: 12, color: AppColors.textGrey)),
              ],
            )),
          )
        else ...[
          // Main preview
          GestureDetector(
            onTap: () => _open(context, _selected),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(children: [
                AdminFotoImage(
                  url: fotos[_selected],
                  width: double.infinity,
                  height: 160,
                  fit: BoxFit.cover,
                ),
                Positioned(bottom: 8, right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                        color: Colors.black54, borderRadius: BorderRadius.circular(6)),
                    child: const Icon(Icons.zoom_in, size: 14, color: Colors.white),
                  )),
                if (fotos.length > 1)
                  Positioned(top: 8, left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                          color: Colors.black54, borderRadius: BorderRadius.circular(6)),
                      child: Text('${_selected + 1}/${fotos.length}',
                          style: GoogleFonts.inter(fontSize: 10,
                              color: Colors.white, fontWeight: FontWeight.w600)),
                    )),
              ]),
            ),
          ),

          // Thumbnails jika > 1
          if (fotos.length > 1) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 52,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: fotos.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (_, i) => GestureDetector(
                  onTap: () => setState(() => _selected = i),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Stack(children: [
                      AdminFotoImage(url: fotos[i], width: 52, height: 52, fit: BoxFit.cover),
                      if (_selected == i)
                        Container(width: 52, height: 52,
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.primary, width: 2),
                              borderRadius: BorderRadius.circular(6))),
                    ]),
                  ),
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }
}

class FullscreenViewer extends StatefulWidget {
  const FullscreenViewer({super.key, required this.urls, required this.initial});
  final List<String> urls;
  final int initial;

  @override
  State<FullscreenViewer> createState() => _FullscreenViewerState();
}

class _FullscreenViewerState extends State<FullscreenViewer> {
  late int _current;

  @override
  void initState() { super.initState(); _current = widget.initial; }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            if (widget.urls.length > 1)
              Text('${_current + 1} / ${widget.urls.length}',
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 13))
            else const SizedBox(),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.close, color: Colors.white, size: 20),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AdminFotoImage(
              url: widget.urls[_current],
              fit: BoxFit.contain,
              dark: true,
            ),
          ),
          if (widget.urls.length > 1) ...[
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              NavBtn(Icons.arrow_back_ios_new, _current > 0,
                  () => setState(() => _current--)),
              const SizedBox(width: 16),
              NavBtn(Icons.arrow_forward_ios, _current < widget.urls.length - 1,
                  () => setState(() => _current++)),
            ]),
          ],
        ],
      ),
    );
  }
}

class NavBtn extends StatelessWidget {
  const NavBtn(this.icon, this.enabled, this.onTap, {super.key});
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: enabled ? Colors.white24 : Colors.white10,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: enabled ? Colors.white : Colors.white38, size: 18),
      ),
    );
  }
}
