import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import 'widgets/admin_sidebar.dart';
import 'widgets/admin_top_bar.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Mock data
// ─────────────────────────────────────────────────────────────────────────────

class _ResidentData {
  const _ResidentData({
    required this.nama,
    required this.email,
    required this.blok,
    required this.nomorUnit,
    required this.role,
    this.avatarUrl,
  });
  final String nama;
  final String email;
  final String blok;
  final String nomorUnit;
  final String role;
  final String? avatarUrl;

  String get unitLabel => '$blok - No. $nomorUnit';
}

const _allResidents = [
  _ResidentData(
    nama: 'Budi Sudarsono',
    email: 'budi.s@warga.res',
    blok: 'Blok A',
    nomorUnit: '12',
    role: 'Ketua RT',
    avatarUrl: 'https://i.pravatar.cc/150?u=budi',
  ),
  _ResidentData(
    nama: 'Siti Aminah',
    email: 'siti.a@warga.res',
    blok: 'Blok B',
    nomorUnit: '04',
    role: 'Warga',
  ),
  _ResidentData(
    nama: 'Agus Pratama',
    email: 'agus.p@warga.res',
    blok: 'Blok A',
    nomorUnit: '01',
    role: 'Ketua RW',
  ),
  _ResidentData(
    nama: 'Rian Wijaya',
    email: 'rian.w@warga.res',
    blok: 'Blok C',
    nomorUnit: '22',
    role: 'Warga',
  ),
  _ResidentData(
    nama: 'Lestari Putri',
    email: 'lestari.p@warga.res',
    blok: 'Blok A',
    nomorUnit: '15',
    role: 'Warga',
  ),
  _ResidentData(
    nama: 'Dimas Prayoga',
    email: 'dimas.p@warga.res',
    blok: 'Blok D',
    nomorUnit: '07',
    role: 'Warga',
  ),
  _ResidentData(
    nama: 'Ratna Dewi',
    email: 'ratna.d@warga.res',
    blok: 'Blok B',
    nomorUnit: '11',
    role: 'Warga',
  ),
  _ResidentData(
    nama: 'Hendra Kusuma',
    email: 'hendra.k@warga.res',
    blok: 'Blok E',
    nomorUnit: '03',
    role: 'Ketua RT',
  ),
];

const _filterBloks = ['All Units', 'Blok A', 'Blok B', 'Blok C', 'Blok D', 'Blok E'];
const _totalUnits = 124;
const _pageSize = 5;

// ─────────────────────────────────────────────────────────────────────────────
// Page
// ─────────────────────────────────────────────────────────────────────────────

class WargaUserPage extends StatefulWidget {
  const WargaUserPage({super.key});

  @override
  State<WargaUserPage> createState() => _WargaUserPageState();
}

class _WargaUserPageState extends State<WargaUserPage> {
  String _selectedBlok = 'All Units';
  int _currentPage = 1;

  List<_ResidentData> get _filtered {
    if (_selectedBlok == 'All Units') return _allResidents;
    return _allResidents
        .where((r) => r.blok == _selectedBlok)
        .toList();
  }

  List<_ResidentData> get _paginated {
    final start = (_currentPage - 1) * _pageSize;
    final end = (start + _pageSize).clamp(0, _filtered.length);
    if (start >= _filtered.length) return [];
    return _filtered.sublist(start, end);
  }

  int get _totalPages => (_filtered.length / _pageSize).ceil().clamp(1, 9999);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // ── Sidebar ────────────────────────────────────────────────────
          const AdminSidebar(activePage: AdminPage.wargaUser),

          // ── Main content ───────────────────────────────────────────────
          Expanded(
            child: Column(
              children: [
                // Top bar
                AdminTopBar(
                  searchHint: 'Search residents, unit, or phone...',
                  actionButton: AdminAddButton(
                    label: 'Tambah Data',
                    onPressed: () => _showTambahDialog(context),
                  ),
                ),

                // Body
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Header + stat cards ──────────────────────────
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Resident Directory',
                                    style: GoogleFonts.inter(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Manage Warga Residence community data and permissions.',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: AppColors.textGrey,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Stat cards
                            _MiniStatCard(
                              label: 'TOTAL UNITS',
                              value: '$_totalUnits',
                            ),
                            const SizedBox(width: 12),
                            const _MiniStatCard(
                              label: 'OCCUPANCY',
                              value: '92%',
                              valueColor: AppColors.primary,
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // ── Main table card ──────────────────────────────
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Filter chips
                              _FilterBar(
                                selected: _selectedBlok,
                                onSelect: (blok) => setState(() {
                                  _selectedBlok = blok;
                                  _currentPage = 1;
                                }),
                              ),

                              // Table
                              _ResidentTable(residents: _paginated),

                              // Pagination
                              _PaginationBar(
                                currentPage: _currentPage,
                                totalPages: _totalPages,
                                totalItems: _filtered.length,
                                pageSize: _pageSize,
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

  void _showTambahDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Tambah Warga Baru',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: Text(
          'Form tambah warga akan ditampilkan di sini.',
          style: GoogleFonts.inter(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Tutup',
                style: GoogleFonts.inter(color: AppColors.textGrey)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mini stat card (pojok kanan atas)
// ─────────────────────────────────────────────────────────────────────────────

class _MiniStatCard extends StatelessWidget {
  const _MiniStatCard({
    required this.label,
    required this.value,
    this.valueColor = AppColors.textDark,
  });
  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.textGrey,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Filter bar (chip blok)
// ─────────────────────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.selected, required this.onSelect});
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        children: [
          Text(
            'Filter by Block:',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textGrey,
            ),
          ),
          const SizedBox(width: 12),
          Wrap(
            spacing: 8,
            children: _filterBloks.map((blok) {
              final isActive = blok == selected;
              return GestureDetector(
                onTap: () => onSelect(blok),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isActive
                          ? AppColors.primary
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Text(
                    blok,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isActive ? Colors.white : const Color(0xFF374151),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Resident table
// ─────────────────────────────────────────────────────────────────────────────

class _ResidentTable extends StatelessWidget {
  const _ResidentTable({required this.residents});
  final List<_ResidentData> residents;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header row
        Container(
          color: const Color(0xFFF8FAFC),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: _tableHeader('Resident'),
              ),
              Expanded(
                flex: 2,
                child: _tableHeader('Unit Number'),
              ),
              Expanded(
                flex: 2,
                child: _tableHeader('Role'),
              ),
              SizedBox(
                width: 160,
                child: _tableHeader('Actions'),
              ),
            ],
          ),
        ),

        // Data rows
        if (residents.isEmpty)
          Padding(
            padding: const EdgeInsets.all(40),
            child: Center(
              child: Text(
                'Tidak ada data warga.',
                style: GoogleFonts.inter(
                    fontSize: 14, color: AppColors.textGrey),
              ),
            ),
          )
        else
          ...residents.map((r) => _ResidentRow(resident: r)).toList(),
      ],
    );
  }

  Widget _tableHeader(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.textGrey,
        letterSpacing: 0.4,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Single resident row
// ─────────────────────────────────────────────────────────────────────────────

class _ResidentRow extends StatelessWidget {
  const _ResidentRow({required this.resident});
  final _ResidentData resident;

  Color _roleColor(String role) {
    switch (role) {
      case 'Ketua RT':
      case 'Ketua RW':
        return AppColors.primary;
      default:
        return const Color(0xFF374151);
    }
  }

  Color _roleBgColor(String role) {
    switch (role) {
      case 'Ketua RT':
      case 'Ketua RW':
        return AppColors.primary.withOpacity(0.1);
      default:
        return Colors.grey.shade100;
    }
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          // ── Resident (avatar + nama + email) ────────────────────────
          Expanded(
            flex: 4,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary.withOpacity(0.12),
                  child: Text(
                    _initials(resident.nama),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      resident.nama,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      resident.email,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textGrey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Unit Number ──────────────────────────────────────────────
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                resident.unitLabel,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),

          // ── Role ────────────────────────────────────────────────────
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _roleBgColor(resident.role),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                resident.role,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _roleColor(resident.role),
                ),
              ),
            ),
          ),

          // ── Actions ─────────────────────────────────────────────────
          SizedBox(
            width: 160,
            child: Row(
              children: [
                OutlinedButton(
                  onPressed: () => _showEditDialog(context, resident),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade300),
                    foregroundColor: AppColors.textDark,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Edit',
                    style: GoogleFonts.inter(
                        fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => _showHapusDialog(context, resident),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFFCA5A5)),
                    foregroundColor: const Color(0xFFDC2626),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Hapus',
                    style: GoogleFonts.inter(
                        fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, _ResidentData r) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Edit Warga — ${r.nama}',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        content: Text(
          'Form edit warga akan ditampilkan di sini.',
          style: GoogleFonts.inter(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Tutup',
                style: GoogleFonts.inter(color: AppColors.textGrey)),
          ),
        ],
      ),
    );
  }

  void _showHapusDialog(BuildContext context, _ResidentData r) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: Color(0xFFDC2626), size: 22),
            const SizedBox(width: 8),
            Text(
              'Hapus Warga?',
              style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ],
        ),
        content: Text(
          'Anda yakin ingin menghapus data "${r.nama}"?\nTindakan ini tidak dapat dibatalkan.',
          style: GoogleFonts.inter(fontSize: 14, height: 1.5),
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
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Hapus',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pagination bar
// ─────────────────────────────────────────────────────────────────────────────

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.pageSize,
    required this.onPageChanged,
  });
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int pageSize;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    final start = ((currentPage - 1) * pageSize) + 1;
    final end = (currentPage * pageSize).clamp(0, totalItems);

    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Text(
            'Showing $start to $end of $totalItems residents',
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textGrey),
          ),
          const Spacer(),

          // < prev
          _PageBtn(
            label: '<',
            enabled: currentPage > 1,
            onTap: () => onPageChanged(currentPage - 1),
          ),

          const SizedBox(width: 4),

          // Pages: 1, 2, 3, ..., last
          ..._buildPageNumbers(),

          const SizedBox(width: 4),

          // > next
          _PageBtn(
            label: '>',
            enabled: currentPage < totalPages,
            onTap: () => onPageChanged(currentPage + 1),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPageNumbers() {
    final pages = <Widget>[];

    void addPage(int page) {
      pages.add(_PageBtn(
        label: '$page',
        isActive: page == currentPage,
        onTap: () => onPageChanged(page),
      ));
      pages.add(const SizedBox(width: 4));
    }

    if (totalPages <= 5) {
      for (int i = 1; i <= totalPages; i++) addPage(i);
    } else {
      addPage(1);
      addPage(2);
      addPage(3);
      pages.add(Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text('...', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textGrey)),
      ));
      pages.add(const SizedBox(width: 4));
      addPage(totalPages);
    }

    return pages;
  }
}

class _PageBtn extends StatelessWidget {
  const _PageBtn({
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
