import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../security/data/security_repository.dart';
import 'models/satpam_insiden_model.dart';
import 'widgets/satpam_insiden_shared_widgets.dart';
import 'widgets/satpam_insiden_card.dart';
import 'widgets/satpam_insiden_detail_sheet.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Halaman Daftar Insiden (Satpam) — daftar + filter status + detail sheet.
//
// Model (SatpamInsidenItem) dan widget pendukung (kartu, info section,
// detail sheet, empty state) dipecah ke models/ dan widgets/ agar file ini
// fokus pada state management saja.
// ─────────────────────────────────────────────────────────────────────────────

class SatpamInsidenPage extends StatefulWidget {
  const SatpamInsidenPage({super.key});

  @override
  State<SatpamInsidenPage> createState() => _SatpamInsidenPageState();
}

class _SatpamInsidenPageState extends State<SatpamInsidenPage> {
  StreamSubscription<QuerySnapshot>? _sub;
  List<SatpamInsidenItem> _all  = [];
  bool _loading                 = true;
  String _filterStatus          = 'Semua';

  List<SatpamInsidenItem> get _filtered => _filterStatus == 'Semua'
      ? _all
      : _all.where((i) => i.status == _filterStatus).toList();

  @override
  void initState() {
    super.initState();
    _sub = SecurityRepository.instance.insidenStream().listen(
      (snap) {
        if (!mounted) return;
        setState(() {
          _all = snap.docs.map(SatpamInsidenItem.fromDoc).toList();
          _loading = false;
        });
      },
      onError: (_) {
        if (mounted) setState(() => _loading = false);
      },
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  // ── Update status dengan bottom sheet konfirmasi ──────────────────────────
  Future<void> _updateStatus(SatpamInsidenItem item, String newStatus) async {
    HapticFeedback.mediumImpact();
    try {
      await SecurityRepository.instance.updateInsidenStatus(item.id, newStatus);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal update: $e')),
      );
    }
  }

  void _showDetail(SatpamInsidenItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SatpamInsidenDetailSheet(
        item: item,
        onUpdateStatus: _updateStatus,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6F9),
        body: SafeArea(
          child: Column(
            children: [
              // ── Top Bar ───────────────────────────────────────────────────
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 14),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          size: 20, color: Color(0xFF0D1B2A)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'Daftar Insiden',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                    // Badge total
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_filtered.length}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFD32F2F),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Filter chips ─────────────────────────────────────────────
              Container(
                color: Colors.white,
                padding:
                    const EdgeInsets.only(left: 16, right: 16, bottom: 12),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: satpamInsidenStatusOptions.map((s) {
                      final active = _filterStatus == s;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _filterStatus = s),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: active
                                  ? AppColors.primary
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              s == 'Semua'
                                  ? 'Semua (${_all.length})'
                                  : _chipLabel(s),
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: active
                                    ? Colors.white
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              // ── List ─────────────────────────────────────────────────────
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : _filtered.isEmpty
                        ? SatpamInsidenEmptyState(filterStatus: _filterStatus)
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                            itemCount: _filtered.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (_, i) => SatpamInsidenCard(
                              item: _filtered[i],
                              onTap: () => _showDetail(_filtered[i]),
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _chipLabel(String status) {
    final count =
        _all.where((i) => i.status == status).length;
    return '$status ($count)';
  }
}
