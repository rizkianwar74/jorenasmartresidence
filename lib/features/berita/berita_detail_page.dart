import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/data/berita_data.dart';
import '../../core/utils/responsive_helper.dart';

class BeritaDetailPage extends StatelessWidget {
  const BeritaDetailPage({super.key, required this.berita});

  final BeritaModel berita;

  /// Estimasi waktu baca berdasarkan panjang isi artikel
  /// Rata-rata orang membaca 200 kata/menit
  String get _estimasiBaca {
    final wordCount = berita.isi.split(' ').length;
    final minutes = (wordCount / 200).ceil();
    return '$minutes menit baca';
  }

  @override
  Widget build(BuildContext context) {
    final hPad = Responsive.value<double>(context, mobile: 20, tablet: 32);
    final titleSize =
        Responsive.value<double>(context, mobile: 24, tablet: 28);

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // ── SliverAppBar dengan hero image ────────────────────────────
          SliverAppBar(
            expandedHeight:
                Responsive.value<double>(context, mobile: 260, tablet: 340),
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new,
                    size: 16,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
            title: Text(
              'Berita Komunitas',
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            centerTitle: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Gambar hero
                  Image.network(
                    berita.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.broken_image_outlined,
                          size: 48, color: Colors.grey),
                    ),
                    loadingBuilder: (_, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        color: Colors.grey.shade100,
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    },
                  ),
                  // Gradient overlay bawah
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 80,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.3),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Badge kategori
                  Positioned(
                    top: 100,
                    left: hPad,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        berita.kategoriLabel.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Konten artikel ────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: hPad, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Judul
                      Text(
                        berita.judul,
                        style: GoogleFonts.inter(
                          fontSize: titleSize,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                          height: 1.3,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Info penulis + tanggal + estimasi baca
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor:
                                AppColors.primary.withOpacity(0.1),
                            child: const Icon(Icons.person,
                                color: AppColors.primary, size: 18),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  berita.penulis,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                Text(
                                  '${berita.tanggal}  •  $_estimasiBaca',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: AppColors.textGrey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),
                      Divider(color: Colors.grey.shade100),
                      const SizedBox(height: 20),

                      // Isi artikel
                      _ArticleContent(isi: berita.isi),

                      const SizedBox(height: 40),

                      // Tag kategori di bawah
                      Wrap(
                        spacing: 8,
                        children: [
                          _TagChip(label: berita.kategoriLabel),
                          _TagChip(label: 'Jorena Residence'),
                        ],
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Parser konten artikel ────────────────────────────────────────────────────
// Mengubah teks mentah menjadi widget yang terformat
// Aturan sederhana:
//   - Baris diawali "•" → bullet item dengan ikon centang biru
//   - Baris yang seluruhnya huruf kapital atau diakhiri ":" → heading section
//   - Baris lainnya → paragraf biasa

class _ArticleContent extends StatelessWidget {
  const _ArticleContent({required this.isi});
  final String isi;

  @override
  Widget build(BuildContext context) {
    final lines = isi.split('\n');
    final widgets = <Widget>[];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();

      if (line.isEmpty) {
        widgets.add(const SizedBox(height: 12));
        continue;
      }

      // Bullet item
      if (line.startsWith('•')) {
        widgets.add(_BulletItem(text: line.replaceFirst('•', '').trim()));
        widgets.add(const SizedBox(height: 6));
        continue;
      }

      // Heading section (baris pendek diakhiri ":" atau semua kapital)
      final isHeading = (line.endsWith(':') && line.length < 60) ||
          (line == line.toUpperCase() && line.length > 3 && !line.contains('.'));

      if (isHeading) {
        if (widgets.isNotEmpty) widgets.add(const SizedBox(height: 8));
        widgets.add(
          Text(
            line,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
        );
        widgets.add(const SizedBox(height: 10));
        continue;
      }

      // Paragraf biasa
      widgets.add(
        Text(
          line,
          style: GoogleFonts.inter(
            fontSize: 15,
            color: const Color(0xFF2D3748),
            height: 1.7,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }
}

class _BulletItem extends StatelessWidget {
  const _BulletItem({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 3),
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check,
            size: 12,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: const Color(0xFF2D3748),
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );
  }
}