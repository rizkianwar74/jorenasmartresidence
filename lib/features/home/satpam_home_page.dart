import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/router/app_router.dart';
import '../auth/auth_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Model
// ─────────────────────────────────────────────────────────────────────────────
class _AktivitasItem {
  const _AktivitasItem({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.sublabel,
    required this.waktu,
  });
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String sublabel;
  final String waktu;
}

class _SosAlertData {
  const _SosAlertData({
    required this.unitLabel,
    required this.description,
    required this.waktu,
  });
  final String unitLabel;
  final String description;
  final String waktu;
}

// ─────────────────────────────────────────────────────────────────────────────
// Page
// ─────────────────────────────────────────────────────────────────────────────
class SatpamHomePage extends StatefulWidget {
  const SatpamHomePage({super.key});

  @override
  State<SatpamHomePage> createState() => _SatpamHomePageState();
}

class _SatpamHomePageState extends State<SatpamHomePage> {
  static const double _contentMaxWidth = 600.0;

  // ── Mock SOS: set ke null jika tidak ada SOS aktif ───────────────────────
  // Ganti dengan stream Firestore nanti:
  // Stream<SosAlertData?> get _sosStream => FirebaseFirestore.instance
  //     .collection('sos_alerts').where('status', isEqualTo: 'active')
  //     .snapshots().map((s) => s.docs.isEmpty ? null : SosAlertData.fromDoc(s.docs.first));
  _SosAlertData? _activeSos = const _SosAlertData(
    unitLabel: 'Unit Blok A – No 12',
    description: 'Resident requesting immediate assistance at the main entrance.',
    waktu: '2 mins ago',
  );

  // ── Mock Stats ────────────────────────────────────────────────────────────
  final int _activePatrols = 2;
  final int _pendingReports = 5;
  final int _tamuHariIni = 8;
  final int _insidenAktif = 1;

  // ── Mock Aktivitas ────────────────────────────────────────────────────────
  static const _mockAktivitas = [
    _AktivitasItem(
      icon: Icons.local_shipping_outlined,
      iconBg: Color(0xFFE3F0FF),
      iconColor: Color(0xFF1173D4),
      label: 'Tamu Datang: Kurir',
      sublabel: 'Blok B – G5',
      waktu: '2 mnt lalu',
    ),
    _AktivitasItem(
      icon: Icons.warning_amber_rounded,
      iconBg: Color(0xFFFFF3E0),
      iconColor: Color(0xFFE65100),
      label: 'Kendaraan Menghalangi',
      sublabel: 'Blok C – Area Parkir',
      waktu: '15 mnt lalu',
    ),
    _AktivitasItem(
      icon: Icons.check_circle_outline,
      iconBg: Color(0xFFE8F5E9),
      iconColor: Color(0xFF2E7D32),
      label: 'Patroli Rutin Selesai',
      sublabel: 'Area Barat – Gate 2',
      waktu: '1 jam lalu',
    ),
    _AktivitasItem(
      icon: Icons.person_add_outlined,
      iconBg: Color(0xFFEDE7F6),
      iconColor: Color(0xFF512DA8),
      label: 'Tamu Dicatat: Keluarga',
      sublabel: 'Blok D – No 3',
      waktu: '2 jam lalu',
    ),
  ];

  void _dismissSos() {
    setState(() => _activeSos = null);
  }

  @override
  Widget build(BuildContext context) {
    final namaUser =
        AuthRepository.currentUser?.namaLengkap.split(' ').first ?? 'Satpam';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6F9),
        body: Stack(
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top,
                    bottom: 100,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Top Bar ─────────────────────────────────────
                      _TopBar(
                        namaUser: namaUser,
                        photoUrl: AuthRepository.currentUser?.photoUrl,
                      ),

                      const SizedBox(height: 16),

                      // ── SOS Alert (conditional) ──────────────────────
                      if (_activeSos != null) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: _SosAlertCard(
                            data: _activeSos!,
                            onOnMyWay: () {
                              HapticFeedback.heavyImpact();
                              // TODO: update status 'on_my_way' ke Firestore
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Status dikirim: On My Way'),
                                  backgroundColor: Color(0xFF2E7D32),
                                ),
                              );
                            },
                            onDismiss: _dismissSos,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // ── Stats Grid ───────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _StatsGrid(
                          activePatrols: _activePatrols,
                          pendingReports: _pendingReports,
                          tamuHariIni: _tamuHariIni,
                          insidenAktif: _insidenAktif,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── Quick Actions ────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _QuickActions(
                          onMulaiPatroli: () {
                            HapticFeedback.mediumImpact();
                            Navigator.pushNamed(context, AppRouter.satpamPatroli);
                          },
                          onCatatTamu: () {
                            HapticFeedback.mediumImpact();
                            Navigator.pushNamed(context, AppRouter.satpamCatatTamu);
                          },
                          onLaporInsiden: () {
                            HapticFeedback.mediumImpact();
                            Navigator.pushNamed(context, AppRouter.satpamReports);
                          },
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ── Recent Activity ──────────────────────────────
                      _RecentActivitySection(items: _mockAktivitas),

                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),

            // ── Bottom Nav ───────────────────────────────────────────
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _SatpamBottomNav(currentIndex: 0),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top Bar
// ─────────────────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  const _TopBar({required this.namaUser, this.photoUrl});
  final String namaUser;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primary.withOpacity(0.15),
            backgroundImage:
                (photoUrl != null && photoUrl!.isNotEmpty)
                    ? NetworkImage(photoUrl!)
                    : null,
            child: (photoUrl == null || photoUrl!.isEmpty)
                ? Text(
                    namaUser.isNotEmpty ? namaUser[0].toUpperCase() : '?',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Selamat bertugas,',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF94A3B8),
                ),
              ),
              Text(
                namaUser,
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0D1B2A),
                ),
              ),
            ],
          ),
          const Spacer(),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
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
                  Icons.notifications_outlined,
                  size: 20,
                  color: Color(0xFF0D1B2A),
                ),
              ),
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SOS Alert Card (conditional)
// ─────────────────────────────────────────────────────────────────────────────
class _SosAlertCard extends StatelessWidget {
  const _SosAlertCard({
    required this.data,
    required this.onOnMyWay,
    required this.onDismiss,
  });
  final _SosAlertData data;
  final VoidCallback onOnMyWay;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFD32F2F), Color(0xFFB71C1C)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: badge + dismiss
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.circle, size: 7, color: Colors.white),
                    const SizedBox(width: 5),
                    Text(
                      'SOS ACTIVE ALERT',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Waktu
              Text(
                data.waktu,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.75),
                ),
              ),
              const SizedBox(width: 8),
              // Dismiss button
              GestureDetector(
                onTap: onDismiss,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Lokasi
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.location_on, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  data.unitLabel,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            data.description,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.white.withOpacity(0.9),
              height: 1.5,
            ),
          ),

          const SizedBox(height: 16),

          // Tombol ON MY WAY
          GestureDetector(
            onTap: onOnMyWay,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.directions_walk_rounded,
                      color: Color(0xFFD32F2F), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'ON MY WAY',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFD32F2F),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stats Grid: 2x2
// ─────────────────────────────────────────────────────────────────────────────
class _StatsGrid extends StatelessWidget {
  const _StatsGrid({
    required this.activePatrols,
    required this.pendingReports,
    required this.tamuHariIni,
    required this.insidenAktif,
  });
  final int activePatrols;
  final int pendingReports;
  final int tamuHariIni;
  final int insidenAktif;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.route_outlined,
                iconColor: AppColors.primary,
                iconBg: const Color(0xFFE3F0FF),
                label: 'PATROLI AKTIF',
                value: '$activePatrols',
                valueLabel: 'Online',
                valueColor: AppColors.primary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _StatCard(
                icon: Icons.inbox_outlined,
                iconColor: const Color(0xFFE65100),
                iconBg: const Color(0xFFFFF3E0),
                label: 'LAPORAN PENDING',
                value: '$pendingReports',
                valueLabel: 'Item',
                valueColor: const Color(0xFF0D1B2A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.people_outline,
                iconColor: const Color(0xFF512DA8),
                iconBg: const Color(0xFFEDE7F6),
                label: 'TAMU HARI INI',
                value: '$tamuHariIni',
                valueLabel: 'Orang',
                valueColor: const Color(0xFF0D1B2A),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _StatCard(
                icon: Icons.warning_amber_rounded,
                iconColor: const Color(0xFFD32F2F),
                iconBg: const Color(0xFFFFEBEE),
                label: 'INSIDEN AKTIF',
                value: '$insidenAktif',
                valueLabel: 'Kasus',
                valueColor: insidenAktif > 0
                    ? const Color(0xFFD32F2F)
                    : const Color(0xFF2E7D32),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.value,
    required this.valueLabel,
    required this.valueColor,
  });
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final String value;
  final String valueLabel;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF94A3B8),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      value,
                      style: GoogleFonts.inter(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: valueColor,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      valueLabel,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
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
// Quick Actions
// ─────────────────────────────────────────────────────────────────────────────
class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.onMulaiPatroli,
    required this.onCatatTamu,
    required this.onLaporInsiden,
  });
  final VoidCallback onMulaiPatroli;
  final VoidCallback onCatatTamu;
  final VoidCallback onLaporInsiden;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Aksi Cepat',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0D1B2A),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // Mulai Patroli — primary, lebih besar
            Expanded(
              flex: 5,
              child: _QuickActionPrimary(
                icon: Icons.shield_outlined,
                label: 'Mulai\nPatroli',
                colors: const [Color(0xFF1E6FD9), Color(0xFF1173D4)],
                shadowColor: AppColors.primary,
                onTap: onMulaiPatroli,
              ),
            ),
            const SizedBox(width: 12),
            // Kolom kanan: 2 tombol kecil
            Expanded(
              flex: 4,
              child: Column(
                children: [
                  _QuickActionSecondary(
                    icon: Icons.person_add_outlined,
                    label: 'Catat Tamu',
                    iconBg: const Color(0xFFEDE7F6),
                    iconColor: const Color(0xFF512DA8),
                    onTap: onCatatTamu,
                  ),
                  const SizedBox(height: 10),
                  _QuickActionSecondary(
                    icon: Icons.report_problem_outlined,
                    label: 'Laporkan Insiden',
                    iconBg: const Color(0xFFFFEBEE),
                    iconColor: const Color(0xFFD32F2F),
                    onTap: onLaporInsiden,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickActionPrimary extends StatelessWidget {
  const _QuickActionPrimary({
    required this.icon,
    required this.label,
    required this.colors,
    required this.shadowColor,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final List<Color> colors;
  final Color shadowColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: shadowColor.withOpacity(0.3),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Lingkaran dekoratif
            Positioned(
              right: -16,
              top: -16,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.07),
                ),
              ),
            ),
            Positioned(
              right: 20,
              bottom: -20,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),
            // Konten
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.2),
                    ),
                    child: Icon(icon, color: Colors.white, size: 26),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionSecondary extends StatelessWidget {
  const _QuickActionSecondary({
    required this.icon,
    required this.label,
    required this.iconBg,
    required this.iconColor,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color iconBg;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0D1B2A),
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: Color(0xFFB0BEC5),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Recent Activity Section
// ─────────────────────────────────────────────────────────────────────────────
class _RecentActivitySection extends StatelessWidget {
  const _RecentActivitySection({required this.items});
  final List<_AktivitasItem> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Aktivitas Terkini',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0D1B2A),
                ),
              ),
              GestureDetector(
                onTap: () {
                  // TODO: navigasi ke semua aktivitas
                },
                child: Text(
                  'LIHAT SEMUA',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: List.generate(items.length, (i) {
                return _AktivitasTile(
                  item: items[i],
                  isLast: i == items.length - 1,
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _AktivitasTile extends StatelessWidget {
  const _AktivitasTile({required this.item, required this.isLast});
  final _AktivitasItem item;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: () {
            // TODO: detail aktivitas
          },
          borderRadius: BorderRadius.vertical(
            top: Radius.zero,
            bottom: isLast ? const Radius.circular(16) : Radius.zero,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: item.iconBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(item.icon, color: item.iconColor, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.label,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0D1B2A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.sublabel,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  item.waktu,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            indent: 72,
            endIndent: 16,
            color: Colors.grey.shade100,
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom Nav Bar
// ─────────────────────────────────────────────────────────────────────────────
class _SatpamBottomNav extends StatelessWidget {
  const _SatpamBottomNav({required this.currentIndex});
  final int currentIndex;

  static const _items = [
    (icon: Icons.home_filled,    label: 'Home',    route: AppRouter.satpamHome),
    (icon: Icons.route_outlined, label: 'Patroli', route: AppRouter.satpamPatroli),
    (icon: Icons.inbox_outlined, label: 'Laporan', route: AppRouter.satpamReports),
    (icon: Icons.person_outline, label: 'Profil',  route: AppRouter.profil),
  ];

  void _onTap(BuildContext context, int index) {
    if (index == currentIndex) return;
    final route = _items[index].route;
    if (route.isEmpty) return;
    Navigator.pushNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_items.length, (i) {
              final isActive = i == currentIndex;
              final color = isActive ? AppColors.primary : const Color(0xFFB0BEC5);
              return GestureDetector(
                onTap: () => _onTap(context, i),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_items[i].icon, color: color, size: 24),
                    const SizedBox(height: 4),
                    Text(
                      _items[i].label,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                        color: color,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}