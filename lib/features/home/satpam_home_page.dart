import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/router/app_router.dart';
import '../../shared/widgets/bottom_nav_bar.dart';
import '../auth/auth_repository.dart';
import 'widgets/home_header.dart';
import 'widgets/news_carousel.dart';

class SatpamHomePage extends StatelessWidget {
  const SatpamHomePage({super.key});

  static const double _contentMaxWidth = 600.0;

  // ── Mock news — nanti ganti dari Firestore ─────────────────────────────
  static const _newsList = [
    NewsItem(
      imageUrl: 'https://picsum.photos/id/1/400/250',
      category: 'Fasilitas',
      title: 'Renovasi Clubhouse Selesai',
      date: '12 Okt 2023',
    ),
    NewsItem(
      imageUrl: 'https://picsum.photos/id/200/400/250',
      category: 'Kegiatan',
      title: 'Sesi Yoga Aktif',
      date: '14 Okt 2023',
    ),
    NewsItem(
      imageUrl: 'https://picsum.photos/id/58/400/250',
      category: 'Keamanan',
      title: 'Protokol Keamanan Baru',
      date: '15 Okt 2023',
    ),
  ];

  // ── Mock aktivitas keamanan — nanti ganti dari Firestore ───────────────
  static const _mockAktivitas = [
    _AktivitasItem(
      icon: Icons.wifi_tethering,
      label: 'Gerbang Blok A Dibuka',
      waktu: 'Baru saja • Via RFID',
      warna: _AktivitasWarna.biru,
    ),
    _AktivitasItem(
      icon: Icons.directions_walk_rounded,
      label: 'Patroli Area Barat Selesai',
      waktu: '07:00 • Rudi H.',
      warna: _AktivitasWarna.hijau,
    ),
    _AktivitasItem(
      icon: Icons.local_shipping_outlined,
      label: 'Tamu Masuk: Kurir JNE',
      waktu: 'Kemarin, 19:15 • Gerbang Utama',
      warna: _AktivitasWarna.abu,
    ),
    _AktivitasItem(
      icon: Icons.warning_amber_rounded,
      label: 'SOS Diterima — Blok B No. 17',
      waktu: 'Kemarin, 21:30 • Sudah ditangani',
      warna: _AktivitasWarna.merah,
    ),
  ];

  String _buildGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat Pagi';
    if (hour < 15) return 'Selamat Siang';
    if (hour < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  @override
  Widget build(BuildContext context) {
    final namaUser =
        AuthRepository.currentUser?.namaLengkap.split(' ').first ?? 'Satpam';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── Main scrollable content ──────────────────────────────────
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: MediaQuery.of(context).padding.top),

                    // ── Header ─────────────────────────────────────────
                    HomeHeader(
                      userName: namaUser,
                      greeting: _buildGreeting(),
                      notificationCount: 2, // TODO: dari Firestore
                      onNotificationTap: () {
                        // TODO: buka notifikasi / SOS inbox
                      },
                    ),

                    // ── Badge role ─────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.teal.shade100),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.shield_outlined,
                              size: 14,
                              color: Colors.teal.shade700,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'PETUGAS KEAMANAN • Shift Pagi',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal.shade700,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Row: Shift card + Laporan masuk card ───────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          Expanded(child: _SatpamShiftCard()),
                          const SizedBox(width: 14),
                          Expanded(child: _LaporanMasukCard()),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Quick action grid ──────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _QuickActionGrid(context: context),
                    ),

                    // ── News carousel (sama seperti user) ─────────────
                    NewsCarousel(
                      items: _newsList,
                      onSeeAllTap: () {},
                      onNewsTap: (item) {},
                    ),

                    // ── Log aktivitas keamanan ─────────────────────────
                    _AktivitasSection(items: _mockAktivitas),

                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),

          // ── Bottom nav ───────────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: BottomNavBar(
              currentIndex: 0,
              contentMaxWidth: _contentMaxWidth,
            ),
          ),

          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 130,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Widget: Shift Card
// Menampilkan info shift aktif + jam mulai & selesai + jam ronda berikutnya
// ════════════════════════════════════════════════════════════════════════════
class _SatpamShiftCard extends StatelessWidget {
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
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label atas
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.access_time_rounded,
                  color: Colors.teal.shade600,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'SHIFT AKTIF',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textGrey,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Nama shift
          Text(
            'Pagi',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),

          Text(
            '06:00 – 14:00',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textGrey,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 12),

          // Ronda berikutnya
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.directions_walk_rounded,
                  size: 12,
                  color: Colors.teal.shade700,
                ),
                const SizedBox(width: 4),
                Text(
                  'Ronda: 10:00',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.teal.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Widget: Laporan Masuk Card
// Menampilkan jumlah SOS dan keluhan aktif hari ini
// ════════════════════════════════════════════════════════════════════════════
class _LaporanMasukCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // TODO: ganti angka ini dari Firestore stream
    const int jumlahSos = 1;
    const int jumlahKeluhan = 3;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label atas
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: jumlahSos > 0
                      ? Colors.red.shade50
                      : AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.inbox_outlined,
                  color:
                      jumlahSos > 0 ? Colors.red.shade600 : AppColors.primary,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'LAPORAN',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textGrey,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // SOS aktif
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: jumlahSos > 0
                      ? Colors.red.shade600
                      : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '$jumlahSos',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: jumlahSos > 0 ? Colors.white : AppColors.textGrey,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'SOS aktif',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: jumlahSos > 0
                      ? Colors.red.shade600
                      : AppColors.textGrey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // Keluhan
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '$jumlahKeluhan',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Keluhan',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textGrey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Tombol lihat
          GestureDetector(
            onTap: () {
              // TODO: navigasi ke halaman kelola laporan
            },
            child: Text(
              'LIHAT SEMUA →',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Widget: Quick Action Grid (2×2)
// 4 shortcut utama untuk satpam
// ════════════════════════════════════════════════════════════════════════════
class _QuickActionGrid extends StatelessWidget {
  const _QuickActionGrid({required this.context});
  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    final items = [
      _QuickItem(
        icon: Icons.person_add_alt_1_outlined,
        label: 'Catat Tamu',
        sublabel: 'LOG KUNJUNGAN',
        iconColor: AppColors.primary,
        bgColor: AppColors.primaryLight,
        onTap: () {
          // TODO: navigasi ke LogTamuPage
        },
      ),
      _QuickItem(
        icon: Icons.inbox_outlined,
        label: 'Laporan Masuk',
        sublabel: 'SOS & KELUHAN',
        iconColor: Colors.red.shade600,
        bgColor: Colors.red.shade50,
        onTap: () {
          // TODO: navigasi ke IncomingAlertsPage
        },
      ),
      _QuickItem(
        icon: Icons.route_outlined,
        label: 'Mulai Patroli',
        sublabel: 'CHECKLIST AREA',
        iconColor: Colors.teal.shade600,
        bgColor: Colors.teal.shade50,
        onTap: () {
          HapticFeedback.mediumImpact();
          // TODO: navigasi ke PatroliPage
        },
      ),
      _QuickItem(
        icon: Icons.phone_in_talk_outlined,
        label: 'Hubungi Pos',
        sublabel: 'PUSAT KENDALI',
        iconColor: Colors.orange.shade700,
        bgColor: Colors.orange.shade50,
        onTap: () {
          // TODO: url_launcher → tel:nomor_pos
        },
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.45,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: items.map((item) => _QuickActionTile(item: item)).toList(),
    );
  }
}

class _QuickItem {
  const _QuickItem({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.iconColor,
    required this.bgColor,
    this.onTap,
  });
  final IconData icon;
  final String label;
  final String sublabel;
  final Color iconColor;
  final Color bgColor;
  final VoidCallback? onTap;
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({required this.item});
  final _QuickItem item;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: item.onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: item.bgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(item.icon, color: item.iconColor, size: 20),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.sublabel,
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textGrey,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Widget: Aktivitas Section
// Log aktivitas keamanan terkini (RFID, patroli, tamu, SOS)
// ════════════════════════════════════════════════════════════════════════════
enum _AktivitasWarna { biru, hijau, merah, abu }

class _AktivitasItem {
  const _AktivitasItem({
    required this.icon,
    required this.label,
    required this.waktu,
    required this.warna,
  });
  final IconData icon;
  final String label;
  final String waktu;
  final _AktivitasWarna warna;
}

class _AktivitasSection extends StatelessWidget {
  const _AktivitasSection({required this.items});
  final List<_AktivitasItem> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Aktivitas Keamanan',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              GestureDetector(
                onTap: () {
                  // TODO: navigasi ke SecurityPage (lihat semua)
                },
                child: Text(
                  'Lihat Semua',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // List item
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: List.generate(items.length, (i) {
                final item = items[i];
                final isLast = i == items.length - 1;
                return _AktivitasTile(
                  item: item,
                  isLast: isLast,
                  onTap: () {
                    // TODO: buka detail aktivitas
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _AktivitasTile extends StatelessWidget {
  const _AktivitasTile({
    required this.item,
    required this.isLast,
    this.onTap,
  });
  final _AktivitasItem item;
  final bool isLast;
  final VoidCallback? onTap;

  Color get _iconBg => switch (item.warna) {
        _AktivitasWarna.biru => AppColors.primaryLight,
        _AktivitasWarna.hijau => Colors.green.shade50,
        _AktivitasWarna.merah => Colors.red.shade50,
        _AktivitasWarna.abu => Colors.grey.shade100,
      };

  Color get _iconColor => switch (item.warna) {
        _AktivitasWarna.biru => AppColors.primary,
        _AktivitasWarna.hijau => Colors.green.shade600,
        _AktivitasWarna.merah => Colors.red.shade600,
        _AktivitasWarna.abu => AppColors.textGrey,
      };

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.vertical(
            bottom: isLast ? const Radius.circular(14) : Radius.zero,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: _iconBg,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(item.icon, color: _iconColor, size: 19),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.label,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.waktu,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.textGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: AppColors.textGrey,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            indent: 68,
            endIndent: 16,
            color: Colors.grey.shade100,
          ),
      ],
    );
  }
}