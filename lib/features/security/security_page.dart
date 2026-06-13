import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/sos_service.dart';
import 'bantuan/bantuan_satpam_page.dart';
import 'sos_status_page.dart';
import 'widgets/sos_button.dart';

class SecurityPage extends StatefulWidget {
  const SecurityPage({super.key});

  @override
  State<SecurityPage> createState() => _SecurityPageState();
}

// ── Model sederhana untuk satpam bertugas ────────────────────────────────────
class _SatpamInfo {
  final String namaLengkap;
  final String nomorHp;
  _SatpamInfo({required this.namaLengkap, required this.nomorHp});
}

class _SecurityPageState extends State<SecurityPage> {
  bool _isLoading = false;
  List<_SatpamInfo>? _satpamList;
  bool _satpamLoading = true;
  StreamSubscription<QuerySnapshot>? _satpamSub;

  static const double _contentMaxWidth = 600.0;

  @override
  void initState() {
    super.initState();
    _loadSatpam();
  }

  // ── Format Timestamp Firestore → string relatif ─────────────────────────
  static String _formatTs(dynamic ts) {
    if (ts == null) return '';
    DateTime dt;
    if (ts is Timestamp) {
      dt = ts.toDate();
    } else {
      return '';
    }
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1)  return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} mnt lalu';
    if (diff.inHours < 24)   return '${diff.inHours} jam lalu';
    if (diff.inDays == 1)    return 'Kemarin';
    return '${diff.inDays} hari lalu';
  }

  void _loadSatpam() {
    _satpamSub = FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'satpam')
        .where('isOnDuty', isEqualTo: true)
        .snapshots()
        .listen(
          (snap) {
            final list = snap.docs.map((d) {
              final data = d.data() as Map<String, dynamic>;
              return _SatpamInfo(
                namaLengkap: (data['namaLengkap'] as String?)?.trim() ?? 'Satpam',
                nomorHp    : (data['nomorHp']     as String?)?.trim() ?? '-',
              );
            }).toList();
            if (mounted) setState(() { _satpamList = list; _satpamLoading = false; });
          },
          onError: (e) {
            debugPrint('[SatpamStream] error: $e');
            if (mounted) setState(() { _satpamList = []; _satpamLoading = false; });
          },
        );
  }

  @override
  void dispose() {
    _satpamSub?.cancel();
    super.dispose();
  }

  Future<void> _onSosActivated() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    final alert = await SosService.sendSos();
    setState(() => _isLoading = false);

    if (!mounted) return;

    if (alert != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SosStatusPage(
            alertId: alert.id,
            type: SosType.sos,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengirim SOS. Coba lagi.',
              style: GoogleFonts.inter(fontSize: 13)),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
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
        backgroundColor: AppColors.background,
        body: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: MediaQuery.of(context).padding.top),

                  // ── App Bar ──────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 16),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new,
                              size: 16,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'Keamanan',
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── SOS Section ──────────────────────────────────────
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Butuh Bantuan Segera?',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tahan tombol SOS selama 3 detik\nuntuk memanggil satpam.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.textGrey,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // SOS Button (hold 3 detik)
                        SosButton(
                          onActivated: _isLoading ? null : _onSosActivated,
                        ),

                        const SizedBox(height: 24),

                        // Tombol Minta Bantuan (non-emergency)
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const BantuanSatpamPage(),
                            ),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.support_agent_outlined,
                                    size: 18, color: AppColors.primary),
                                const SizedBox(width: 8),
                                Text(
                                  'Minta Bantuan',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── Satpam Bertugas ──────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Text(
                          'Satpam Bertugas',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (!_satpamLoading && (_satpamList?.isNotEmpty ?? false))
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${_satpamList!.length} orang',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  if (_satpamLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  else if (_satpamList == null || _satpamList!.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 8),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            vertical: 20, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          'Tidak ada data satpam',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.textGrey,
                          ),
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      height: 140,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: _satpamList!.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(width: 12),
                        itemBuilder: (context, i) {
                          final s = _satpamList![i];
                          return _SatpamCard(satpam: s);
                        },
                      ),
                    ),

                  const SizedBox(height: 28),

                  // ── Aktivitas Keamanan (realtime dari Firestore) ─────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'Aktivitas Keamanan',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('patroli')
                        .orderBy('createdAt', descending: true)
                        .limit(10)
                        .snapshots(),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                              child: CircularProgressIndicator(strokeWidth: 2)),
                        );
                      }
                      final docs = snap.data?.docs ?? [];
                      if (docs.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 8),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                vertical: 24, horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              'Belum ada aktivitas keamanan',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: AppColors.textGrey,
                              ),
                            ),
                          ),
                        );
                      }
                      return Column(
                        children: docs.map((doc) {
                          final d      = doc.data() as Map<String, dynamic>;
                          final status = d['status'] as String? ?? '';
                          final blok   = d['blokPatroli'] as String? ?? '-';
                          final nama   = d['namaSatpam']  as String? ?? 'Satpam';
                          final jamMulai   = d['jamMulai']  as String? ?? '';
                          final jamSelesai = d['jamSelesai'] as String? ?? '';
                          final ts = d['createdAt'];
                          final waktu = _formatTs(ts);

                          final bool isAktif = status == 'AKTIF';
                          final icon = isAktif
                              ? Icons.shield_outlined
                              : Icons.security;
                          final title = isAktif
                              ? 'Patroli Berlangsung · $blok'
                              : 'Patroli Selesai · $blok';
                          final subtitle = isAktif
                              ? 'Mulai $jamMulai · $nama'
                              : jamSelesai.isNotEmpty
                                  ? 'Pukul $jamSelesai · $nama · $waktu'
                                  : '$nama · $waktu';

                          return _AktivitasItem(
                            icon    : icon,
                            title   : title,
                            subtitle: subtitle,
                            isAktif : isAktif,
                          );
                        }).toList(),
                      );
                    },
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Item aktivitas keamanan ───────────────────────────────────────────────────
class _AktivitasItem extends StatelessWidget {
  const _AktivitasItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.isAktif = false,
  });

  final IconData icon;
  final String   title;
  final String   subtitle;
  final bool     isAktif;

  @override
  Widget build(BuildContext context) {
    final color = isAktif ? Colors.orange.shade700 : AppColors.textGrey;
    final bg    = isAktif
        ? Colors.orange.shade50
        : AppColors.primary.withOpacity(0.07);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppColors.textGrey),
                  ),
                ],
              ],
            ),
          ),
          if (isAktif)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Text(
                'AKTIF',
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade700,
                  letterSpacing: 0.4,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Card satpam bertugas ──────────────────────────────────────────────────────
class _SatpamCard extends StatelessWidget {
  const _SatpamCard({required this.satpam});
  final _SatpamInfo satpam;

  String get _initials {
    final parts = satpam.namaLengkap.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0].isNotEmpty ? parts[0][0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Avatar initials
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF1A4080),
            ),
            child: Text(
              _initials,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Nama
          Text(
            satpam.namaLengkap,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6),
          // Badge bertugas
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.green.shade600,
                  ),
                ),
                const SizedBox(width: 3),
                Text(
                  'Bertugas',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade700,
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
