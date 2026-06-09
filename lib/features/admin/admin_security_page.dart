import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import 'widgets/admin_sidebar.dart';
import 'widgets/admin_top_bar.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Mock data — Aktivitas
// ─────────────────────────────────────────────────────────────────────────────

enum _ActivityStatus { sosPending, onMyWay, resolved }

class _ActivityItem {
  const _ActivityItem({
    required this.unit,
    required this.kategori,
    required this.deskripsi,
    required this.status,
  });
  final String unit;
  final String kategori;
  final String deskripsi;
  final _ActivityStatus status;
}

const _activities = [
  _ActivityItem(
    unit: 'Unit B-12',
    kategori: 'SOS PENDING',
    deskripsi: 'Pemicu: Panic Button • 08:45 WIB • Lokasi Lantai 3',
    status: _ActivityStatus.sosPending,
  ),
  _ActivityItem(
    unit: 'Unit C-05',
    kategori: 'Keperluan Bantuan',
    deskripsi: 'Bantuan Parkir Tamu • 09:12 WIB • Ahmad S. Menuju Lokasi',
    status: _ActivityStatus.onMyWay,
  ),
  _ActivityItem(
    unit: 'Unit A-22',
    kategori: 'Penjemputan Paket',
    deskripsi: 'Selesai dilayani oleh Budi S. pada 09:15 WIB',
    status: _ActivityStatus.resolved,
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// Mock data — Satpam Bertugas
// ─────────────────────────────────────────────────────────────────────────────

class _SatpamItem {
  const _SatpamItem({
    required this.nama,
    required this.lokasi,
    required this.posisi,
  });
  final String nama;
  final String lokasi;
  final String posisi;
}

const _satpamList = [
  _SatpamItem(nama: 'Ahmad Subarjo', lokasi: 'Main Gate', posisi: 'Shift Pagi'),
  _SatpamItem(nama: 'Budi Santoso', lokasi: 'Sector A', posisi: 'Supervisor'),
  _SatpamItem(nama: 'Dedi Kurniawan', lokasi: 'Lobby Timur', posisi: 'Patroli'),
];

// ─────────────────────────────────────────────────────────────────────────────
// Mock data — Log Patroli
// ─────────────────────────────────────────────────────────────────────────────

class _PatroliLog {
  const _PatroliLog({
    required this.waktu,
    required this.petugas,
    required this.lokasi,
    required this.catatan,
    required this.isBerjalan,
  });
  final String waktu;
  final String petugas;
  final String lokasi;
  final String catatan;
  final bool isBerjalan;
}

const _patroliLogs = [
  _PatroliLog(
    waktu: '09:00',
    petugas: 'Ahmad Subarjo',
    lokasi: 'Keliling Sector A',
    catatan: 'Lampu koridor Lt 2 redup',
    isBerjalan: true,
  ),
  _PatroliLog(
    waktu: '08:30',
    petugas: 'Budi Santoso',
    lokasi: 'Basement P1',
    catatan: 'Pengecekan hydrant ok',
    isBerjalan: false,
  ),
  _PatroliLog(
    waktu: '08:00',
    petugas: 'Dedi Kurniawan',
    lokasi: 'Area Taman',
    catatan: 'Kondisi gerbang terkunci',
    isBerjalan: false,
  ),
  _PatroliLog(
    waktu: '07:30',
    petugas: 'Siti Aminah',
    lokasi: 'Koridor LT 5',
    catatan: 'Aman terkendali',
    isBerjalan: false,
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// Page
// ─────────────────────────────────────────────────────────────────────────────

class AdminSecurityPage extends StatelessWidget {
  const AdminSecurityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // ── Sidebar ────────────────────────────────────────────────────
          const AdminSidebar(activePage: AdminPage.security),

          // ── Main content ───────────────────────────────────────────────
          Expanded(
            child: Column(
              children: [
                // Top bar
                const AdminTopBar(searchHint: 'Search security, incidents...'),

                // Body
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Stat cards ───────────────────────────────────
                        const _StatCardsRow(),
                        const SizedBox(height: 20),

                        // ── Main row: activities + satpam ────────────────
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Expanded(
                              flex: 3,
                              child: Column(
                                children: [
                                  _AktivitasSection(),
                                  SizedBox(height: 20),
                                  _LogPatroliSection(),
                                ],
                              ),
                            ),
                            SizedBox(width: 20),
                            Expanded(
                              flex: 1,
                              child: _SatpamBertugasSection(),
                            ),
                          ],
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
// Stat cards row
// ─────────────────────────────────────────────────────────────────────────────

class _StatCardsRow extends StatelessWidget {
  const _StatCardsRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(
          child: _StatCard(
            label: 'SATPAM AKTIF',
            value: '08',
            sub: 'Online',
            subIcon: Icons.check_circle_outline,
            subColor: Color(0xFF16A34A),
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            label: 'PANGGILAN SOS',
            value: '01',
            sub: 'Urgent',
            subIcon: Icons.priority_high_rounded,
            subColor: Color(0xFFDC2626),
            valueColor: Color(0xFFDC2626),
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            label: 'UNIT DILAYANI',
            value: '12',
            sub: 'Hari ini',
            subColor: Color(0xFF64748B),
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
    this.subIcon,
    required this.subColor,
    this.valueColor = AppColors.textDark,
  });
  final String label;
  final String value;
  final String sub;
  final IconData? subIcon;
  final Color subColor;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
              const SizedBox(height: 8),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: valueColor,
                  height: 1,
                ),
              ),
            ],
          ),
          Row(
            children: [
              if (subIcon != null) ...[
                Icon(subIcon, size: 15, color: subColor),
                const SizedBox(width: 4),
              ],
              Text(
                sub,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: subColor,
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
// Aktivitas Panggil Satpam
// ─────────────────────────────────────────────────────────────────────────────

class _AktivitasSection extends StatelessWidget {
  const _AktivitasSection();

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
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Aktivitas Panggil Satpam',
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

          const SizedBox(height: 8),

          // Activity items
          ..._activities.map((a) => _ActivityCard(item: a)).toList(),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.item});
  final _ActivityItem item;

  @override
  Widget build(BuildContext context) {
    final isSos = item.status == _ActivityStatus.sosPending;
    final isOnMyWay = item.status == _ActivityStatus.onMyWay;
    final isResolved = item.status == _ActivityStatus.resolved;

    // Icon config
    final iconBg = isSos
        ? const Color(0xFFFFE4E6)
        : isOnMyWay
            ? const Color(0xFFFFF3E0)
            : Colors.grey.shade100;
    final iconColor = isSos
        ? const Color(0xFFDC2626)
        : isOnMyWay
            ? const Color(0xFFF97316)
            : Colors.grey.shade400;
    final icon = isSos
        ? Icons.emergency_outlined
        : isOnMyWay
            ? Icons.support_agent_outlined
            : Icons.check_circle_outline;

    // Badge
    Widget? badge;
    if (isSos) {
      badge = _Badge(label: 'SOS PENDING', bg: const Color(0xFFDC2626), fg: Colors.white);
    } else if (isOnMyWay) {
      badge = _Badge(label: 'ON MY WAY', bg: const Color(0xFF0D9488), fg: Colors.white);
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSos
              ? const Color(0xFFFCA5A5)
              : Colors.grey.shade200,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 22, color: iconColor),
          ),
          const SizedBox(width: 12),

          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      item.unit,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    if (!isResolved) ...[
                      const SizedBox(width: 8),
                      Text(
                        '•  ${item.kategori}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textGrey,
                        ),
                      ),
                    ] else ...[
                      const SizedBox(width: 8),
                      Text(
                        item.kategori,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textGrey,
                        ),
                      ),
                    ],
                    if (badge != null) ...[
                      const SizedBox(width: 8),
                      badge,
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.deskripsi,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textGrey,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Action
          if (isSos) ...[
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                'Tugaskan\nSatpam',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.more_vert,
                  size: 18, color: Color(0xFF374151)),
            ),
          ] else if (isOnMyWay) ...[
            GestureDetector(
              onTap: () {},
              child: Text(
                'Update\nStatus',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ] else ...[
            Text(
              'Resolved',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: AppColors.textGrey,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.bg, required this.fg});
  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: fg,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Log Patroli Terbaru
// ─────────────────────────────────────────────────────────────────────────────

class _LogPatroliSection extends StatelessWidget {
  const _LogPatroliSection();

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
              children: [
                Text(
                  'Log Patroli Terbaru',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const Spacer(),
                _OutlineIconBtn(
                  icon: Icons.filter_list_outlined,
                  label: 'Filter',
                  onTap: () {},
                ),
                const SizedBox(width: 10),
                _OutlineIconBtn(
                  icon: Icons.download_outlined,
                  label: 'Export',
                  onTap: () {},
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Table header
          Container(
            color: const Color(0xFFF8FAFC),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: const [
                SizedBox(width: 60, child: _ColHeader('Waktu')),
                Expanded(flex: 2, child: _ColHeader('Petugas')),
                Expanded(flex: 2, child: _ColHeader('Lokasi / Area')),
                Expanded(flex: 3, child: _ColHeader('Catatan')),
                SizedBox(width: 90, child: _ColHeader('Status')),
              ],
            ),
          ),

          // Rows
          ..._patroliLogs.map((log) => _PatroliRow(log: log)).toList(),
        ],
      ),
    );
  }
}

class _ColHeader extends StatelessWidget {
  const _ColHeader(this.text);
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

class _PatroliRow extends StatelessWidget {
  const _PatroliRow({required this.log});
  final _PatroliLog log;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              log.waktu,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textDark,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              log.petugas,
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textDark),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              log.lokasi,
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textDark),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              log.catatan,
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textDark),
            ),
          ),
          SizedBox(
            width: 90,
            child: log.isBerjalan
                ? Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Berjalan',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  )
                : Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Selesai',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textGrey,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _OutlineIconBtn extends StatelessWidget {
  const _OutlineIconBtn({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: const Color(0xFF374151)),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF374151),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Satpam Bertugas
// ─────────────────────────────────────────────────────────────────────────────

class _SatpamBertugasSection extends StatelessWidget {
  const _SatpamBertugasSection();

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : 'S';
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
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
            child: Row(
              children: [
                Text(
                  'Satpam Bertugas',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '8 Aktif',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Satpam list
          ..._satpamList.map((s) {
            return Container(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade100)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.primary.withOpacity(0.12),
                    child: Text(
                      _initials(s.nama),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.nama,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${s.lokasi} • ${s.posisi}',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.textGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 18,
                    color: AppColors.textGrey,
                  ),
                ],
              ),
            );
          }).toList(),

          // Lihat Semua Petugas
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
            child: GestureDetector(
              onTap: () {},
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Center(
                  child: Text(
                    'Lihat Semua Petugas',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF374151),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
