import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive_helper.dart';
import '../../../core/data/keluhan_repository.dart';
import '../../auth/data/auth_repository.dart';
import 'lapor_keluhan_page.dart';
import 'widgets/keluhan_shared_widgets.dart';
import 'widgets/riwayat_card.dart';
import 'widgets/riwayat_detail_sheet.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Halaman Riwayat Laporan — daftar keluhan warga + bottom sheet detail.
//
// Widget pendukung (empty state, banner, kartu riwayat, bottom sheet detail)
// dipecah ke widgets/ agar file ini fokus pada state management saja.
// ─────────────────────────────────────────────────────────────────────────────

class RiwayatKeluhanPage extends StatefulWidget {
  const RiwayatKeluhanPage({super.key});

  @override
  State<RiwayatKeluhanPage> createState() => _RiwayatKeluhanPageState();
}

class _RiwayatKeluhanPageState extends State<RiwayatKeluhanPage> {
  StreamSubscription<List<KeluhanItem>>? _sub;
  List<KeluhanItem> _items = [];
  bool _loading = true;

  static const double _contentMaxWidth = 600.0;

  @override
  void initState() {
    super.initState();
    final uid = AuthRepository.currentUid;
    if (uid == null) {
      setState(() => _loading = false);
      return;
    }
    _sub = KeluhanRepository.watchMyKeluhan(uid).listen(
      (list) {
        if (mounted) setState(() { _items = list; _loading = false; });
      },
      onError: (_) { if (mounted) setState(() => _loading = false); },
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hPad = Responsive.value<double>(context, mobile: 24, tablet: 32);

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
          'Riwayat Laporan',
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
          constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(strokeWidth: 2))
              : _items.isEmpty
                  ? KeluhanEmptyState(
                      onBuatLaporan: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const LaporKeluhanPage()),
                      ),
                    )
                  : ListView.separated(
                      padding:
                          EdgeInsets.fromLTRB(hPad, 16, hPad, 32),
                      itemCount: _items.length + 1, // +1 untuk banner bawah
                      separatorBuilder: (_, i) =>
                          i < _items.length - 1
                              ? const SizedBox(height: 12)
                              : const SizedBox.shrink(),
                      itemBuilder: (_, i) {
                        if (i < _items.length) {
                          return KeluhanRiwayatCard(
                            item: _items[i],
                            onDetailTap: () => _showDetail(_items[i]),
                          );
                        }
                        // Banner buat laporan baru
                        return Padding(
                          padding: const EdgeInsets.only(top: 20),
                          child: BuatLaporanBanner(
                            onTap: () => Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const LaporKeluhanPage()),
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ),
    );
  }

  void _showDetail(KeluhanItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RiwayatDetailSheet(item: item),
    );
  }
}
