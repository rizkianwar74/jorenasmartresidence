import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_colors.dart';
import '../widgets/admin_sidebar.dart';
import '../widgets/admin_top_bar.dart';
import '../data/admin_repository.dart';
import '../../berita/models/berita_doc.dart';
import 'admin_berita_form_page.dart';
import 'widgets/berita_shared_widgets.dart';
import 'widgets/berita_row.dart';
import 'widgets/berita_pagination_bar.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Halaman Manajemen Berita — daftar + statistik + pagination.
//
// Widget-widget pendukung (kartu stat, baris tabel, badge status, tombol
// aksi, pagination) dipecah ke folder widgets/ agar file ini tetap ringkas.
// ─────────────────────────────────────────────────────────────────────────────

class AdminBeritaPage extends StatefulWidget {
  const AdminBeritaPage({super.key});

  @override
  State<AdminBeritaPage> createState() => _AdminBeritaPageState();
}

class _AdminBeritaPageState extends State<AdminBeritaPage> {
  static const _perPage = 10;
  int _currentPage = 1;

  final _repo = AdminRepository.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          const AdminSidebar(activePage: AdminPage.berita),
          Expanded(
            child: Column(
              children: [
                AdminTopBar(searchHint: 'Cari berita...'),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _repo.beritaStream(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Text('Error: ${snapshot.error}',
                              style: GoogleFonts.inter(color: Colors.red)),
                        );
                      }

                      final docs = (snapshot.data?.docs ?? [])
                          .map((d) => BeritaDoc.fromDoc(d))
                          .toList()
                        ..sort((a, b) {
                          if (a.publishedAt == null && b.publishedAt == null) return 0;
                          if (a.publishedAt == null) return 1;
                          if (b.publishedAt == null) return -1;
                          return b.publishedAt!.compareTo(a.publishedAt!);
                        });

                      final total      = docs.length;
                      final published  = docs.where((d) => d.isPublished).length;
                      final draft      = docs.where((d) => !d.isPublished).length;
                      final totalPages = (total / _perPage).ceil().clamp(1, 9999);
                      final page       = _currentPage.clamp(1, totalPages);
                      final start      = (page - 1) * _perPage;
                      final end        = (start + _perPage).clamp(0, total);
                      final pageItems  = docs.sublist(start, end);

                      return SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(28, 24, 28, 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Header(onCreated: () => setState(() => _currentPage = 1)),

                            const SizedBox(height: 24),

                            // ── Stat cards ───────────────────────────────
                            Row(
                              children: [
                                Expanded(
                                  child: BeritaStatCard(
                                    label: 'Total Berita',
                                    value: '$total',
                                    icon: Icons.article_outlined,
                                    iconBg: const Color(0xFFEFF6FF),
                                    iconColor: const Color(0xFF1D4ED8),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: BeritaStatCard(
                                    label: 'Diterbitkan',
                                    value: '$published',
                                    icon: Icons.check_circle_outline,
                                    iconBg: const Color(0xFFF0FDF4),
                                    iconColor: const Color(0xFF16A34A),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: BeritaStatCard(
                                    label: 'Draf',
                                    value: '$draft',
                                    icon: Icons.edit_note_outlined,
                                    iconBg: const Color(0xFFFFF7ED),
                                    iconColor: const Color(0xFFF97316),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // ── Table ────────────────────────────────────
                            _BeritaTableCard(
                              pageItems : pageItems,
                              page      : page,
                              total     : total,
                              perPage   : _perPage,
                              onPageChanged: (p) => setState(() => _currentPage = p),
                              onRowDeleted : () => setState(() {}),
                            ),
                          ],
                        ),
                      );
                    },
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
// Header halaman: judul + tombol "Tambah Berita Baru"
// ─────────────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.onCreated});
  final VoidCallback onCreated;

  @override
  Widget build(BuildContext context) {
    return Row(
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
                    fontSize: 13, color: AppColors.textGrey),
              ),
            ],
          ),
        ),
        ElevatedButton.icon(
          onPressed: () async {
            await showBeritaFormDialog(context);
            onCreated();
          },
          icon: const Icon(Icons.add, size: 18, color: Colors.white),
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
            minimumSize: Size.zero,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Kartu tabel: header kolom (adaptif) + baris + pagination
// ─────────────────────────────────────────────────────────────────────────────

class _BeritaTableCard extends StatelessWidget {
  const _BeritaTableCard({
    required this.pageItems,
    required this.page,
    required this.total,
    required this.perPage,
    required this.onPageChanged,
    required this.onRowDeleted,
  });
  final List<BeritaDoc> pageItems;
  final int page;
  final int total;
  final int perPage;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onRowDeleted;

  @override
  Widget build(BuildContext context) {
    // LayoutBuilder supaya tabel bisa menyesuaikan diri di lebar tablet:
    // kolom TANGGAL disembunyikan dan kolom STATUS diberi ruang lebih saat
    // layar sempit, supaya tidak overflow.
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 640;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
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

              // Header row
              Container(
                color: const Color(0xFFF8FAFC),
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10),
                child: Row(
                  children: [
                    const Expanded(flex: 4, child: BeritaColHeader('JUDUL BERITA')),
                    const Expanded(flex: 2, child: BeritaColHeader('KATEGORI')),
                    if (!isCompact)
                      const Expanded(flex: 2, child: BeritaColHeader('TANGGAL')),
                    Expanded(
                        flex: isCompact ? 3 : 2,
                        child: const BeritaColHeader('STATUS')),
                    const SizedBox(width: 70, child: BeritaColHeader('AKSI')),
                  ],
                ),
              ),

              // Data rows
              if (pageItems.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text(
                      'Belum ada berita.',
                      style: GoogleFonts.inter(
                          fontSize: 13, color: AppColors.textGrey),
                    ),
                  ),
                )
              else
                ...pageItems.map((item) => BeritaRow(
                      item: item,
                      isCompact: isCompact,
                      onDeleted: onRowDeleted,
                    )),

              // Pagination
              BeritaPaginationBar(
                currentPage: page,
                totalItems: total,
                perPage: perPage,
                onPageChanged: onPageChanged,
              ),
            ],
          ),
        );
      },
    );
  }
}
