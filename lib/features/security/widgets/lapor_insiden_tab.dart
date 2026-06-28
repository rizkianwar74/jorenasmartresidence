import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../data/security_repository.dart';
import '../helpers/status_keluhan_helpers.dart';
import '../models/insiden_form_data.dart';
import 'report_form_widgets.dart';

class LaporInsidenTab extends StatefulWidget {
  const LaporInsidenTab({super.key});

  @override
  State<LaporInsidenTab> createState() => _LaporInsidenTabState();
}

class _LaporInsidenTabState extends State<LaporInsidenTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  String? _selectedKategori;
  final _blokController         = TextEditingController();
  final _nomorController        = TextEditingController();
  final _detailLokasiController = TextEditingController();
  final _deskripsiController    = TextEditingController();
  DateTime _waktuKejadian       = DateTime.now();
  bool _saving                  = false;

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

  Future<void> _submit() async {
    if (_selectedKategori == null) {
      _showSnack('Pilih kategori insiden terlebih dahulu.', isError: true);
      return;
    }
    if (_blokController.text.trim().isEmpty) {
      _showSnack('Isi blok lokasi kejadian.', isError: true);
      return;
    }
    if (_deskripsiController.text.trim().isEmpty) {
      _showSnack('Isi deskripsi detail kejadian.', isError: true);
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _saving = true);

    try {
      final repo       = SecurityRepository.instance;
      final satpamUid  = repo.currentSatpamUid;
      final namaSatpam = repo.satpamDisplayName;

      final data = InsidenFormData(
        satpamUid: satpamUid,
        namaSatpam: namaSatpam,
        kategori: _selectedKategori!,
        blok: _blokController.text.trim(),
        nomor: _nomorController.text.trim(),
        detailLokasi: _detailLokasiController.text.trim(),
        deskripsi: _deskripsiController.text.trim(),
        waktuKejadian: _waktuKejadian,
      );

      await repo.kirimInsiden(data.toMap());

      if (!mounted) return;

      setState(() {
        _selectedKategori = null;
        _waktuKejadian    = DateTime.now();
        _saving           = false;
      });
      _blokController.clear();
      _nomorController.clear();
      _detailLokasiController.clear();
      _deskripsiController.clear();

      _showSnack('Laporan insiden berhasil dikirim ke Command Center.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showSnack('Gagal mengirim laporan: $e', isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.inter(fontSize: 13)),
      backgroundColor: isError ? Colors.red.shade600 : const Color(0xFF1173D4),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
    ));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HeroBanner(),
          const SizedBox(height: 20),

          FormCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionLabel(label: 'KATEGORI INSIDEN'),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _kategoriList.map((k) {
                    final isSelected = _selectedKategori == k.label;
                    return GestureDetector(
                      onTap: () =>
                          setState(() => _selectedKategori = k.label),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withValues(alpha: 0.08)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(10),
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
                                    : const Color(0xFF64748B)),
                            const SizedBox(width: 6),
                            Text(
                              k.label,
                              style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? AppColors.primary
                                      : const Color(0xFF0D1B2A)),
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

                const SectionLabel(label: 'LOKASI KEJADIAN'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ReportInputField(
                        controller: _blokController,
                        icon: Icons.grid_view_outlined,
                        hint: 'Blok',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ReportInputField(
                        controller: _nomorController,
                        icon: Icons.tag,
                        hint: 'Nomor',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ReportInputField(
                  controller: _detailLokasiController,
                  icon: Icons.location_on_outlined,
                  hint: 'Detail Lokasi (Contoh: Lobby Selatan, Lantai 1)',
                ),

                const SizedBox(height: 22),
                Divider(color: Colors.grey.shade100),
                const SizedBox(height: 18),

                const SectionLabel(label: 'WAKTU KEJADIAN'),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _pickWaktu,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.access_time_outlined,
                            size: 16, color: AppColors.primary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            formatWaktuKejadian(_waktuKejadian),
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

                const SectionLabel(label: 'DESKRIPSI DETAIL'),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: Colors.grey.shade300),
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
                      contentPadding: const EdgeInsets.all(14),
                      hintText:
                          'Jelaskan kronologi kejadian secara detail...',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFFB0BEC5),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _submit,
                    icon: _saving
                        ? const SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send_outlined,
                            color: Colors.white, size: 18),
                    label: Text(
                      _saving ? 'Mengirim...' : 'SUBMIT LAPORAN SEKARANG',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1173D4),
                      disabledBackgroundColor:
                          const Color(0xFF1173D4).withValues(alpha: 0.6),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    'Laporan akan langsung diteruskan ke Pusat Komando.',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFF94A3B8),
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

class _HeroBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 100,
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
          const Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: Opacity(
              opacity: 0.15,
              child: Icon(Icons.grid_on, size: 130, color: Colors.white),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Pelaporan Real-Time',
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Pastikan data yang diinput akurat dan objektif.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.8),
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
