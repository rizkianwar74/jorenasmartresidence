import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/router/app_router.dart';

class SatpamReportsPage extends StatefulWidget {
  const SatpamReportsPage({super.key});

  @override
  State<SatpamReportsPage> createState() => _SatpamReportsPageState();
}

class _SatpamReportsPageState extends State<SatpamReportsPage> {
  static const double _contentMaxWidth = 600.0;

  // Form state
  String? _selectedKategori;
  final _blokController       = TextEditingController();
  final _nomorController      = TextEditingController();
  final _detailLokasiController = TextEditingController();
  final _deskripsiController  = TextEditingController();
  DateTime _waktuKejadian     = DateTime.now();

  static const _kategoriList = [
    (label: 'Kebakaran',  icon: Icons.local_fire_department_outlined),
    (label: 'Vandalisme', icon: Icons.format_paint_outlined),
    (label: 'Medis',      icon: Icons.medical_services_outlined),
    (label: 'Pencurian',  icon: Icons.person_search_outlined),
    (label: 'Lainnya',    icon: Icons.more_time_outlined),
  ];

  @override
  void dispose() {
    _blokController.dispose();
    _nomorController.dispose();
    _detailLokasiController.dispose();
    _deskripsiController.dispose();
    super.dispose();
  }

  String _formatWaktu(DateTime dt) {
    final d  = '${dt.month.toString().padLeft(2,'0')}/${dt.day.toString().padLeft(2,'0')}/${dt.year}';
    final h  = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final m  = dt.minute.toString().padLeft(2, '0');
    final pm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$d  ${h.toString().padLeft(2,'0')}:$m $pm';
  }

  Future<void> _pickWaktu() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _waktuKejadian,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_waktuKejadian),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (time == null) return;
    setState(() {
      _waktuKejadian = DateTime(
          date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  void _submit() {
    HapticFeedback.mediumImpact();
    // TODO: simpan ke Firestore
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Laporan insiden berhasil dikirim',
          style: GoogleFonts.inter(fontSize: 13),
        ),
        backgroundColor: const Color(0xFF1173D4),
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
                    // ── Top Bar ──────────────────────────────────────
                    _TopBar(),

                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 160),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Hero Banner ──────────────────────────
                            _HeroBanner(),
                            const SizedBox(height: 20),

                            // ── Form Card ────────────────────────────
                            _FormCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 1. Kategori Insiden
                                  _SectionLabel(label: 'KATEGORI INSIDEN'),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: _kategoriList.map((k) {
                                      final isSelected =
                                          _selectedKategori == k.label;
                                      return GestureDetector(
                                        onTap: () => setState(
                                            () => _selectedKategori = k.label),
                                        child: AnimatedContainer(
                                          duration: const Duration(
                                              milliseconds: 150),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 14, vertical: 10),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? AppColors.primary
                                                    .withOpacity(0.08)
                                                : Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            border: Border.all(
                                              color: isSelected
                                                  ? AppColors.primary
                                                  : Colors.grey.shade300,
                                              width: isSelected ? 1.5 : 1,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(k.icon,
                                                  size: 16,
                                                  color: isSelected
                                                      ? AppColors.primary
                                                      : const Color(
                                                          0xFF64748B)),
                                              const SizedBox(width: 6),
                                              Text(
                                                k.label,
                                                style: GoogleFonts.inter(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: isSelected
                                                      ? AppColors.primary
                                                      : const Color(
                                                          0xFF0D1B2A),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),

                                  const SizedBox(height: 22),
                                  Divider(color: Colors.grey.shade100),
                                  const SizedBox(height: 18),

                                  // 2. Lokasi Kejadian
                                  _SectionLabel(label: 'LOKASI KEJADIAN'),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _InputField(
                                          controller: _blokController,
                                          icon: Icons.grid_view_outlined,
                                          hint: 'Blok',
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: _InputField(
                                          controller: _nomorController,
                                          icon: Icons.tag,
                                          hint: 'Nomor',
                                          keyboardType: TextInputType.number,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  _InputField(
                                    controller: _detailLokasiController,
                                    icon: Icons.location_on_outlined,
                                    hint:
                                        'Detail Lokasi (Contoh: Lobby Selatan, Lantai 1)',
                                  ),

                                  const SizedBox(height: 22),
                                  Divider(color: Colors.grey.shade100),
                                  const SizedBox(height: 18),

                                  // 3. Waktu Kejadian
                                  _SectionLabel(label: 'WAKTU KEJADIAN'),
                                  const SizedBox(height: 12),
                                  GestureDetector(
                                    onTap: _pickWaktu,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 14),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(10),
                                        border: Border.all(
                                            color: Colors.grey.shade300),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.access_time_outlined,
                                              size: 16,
                                              color: AppColors.primary),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              _formatWaktu(_waktuKejadian),
                                              style: GoogleFonts.inter(
                                                fontSize: 14,
                                                color: const Color(0xFF0D1B2A),
                                              ),
                                            ),
                                          ),
                                          Icon(Icons.calendar_today_outlined,
                                              size: 16,
                                              color: Colors.grey.shade400),
                                        ],
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 22),
                                  Divider(color: Colors.grey.shade100),
                                  const SizedBox(height: 18),

                                  // 4. Deskripsi Detail
                                  _SectionLabel(label: 'DESKRIPSI DETAIL'),
                                  const SizedBox(height: 12),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                          color: Colors.grey.shade300),
                                    ),
                                    child: TextField(
                                      controller: _deskripsiController,
                                      maxLines: 5,
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: const Color(0xFF0D1B2A),
                                      ),
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        contentPadding:
                                            const EdgeInsets.all(14),
                                        hintText:
                                            'Jelaskan kronologi kejadian secara detail...',
                                        hintStyle: GoogleFonts.inter(
                                          fontSize: 13,
                                          color: const Color(0xFFB0BEC5),
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 22),
                                  Divider(color: Colors.grey.shade100),
                                  const SizedBox(height: 18),

                                  // 5. Bukti Foto / Dokumen
                                  _SectionLabel(
                                      label: 'BUKTI FOTO / DOKUMEN'),
                                  const SizedBox(height: 12),
                                  GestureDetector(
                                    onTap: () {
                                      // TODO: image picker
                                    },
                                    child: Container(
                                      width: 140,
                                      height: 120,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.grey.shade300,
                                          width: 1.5,
                                          strokeAlign:
                                              BorderSide.strokeAlignInside,
                                        ),
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.add_a_photo_outlined,
                                            size: 32,
                                            color: Colors.grey.shade400,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Ambil Foto',
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              color: Colors.grey.shade400,
                                              fontWeight: FontWeight.w500,
                                            ),
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
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Bottom: Submit + Nav ───────────────────────────────
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    color: const Color(0xFFF4F6F9),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton.icon(
                            onPressed: _submit,
                            icon: const Icon(Icons.send_outlined,
                                color: Colors.white, size: 18),
                            label: Text(
                              'SUBMIT LAPORAN SEKARANG',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1173D4),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Laporan akan langsung diteruskan ke Pusat Komando.',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _SatpamBottomNav(currentIndex: 2),
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
          Icon(Icons.security, color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          Text(
            'Lapor Insiden',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const Spacer(),
          Icon(Icons.notifications_outlined,
              size: 22, color: const Color(0xFF0D1B2A)),
          const SizedBox(width: 14),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: const Icon(Icons.person_outline,
                size: 18, color: Color(0xFF0D1B2A)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero Banner
// ─────────────────────────────────────────────────────────────────────────────
class _HeroBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 110,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D2137), Color(0xFF1173D4)],
        ),
      ),
      child: Stack(
        children: [
          // Dekoratif grid/pattern
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: Opacity(
              opacity: 0.15,
              child: Icon(Icons.grid_on,
                  size: 140, color: Colors.white),
            ),
          ),
          // Konten teks
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Pelaporan Real-Time',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pastikan data yang diinput akurat dan objektif.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
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
// Form Card
// ─────────────────────────────────────────────────────────────────────────────
class _FormCard extends StatelessWidget {
  const _FormCard({required this.child});
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
// Section Label
// ─────────────────────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF94A3B8),
        letterSpacing: 0.8,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Input Field
// ─────────────────────────────────────────────────────────────────────────────
class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.icon,
    required this.hint,
    this.keyboardType,
  });
  final TextEditingController controller;
  final IconData icon;
  final String hint;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF0D1B2A)),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
          prefixIcon: Icon(icon, size: 16, color: const Color(0xFF94A3B8)),
          prefixIconConstraints:
              const BoxConstraints(minWidth: 38, minHeight: 38),
          hintText: hint,
          hintStyle: GoogleFonts.inter(
              fontSize: 13, color: const Color(0xFFB0BEC5)),
        ),
      ),
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
    (icon: Icons.dashboard_outlined,  label: 'Dashboard', route: AppRouter.satpamHome),
    (icon: Icons.shield_outlined,     label: 'Patrol',    route: AppRouter.satpamPatroli),
    (icon: Icons.crisis_alert,        label: 'Incidents', route: AppRouter.satpamReports),
    (icon: Icons.assignment_outlined, label: 'Requests',  route: AppRouter.satpamCatatTamu),
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
