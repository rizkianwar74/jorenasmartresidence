// lib/features/layanan/pusat_bantuan/pusat_bantuan_page.dart
//
// Halaman Darurat — menampilkan card kontak Ketua RT dan Ketua STM.
// Data diambil dari koleksi `users` berdasarkan field `komunitasRole`.
// Admin dapat mengubah jabatan warga melalui halaman Admin → Kelola Warga.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../data/layanan_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Model
// ─────────────────────────────────────────────────────────────────────────────

class _KontakModel {
  const _KontakModel({
    required this.role,
    required this.nama,
    required this.nomor,
    required this.alamat,
    required this.accentColor,
    required this.icon,
  });
  final String   role;
  final String   nama;
  final String   nomor;
  final String   alamat;
  final Color    accentColor;
  final IconData icon;
}

// ─────────────────────────────────────────────────────────────────────────────
// Page
// ─────────────────────────────────────────────────────────────────────────────

class PusatBantuanPage extends StatefulWidget {
  const PusatBantuanPage({super.key});

  @override
  State<PusatBantuanPage> createState() => _PusatBantuanPageState();
}

class _PusatBantuanPageState extends State<PusatBantuanPage> {
  List<_KontakModel> _kontak = [];
  bool    _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadKontak();
  }

  Future<void> _loadKontak() async {
    if (!mounted) return;
    setState(() { _loading = true; _error = null; });
    try {
      final docs = await LayananRepository.instance.fetchKontakDarurat();
      if (!mounted) return;

      final list = docs.map((data) {
        final role  = (data['komunitasRole'] as String? ?? '').trim();
        final nama  = (data['namaLengkap']   as String? ?? '').trim();
        final nomor = (data['nomorHp']        as String? ?? '').trim();
        final blok  = (data['blok']           as String? ?? '').trim();
        final unit  = (data['nomorUnit']      as String? ?? '').trim();

        // Gabung blok + unit sebagai "tempat tinggal"
        final alamat = [
          if (blok.isNotEmpty) 'Blok $blok',
          if (unit.isNotEmpty) 'No. $unit',
        ].join(', ');

        final isRT = role == 'KETUA RT';
        return _KontakModel(
          role       : isRT ? 'Ketua RT' : 'Ketua STM',
          nama       : nama.isNotEmpty ? nama : (isRT ? 'Ketua RT' : 'Ketua STM'),
          nomor      : nomor,
          alamat     : alamat,
          accentColor: isRT ? AppColors.primary : const Color(0xFF16A34A),
          icon       : isRT ? Icons.home_work_outlined : Icons.groups_outlined,
        );
      }).toList();

      setState(() => _kontak = list);
    } catch (e) {
      debugPrint('[PusatBantuan] error: $e');
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Custom AppBar ─────────────────────────────────────────────
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 20,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      'Darurat',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Body ──────────────────────────────────────────────────────
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              Text(
                'Gagal memuat kontak',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 11, color: AppColors.textGrey),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: _loadKontak,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ───────────────────────────────────────────────────
              Text(
                'Kontak Darurat',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Hubungi pengelola kompleks langsung melalui WhatsApp',
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.textGrey),
              ),
              const SizedBox(height: 16),

              // ── Warning banner ────────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3CD),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFFFC107).withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: Color(0xFFD97706), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Untuk keadaan darurat, segera hubungi salah satu kontak di bawah ini.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF92400E),
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Contact cards ─────────────────────────────────────────────
              if (_kontak.isEmpty)
                _EmptyState(onRetry: _loadKontak)
              else
                ...List.generate(_kontak.length, (i) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _KontakCard(kontak: _kontak[i]),
                )),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Contact card
// ─────────────────────────────────────────────────────────────────────────────

class _KontakCard extends StatelessWidget {
  const _KontakCard({required this.kontak});
  final _KontakModel kontak;

  String get _initials {
    final parts = kontak.nama.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return parts[0].isNotEmpty ? parts[0][0].toUpperCase() : '?';
  }

  String _toWaNumber(String nomor) {
    final digits = nomor.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('0'))  return '62${digits.substring(1)}';
    if (digits.startsWith('62')) return digits;
    return '62$digits';
  }

  Future<void> _openWhatsApp(BuildContext context) async {
    if (kontak.nomor.isEmpty) return;
    final url = Uri.parse('https://wa.me/${_toWaNumber(kontak.nomor)}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
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
    final color = kontak.accentColor;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Colored header strip ────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              border: Border(
                bottom: BorderSide(color: color.withValues(alpha: 0.12)),
              ),
            ),
            child: Row(
              children: [
                Icon(kontak.icon, size: 15, color: color),
                const SizedBox(width: 6),
                Text(
                  kontak.role,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: color,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),

          // ── Card body ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar + nama
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color.withValues(alpha: 0.12),
                        border: Border.all(
                          color: color.withValues(alpha: 0.25),
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        _initials,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        kontak.nama,
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Divider(height: 1, color: Colors.grey.shade100),
                const SizedBox(height: 12),

                // Tempat tinggal
                if (kontak.alamat.isNotEmpty) ...[
                  _InfoRow(
                    icon : Icons.home_outlined,
                    color: color,
                    text : kontak.alamat,
                  ),
                  const SizedBox(height: 8),
                ],

                // Nomor HP
                _InfoRow(
                  icon : Icons.phone_outlined,
                  color: kontak.nomor.isNotEmpty ? color : Colors.grey,
                  text : kontak.nomor.isNotEmpty ? kontak.nomor : 'Nomor belum diisi',
                ),

                const SizedBox(height: 16),

                // WhatsApp button
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: kontak.nomor.isNotEmpty
                        ? () => _openWhatsApp(context)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      disabledBackgroundColor: Colors.grey.shade200,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.chat_rounded, size: 18),
                    label: Text(
                      'Chat via WhatsApp',
                      style: GoogleFonts.inter(
                          fontSize: 14, fontWeight: FontWeight.bold),
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
// Info row
// ─────────────────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.color,
    required this.text,
  });
  final IconData icon;
  final Color    color;
  final String   text;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 16, color: color),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.textDark,
            height: 1.4,
          ),
        ),
      ),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(32),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      children: [
        const Icon(Icons.contact_phone_outlined, size: 48, color: Colors.grey),
        const SizedBox(height: 12),
        Text(
          'Data kontak belum diisi',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Admin perlu menetapkan jabatan Ketua RT dan Ketua STM\nmelalui halaman Kelola Warga.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.textGrey,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded, size: 16),
          label: const Text('Refresh'),
        ),
      ],
    ),
  );
}
