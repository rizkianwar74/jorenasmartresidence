import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_colors.dart';
import '../widgets/admin_sidebar.dart';
import '../widgets/admin_top_bar.dart';
import '../data/admin_repository.dart';
import 'models/warga_model.dart';
import 'widgets/warga_shared_widgets.dart';
import 'widgets/warga_filter_bar.dart';
import 'widgets/warga_table.dart';
import 'widgets/warga_pagination_bar.dart';

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
  static const int _pageSize = 10;

  List<AdminWargaModel> _allWarga = [];
  StreamSubscription<QuerySnapshot>? _sub;

  // ── Derived ───────────────────────────────────────────────────────────────
  List<String> get _filterOptions {
    final bloks = _allWarga.map((w) => w.blok).toSet().toList()..sort();
    return ['All Units', ...bloks];
  }

  List<AdminWargaModel> get _filtered {
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

  List<AdminWargaModel> get _paginated {
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
            .map((d) => AdminWargaModel.fromFirestore(
                  d.id,
                  d.data() as Map<String, dynamic>,
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
  void _showEditDialog(BuildContext context, AdminWargaModel w) {
    final blokCtrl   = TextEditingController(text: w.blok);
    final nomorCtrl  = TextEditingController(text: w.nomorUnit);
    // Pastikan nilai ada di opsi; kalau tidak (data lama), fallback ke ''
    String? jabatan  = jabatanOptions.contains(w.komunitasRole)
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
                const DialogLabel('Blok'),
                const SizedBox(height: 6),
                TextField(
                  controller: blokCtrl,
                  style: GoogleFonts.inter(fontSize: 14),
                  textCapitalization: TextCapitalization.characters,
                  decoration: wargaInputDecoration('Contoh: Blok A'),
                ),
                const SizedBox(height: 16),

                const DialogLabel('Nomor Unit'),
                const SizedBox(height: 6),
                TextField(
                  controller: nomorCtrl,
                  style: GoogleFonts.inter(fontSize: 14),
                  keyboardType: TextInputType.number,
                  decoration: wargaInputDecoration('Contoh: 12'),
                ),
                const SizedBox(height: 16),

                const DialogLabel('Jabatan Komunitas'),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: jabatan ?? '',
                  style: GoogleFonts.inter(
                      fontSize: 14, color: AppColors.textDark),
                  decoration: wargaInputDecoration('Pilih jabatan'),
                  items: jabatanOptions
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

  void _showHapusDialog(BuildContext context, AdminWargaModel w) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          const AdminSidebar(activePage: AdminPage.wargaUser),
          Expanded(
            child: Column(
              children: [
                const AdminTopBar(
                  searchHint: 'Search residents, unit, or phone...',
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                            MiniStatCard(
                              label: 'TOTAL WARGA',
                              value: _loading ? '...' : '${_allWarga.length}',
                            ),
                            const SizedBox(width: 12),
                            MiniStatCard(
                              label: 'TAMPIL',
                              value: _loading ? '...' : '${_filtered.length}',
                              valueColor: AppColors.primary,
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

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

                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!_loading)
                                WargaFilterBar(
                                  options: _filterOptions,
                                  selected: _selectedBlok,
                                  onSelect: (blok) => setState(() {
                                    _selectedBlok = blok;
                                    _currentPage  = 1;
                                  }),
                                ),

                              if (_loading)
                                const Padding(
                                  padding: EdgeInsets.all(48),
                                  child: Center(
                                      child: CircularProgressIndicator()),
                                )
                              else
                                WargaTable(
                                  wargaList: _paginated,
                                  onEdit  : (w) =>
                                      _showEditDialog(context, w),
                                  onHapus : (w) =>
                                      _showHapusDialog(context, w),
                                ),

                              if (!_loading)
                                WargaPaginationBar(
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
