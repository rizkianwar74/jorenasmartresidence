import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/data/sos_repository.dart';
import '../sos_status_page.dart';
import 'bantuan_form_page.dart';

class BantuanCategory {
  const BantuanCategory({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;
}

const _categories = [
  BantuanCategory(
    icon: Icons.directions_walk_rounded,
    title: 'Pendampingan',
    subtitle: 'Satpam mengantar',
  ),
  BantuanCategory(
    icon: Icons.directions_car_outlined,
    title: 'Kendaraan',
    subtitle: 'Kendaraan menghalangi',
  ),
  BantuanCategory(
    icon: Icons.remove_red_eye_outlined,
    title: 'Orang Mencurigakan',
    subtitle: 'Melaporkan aktivitas',
  ),
  BantuanCategory(
    icon: Icons.volume_up_outlined,
    title: 'Gangguan Lingkungan',
    subtitle: 'Keributan / gangguan',
  ),
  BantuanCategory(
    icon: Icons.edit_outlined,
    title: 'Lainnya',
    subtitle: 'Bantuan lainnya',
  ),
];

class BantuanSatpamPage extends StatelessWidget {
  const BantuanSatpamPage({super.key});

  static const double _contentMaxWidth = 600.0;

  void _onPanggil(BuildContext context) {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Panggil Satpam?',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Text(
          'Satpam akan menerima notifikasi dan segera merespons.',
          style: GoogleFonts.inter(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal',
                style: GoogleFonts.inter(color: AppColors.textGrey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              // Cek satpam bertugas & kirim panggilan sekaligus (paralel)
              // supaya pengecekan ini tidak menambah delay.
              final results = await Future.wait([
                SosRepository.hasSatpamOnDuty(),
                SosRepository.sendCall(),
              ]);
              final hasOnDuty = results[0] as bool;
              final alert = results[1] as SosAlert?;
              if (!context.mounted) return;
              if (alert != null) {
                if (!hasOnDuty) {
                  await _showNoSatpamOnDutyWarning(
                    context,
                    'Panggilan Anda tetap tersimpan dan akan segera '
                    'diproses begitu ada satpam yang online.',
                  );
                  if (!context.mounted) return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SosStatusPage(
                      alertId: alert.id,
                      type: SosType.call,
                    ),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Gagal mengirim panggilan. Coba lagi.',
                        style: GoogleFonts.inter(fontSize: 13)),
                    backgroundColor: Colors.red.shade700,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Panggil',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ── Warning: tidak ada satpam yang sedang bertugas ───────────────────────
  Future<void> _showNoSatpamOnDutyWarning(BuildContext context, String message) {
    return showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Tidak Ada Satpam Bertugas',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        content: Text(message,
            style: GoogleFonts.inter(fontSize: 14, height: 1.4)),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Mengerti',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          'Bantuan Satpam',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, size: 22),
            color: AppColors.primary,
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: Text(
                    'Informasi Layanan',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                  ),
                  content: Text(
                    'Layanan Bantuan Satpam tersedia 24/7. '
                    'Satpam akan merespons dalam 3–5 menit setelah laporan diterima.',
                    style: GoogleFonts.inter(fontSize: 14, height: 1.5),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Mengerti',
                        style: GoogleFonts.inter(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- Heading ---
                      Text(
                        'Apa yang Anda perlukan?',
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Kami siap membantu menjaga keamanan\nlingkungan Anda 24/7.',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.textGrey,
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // --- List kategori ---
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: List.generate(_categories.length, (i) {
                            final cat = _categories[i];
                            final isLast = i == _categories.length - 1;
                            return _CategoryItem(
                              category: cat,
                              isLast: isLast,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => BantuanFormPage(
                                      category: cat,
                                    ),
                                  ),
                                );
                              },
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // --- Banner darurat (pinned di bawah) ---
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.red.shade100),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.red,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'KEADAAN DARURAT?',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade700,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Segera hubungi pos keamanan pusat.',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: Colors.red.shade700,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () => _onPanggil(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade700,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'PANGGIL',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryItem extends StatelessWidget {
  const _CategoryItem({
    required this.category,
    required this.isLast,
    this.onTap,
  });

  final BantuanCategory category;
  final bool isLast;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.vertical(
            top: const Radius.circular(0),
            bottom: isLast ? const Radius.circular(16) : Radius.zero,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    category.icon,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.title,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        category.subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.textGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: AppColors.textGrey,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            indent: 80,
            endIndent: 16,
            color: Colors.grey.shade100,
          ),
      ],
    );
  }
}