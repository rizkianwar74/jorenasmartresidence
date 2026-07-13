import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' show DateFormat;
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/smart_image.dart';
import '../../core/utils/responsive_helper.dart';
import 'models/berita_doc.dart';

class BeritaDetailPage extends StatelessWidget {
  const BeritaDetailPage({super.key, required this.berita});

  final BeritaDoc berita;

  String get _estimasiBaca {
    final words = berita.konten.split(' ').length;
    final minutes = (words / 200).ceil();
    return '$minutes menit baca';
  }

  String get _tanggal {
    if (berita.publishedAt == null) return '-';
    return DateFormat('dd MMM yyyy').format(berita.publishedAt!);
  }

  @override
  Widget build(BuildContext context) {
    final hPad = Responsive.value<double>(context, mobile: 20, tablet: 32);
    final titleSize = Responsive.value<double>(context, mobile: 22, tablet: 26);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          color: AppColors.textDark,
          onPressed: () => Navigator.pop(context),
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
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Hero image ─────────────────────────────────────────
                Stack(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: Responsive.value<double>(
                          context, mobile: 230, tablet: 300),
                      child: SmartImage(imageUrl: berita.imageUrl),
                    ),
                    Positioned(
                      top: 12,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          berita.kategori.toUpperCase(),
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

                // ── Konten artikel ────────────────────────────────────
                Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: hPad, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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

                      Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor:
                                AppColors.primary.withValues(alpha: 0.1),
                            child: const Icon(Icons.person,
                                color: AppColors.primary, size: 18),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tim Redaksi',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                Text(
                                  '$_tanggal  •  $_estimasiBaca',
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
                      Divider(color: Colors.grey.shade200),
                      const SizedBox(height: 20),

                      _ArticleContent(konten: berita.konten),

                      const SizedBox(height: 40),

                      Wrap(
                        spacing: 8,
                        children: [
                          _TagChip(label: berita.kategori),
                          const _TagChip(label: 'Jorena Residence'),
                        ],
                      ),

                      const SizedBox(height: 32),
                    ],
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


// ── Parser konten artikel ─────────────────────────────────────────────────────

class _ArticleContent extends StatelessWidget {
  const _ArticleContent({required this.konten});
  final String konten;

  @override
  Widget build(BuildContext context) {
    final lines = konten.split('\n');
    final widgets = <Widget>[];

    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty) {
        widgets.add(const SizedBox(height: 12));
        continue;
      }
      if (line.startsWith('•')) {
        widgets.add(_BulletItem(text: line.replaceFirst('•', '').trim()));
        widgets.add(const SizedBox(height: 6));
        continue;
      }
      final isHeading = (line.endsWith(':') && line.length < 60) ||
          (line == line.toUpperCase() &&
              line.length > 3 &&
              !line.contains('.'));
      if (isHeading) {
        if (widgets.isNotEmpty) widgets.add(const SizedBox(height: 8));
        widgets.add(Text(line,
            style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark)));
        widgets.add(const SizedBox(height: 10));
        continue;
      }
      widgets.add(Text(line,
          style: GoogleFonts.inter(
              fontSize: 15,
              color: const Color(0xFF2D3748),
              height: 1.7)));
    }

    return Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: widgets);
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
            color: AppColors.primary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check, size: 12, color: AppColors.primary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text,
              style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF2D3748),
                  height: 1.6)),
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
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primary)),
    );
  }
}
