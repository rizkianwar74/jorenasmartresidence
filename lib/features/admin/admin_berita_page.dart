import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_colors.dart';
import 'widgets/admin_sidebar.dart';
import 'widgets/admin_top_bar.dart';
import 'admin_berita_form_page.dart';
import 'data/admin_repository.dart';
import 'models/berita_doc.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Page
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
                            // ── Header ──────────────────────────────────
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    await showBeritaFormDialog(context);
                                    setState(() => _currentPage = 1);
                                  },
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

                            // ── Stat cards ───────────────────────────────
                            Row(
                              children: [
                                Expanded(
                                  child: _StatCard(
                                    label: 'Total Berita',
                                    value: '$total',
                                    icon: Icons.article_outlined,
                                    iconBg: const Color(0xFFEFF6FF),
                                    iconColor: const Color(0xFF1D4ED8),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _StatCard(
                                    label: 'Diterbitkan',
                                    value: '$published',
                                    icon: Icons.check_circle_outline,
                                    iconBg: const Color(0xFFF0FDF4),
                                    iconColor: const Color(0xFF16A34A),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _StatCard(
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
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    Border.all(color: Colors.grey.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
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

                                  // Header row
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

                                  // Data rows
                                  if (pageItems.isEmpty)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 40),
                                      child: Center(
                                        child: Text(
                                          'Belum ada berita.',
                                          style: GoogleFonts.inter(
                                              fontSize: 13,
                                              color: AppColors.textGrey),
                                        ),
                                      ),
                                    )
                                  else
                                    ...pageItems.map((item) =>
                                        _BeritaRow(
                                          item: item,
                                          onDeleted: () =>
                                              setState(() {}),
                                        )),

                                  // Pagination
                                  _PaginationBar(
                                    currentPage: page,
                                    totalItems: total,
                                    perPage: _perPage,
                                    onPageChanged: (p) =>
                                        setState(() => _currentPage = p),
                                  ),
                                ],
                              ),
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
              Text(label,
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textGrey,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text(value,
                  style: GoogleFonts.inter(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                      height: 1)),
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
    return Text(text,
        style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.textGrey,
            letterSpacing: 0.5));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Berita row
// ─────────────────────────────────────────────────────────────────────────────

class _BeritaRow extends StatefulWidget {
  const _BeritaRow({required this.item, required this.onDeleted});
  final BeritaDoc item;
  final VoidCallback onDeleted;

  @override
  State<_BeritaRow> createState() => _BeritaRowState();
}

class _BeritaRowState extends State<_BeritaRow> {
  bool _hovered = false;

  Color _kategoriColor(String k) {
    switch (k.toLowerCase()) {
      case 'keamanan':   return const Color(0xFF1D4ED8);
      case 'lingkungan': return const Color(0xFF15803D);
      case 'fasilitas':  return const Color(0xFF0369A1);
      case 'agenda':     return const Color(0xFF6B21A8);
      default:           return const Color(0xFF64748B);
    }
  }

  Color _kategoriBg(String k) {
    switch (k.toLowerCase()) {
      case 'keamanan':   return const Color(0xFFEFF6FF);
      case 'lingkungan': return const Color(0xFFF0FDF4);
      case 'fasilitas':  return const Color(0xFFE0F2FE);
      case 'agenda':     return const Color(0xFFF5F3FF);
      default:           return const Color(0xFFF1F5F9);
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('Hapus Berita?',
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Text(
          'Apakah Anda yakin ingin menghapus "${widget.item.judul}"?',
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textGrey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal',
                style: GoogleFonts.inter(color: AppColors.textGrey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade500,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child:
                Text('Hapus', style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AdminRepository.instance.deleteBerita(widget.item.id);
      widget.onDeleted();
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: Container(
        decoration: BoxDecoration(
          color: _hovered
              ? AppColors.primary.withValues(alpha: 0.03)
              : Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade100)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            // Judul + thumbnail
            Expanded(
              flex: 4,
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: _buildThumbnail(item),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.judul,
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textDark,
                          height: 1.4),
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
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _kategoriBg(item.kategori),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item.kategoriLabel.toUpperCase(),
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _kategoriColor(item.kategori),
                        letterSpacing: 0.3),
                  ),
                ),
              ),
            ),

            // Tanggal
            Expanded(
              flex: 2,
              child: Text(item.tanggalFormatted,
                  style: GoogleFonts.inter(
                      fontSize: 12, color: AppColors.textGrey)),
            ),

            // Status
            Expanded(flex: 2, child: _StatusBadge(item.isPublished)),

            // Aksi
            SizedBox(
              width: 60,
              child: Row(
                children: [
                  _AksiBtn(
                    icon: Icons.edit_outlined,
                    color: AppColors.primary,
                    onTap: () => showBeritaFormDialog(
                      context,
                      editDoc: widget.item,
                    ),
                  ),
                  const SizedBox(width: 6),
                  _AksiBtn(
                    icon: Icons.delete_outline,
                    color: Colors.red.shade400,
                    onTap: _delete,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail(BeritaDoc item) {
    if (item.imageUrl.isEmpty) return _thumbPlaceholder(item.kategori);

    // Base64 data URL — simpan langsung di Firestore
    if (item.imageUrl.startsWith('data:')) {
      try {
        final base64Str = item.imageUrl.split(',').last;
        final bytes = base64Decode(base64Str);
        return Image.memory(bytes,
            width: 46, height: 36, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _thumbPlaceholder(item.kategori));
      } catch (_) {
        return _thumbPlaceholder(item.kategori);
      }
    }

    // URL biasa (http/https)
    return Image.network(
      item.imageUrl,
      width: 46,
      height: 36,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _thumbPlaceholder(item.kategori),
    );
  }

  Widget _thumbPlaceholder(String kategori) {
    return Container(
      width: 46,
      height: 36,
      color: _kategoriColor(kategori).withValues(alpha: 0.15),
      child: Icon(Icons.article_outlined,
          size: 18, color: _kategoriColor(kategori)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Status badge
// ─────────────────────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge(this.isPublished);
  final bool isPublished;

  @override
  Widget build(BuildContext context) {
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

// ─────────────────────────────────────────────────────────────────────────────
// Aksi button
// ─────────────────────────────────────────────────────────────────────────────

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
          color: color.withValues(alpha: 0.08),
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
    required this.perPage,
    required this.onPageChanged,
  });
  final int currentPage;
  final int totalItems;
  final int perPage;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    final totalPages = (totalItems / perPage).ceil().clamp(1, 9999);
    final start      = (currentPage - 1) * perPage + 1;
    final end        = (currentPage * perPage).clamp(0, totalItems);

    return Container(
      decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey.shade100))),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Text(
            totalItems == 0
                ? 'Tidak ada berita'
                : 'Menampilkan $start–$end dari $totalItems berita',
            style: GoogleFonts.inter(
                fontSize: 12, color: AppColors.textGrey),
          ),
          const Spacer(),
          _PageBtn(
            icon: Icons.chevron_left,
            enabled: currentPage > 1,
            onTap: () => onPageChanged(currentPage - 1),
          ),
          const SizedBox(width: 8),
          Text('$currentPage / $totalPages',
              style: GoogleFonts.inter(
                  fontSize: 12, color: AppColors.textDark)),
          const SizedBox(width: 8),
          _PageBtn(
            icon: Icons.chevron_right,
            enabled: currentPage < totalPages,
            onTap: () => onPageChanged(currentPage + 1),
          ),
        ],
      ),
    );
  }
}

class _PageBtn extends StatelessWidget {
  const _PageBtn(
      {required this.icon, required this.enabled, required this.onTap});
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: enabled
              ? Colors.white
              : Colors.grey.shade100,
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon,
            size: 18,
            color: enabled
                ? AppColors.textDark
                : Colors.grey.shade400),
      ),
    );
  }
}
