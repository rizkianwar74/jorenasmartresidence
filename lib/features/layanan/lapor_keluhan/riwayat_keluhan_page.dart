import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive_helper.dart';
import '../../../core/services/keluhan_service.dart';
import 'lapor_keluhan_page.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Page
// ─────────────────────────────────────────────────────────────────────────────

class RiwayatKeluhanPage extends StatefulWidget {
  const RiwayatKeluhanPage({super.key});

  @override
  State<RiwayatKeluhanPage> createState() => _RiwayatKeluhanPageState();
}

class _RiwayatKeluhanPageState extends State<RiwayatKeluhanPage> {
  StreamSubscription<List<KeluhanItem>>? _sub;
  List<KeluhanItem> _items = [];
  bool _loading = true;

  static const double _contentMaxWidth = 600.0;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _loading = false);
      return;
    }
    _sub = KeluhanService.watchMyKeluhan(uid).listen(
      (list) {
        if (mounted) setState(() { _items = list; _loading = false; });
      },
      onError: (_) { if (mounted) setState(() => _loading = false); },
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hPad = Responsive.value<double>(context, mobile: 24, tablet: 32);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F7F8),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          color: AppColors.textDark,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Riwayat Laporan',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(strokeWidth: 2))
              : _items.isEmpty
                  ? _EmptyState(
                      onBuatLaporan: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const LaporKeluhanPage()),
                      ),
                    )
                  : ListView.separated(
                      padding:
                          EdgeInsets.fromLTRB(hPad, 16, hPad, 32),
                      itemCount: _items.length + 1, // +1 untuk banner bawah
                      separatorBuilder: (_, i) =>
                          i < _items.length - 1
                              ? const SizedBox(height: 12)
                              : const SizedBox.shrink(),
                      itemBuilder: (_, i) {
                        if (i < _items.length) {
                          return _RiwayatCard(
                            item: _items[i],
                            onDetailTap: () => _showDetail(_items[i]),
                          );
                        }
                        // Banner buat laporan baru
                        return Padding(
                          padding: const EdgeInsets.only(top: 20),
                          child: _BuatLaporanBanner(
                            onTap: () => Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const LaporKeluhanPage()),
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ),
    );
  }

  void _showDetail(KeluhanItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DetailSheet(item: item),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState({this.onBuatLaporan});
  final VoidCallback? onBuatLaporan;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'Belum ada laporan',
              style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textGrey),
            ),
            const SizedBox(height: 6),
            Text(
              'Laporan yang Anda kirim akan muncul di sini',
              style: GoogleFonts.inter(
                  fontSize: 13, color: AppColors.textGrey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onBuatLaporan,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text('Buat Laporan',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Kartu riwayat
// ─────────────────────────────────────────────────────────────────────────────
class _RiwayatCard extends StatelessWidget {
  const _RiwayatCard({required this.item, this.onDetailTap});

  final KeluhanItem item;
  final VoidCallback? onDetailTap;

  Color get _statusColor => switch (item.status) {
        StatusKeluhan.diproses => const Color(0xFFFF9500),
        StatusKeluhan.selesai  => const Color(0xFF34C759),
        StatusKeluhan.ditolak  => Colors.red,
        StatusKeluhan.menunggu => AppColors.textGrey,
      };

  Color get _statusBg => switch (item.status) {
        StatusKeluhan.diproses => const Color(0xFFFFF3E0),
        StatusKeluhan.selesai  => const Color(0xFFE8F5E9),
        StatusKeluhan.ditolak  => const Color(0xFFFFEBEE),
        StatusKeluhan.menunggu => const Color(0xFFF5F5F5),
      };

  String get _statusLabel => item.statusLabel.toUpperCase();

  @override
  Widget build(BuildContext context) {
    final tgl = DateFormat('dd MMM yyyy, HH:mm', 'id_ID')
        .format(item.createdAt);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Baris atas: kategori chip + badge status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                item.kategori,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textGrey,
                  letterSpacing: 0.2,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _statusLabel,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _statusColor,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Judul
          Text(
            item.judul,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),

          const SizedBox(height: 4),

          // Deskripsi singkat
          Text(
            item.deskripsi,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
                fontSize: 13, color: AppColors.textGrey),
          ),

          // Admin note (jika ada)
          if (item.adminNote != null && item.adminNote!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.chat_bubble_outline_rounded,
                      size: 13, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      item.adminNote!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.primary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),

          Divider(color: Colors.grey.shade100, height: 1),
          const SizedBox(height: 10),

          // Baris bawah: tanggal + lihat detail
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.calendar_today_outlined,
                      size: 13, color: AppColors.textGrey),
                  const SizedBox(width: 6),
                  Text(
                    tgl,
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppColors.textGrey),
                  ),
                ],
              ),
              GestureDetector(
                onTap: onDetailTap,
                child: Text(
                  'LIHAT DETAIL',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom sheet detail
// ─────────────────────────────────────────────────────────────────────────────
class _DetailSheet extends StatelessWidget {
  const _DetailSheet({required this.item});
  final KeluhanItem item;

  @override
  Widget build(BuildContext context) {
    final tgl = DateFormat('dd MMMM yyyy, HH:mm', 'id_ID')
        .format(item.createdAt);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Header: judul + status
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    item.judul,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                _StatusBadge(status: item.status),
              ],
            ),

            const SizedBox(height: 6),
            Text(
              item.kategori,
              style: GoogleFonts.inter(
                  fontSize: 13, color: AppColors.textGrey),
            ),

            const SizedBox(height: 16),
            Divider(color: Colors.grey.shade100),
            const SizedBox(height: 16),

            // Info warga
            _DetailRow(
              icon: Icons.person_outline_rounded,
              label: 'Pelapor',
              value:
                  '${item.namaWarga} • Blok ${item.blok} – Unit ${item.nomorUnit}',
            ),
            const SizedBox(height: 10),
            _DetailRow(
              icon: Icons.calendar_today_outlined,
              label: 'Tanggal',
              value: tgl,
            ),

            const SizedBox(height: 16),

            // Deskripsi
            Text(
              'DESKRIPSI',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textGrey,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.deskripsi,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textDark,
                height: 1.6,
              ),
            ),

            // Foto (jika ada)
            if (item.fotoUrls.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'FOTO BUKTI',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textGrey,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 90,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: item.fotoUrls.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      item.fotoUrls[i],
                      width: 90,
                      height: 90,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 90,
                        height: 90,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.broken_image_outlined,
                            color: Colors.grey),
                      ),
                    ),
                  ),
                ),
              ),
            ],

            // Catatan admin (jika ada)
            if (item.adminNote != null && item.adminNote!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'CATATAN ADMIN',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textGrey,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.primary.withOpacity(0.15)),
                ),
                child: Text(
                  item.adminNote!,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.primary,
                    height: 1.5,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final StatusKeluhan status;

  Color get _color => switch (status) {
        StatusKeluhan.diproses => const Color(0xFFFF9500),
        StatusKeluhan.selesai  => const Color(0xFF34C759),
        StatusKeluhan.ditolak  => Colors.red,
        StatusKeluhan.menunggu => AppColors.textGrey,
      };

  Color get _bg => switch (status) {
        StatusKeluhan.diproses => const Color(0xFFFFF3E0),
        StatusKeluhan.selesai  => const Color(0xFFE8F5E9),
        StatusKeluhan.ditolak  => const Color(0xFFFFEBEE),
        StatusKeluhan.menunggu => const Color(0xFFF5F5F5),
      };

  String get _label => switch (status) {
        StatusKeluhan.diproses => 'DIPROSES',
        StatusKeluhan.selesai  => 'SELESAI',
        StatusKeluhan.ditolak  => 'DITOLAK',
        StatusKeluhan.menunggu => 'MENUNGGU',
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        _label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: _color,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textGrey),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.inter(
                  fontSize: 13, color: AppColors.textGrey),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Banner buat laporan baru
// ─────────────────────────────────────────────────────────────────────────────
class _BuatLaporanBanner extends StatelessWidget {
  const _BuatLaporanBanner({this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, Color(0xFF0D5BAA)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.07),
              ),
            ),
          ),
          Positioned(
            right: 40,
            top: -10,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Punya Masalah Lain?',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Layanan kami tersedia 24/7 untuk\nmemastikan kenyamanan Anda di hunian ini.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.85),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: onTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'BUAT LAPORAN BARU',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
