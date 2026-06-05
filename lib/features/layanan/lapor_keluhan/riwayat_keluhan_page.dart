import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive_helper.dart';
import 'lapor_keluhan_page.dart';

// ── Model ────────────────────────────────────────────────────────────────────

enum StatusKeluhan { diproses, selesai, menunggu, ditolak }

class RiwayatKeluhan {
  const RiwayatKeluhan({
    required this.refId,
    required this.judul,
    required this.deskripsi,
    required this.tanggal,
    required this.jam,
    required this.status,
    required this.kategori,
  });

  final String refId;
  final String judul;
  final String deskripsi;
  final String tanggal;
  final String jam;
  final StatusKeluhan status;
  final String kategori;
}

// Mock data
const _mockRiwayat = [
  RiwayatKeluhan(
    refId: '#REF-1024',
    judul: 'Keluhan Infrastruktur',
    deskripsi: 'Lampu jalan di area Cluster Magnolia blok C...',
    tanggal: '24 Okt 2023',
    jam: '14:30',
    status: StatusKeluhan.diproses,
    kategori: 'Keluhan Infrastruktur',
  ),
  RiwayatKeluhan(
    refId: '#REF-1018',
    judul: 'Kendaraan Menghalangi',
    deskripsi: 'Ada mobil putih B 1234 XYZ parkir tepat di...',
    tanggal: '22 Okt 2023',
    jam: '08:15',
    status: StatusKeluhan.selesai,
    kategori: 'Keluhan Manajemen',
  ),
  RiwayatKeluhan(
    refId: '#REF-1005',
    judul: 'Bantuan Keamanan',
    deskripsi: 'Mohon pengecekan CCTV area taman...',
    tanggal: '10 Okt 2023',
    jam: '11:45',
    status: StatusKeluhan.selesai,
    kategori: 'Keluhan Manajemen',
  ),
];

// ── Page ─────────────────────────────────────────────────────────────────────

class RiwayatKeluhanPage extends StatelessWidget {
  const RiwayatKeluhanPage({super.key});

  static const double _contentMaxWidth = 600.0;

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
          'Report History',
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
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 32),
            child: Column(
              children: [
                // ── List riwayat ──────────────────────────────────────
                ..._mockRiwayat.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _RiwayatCard(
                      item: item,
                      onDetailTap: () {
                        // TODO: navigasi ke detail keluhan
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // ── Banner buat laporan baru ──────────────────────────
                _BuatLaporanBanner(
                  onTap: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LaporKeluhanPage(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Kartu riwayat ─────────────────────────────────────────────────────────────

class _RiwayatCard extends StatelessWidget {
  const _RiwayatCard({required this.item, this.onDetailTap});

  final RiwayatKeluhan item;
  final VoidCallback? onDetailTap;

  Color get _statusColor => switch (item.status) {
        StatusKeluhan.diproses => const Color(0xFFFF9500),
        StatusKeluhan.selesai  => const Color(0xFF34C759),
        StatusKeluhan.menunggu => AppColors.textGrey,
        StatusKeluhan.ditolak  => Colors.red,
      };

  Color get _statusBg => switch (item.status) {
        StatusKeluhan.diproses => const Color(0xFFFFF3E0),
        StatusKeluhan.selesai  => const Color(0xFFE8F5E9),
        StatusKeluhan.menunggu => const Color(0xFFF5F5F5),
        StatusKeluhan.ditolak  => const Color(0xFFFFEBEE),
      };

  String get _statusLabel => switch (item.status) {
        StatusKeluhan.diproses => 'DIPROSES',
        StatusKeluhan.selesai  => 'SELESAI',
        StatusKeluhan.menunggu => 'MENUNGGU',
        StatusKeluhan.ditolak  => 'DITOLAK',
      };

  @override
  Widget build(BuildContext context) {
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
          // Baris atas: ref id + badge status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                item.refId,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textGrey,
                  letterSpacing: 0.3,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
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
              fontSize: 16,
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
              fontSize: 13,
              color: AppColors.textGrey,
            ),
          ),

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
                    '${item.tanggal}, ${item.jam}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textGrey,
                    ),
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

// ── Banner buat laporan baru ──────────────────────────────────────────────────

class _BuatLaporanBanner extends StatelessWidget {
  const _BuatLaporanBanner({this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, const Color(0xFF0D5BAA)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          // Dekorasi lingkaran
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

          // Konten
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
                    horizontal: 20,
                    vertical: 12,
                  ),
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