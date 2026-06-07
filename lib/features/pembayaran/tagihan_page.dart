import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive_helper.dart';
import 'tagihan_model.dart';
import 'payment_webview_page.dart';

class TagihanPage extends StatelessWidget {
  const TagihanPage({super.key});

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
          'Tagihan Saya',
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TagihanAktifCard(
                  tagihan: mockTagihanAktif,
                  onBayar: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          PaymentWebViewPage(tagihan: mockTagihanAktif),
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Riwayat Pembayaran',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      '${mockRiwayatTagihan.length} transaksi',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppColors.textGrey),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                ...mockRiwayatTagihan.map(
                  (t) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _RiwayatCard(tagihan: t),
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

// ── Kartu tagihan aktif ───────────────────────────────────────────────────────
class _TagihanAktifCard extends StatelessWidget {
  const _TagihanAktifCard({required this.tagihan, this.onBayar});
  final TagihanModel tagihan;
  final VoidCallback? onBayar;

  String get _statusLabel => switch (tagihan.status) {
        StatusTagihan.belumBayar => 'Belum Dibayar',
        StatusTagihan.jatuhTempo => 'Jatuh Tempo',
        StatusTagihan.lunas      => 'Lunas',
        StatusTagihan.pending    => 'Menunggu Konfirmasi',
      };

  @override
  Widget build(BuildContext context) {
    final isLunas = tagihan.status == StatusTagihan.lunas;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, const Color(0xFF0D5BAA)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20, top: -20,
            child: Container(
              width: 160, height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),
          Positioned(
            right: 40, bottom: -30,
            child: Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'IURAN BULANAN',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withOpacity(0.7),
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          tagihan.periodeLabel,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _statusLabel,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                Row(
                  children: [
                    const Icon(Icons.person_outline,
                        color: Colors.white54, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      tagihan.namaResiden,
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.85)),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.apartment,
                        color: Colors.white54, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      tagihan.unitLabel,
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.85)),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Text(
                  tagihan.jumlahFormatted,
                  style: GoogleFonts.inter(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 4),

                Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        color: Colors.white54, size: 13),
                    const SizedBox(width: 6),
                    Text(
                      'Jatuh tempo: ${tagihan.jatuhTempo}',
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.7)),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                if (isLunas)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle,
                            color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Tagihan Anda Lunas',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: onBayar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Bayar Sekarang',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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

// ── Kartu riwayat ─────────────────────────────────────────────────────────────
class _RiwayatCard extends StatelessWidget {
  const _RiwayatCard({required this.tagihan});
  final TagihanModel tagihan;

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
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_circle_outline,
                color: Colors.green.shade600, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Iuran ${tagihan.periodeLabel}',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      tagihan.tanggalBayar ?? '-',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppColors.textGrey),
                    ),
                    if (tagihan.metodeBayar != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        width: 3, height: 3,
                        decoration: const BoxDecoration(
                          color: AppColors.textGrey,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        tagihan.metodeBayar!,
                        style: GoogleFonts.inter(
                            fontSize: 12, color: AppColors.textGrey),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                tagihan.jumlahFormatted,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 3),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Lunas',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade600,
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