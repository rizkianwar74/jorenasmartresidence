import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/router/app_router.dart';
import '../../shared/widgets/bottom_nav_bar.dart';
import 'data/komunitas_repository.dart';
import 'models/warga_model.dart';
import 'widgets/blok_filter_chips.dart';
import 'widgets/warga_list_item.dart';

class KomunitasPage extends StatefulWidget {
  const KomunitasPage({super.key});

  @override
  State<KomunitasPage> createState() => _KomunitasPageState();
}

class _KomunitasPageState extends State<KomunitasPage> {
  static const double _contentMaxWidth = 600.0;

  String _selectedBlok = 'Semua';
  String _searchQuery  = '';

  List<WargaModel> _allWarga = [];
  bool _loading = true;
  StreamSubscription? _sub;

  // ── Filter chips dinamis dari data ────────────────────────────────────────
  List<String> get _filterOptions {
    final bloks = _allWarga.map((w) => w.blok).toSet().toList()..sort();
    return ['Semua', ...bloks];
  }

  // ── List setelah filter + search ──────────────────────────────────────────
  List<WargaModel> get _filteredList {
    return _allWarga.where((w) {
      final matchBlok   = _selectedBlok == 'Semua' || w.blok == _selectedBlok;
      final matchSearch = _searchQuery.isEmpty ||
          w.namaLengkap.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          w.nomorUnit.contains(_searchQuery);
      return matchBlok && matchSearch;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _startListening();
  }

  void _startListening() {
    _sub = KomunitasRepository.instance.wargaStream().listen((snap) {
      if (!mounted) return;
      setState(() {
        _allWarga = snap.docs
            .map((d) => WargaModel.fromFirestore(d.id, d.data()))
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

  // ── Modal detail warga ────────────────────────────────────────────────────
  void _showDetailModal(BuildContext context, WargaModel warga) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _WargaDetailSheet(warga: warga),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F7F8),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pushReplacementNamed(context, AppRouter.home),
          child: const Icon(Icons.arrow_back_ios_new, size: 20),
        ),
        title: Text(
          'Warga Residence',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
      ),
      body: Stack(
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
              child: Column(
                children: [
                  const SizedBox(height: 12),

                  // ── Search bar ─────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: TextField(
                        onChanged: (v) => setState(() => _searchQuery = v),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.textDark,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Cari warga atau nomor rumah...',
                          hintStyle: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.textGrey,
                          ),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: AppColors.textGrey,
                            size: 20,
                          ),
                          border: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Filter chips ───────────────────────────────────────────
                  if (!_loading)
                    BlokFilterChips(
                      options: _filterOptions,
                      selected: _selectedBlok,
                      onSelected: (v) => setState(() => _selectedBlok = v),
                    ),

                  const SizedBox(height: 16),

                  // ── List warga ─────────────────────────────────────────────
                  Expanded(child: _buildList()),
                ],
              ),
            ),
          ),

          // ── Bottom nav ─────────────────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: BottomNavBar(
              currentIndex: 2,
              contentMaxWidth: _contentMaxWidth,
            ),
          ),

          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 130,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_filteredList.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              'Tidak ada warga ditemukan',
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.textGrey),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 4, bottom: 120),
      itemCount: _filteredList.length,
      itemBuilder: (_, i) => WargaListItem(
        warga: _filteredList[i],
        onTap: () => _showDetailModal(context, _filteredList[i]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Modal Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _WargaDetailSheet extends StatefulWidget {
  const _WargaDetailSheet({required this.warga});
  final WargaModel warga;

  @override
  State<_WargaDetailSheet> createState() => _WargaDetailSheetState();
}

class _WargaDetailSheetState extends State<_WargaDetailSheet> {
  // Sama seperti WargaListItem — fallback ke inisial kalau gambar gagal load.
  bool _imageFailed = false;

  WargaModel get warga => widget.warga;

  Future<void> _openWhatsApp(BuildContext context) async {
    final uri = Uri.parse('https://wa.me/${warga.waNumber}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka WhatsApp')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 24),

          // Avatar + nama — avatarImageProvider sudah aware base64 & http URL
          Builder(builder: (_) {
            final provider = _imageFailed ? null : warga.avatarImageProvider;
            return CircleAvatar(
              radius: 36,
              backgroundColor: AppColors.primary.withValues(alpha: 0.15),
              backgroundImage: provider,
              onBackgroundImageError: provider != null
                  ? (_, __) {
                      if (mounted && !_imageFailed) {
                        setState(() => _imageFailed = true);
                      }
                    }
                  : null,
              child: provider == null
                  ? Text(
                      warga.namaLengkap.isNotEmpty
                          ? warga.namaLengkap[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
                      ),
                    )
                  : null,
            );
          }),
          const SizedBox(height: 12),

          Text(
            warga.namaLengkap,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
            textAlign: TextAlign.center,
          ),

          if (warga.komunitasRole != null) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                warga.komunitasRole!,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Info rows
          _InfoRow(
            icon: Icons.home_outlined,
            label: 'Alamat',
            value: warga.unitLabel,
          ),
          const SizedBox(height: 12),
          _InfoRow(
            icon: Icons.phone_outlined,
            label: 'No. HP',
            value: warga.nomorHp,
          ),
          const SizedBox(height: 12),
          _InfoRow(
            icon: Icons.email_outlined,
            label: 'Email',
            value: warga.email,
          ),

          const SizedBox(height: 28),

          // Tombol WhatsApp
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _openWhatsApp(context),
              icon: const Icon(Icons.chat, size: 20),
              label: Text(
                'Chat via WhatsApp',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366), // warna WhatsApp
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Info Row
// ─────────────────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textGrey,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
