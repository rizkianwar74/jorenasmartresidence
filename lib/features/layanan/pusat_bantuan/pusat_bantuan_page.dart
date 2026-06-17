import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../data/layanan_repository.dart';

class PusatBantuanPage extends StatefulWidget {
  const PusatBantuanPage({super.key});

  @override
  State<PusatBantuanPage> createState() => _PusatBantuanPageState();
}

class _PusatBantuanPageState extends State<PusatBantuanPage> {
  _KontakItem? _kontakAdmin;
  _KontakItem? _kontakRt;
  bool _loading = true;
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
      final d = await LayananRepository.instance.fetchKontak();
      if (!mounted) return;
      if (d != null) {
        setState(() {
          _kontakAdmin = _KontakItem(
            nama  : (d['admin_nama']  as String?)?.trim().isNotEmpty == true
                        ? d['admin_nama'] as String
                        : 'Admin Kompleks',
            nomor : (d['admin_nomor'] as String?)?.trim() ?? '',
          );
          _kontakRt = _KontakItem(
            nama  : (d['rt_nama']  as String?)?.trim().isNotEmpty == true
                        ? d['rt_nama'] as String
                        : 'Ketua RT',
            nomor : (d['rt_nomor'] as String?)?.trim() ?? '',
          );
        });
      } else {
        debugPrint('[PusatBantuan] doc settings/kontak tidak ditemukan');
      }
    } catch (e) {
      debugPrint('[PusatBantuan] error: $e');
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────────────
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
                    Text(
                      'Pusat Bantuan',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Content ─────────────────────────────────────────────────
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : _error != null
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.wifi_off_rounded,
                                      size: 48, color: Colors.grey),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Gagal memuat kontak',
                                    style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textDark),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _error!,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: AppColors.textGrey),
                                  ),
                                  const SizedBox(height: 16),
                                  TextButton.icon(
                                    onPressed: _loadKontak,
                                    icon: const Icon(Icons.refresh_rounded,
                                        size: 18),
                                    label: const Text('Coba Lagi'),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : SingleChildScrollView(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Kontak Pengelola',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Hubungi pengelola kompleks melalui WhatsApp',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: AppColors.textGrey,
                                  ),
                                ),
                                const SizedBox(height: 14),

                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.04),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: _kontakAdmin == null &&
                                          _kontakRt == null
                                      ? Padding(
                                          padding: const EdgeInsets.all(24),
                                          child: Column(
                                            children: [
                                              const Icon(
                                                Icons.contact_phone_outlined,
                                                size: 40,
                                                color: Colors.grey,
                                              ),
                                              const SizedBox(height: 10),
                                              Text(
                                                'Data kontak belum diisi',
                                                style: GoogleFonts.inter(
                                                    fontSize: 13,
                                                    fontWeight:
                                                        FontWeight.w600,
                                                    color: AppColors.textDark),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Hubungi admin untuk mengisi\ndata kontak pengelola',
                                                textAlign: TextAlign.center,
                                                style: GoogleFonts.inter(
                                                    fontSize: 11,
                                                    color: AppColors.textGrey,
                                                    height: 1.5),
                                              ),
                                              const SizedBox(height: 12),
                                              TextButton.icon(
                                                onPressed: _loadKontak,
                                                icon: const Icon(
                                                    Icons.refresh_rounded,
                                                    size: 16),
                                                label: const Text('Refresh'),
                                              ),
                                            ],
                                          ),
                                        )
                                      : Column(
                                          children: [
                                            if (_kontakAdmin != null)
                                              _KontakTile(
                                                item   : _kontakAdmin!,
                                                label  : 'Admin',
                                                color  : AppColors.primary,
                                                isLast : _kontakRt == null,
                                              ),
                                            if (_kontakRt != null)
                                              _KontakTile(
                                                item   : _kontakRt!,
                                                label  : 'RT',
                                                color  : Colors.green.shade700,
                                                isLast : true,
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
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Model & Widget
// ─────────────────────────────────────────────────────────────────────────────

class _KontakItem {
  const _KontakItem({required this.nama, required this.nomor});
  final String nama;
  final String nomor;
}

class _KontakTile extends StatelessWidget {
  const _KontakTile({
    required this.item,
    required this.label,
    required this.color,
    required this.isLast,
  });

  final _KontakItem item;
  final String      label;
  final Color       color;
  final bool        isLast;

  String _toWaNumber(String nomor) {
    final digits = nomor.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('0'))  return '62${digits.substring(1)}';
    if (digits.startsWith('62')) return digits;
    return '62$digits';
  }

  Future<void> _openWhatsApp() async {
    final url = Uri.parse('https://wa.me/${_toWaNumber(item.nomor)}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  String get _initials {
    final parts = item.nama.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return parts[0].isNotEmpty ? parts[0][0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 44, height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.12),
                ),
                child: Text(
                  _initials,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Nama + badge + nomor
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            item.nama,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            label,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (item.nomor.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.nomor,
                        style: GoogleFonts.inter(
                            fontSize: 12, color: AppColors.textGrey),
                      ),
                    ],
                  ],
                ),
              ),

              // Tombol WhatsApp
              if (item.nomor.isNotEmpty)
                GestureDetector(
                  onTap: _openWhatsApp,
                  child: Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFF25D366).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.chat_rounded,
                      color: Color(0xFF25D366),
                      size: 20,
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
            height: 1, indent: 74, endIndent: 16,
            color: Colors.grey.shade100,
          ),
      ],
    );
  }
}
