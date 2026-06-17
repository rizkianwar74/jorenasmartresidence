import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_colors.dart';
import 'widgets/admin_sidebar.dart';
import 'widgets/admin_top_bar.dart';
import 'data/admin_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Model
// ─────────────────────────────────────────────────────────────────────────────

class _AdminWargaModel {
  _AdminWargaModel({
    required this.uid,
    required this.namaLengkap,
    required this.email,
    required this.blok,
    required this.nomorUnit,
    required this.nomorHp,
    this.komunitasRole,
  });

  final String uid;
  final String namaLengkap;
  final String email;
  final String blok;
  final String nomorUnit;
  final String nomorHp;
  final String? komunitasRole;

  String get unitLabel => '$blok - No. $nomorUnit';

  String get initials {
    final parts = namaLengkap.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return namaLengkap.isNotEmpty ? namaLengkap[0].toUpperCase() : '?';
  }

  factory _AdminWargaModel.fromFirestore(
      String uid, Map<String, dynamic> data) {
    return _AdminWargaModel(
      uid           : uid,
      namaLengkap   : data['namaLengkap']   as String? ?? '-',
      email         : data['email']          as String? ?? '-',
      blok          : data['blok']           as String? ?? '-',
      nomorUnit     : data['nomorUnit']      as String? ?? '-',
      nomorHp       : data['nomorHp']        as String? ?? '-',
      komunitasRole : data['komunitasRole']  as String?,
    );
  }
}

const _jabatanOptions = [
  '',
  'KETUA RT',
  'WAKIL KETUA RT',
  'SEKRETARIS RT',
  'BENDAHARA RT',
  'KETUA RW',
  'KOORDINATOR BLOK',
];

const _pageSize = 10;

// ─────────────────────────────────────────────────────────────────────────────
// Page
// ─────────────────────────────────────────────────────────────────────────────

class WargaUserPage extends StatefulWidget {
  const WargaUserPage({super.key});

  @override
  State<WargaUserPage> createState() => _WargaUserPageState();
}

class _WargaUserPageState extends State<WargaUserPage> {
  String _selectedBlok  = 'All Units';
  String _searchQuery   = '';
  int    _currentPage   = 1;
  bool   _loading       = true;

  List<_AdminWargaModel> _allWarga = [];
  StreamSubscription<QuerySnapshot>? _sub;

  // ── Derived ───────────────────────────────────────────────────────────────
  List<String> get _filterOptions {
    final bloks = _allWarga.map((w) => w.blok).toSet().toList()..sort();
    return ['All Units', ...bloks];
  }

  List<_AdminWargaModel> get _filtered {
    final q = _searchQuery.toLowerCase();
    return _allWarga.where((w) {
      final matchBlok = _selectedBlok == 'All Units' || w.blok == _selectedBlok;
      final matchSearch = q.isEmpty ||
          w.namaLengkap.toLowerCase().contains(q) ||
          w.nomorUnit.contains(q) ||
          w.nomorHp.contains(q) ||
          w.email.toLowerCase().contains(q);
      return matchBlok && matchSearch;
    }).toList();
  }

  List<_AdminWargaModel> get _paginated {
    final start = (_currentPage - 1) * _pageSize;
    final end   = (start + _pageSize).clamp(0, _filtered.length);
    if (start >= _filtered.length) return [];
    return _filtered.sublist(start, end);
  }

  int get _totalPages =>
      (_filtered.length / _pageSize).ceil().clamp(1, 9999);

  // ── Lifecycle ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _startListening();
  }

  void _startListening() {
    _sub = AdminRepository.instance.wargaSortedStream().listen((snap) {
      if (!mounted) return;
      setState(() {
        _allWarga = snap.docs
            .map((d) => _AdminWargaModel.fromFirestore(
                  d.id,
                  d.data(),
                ))
            .toList();
        _loading = false;
      });
    }, onError: (_) {
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  // ── Actions ───────────────────────────────────────────────────────────────
  Future<void> _editWarga(
    String uid,
    String blok,
    String nomorUnit,
    String? komunitasRole,
  ) async {
    final Map<String, dynamic> data = {
      'blok'     : blok.trim().toUpperCase(),
      'nomorUnit': nomorUnit.trim(),
    };
    if (komunitasRole == null || komunitasRole.isEmpty) {
      data['komunitasRole'] = FieldValue.delete();
    } else {
      data['komunitasRole'] = komunitasRole;
    }
    await AdminRepository.instance.updateWarga(uid, data);
  }

  Future<void> _hapusWarga(String uid) async {
    await AdminRepository.instance.deleteWarga(uid);
  }

  // ── Dialogs ───────────────────────────────────────────────────────────────
  void _showEditDialog(BuildContext context, _AdminWargaModel w) {
    final blokCtrl   = TextEditingController(text: w.blok);
    final nomorCtrl  = TextEditingController(text: w.nomorUnit);
    // Pastikan nilai ada di opsi; kalau tidak (data lama), fallback ke ''
    String? jabatan  = _jabatanOptions.contains(w.komunitasRole)
        ? w.komunitasRole
        : '';
    bool saving      = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edit Warga',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 2),
              Text(
                w.namaLengkap,
                style: GoogleFonts.inter(
                    fontSize: 13, color: AppColors.textGrey),
              ),
            ],
          ),
          content: SizedBox(
            width: 380,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Blok
                _DialogLabel('Blok'),
                const SizedBox(height: 6),
                TextField(
                  controller: blokCtrl,
                  style: GoogleFonts.inter(fontSize: 14),
                  textCapitalization: TextCapitalization.characters,
                  decoration: _inputDecoration('Contoh: Blok A'),
                ),
                const SizedBox(height: 16),

                // Nomor Unit
                _DialogLabel('Nomor Unit'),
                const SizedBox(height: 6),
                TextField(
                  controller: nomorCtrl,
                  style: GoogleFonts.inter(fontSize: 14),
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration('Contoh: 12'),
                ),
                const SizedBox(height: 16),

                // Jabatan
                _DialogLabel('Jabatan Komunitas'),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: jabatan ?? '',
                  style: GoogleFonts.inter(
                      fontSize: 14, color: AppColors.textDark),
                  decoration: _inputDecoration('Pilih jabatan'),
                  items: _jabatanOptions
                      .map((j) => DropdownMenuItem(
                            value: j,
                            child: Text(
                              j.isEmpty ? '— Tidak ada jabatan —' : j,
                              style: GoogleFonts.inter(fontSize: 13),
                            ),
                          ))
                      .toList(),
                  onChanged: (v) => setS(() => jabatan = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(ctx),
              child: Text('Batal',
                  style: GoogleFonts.inter(color: AppColors.textGrey)),
            ),
            ElevatedButton(
              onPressed: saving
                  ? null
                  : () async {
                      if (blokCtrl.text.trim().isEmpty ||
                          nomorCtrl.text.trim().isEmpty) return;
                      setS(() => saving = true);
                      try {
                        await _editWarga(
                          w.uid,
                          blokCtrl.text,
                          nomorCtrl.text,
                          jabatan,
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Data warga berhasil diperbarui')),
                          );
                        }
                      } catch (_) {
                        setS(() => saving = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Gagal menyimpan perubahan')),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text('Simpan',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showHapusDialog(BuildContext context, _AdminWargaModel w) {
    bool deleting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Anda yakin ingin menghapus data "${w.namaLengkap}"?\nTindakan ini tidak dapat dibatalkan.',
                style: GoogleFonts.inter(fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                ),
                child: Text(
                  '⚠️ Data profil akan dihapus dari sistem.',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: const Color(0xFFDC2626)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: deleting ? null : () => Navigator.pop(ctx),
              child: Text('Batal',
                  style: GoogleFonts.inter(color: AppColors.textGrey)),
            ),
            ElevatedButton(
              onPressed: deleting
                  ? null
                  : () async {
                      setS(() => deleting = true);
                      try {
                        await _hapusWarga(w.uid);
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    'Data ${w.namaLengkap} berhasil dihapus')),
                          );
                        }
                      } catch (_) {
                        setS(() => deleting = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Gagal menghapus data')),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: deleting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text('Hapus',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // ── Sidebar ──────────────────────────────────────────────────────
          const AdminSidebar(activePage: AdminPage.wargaUser),

          // ── Main content ─────────────────────────────────────────────────
          Expanded(
            child: Column(
              children: [
                AdminTopBar(
                  searchHint: 'Search residents, unit, or phone...',
                ),

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
                                    'Kelola data dan jabatan komunitas warga residence.',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: AppColors.textGrey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _MiniStatCard(
                              label: 'TOTAL WARGA',
                              value: _loading ? '...' : '${_allWarga.length}',
                            ),
                            const SizedBox(width: 12),
                            _MiniStatCard(
                              label: 'TAMPIL',
                              value: _loading ? '...' : '${_filtered.length}',
                              valueColor: AppColors.primary,
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // ── Search field ─────────────────────────────────
                        Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: TextField(
                            onChanged: (v) => setState(() {
                              _searchQuery  = v;
                              _currentPage  = 1;
                            }),
                            style: GoogleFonts.inter(
                                fontSize: 13, color: AppColors.textDark),
                            decoration: InputDecoration(
                              hintText:
                                  'Cari nama, nomor unit, HP, atau email...',
                              hintStyle: GoogleFonts.inter(
                                  fontSize: 13, color: AppColors.textGrey),
                              prefixIcon: const Icon(Icons.search,
                                  size: 18, color: AppColors.textGrey),
                              border: InputBorder.none,
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 13),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

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
                              // Filter bar
                              if (!_loading)
                                _FilterBar(
                                  options: _filterOptions,
                                  selected: _selectedBlok,
                                  onSelect: (blok) => setState(() {
                                    _selectedBlok = blok;
                                    _currentPage  = 1;
                                  }),
                                ),

                              // Table
                              if (_loading)
                                const Padding(
                                  padding: EdgeInsets.all(48),
                                  child: Center(
                                      child: CircularProgressIndicator()),
                                )
                              else
                                _WargaTable(
                                  wargaList: _paginated,
                                  onEdit  : (w) =>
                                      _showEditDialog(context, w),
                                  onHapus : (w) =>
                                      _showHapusDialog(context, w),
                                ),

                              // Pagination
                              if (!_loading)
                                _PaginationBar(
                                  currentPage : _currentPage,
                                  totalPages  : _totalPages,
                                  totalItems  : _filtered.length,
                                  pageSize    : _pageSize,
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
// Dialog helpers
// ─────────────────────────────────────────────────────────────────────────────

class _DialogLabel extends StatelessWidget {
  const _DialogLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textGrey),
    );
  }
}

InputDecoration _inputDecoration(String hint) {
  return InputDecoration(
    hintText: hint,
    hintStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.textGrey),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: AppColors.primary),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Stat card
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
// Filter bar
// ─────────────────────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  const _FilterBar(
      {required this.options,
      required this.selected,
      required this.onSelect});
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        children: [
          Text(
            'Filter:',
            style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textGrey),
          ),
          const SizedBox(width: 12),
          Wrap(
            spacing: 8,
            children: options.map((blok) {
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
                      color: isActive
                          ? Colors.white
                          : const Color(0xFF374151),
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
// Table
// ─────────────────────────────────────────────────────────────────────────────

class _WargaTable extends StatelessWidget {
  const _WargaTable({
    required this.wargaList,
    required this.onEdit,
    required this.onHapus,
  });
  final List<_AdminWargaModel> wargaList;
  final ValueChanged<_AdminWargaModel> onEdit;
  final ValueChanged<_AdminWargaModel> onHapus;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          color: const Color(0xFFF8FAFC),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Expanded(flex: 4, child: _th('Warga')),
              Expanded(flex: 2, child: _th('Unit')),
              Expanded(flex: 2, child: _th('No. HP')),
              Expanded(flex: 2, child: _th('Jabatan')),
              const SizedBox(width: 160, child: _ThWidget('Aksi')),
            ],
          ),
        ),

        // Rows
        if (wargaList.isEmpty)
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
          ...wargaList.map(
            (w) => _WargaRow(
              warga  : w,
              onEdit : () => onEdit(w),
              onHapus: () => onHapus(w),
            ),
          ),
      ],
    );
  }

  Widget _th(String text) => _ThWidget(text);
}

class _ThWidget extends StatelessWidget {
  const _ThWidget(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
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
// Single row
// ─────────────────────────────────────────────────────────────────────────────

class _WargaRow extends StatelessWidget {
  const _WargaRow({
    required this.warga,
    required this.onEdit,
    required this.onHapus,
  });
  final _AdminWargaModel warga;
  final VoidCallback onEdit;
  final VoidCallback onHapus;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          // ── Warga (avatar + nama + email) ──────────────────────────────
          Expanded(
            flex: 4,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                  child: Text(
                    warga.initials,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        warga.namaLengkap,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        warga.email,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textGrey,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Unit ───────────────────────────────────────────────────────
          Expanded(
            flex: 2,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                warga.unitLabel,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),

          // ── No. HP ─────────────────────────────────────────────────────
          Expanded(
            flex: 2,
            child: Text(
              warga.nomorHp,
              style: GoogleFonts.inter(
                  fontSize: 12, color: AppColors.textDark),
            ),
          ),

          // ── Jabatan ────────────────────────────────────────────────────
          Expanded(
            flex: 2,
            child: warga.komunitasRole != null
                ? Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      warga.komunitasRole!,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        letterSpacing: 0.3,
                      ),
                    ),
                  )
                : Text(
                    '—',
                    style: GoogleFonts.inter(
                        fontSize: 13, color: Colors.grey.shade400),
                  ),
          ),

          // ── Aksi ───────────────────────────────────────────────────────
          SizedBox(
            width: 160,
            child: Row(
              children: [
                OutlinedButton(
                  onPressed: onEdit,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade300),
                    foregroundColor: AppColors.textDark,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text('Edit',
                      style: GoogleFonts.inter(
                          fontSize: 12, fontWeight: FontWeight.w500)),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: onHapus,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFFCA5A5)),
                    foregroundColor: const Color(0xFFDC2626),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text('Hapus',
                      style: GoogleFonts.inter(
                          fontSize: 12, fontWeight: FontWeight.w500)),
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
    final start = totalItems == 0 ? 0 : ((currentPage - 1) * pageSize) + 1;
    final end   = (currentPage * pageSize).clamp(0, totalItems);

    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Text(
            'Menampilkan $start–$end dari $totalItems warga',
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textGrey),
          ),
          const Spacer(),
          _PageBtn(
            label: '<',
            enabled: currentPage > 1,
            onTap: () => onPageChanged(currentPage - 1),
          ),
          const SizedBox(width: 4),
          ..._buildPageNumbers(),
          const SizedBox(width: 4),
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
        label   : '$page',
        isActive: page == currentPage,
        onTap   : () => onPageChanged(page),
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
        child: Text('...',
            style: GoogleFonts.inter(
                fontSize: 13, color: AppColors.textGrey)),
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
    this.enabled  = true,
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
