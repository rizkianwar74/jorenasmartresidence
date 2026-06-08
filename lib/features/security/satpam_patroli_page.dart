import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/router/app_router.dart';

class SatpamPatroliPage extends StatefulWidget {
  const SatpamPatroliPage({super.key});

  @override
  State<SatpamPatroliPage> createState() => _SatpamPatroliPageState();
}

class _SatpamPatroliPageState extends State<SatpamPatroliPage> {
  static const double _contentMaxWidth = 600.0;

  TimeOfDay _jamMulai  = const TimeOfDay(hour: 8,  minute: 0);
  TimeOfDay _jamSelesai = const TimeOfDay(hour: 9, minute: 0);

  final _keteranganController = TextEditingController();
  final Set<String> _selectedTags = {};

  static const _quickTags = [
    'Aman & Terkendali',
    'Pengecekan Rutin',
    'Insiden Terdeteksi',
  ];

  @override
  void dispose() {
    _keteranganController.dispose();
    super.dispose();
  }

  String _formatTime(TimeOfDay t) {
    final hour   = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  Future<void> _pickTime({required bool isMulai}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isMulai ? _jamMulai : _jamSelesai,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      if (isMulai) _jamMulai = picked;
      else _jamSelesai = picked;
    });
  }

  void _simpanLaporan() {
    HapticFeedback.mediumImpact();
    // TODO: simpan ke Firestore
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Laporan patroli berhasil disimpan',
          style: GoogleFonts.inter(fontSize: 13),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
        body: Stack(
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
                child: Column(
                  children: [
                    // ── Top Bar ────────────────────────────────────────
                    _TopBar(),

                    // ── Scrollable content ─────────────────────────────
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 140),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Judul
                            Text(
                              'Input Detail Patroli',
                              style: GoogleFonts.inter(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0D1B2A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Lengkapi detail pengecekan area tugas anda.',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // ── Card 1: Jadwal Patroli ─────────────────
                            _SectionCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _CardHeader(
                                    icon: Icons.access_time_outlined,
                                    label: 'JADWAL PATROLI',
                                  ),
                                  const SizedBox(height: 16),
                                  _TimeField(
                                    label: 'Jam Mulai',
                                    value: _formatTime(_jamMulai),
                                    onTap: () => _pickTime(isMulai: true),
                                  ),
                                  const SizedBox(height: 12),
                                  _TimeField(
                                    label: 'Jam Selesai',
                                    value: _formatTime(_jamSelesai),
                                    onTap: () => _pickTime(isMulai: false),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 14),

                            // ── Card 2: Blok Patroli ───────────────────
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppColors.primary.withOpacity(0.15),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Blok Patroli',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Blok A, B, & C',
                                    style: GoogleFonts.inter(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF0D1B2A),
                                    ),
                                  ),
                                  Text(
                                    'Seluruh Area Blok',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: const Color(0xFF94A3B8),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Divider(
                                    color: AppColors.primary.withOpacity(0.15),
                                    height: 1,
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Cuaca saat ini',
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: const Color(0xFF0D1B2A),
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Icon(Icons.cloud_outlined,
                                              size: 16,
                                              color: AppColors.primary),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Cerah',
                                            style: GoogleFonts.inter(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 14),

                            // ── Card 3: Keterangan Patroli ─────────────
                            _SectionCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header dengan tombol Unggah Foto
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.menu,
                                              size: 16,
                                              color: AppColors.primary),
                                          const SizedBox(width: 8),
                                          Text(
                                            'KETERANGAN PATROLI',
                                            style: GoogleFonts.inter(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: const Color(0xFF94A3B8),
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          // TODO: image picker
                                        },
                                        child: Row(
                                          children: [
                                            Icon(Icons.camera_alt_outlined,
                                                size: 16,
                                                color: AppColors.primary),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Unggah Foto',
                                              style: GoogleFonts.inter(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 12),

                                  // Text area
                                  Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF4F6F9),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                          color: Colors.grey.shade200),
                                    ),
                                    child: TextField(
                                      controller: _keteranganController,
                                      maxLines: 6,
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: const Color(0xFF0D1B2A),
                                      ),
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        contentPadding:
                                            const EdgeInsets.all(14),
                                        hintText:
                                            'Tuliskan temuan atau rutinitas patroli di sini... '
                                            '(Contoh: Pintu darurat terkunci, lampu lorong '
                                            'menyala normal, tidak ada aktivitas mencurigakan)',
                                        hintStyle: GoogleFonts.inter(
                                          fontSize: 13,
                                          color: const Color(0xFFB0BEC5),
                                          height: 1.5,
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 14),

                                  // Quick tag chips
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: _quickTags.map((tag) {
                                      final isSelected =
                                          _selectedTags.contains(tag);
                                      return GestureDetector(
                                        onTap: () => setState(() {
                                          isSelected
                                              ? _selectedTags.remove(tag)
                                              : _selectedTags.add(tag);
                                        }),
                                        child: AnimatedContainer(
                                          duration: const Duration(
                                              milliseconds: 150),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 14, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? AppColors.primary
                                                : Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            border: Border.all(
                                              color: isSelected
                                                  ? AppColors.primary
                                                  : Colors.grey.shade300,
                                            ),
                                          ),
                                          child: Text(
                                            tag,
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: isSelected
                                                  ? Colors.white
                                                  : const Color(0xFF0D1B2A),
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
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

            // ── Bottom: Tombol + Nav ───────────────────────────────────
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Tombol Simpan
                  Container(
                    color: const Color(0xFFF4F6F9),
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton.icon(
                            onPressed: _simpanLaporan,
                            icon: const Icon(Icons.save_outlined,
                                color: Colors.white, size: 20),
                            label: Text(
                              'Simpan Laporan',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Laporan akan langsung diteruskan ke Command Center.',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Bottom Nav
                  _SatpamBottomNav(currentIndex: 1),
                ],
              ),
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
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 20,
        right: 20,
        bottom: 12,
      ),
      child: Row(
        children: [
          Icon(Icons.security, color: AppColors.primary, size: 22),
          const SizedBox(width: 8),
          Text(
            'SECURITY OPS',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: const Icon(Icons.person_outline,
                size: 20, color: Color(0xFF0D1B2A)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable: white card dengan shadow
// ─────────────────────────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
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
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable: header icon + label dalam card
// ─────────────────────────────────────────────────────────────────────────────
class _CardHeader extends StatelessWidget {
  const _CardHeader({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF94A3B8),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable: time field (tapable)
// ─────────────────────────────────────────────────────────────────────────────
class _TimeField extends StatelessWidget {
  const _TimeField({
    required this.label,
    required this.value,
    required this.onTap,
  });
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF0D1B2A),
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F6F9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF0D1B2A),
                  ),
                ),
                Icon(Icons.access_time_outlined,
                    size: 18, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom Nav Bar Satpam
// ─────────────────────────────────────────────────────────────────────────────
class _SatpamBottomNav extends StatelessWidget {
  const _SatpamBottomNav({required this.currentIndex});
  final int currentIndex;

  static const _items = [
    (icon: Icons.dashboard_outlined, label: 'Dashboard', route: AppRouter.satpamHome),
    (icon: Icons.shield_outlined,    label: 'Patrol',    route: AppRouter.satpamPatroli),
    (icon: Icons.crisis_alert,       label: 'Incidents', route: AppRouter.satpamReports),
    (icon: Icons.assignment_outlined, label: 'Requests', route: AppRouter.satpamCatatTamu),
  ];

  void _onTap(BuildContext context, int index) {
    if (index == currentIndex) return;
    Navigator.pushNamed(context, _items[index].route);
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
              return GestureDetector(
                onTap: () => _onTap(context, i),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.primary.withOpacity(0.12)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        _items[i].icon,
                        color: isActive
                            ? AppColors.primary
                            : const Color(0xFFB0BEC5),
                        size: 22,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _items[i].label,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight:
                            isActive ? FontWeight.bold : FontWeight.w500,
                        color: isActive
                            ? AppColors.primary
                            : const Color(0xFFB0BEC5),
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
