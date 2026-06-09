import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import '../../core/theme/app_colors.dart';
import '../auth/auth_repository.dart';
import 'widgets/admin_sidebar.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Mock data
// ─────────────────────────────────────────────────────────────────────────────

class _IncidentItem {
  const _IncidentItem({
    required this.tipe,
    required this.lokasi,
    required this.status,
    required this.waktu,
    required this.severity, // 0=green, 1=yellow, 2=red
  });
  final String tipe;
  final String lokasi;
  final String status;
  final String waktu;
  final int severity;
}

const _incidents = [
  _IncidentItem(
    tipe: 'Patroli Selesai',
    lokasi: 'Blok B (Gate 2) - Officer Budi',
    status: 'Selesai',
    waktu: '09:45 AM',
    severity: 0,
  ),
  _IncidentItem(
    tipe: 'Tamu Tanpa Izin',
    lokasi: 'Area Parkir Timur - Officer Agus',
    status: 'Investigasi',
    waktu: '09:32 AM',
    severity: 1,
  ),
  _IncidentItem(
    tipe: 'Masuk Tamu Terdaftar',
    lokasi: 'Main Lobby - Digital Key 04',
    status: 'Berhasil',
    waktu: '09:15 AM',
    severity: 0,
  ),
  _IncidentItem(
    tipe: 'Sensor Kebakaran Aktif',
    lokasi: 'Lantai 4 Koridor Utara',
    status: 'KRITIS',
    waktu: '08:50 AM',
    severity: 2,
  ),
  _IncidentItem(
    tipe: 'Pembersihan Fasilitas',
    lokasi: 'Gym & Yoga Room',
    status: 'Terjadwal',
    waktu: '08:00 AM',
    severity: 0,
  ),
];

class _RequestItem {
  const _RequestItem({
    required this.judul,
    required this.oleh,
    required this.waktu,
    required this.icon,
    required this.iconColor,
    this.status,
  });
  final String judul;
  final String oleh;
  final String waktu;
  final IconData icon;
  final Color iconColor;
  final String? status;
}

const _requests = [
  _RequestItem(
    judul: 'Kerusakan Pipa Air - Unit A-402',
    oleh: 'Ibu Ratna',
    waktu: '15 menit yang lalu',
    icon: Icons.build_outlined,
    iconColor: Color(0xFF1173D4),
  ),
  _RequestItem(
    judul: 'Booking Multi-purpose Hall',
    oleh: 'Bpk. Andi',
    waktu: '1 jam yang lalu',
    icon: Icons.calendar_today_outlined,
    iconColor: Color(0xFF1173D4),
    status: 'Pending Appr.',
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// Main Page
// ─────────────────────────────────────────────────────────────────────────────

class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // ── Sidebar ──────────────────────────────────────────────────────
          const AdminSidebar(activePage: AdminPage.dashboard),

          // ── Main content ─────────────────────────────────────────────────
          Expanded(
            child: Column(
              children: [
                // Top bar
                const _TopBar(),
                // Scrollable body
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // System status bar
                        const _SystemStatusBar(),
                        const SizedBox(height: 20),

                        // Stat cards
                        const _StatCardsRow(),
                        const SizedBox(height: 20),

                        // Heatmap + Financial
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Expanded(flex: 3, child: _SecurityHeatmap()),
                            SizedBox(width: 20),
                            Expanded(flex: 1, child: _FinancialStatus()),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Resident Requests
                        const _ResidentRequests(),
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
// Top Bar
// ─────────────────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          // Search bar
          Expanded(
            child: Container(
              height: 40,
              constraints: const BoxConstraints(maxWidth: 480),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  Icon(Icons.search, size: 18, color: AppColors.textGrey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Search residents, units, or incidents...',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textGrey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Spacer(),

          // Bell notification
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.notifications_outlined,
                  size: 20,
                  color: AppColors.textGrey,
                ),
              ),
              Positioned(
                top: 6,
                right: 8,
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

          const SizedBox(width: 16),
          Container(width: 1, height: 32, color: Colors.grey.shade200),
          const SizedBox(width: 16),

          // Profile
          Row(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Admin Profile',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  Text(
                    'Administrator',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textGrey,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 10),
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primary.withOpacity(0.15),
                child: Icon(Icons.person, size: 20, color: AppColors.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// System Status Bar
// ─────────────────────────────────────────────────────────────────────────────

class _SystemStatusBar extends StatelessWidget {
  const _SystemStatusBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // Green dot
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: Color(0xFF22C55E),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),

          // Status text
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sistem Operasional: Aktif',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              Text(
                'Semua modul berfungsi normal. Terakhir diperbarui: 2 menit yang lalu.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textGrey,
                ),
              ),
            ],
          ),

          const Spacer(),

          // Trigger Alarm
          ElevatedButton(
            onPressed: () => _showAlarmDialog(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'TRIGGER ALARM',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Log Insiden Manual
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textDark,
              side: BorderSide(color: Colors.grey.shade300),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Log Insiden Manual',
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  void _showAlarmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 24),
            const SizedBox(width: 8),
            Text(
              'Aktifkan Alarm Darurat?',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        content: Text(
          'Tindakan ini akan mengirim notifikasi darurat ke seluruh penghuni dan satpam.',
          style: GoogleFonts.inter(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal', style: GoogleFonts.inter(color: AppColors.textGrey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Aktifkan', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stat Cards Row
// ─────────────────────────────────────────────────────────────────────────────

class _StatCardsRow extends StatelessWidget {
  const _StatCardsRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(
          child: _StatCard(
            label: 'TOTAL RESIDENTS',
            value: '1,240',
            sub: '+12 minggu ini',
            subColor: Color(0xFF22C55E),
            icon: Icons.people_alt_outlined,
            iconColor: AppColors.primary,
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            label: 'ACTIVE PATROLS',
            value: '4',
            sub: 'Blok A, B, C & Area Parkir',
            subColor: Color(0xFF64748B),
            icon: Icons.verified_user_outlined,
            iconColor: AppColors.primary,
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            label: 'OPEN INCIDENTS',
            value: '2',
            sub: 'Butuh Tindakan Segera',
            subColor: Color(0xFFDC2626),
            valueColor: Color(0xFFDC2626),
            icon: Icons.emergency_outlined,
            iconColor: Color(0xFFDC2626),
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            label: 'UNPAID BILLS',
            value: '15',
            sub: 'Tenggat Waktu: 3 Hari',
            subColor: Color(0xFFD97706),
            valueColor: Color(0xFFD97706),
            icon: Icons.wallet_outlined,
            iconColor: Color(0xFFD97706),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.sub,
    required this.subColor,
    required this.icon,
    required this.iconColor,
    this.valueColor = AppColors.textDark,
  });
  final String label;
  final String value;
  final String sub;
  final Color subColor;
  final Color valueColor;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textGrey,
                  letterSpacing: 0.5,
                ),
              ),
              Icon(icon, size: 20, color: iconColor),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: valueColor,
              height: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            sub,
            style: GoogleFonts.inter(fontSize: 12, color: subColor),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Security & Incidents Heatmap
// ─────────────────────────────────────────────────────────────────────────────

class _SecurityHeatmap extends StatelessWidget {
  const _SecurityHeatmap();

  Color _severityColor(int severity) {
    switch (severity) {
      case 2:
        return const Color(0xFFDC2626);
      case 1:
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF22C55E);
    }
  }

  Widget _statusBadge(String status) {
    Color bg;
    Color fg;
    switch (status) {
      case 'KRITIS':
        bg = const Color(0xFFFFE4E6); fg = const Color(0xFFDC2626);
        break;
      case 'Investigasi':
        bg = const Color(0xFFFEF3C7); fg = const Color(0xFFD97706);
        break;
      case 'Selesai':
      case 'Berhasil':
        bg = const Color(0xFFDCFCE7); fg = const Color(0xFF16A34A);
        break;
      case 'Terjadwal':
        bg = const Color(0xFFDBEAFE); fg = AppColors.primary;
        break;
      default:
        bg = Colors.grey.shade100; fg = AppColors.textGrey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Security & Incidents Heatmap',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                GestureDetector(
                  onTap: () {},
                  child: Text(
                    'Lihat Semua',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            color: const Color(0xFFF8FAFC),
            child: Row(
              children: [
                const SizedBox(width: 8), // space for color bar
                Expanded(
                  flex: 3,
                  child: Text(
                    'TIPE KEJADIAN',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textGrey,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'LOKASI / PETUGAS',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textGrey,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                SizedBox(
                  width: 110,
                  child: Text(
                    'STATUS',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textGrey,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: Text(
                    'WAKTU',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textGrey,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Table rows
          ..._incidents.map((item) {
            return Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey.shade100),
                ),
              ),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Color severity bar
                    Container(
                      width: 4,
                      decoration: BoxDecoration(
                        color: _severityColor(item.severity),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(0),
                          bottomLeft: Radius.circular(0),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                item.tipe,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                item.lokasi,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: const Color(0xFF374151),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 110,
                              child: _statusBadge(item.status),
                            ),
                            SizedBox(
                              width: 80,
                              child: Text(
                                item.waktu,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: AppColors.textGrey,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Financial Status
// ─────────────────────────────────────────────────────────────────────────────

class _FinancialStatus extends StatelessWidget {
  const _FinancialStatus();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'FINANCIAL STATUS (BULAN INI)',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textGrey,
              letterSpacing: 0.5,
            ),
          ),

          const SizedBox(height: 16),

          // Amount + donut chart
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rp 420M',
                    style: GoogleFonts.inter(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '82% Tertagih',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF16A34A),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              SizedBox(
                width: 56,
                height: 56,
                child: CustomPaint(
                  painter: _DonutChartPainter(progress: 0.82),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Sudah Dibayar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sudah Dibayar',
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.textGrey),
              ),
              Text(
                'Rp 344.4M',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: 0.82,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 6,
            ),
          ),

          const SizedBox(height: 14),

          // Menunggu Pembayaran
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Menunggu Pembayaran',
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.textGrey),
              ),
              Text(
                'Rp 75.6M',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFDC2626),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  _DonutChartPainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 8.0;

    // Background ring
    final bgPaint = Paint()
      ..color = Colors.grey.shade200
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius - strokeWidth / 2, bgPaint);

    // Progress arc
    final fgPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(_DonutChartPainter old) => old.progress != progress;
}

// ─────────────────────────────────────────────────────────────────────────────
// Resident Requests
// ─────────────────────────────────────────────────────────────────────────────

class _ResidentRequests extends StatelessWidget {
  const _ResidentRequests();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
            child: Row(
              children: [
                Text(
                  'Resident Requests',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '3 Permintaan Baru',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {},
                  child: Text(
                    'Lihat Semua',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Request items
          ..._requests.map((req) {
            return Container(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade100)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: req.iconColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(req.icon, size: 20, color: req.iconColor),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          req.judul,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Oleh: ${req.oleh} • ${req.waktu}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (req.status != null) ...[
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        req.status!,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textGrey,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }).toList(),

          const SizedBox(height: 4),
        ],
      ),
    );
  }
}
