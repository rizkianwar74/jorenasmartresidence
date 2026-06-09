import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import 'widgets/admin_sidebar.dart';
import 'widgets/admin_top_bar.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Model & mock data
// ─────────────────────────────────────────────────────────────────────────────

enum _BeritaStatus { published, draft }

class _BeritaItem {
  const _BeritaItem({
    required this.judul,
    required this.kategori,
    required this.penulis,
    required this.tanggal,
    required this.status,
    required this.thumbnailColor,
    required this.thumbnailIcon,
  });
  final String judul;
  final String kategori;
  final String penulis;
  final String tanggal;
  final _BeritaStatus status;
  final Color thumbnailColor;
  final IconData thumbnailIcon;
}

const _mockBerita = [
  _BeritaItem(
    judul: 'Protokol Keamanan Terbaru Untuk Seluruh Warga',
    kategori: 'KEAMANAN',
    penulis: 'Budi Santoso',
    tanggal: '12 Okt 2023',
    status: _BeritaStatus.published,
    thumbnailColor: Color(0xFF1E3A8A),
    thumbnailIcon: Icons.security_outlined,
  ),
  _BeritaItem(
    judul: 'Inisiatif Pengelolaan Sampah Lingkungan Bersama',
    kategori: 'LINGKUNGAN',
    penulis: 'Ani Wijaya',
    tanggal: '10 Okt 2023',
    status: _BeritaStatus.draft,
    thumbnailColor: Color(0xFF15803D),
    thumbnailIcon: Icons.eco_outlined,
  ),
  _BeritaItem(
    judul: 'Renovasi Area Bermain Anak Segera Dimulai',
    kategori: 'FASILITAS',
    penulis: 'Dewi Lestari',
    tanggal: '08 Okt 2023',
    status: _BeritaStatus.published,
    thumbnailColor: Color(0xFF0369A1),
    thumbnailIcon: Icons.sports_soccer_outlined,
  ),
  _BeritaItem(
    judul: 'Rapat Rutin Pengurus Bulan Oktober 2023',
    kategori: 'AGENDA',
    penulis: 'Setyo Nugroho',
    tanggal: '05 Okt 2023',
    status: _BeritaStatus.published,
    thumbnailColor: Color(0xFF6B21A8),
    thumbnailIcon: Icons.event_note_outlined,
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// Page
// ─────────────────────────────────────────────────────────────────────────────

class AdminBeritaPage extends StatefulWidget {
  const AdminBeritaPage({super.key});

  @override
  State<AdminBeritaPage> createState() => _AdminBeritaPageState();
}

class _AdminBeritaPageState extends State<AdminBeritaPage> {
  int _currentPage = 1;
  final int _totalItems = 128;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // ── Sidebar ────────────────────────────────────────────────────
          const AdminSidebar(activePage: AdminPage.berita),

          // ── Main content ───────────────────────────────────────────────
          Expanded(
            child: Column(
              children: [
                AdminTopBar(
                  searchHint: 'Cari berita...',
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(28, 24, 28, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Page header ──────────────────────────────────
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Manajemen Berita',
                                    style: GoogleFonts.inter(
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Kelola dan publikasikan pembaruan komunitas terbaru.',
                                    style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: AppColors.textGrey),
                                  ),
                                ],
                              ),
                            ),
                            // Tambah Berita Baru button
                            ElevatedButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.add,
                                  size: 18, color: Colors.white),
                              label: Text(
                                'Tambah Berita Baru',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // ── Stat cards ───────────────────────────────────
                        Row(
                          children: const [
                            Expanded(
                              child: _StatCard(
                                label: 'Total Berita',
                                value: '128',
                                icon: Icons.article_outlined,
                                iconBg: Color(0xFFEFF6FF),
                                iconColor: Color(0xFF1D4ED8),
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: _StatCard(
                                label: 'Diterbitkan',
                                value: '114',
                                icon: Icons.check_circle_outline,
                                iconBg: Color(0xFFF0FDF4),
                                iconColor: Color(0xFF16A34A),
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: _StatCard(
                                label: 'Draf',
                                value: '14',
                                icon: Icons.edit_note_outlined,
                                iconBg: Color(0xFFFFF7ED),
                                iconColor: Color(0xFFF97316),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // ── Table card ───────────────────────────────────
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Table title
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    20, 18, 20, 0),
                                child: Text(
                                  'DAFTAR BERITA COMMUNITY',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textGrey,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 12),

                              // Table header
                              Container(
                                color: const Color(0xFFF8FAFC),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 10),
                                child: Row(
                                  children: const [
                                    Expanded(
                                        flex: 4,
                                        child: _ColH('JUDUL BERITA')),
                                    Expanded(
                                        flex: 2,
                                        child: _ColH('KATEGORI')),
                                    Expanded(
                                        flex: 2,
                                        child: _ColH('PENULIS')),
                                    Expanded(
                                        flex: 2,
                                        child: _ColH('TANGGAL')),
                                    Expanded(
                                        flex: 2,
                                        child: _ColH('STATUS')),
                                    SizedBox(
                                        width: 60,
                                        child: _ColH('AKSI')),
                                  ],
                                ),
                              ),

                              // Rows
                              ..._mockBerita
                                  .map((item) => _BeritaRow(item: item))
                                  .toList(),

                              // Pagination
                              _PaginationBar(
                                currentPage: _currentPage,
                                totalItems: _totalItems,
                                onPageChanged: (p) =>
                                    setState(() => _currentPage = p),
                              ),
                            ],
                          ),
                        ),
                      ],
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

// ─────────────────────────────────────────────────────────────────────────────
// Stat card
// ─────────────────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // Icon bubble
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 26, color: iconColor),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textGrey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                  height: 1,
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
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

class _ColH extends StatelessWidget {
  const _ColH(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: AppColors.textGrey,
        letterSpacing: 0.5,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Berita row
// ─────────────────────────────────────────────────────────────────────────────

class _BeritaRow extends StatefulWidget {
  const _BeritaRow({required this.item});
  final _BeritaItem item;

  @override
  State<_BeritaRow> createState() => _BeritaRowState();
}

class _BeritaRowState extends State<_BeritaRow> {
  bool _hovered = false;

  Color _kategoriColor(String k) {
    switch (k) {
      case 'KEAMANAN':
        return const Color(0xFF1D4ED8);
      case 'LINGKUNGAN':
        return const Color(0xFFD97706);
      default:
        return const Color(0xFF64748B);
    }
  }

  Color _kategoriBg(String k) {
    switch (k) {
      case 'KEAMANAN':
        return const Color(0xFFEFF6FF);
      case 'LINGKUNGAN':
        return const Color(0xFFFFFBEB);
      default:
        return const Color(0xFFF1F5F9);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Container(
        decoration: BoxDecoration(
          color: _hovered
              ? AppColors.primary.withOpacity(0.03)
              : Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade100)),
        ),
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            // Judul + thumbnail
            Expanded(
              flex: 4,
              child: Row(
                children: [
                  // Thumbnail
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      width: 46,
                      height: 36,
                      color: item.thumbnailColor,
                      child: Icon(
                        item.thumbnailIcon,
                        size: 20,
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.judul,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textDark,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // Kategori badge
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _kategoriBg(item.kategori),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  item.kategori,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _kategoriColor(item.kategori),
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),

            // Penulis
            Expanded(
              flex: 2,
              child: Text(
                item.penulis,
                style: GoogleFonts.inter(
                    fontSize: 13, color: AppColors.textDark),
              ),
            ),

            // Tanggal
            Expanded(
              flex: 2,
              child: Text(
                item.tanggal,
                style: GoogleFonts.inter(
                    fontSize: 12, color: AppColors.textGrey),
              ),
            ),

            // Status
            Expanded(
              flex: 2,
              child: _StatusBadge(item.status),
            ),

            // Aksi
            SizedBox(
              width: 60,
              child: Row(
                children: [
                  _AksiBtn(
                    icon: Icons.edit_outlined,
                    color: AppColors.primary,
                    onTap: () {},
                  ),
                  const SizedBox(width: 6),
                  _AksiBtn(
                    icon: Icons.delete_outline,
                    color: Colors.red.shade400,
                    onTap: () => _showDeleteDialog(context, item.judul),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, String judul) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Hapus Berita?',
          style: GoogleFonts.inter(
              fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus "$judul"?',
          style:
              GoogleFonts.inter(fontSize: 13, color: AppColors.textGrey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal',
                style: GoogleFonts.inter(color: AppColors.textGrey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade500,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Hapus',
                style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge(this.status);
  final _BeritaStatus status;

  @override
  Widget build(BuildContext context) {
    final isPublished = status == _BeritaStatus.published;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: isPublished
                ? const Color(0xFF16A34A)
                : Colors.grey.shade400,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          isPublished ? 'PUBLISHED' : 'DRAFT',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isPublished
                ? const Color(0xFF16A34A)
                : Colors.grey.shade500,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

class _AksiBtn extends StatelessWidget {
  const _AksiBtn({
    required this.icon,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pagination
// ─────────────────────────────────────────────────────────────────────────────

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({
    required this.currentPage,
    required this.totalItems,
    required this.onPageChanged,
  });
  final int currentPage;
  final int totalItems;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    final totalPages = (totalItems / 4).ceil(); // 4 items per page (mock)
    final start = (currentPage - 1) * 4 + 1;
    final end = (currentPage * 4).clamp(0, totalItems);

    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
      ),
      padding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Text(
            'Menampilkan $start-$end dari $totalItems berita',
            style: GoogleFonts.inter(
                fontSize: 12, color: AppColors.textGrey),
          ),
          const Spacer(),
          _PBtn(
            label: '<',
            enabled: currentPage > 1,
            onTap: () => onPageChanged(currentPage - 1),
          ),
          const SizedBox(width: 4),
          _PBtn(
              label: '1',
              isActive: currentPage == 1,
              onTap: () => onPageChanged(1)),
          const SizedBox(width: 4),
          _PBtn(
              label: '2',
              isActive: currentPage == 2,
              onTap: () => onPageChanged(2)),
          const SizedBox(width: 4),
          _PBtn(
              label: '3',
              isActive: currentPage == 3,
              onTap: () => onPageChanged(3)),
          const SizedBox(width: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text('...',
                style: GoogleFonts.inter(
                    fontSize: 13, color: AppColors.textGrey)),
          ),
          const SizedBox(width: 4),
          _PBtn(
            label: '$totalPages',
            isActive: currentPage == totalPages,
            onTap: () => onPageChanged(totalPages),
          ),
          const SizedBox(width: 4),
          _PBtn(
            label: '>',
            enabled: currentPage < totalPages,
            onTap: () => onPageChanged(currentPage + 1),
          ),
        ],
      ),
    );
  }
}

class _PBtn extends StatelessWidget {
  const _PBtn({
    required this.label,
    this.isActive = false,
    this.enabled = true,
    required this.onTap,
  });
  final String label;
  final bool isActive;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive
                ? AppColors.primary
                : enabled
                    ? Colors.grey.shade300
                    : Colors.grey.shade200,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              color: isActive
                  ? Colors.white
                  : enabled
                      ? const Color(0xFF374151)
                      : Colors.grey.shade400,
            ),
          ),
        ),
      ),
    );
  }
}
