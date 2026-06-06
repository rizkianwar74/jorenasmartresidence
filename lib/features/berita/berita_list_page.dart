import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/data/berita_data.dart';
import '../../core/utils/responsive_helper.dart';
import 'berita_detail_page.dart';

class BeritaListPage extends StatefulWidget {
  const BeritaListPage({super.key});

  @override
  State<BeritaListPage> createState() => _BeritaListPageState();
}

class _BeritaListPageState extends State<BeritaListPage> {
  String _searchQuery = '';
  KategoriBerita? _selectedKategori; // null = Semua

  static const _filterOptions = <String, KategoriBerita?>{
    'Semua'       : null,
    'Fasilitas'   : KategoriBerita.fasilitas,
    'Keamanan'    : KategoriBerita.keamanan,
    'Kegiatan'    : KategoriBerita.kegiatan,
    'Pengumuman'  : KategoriBerita.pengumuman,
    'Kehilangan'  : KategoriBerita.kehilangan,
  };

  List<BeritaModel> get _filteredList {
    return dummyBeritaList.where((b) {
      final matchKategori =
          _selectedKategori == null || b.kategori == _selectedKategori;
      final matchSearch = _searchQuery.isEmpty ||
          b.judul.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          b.ringkasan.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchKategori && matchSearch;
    }).toList();
  }

  String _estimasiBaca(BeritaModel b) {
    final minutes = (b.isi.split(' ').length / 200).ceil();
    return '$minutes MENIT BACA';
  }

  @override
  Widget build(BuildContext context) {
    final hPad = Responsive.value<double>(context, mobile: 20, tablet: 32);
    final isTablet = Responsive.isTablet(context) || Responsive.isDesktop(context);

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
          'Berita Komunitas',
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
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 0),
                child: Column(
                  children: [
                    // ── Search bar ───────────────────────────────────
                    Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: TextField(
                        onChanged: (v) => setState(() => _searchQuery = v),
                        style: GoogleFonts.inter(
                            fontSize: 14, color: AppColors.textDark),
                        decoration: InputDecoration(
                          hintText: 'Cari berita atau pengumuman...',
                          hintStyle: GoogleFonts.inter(
                              fontSize: 14, color: AppColors.textGrey),
                          prefixIcon: const Icon(Icons.search,
                              color: AppColors.textGrey, size: 20),
                          border: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 13),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),

              // ── Filter chips ─────────────────────────────────────────
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: hPad),
                  physics: const BouncingScrollPhysics(),
                  children: _filterOptions.entries.map((entry) {
                    final isActive = _selectedKategori == entry.value;
                    return GestureDetector(
                      onTap: () =>
                          setState(() => _selectedKategori = entry.value),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: isActive ? AppColors.primary : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isActive
                                ? AppColors.primary
                                : Colors.grey.shade300,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          entry.key,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isActive
                                ? Colors.white
                                : AppColors.textDark,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 16),

              // ── List berita ─────────────────────────────────────────
              Expanded(
                child: _filteredList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.article_outlined,
                                size: 48, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            Text(
                              'Tidak ada berita ditemukan',
                              style: GoogleFonts.inter(
                                  fontSize: 14, color: AppColors.textGrey),
                            ),
                          ],
                        ),
                      )
                    : isTablet
                        // Grid 2 kolom di tablet
                        ? GridView.builder(
                            padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 32),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 0.75,
                            ),
                            itemCount: _filteredList.length,
                            itemBuilder: (_, i) => _BeritaCard(
                              berita: _filteredList[i],
                              estimasi: _estimasiBaca(_filteredList[i]),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BeritaDetailPage(
                                      berita: _filteredList[i]),
                                ),
                              ),
                            ),
                          )
                        // List vertikal di mobile
                        : ListView.separated(
                            padding:
                                EdgeInsets.fromLTRB(hPad, 0, hPad, 32),
                            itemCount: _filteredList.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 16),
                            itemBuilder: (_, i) => _BeritaCard(
                              berita: _filteredList[i],
                              estimasi: _estimasiBaca(_filteredList[i]),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BeritaDetailPage(
                                      berita: _filteredList[i]),
                                ),
                              ),
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

// ── Kartu berita ──────────────────────────────────────────────────────────────
class _BeritaCard extends StatelessWidget {
  const _BeritaCard({
    required this.berita,
    required this.estimasi,
    this.onTap,
  });

  final BeritaModel berita;
  final String estimasi;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gambar + badge kategori
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(
                      berita.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.broken_image_outlined,
                            color: Colors.grey, size: 32),
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
                  ),
                  // Badge kategori
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
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
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Konten teks
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Judul
                  Text(
                    berita.judul,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Ringkasan
                  Text(
                    berita.ringkasan,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textGrey,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Tanggal + estimasi baca
                  Row(
                    children: [
                      Icon(Icons.calendar_today_outlined,
                          size: 12, color: AppColors.textGrey),
                      const SizedBox(width: 4),
                      Text(
                        berita.tanggal,
                        style: GoogleFonts.inter(
                            fontSize: 12, color: AppColors.textGrey),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.access_time_rounded,
                          size: 12, color: AppColors.textGrey),
                      const SizedBox(width: 4),
                      Text(
                        estimasi,
                        style: GoogleFonts.inter(
                            fontSize: 12, color: AppColors.textGrey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}