// lib/features/layanan/fasilitas/fasilitas_booking_page.dart
//
// Halaman booking fasilitas (kolam renang & gym) — backup untuk saat fasilitas
// sudah dibangun. fasilitas_page.dart (under construction) tetap dipertahankan
// dan masih digunakan dari layanan_page.dart.
//
// Untuk mengaktifkan: ganti import di layanan_page.dart dari FasilitasPage
// ke FasilitasBookingPage ketika fasilitas sudah beroperasi.

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/data/auth_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data model & konstanta
// ─────────────────────────────────────────────────────────────────────────────

class _Fasilitas {
  const _Fasilitas({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    required this.kapasitas,
    required this.jamOperasional,
    required this.aturan,
    required this.accentColor,
    required this.bgColor,
  });
  final String id;
  final String name;
  final String emoji;
  final String description;
  final int kapasitas;
  final String jamOperasional;
  final List<String> aturan;
  final Color accentColor;
  final Color bgColor;
}

const _kFasilitas = <_Fasilitas>[
  _Fasilitas(
    id          : 'kolam_renang',
    name        : 'Kolam Renang',
    emoji       : '🏊',
    description : 'Kolam renang outdoor panjang 25m. Cocok untuk olahraga renang dan relaksasi bersama keluarga.',
    kapasitas   : 30,
    jamOperasional: '06:00 – 20:00',
    accentColor : Color(0xFF0EA5E9),
    bgColor     : Color(0xFFE0F2FE),
    aturan: [
      'Wajib mandi sebelum masuk kolam',
      'Anak di bawah 10 tahun harus didampingi orang dewasa',
      'Wajib menggunakan pakaian renang yang sesuai',
      'Dilarang membawa makanan ke tepi kolam',
      'Dilarang berlari atau melompat dari tepi kolam',
      'Dilarang berenang dalam kondisi sakit atau luka terbuka',
    ],
  ),
  _Fasilitas(
    id          : 'gym',
    name        : 'Gym & Kebugaran',
    emoji       : '🏋️',
    description : 'Pusat kebugaran lengkap dengan alat cardio & beban, ber-AC, tersedia loker dan cermin penuh.',
    kapasitas   : 20,
    jamOperasional: '06:00 – 21:00',
    accentColor : Color(0xFFF97316),
    bgColor     : Color(0xFFFFF7ED),
    aturan: [
      'Wajib menggunakan pakaian olahraga dan sepatu',
      'Simpan tas dan barang bawaan di loker',
      'Kembalikan alat ke tempat semula setelah digunakan',
      'Bersihkan alat dengan lap yang disediakan setelah pakai',
      'Dilarang membawa makanan ke area gym',
      'Anak di bawah 15 tahun harus didampingi orang dewasa',
    ],
  ),
];

const _kSesi = <String>[
  '06:00 – 08:00',
  '08:00 – 10:00',
  '10:00 – 12:00',
  '14:00 – 16:00',
  '16:00 – 18:00',
  '18:00 – 20:00',
];

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

String _generateBookingId() {
  final now  = DateTime.now();
  final rand = (Random().nextInt(9000) + 1000).toString();
  final ymd  = '${now.year}'
      '${now.month.toString().padLeft(2, '0')}'
      '${now.day.toString().padLeft(2, '0')}';
  return 'BK$ymd$rand';
}

String _formatDateFull(DateTime d) {
  const months = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agu','Sep','Okt','Nov','Des'];
  const days   = ['Min','Sen','Sel','Rab','Kam','Jum','Sab'];
  return '${days[d.weekday % 7]}, ${d.day} ${months[d.month - 1]} ${d.year}';
}

String _dayAbbr(DateTime d) {
  const days = ['Min','Sen','Sel','Rab','Kam','Jum','Sab'];
  return days[d.weekday % 7];
}

String _monthAbbr(DateTime d) {
  const months = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agu','Sep','Okt','Nov','Des'];
  return months[d.month - 1];
}

// ─────────────────────────────────────────────────────────────────────────────
// Page
// ─────────────────────────────────────────────────────────────────────────────

enum _Step { list, detail, form, confirmed }

class FasilitasBookingPage extends StatefulWidget {
  const FasilitasBookingPage({super.key});

  @override
  State<FasilitasBookingPage> createState() => _FasilitasBookingPageState();
}

class _FasilitasBookingPageState extends State<FasilitasBookingPage> {
  _Step      _step     = _Step.list;
  _Fasilitas? _selected;

  DateTime? _selectedDate;
  String?   _selectedSesi;
  int       _jumlahPeserta = 1;

  late final TextEditingController _namaCtrl;
  late final TextEditingController _unitCtrl;
  late final TextEditingController _catatanCtrl;

  bool   _isSubmitting = false;
  String _bookingId    = '';

  final List<DateTime> _dates = List.generate(
    14,
    (i) => DateTime.now().add(Duration(days: i + 1)),
  );

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    final user = AuthRepository.currentUser;
    final unit = [user?.blok, user?.nomorUnit]
        .where((e) => e != null && e.isNotEmpty)
        .join('-');
    _namaCtrl    = TextEditingController(text: user?.namaLengkap ?? '');
    _unitCtrl    = TextEditingController(text: unit);
    _catatanCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _unitCtrl.dispose();
    _catatanCtrl.dispose();
    super.dispose();
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  void _selectFasilitas(_Fasilitas f) => setState(() {
    _selected      = f;
    _selectedDate  = null;
    _selectedSesi  = null;
    _jumlahPeserta = 1;
    _step          = _Step.detail;
  });

  void _goToForm() => setState(() => _step = _Step.form);

  void _goBack() => setState(() {
    switch (_step) {
      case _Step.detail:    _step = _Step.list; break;
      case _Step.form:      _step = _Step.detail; break;
      case _Step.confirmed: _step = _Step.list; break;
      case _Step.list:      break;
    }
  });

  void _resetAll() => setState(() {
    _selected      = null;
    _selectedDate  = null;
    _selectedSesi  = null;
    _jumlahPeserta = 1;
    _catatanCtrl.clear();
    _step = _Step.list;
  });

  Future<void> _submitBooking() async {
    if (_selectedDate == null || _selectedSesi == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih tanggal dan sesi terlebih dahulu')),
      );
      return;
    }
    if (_namaCtrl.text.trim().isEmpty || _unitCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama dan blok/unit wajib diisi')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final bookingId = _generateBookingId();
      await FirebaseFirestore.instance.collection('bookingfasilitas').add({
        'bookingId'      : bookingId,
        'uid'            : AuthRepository.currentUid ?? '',
        'namaUser'       : _namaCtrl.text.trim(),
        'blokUnit'       : _unitCtrl.text.trim(),
        'fasilitasId'    : _selected!.id,
        'namaFasilitas'  : _selected!.name,
        'tanggal'        : _formatDateFull(_selectedDate!),
        'tanggalRaw'     : _selectedDate!.toIso8601String().substring(0, 10),
        'sesi'           : _selectedSesi,
        'jumlahPeserta'  : _jumlahPeserta,
        'catatan'        : _catatanCtrl.text.trim(),
        'status'         : 'pending',
        'createdAt'      : FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      setState(() {
        _bookingId    = bookingId;
        _step         = _Step.confirmed;
        _isSubmitting = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengirim booking: $e')),
      );
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _step == _Step.list,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goBack();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: _buildAppBar(),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: _buildBody(),
          ),
        ),
      ),
    );
  }

  // ── AppBar ─────────────────────────────────────────────────────────────────

  AppBar _buildAppBar() {
    final titles = {
      _Step.list     : 'Booking Fasilitas',
      _Step.detail   : _selected?.name ?? 'Detail Fasilitas',
      _Step.form     : 'Pilih Jadwal',
      _Step.confirmed: 'Booking Terkirim',
    };
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, size: 18),
        color: AppColors.textDark,
        onPressed: () {
          if (_step == _Step.list) {
            Navigator.pop(context);
          } else {
            _goBack();
          }
        },
      ),
      title: Text(
        titles[_step]!,
        style: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
      centerTitle: true,
      actions: const [SizedBox(width: 48)],
    );
  }

  // ── Body router ─────────────────────────────────────────────────────────────

  Widget _buildBody() {
    switch (_step) {
      case _Step.list:
        return _ListView(
          fasilitas: _kFasilitas,
          onSelect: _selectFasilitas,
        );
      case _Step.detail:
        return _DetailView(
          fasilitas: _selected!,
          onBook: _goToForm,
        );
      case _Step.form:
        return _FormView(
          fasilitas     : _selected!,
          dates         : _dates,
          selectedDate  : _selectedDate,
          selectedSesi  : _selectedSesi,
          jumlahPeserta : _jumlahPeserta,
          namaCtrl      : _namaCtrl,
          unitCtrl      : _unitCtrl,
          catatanCtrl   : _catatanCtrl,
          isSubmitting  : _isSubmitting,
          onDateSelect  : (d) => setState(() { _selectedDate = d; _selectedSesi = null; }),
          onSesiSelect  : (s) => setState(() => _selectedSesi = s),
          onPesertaChange: (v) => setState(() => _jumlahPeserta = v),
          onSubmit      : _submitBooking,
        );
      case _Step.confirmed:
        return _ConfirmedView(
          bookingId    : _bookingId,
          fasilitas    : _selected!,
          tanggal      : _formatDateFull(_selectedDate!),
          sesi         : _selectedSesi!,
          jumlahPeserta: _jumlahPeserta,
          namaUser     : _namaCtrl.text.trim(),
          blokUnit     : _unitCtrl.text.trim(),
          onReset      : _resetAll,
          onBack       : () => Navigator.pop(context),
        );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 1 — List fasilitas
// ─────────────────────────────────────────────────────────────────────────────

class _ListView extends StatelessWidget {
  const _ListView({required this.fasilitas, required this.onSelect});
  final List<_Fasilitas> fasilitas;
  final ValueChanged<_Fasilitas> onSelect;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pilih Fasilitas',
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark),
          ),
          const SizedBox(height: 4),
          Text(
            'Fasilitas tersedia untuk warga Jorena Residence',
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textGrey),
          ),
          const SizedBox(height: 16),
          ...fasilitas.map((f) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _FacilityCard(fasilitas: f, onSelect: onSelect),
          )),
        ],
      ),
    );
  }
}

class _FacilityCard extends StatelessWidget {
  const _FacilityCard({required this.fasilitas, required this.onSelect});
  final _Fasilitas fasilitas;
  final ValueChanged<_Fasilitas> onSelect;

  @override
  Widget build(BuildContext context) {
    final f = fasilitas;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header illustration
          Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              color: f.bgColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Stack(
              children: [
                Center(
                  child: Text(f.emoji, style: const TextStyle(fontSize: 60)),
                ),
                Positioned(
                  top: 10,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: f.accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: f.accentColor.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      f.jamOperasional,
                      style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: f.accentColor),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Info
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  f.name,
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
                const SizedBox(height: 4),
                Text(
                  f.description,
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textGrey, height: 1.5),
                ),
                const SizedBox(height: 12),

                // Capacity chip
                Row(
                  children: [
                    _InfoChip(
                      icon: Icons.people_outline,
                      label: 'Maks. ${f.kapasitas} orang',
                      color: f.accentColor,
                    ),
                    const SizedBox(width: 8),
                    _InfoChip(
                      icon: Icons.schedule_outlined,
                      label: f.jamOperasional,
                      color: f.accentColor,
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: () => onSelect(f),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: f.accentColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      'Booking Sekarang',
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold),
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

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label, required this.color});
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 2 — Detail fasilitas
// ─────────────────────────────────────────────────────────────────────────────

class _DetailView extends StatelessWidget {
  const _DetailView({required this.fasilitas, required this.onBook});
  final _Fasilitas fasilitas;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    final f = fasilitas;
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Illustration header ────────────────────────────────
                Container(
                  width: double.infinity,
                  height: 160,
                  decoration: BoxDecoration(
                    color: f.bgColor,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  margin: const EdgeInsets.only(top: 16, bottom: 16),
                  child: Center(
                    child: Text(f.emoji, style: const TextStyle(fontSize: 80)),
                  ),
                ),

                // ── Info chips ─────────────────────────────────────────
                Row(
                  children: [
                    _InfoChip(icon: Icons.people_outline,  label: 'Maks. ${f.kapasitas} orang', color: f.accentColor),
                    const SizedBox(width: 8),
                    _InfoChip(icon: Icons.schedule_outlined, label: f.jamOperasional,          color: f.accentColor),
                  ],
                ),
                const SizedBox(height: 14),

                // ── Description ────────────────────────────────────────
                Text(
                  f.description,
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.textGrey, height: 1.6),
                ),
                const SizedBox(height: 20),

                // ── Aturan penggunaan ──────────────────────────────────
                Text(
                  'Aturan Penggunaan',
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade100),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: f.aturan.map((rule) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(color: f.accentColor, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              rule,
                              style: GoogleFonts.inter(fontSize: 12, color: AppColors.textDark, height: 1.5),
                            ),
                          ),
                        ],
                      ),
                    )).toList(),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),

        // ── Sticky bottom button ───────────────────────────────────────
        Container(
          color: Colors.white,
          padding: EdgeInsets.fromLTRB(
            16, 12, 16, MediaQuery.of(context).padding.bottom + 12,
          ),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: onBook,
              style: ElevatedButton.styleFrom(
                backgroundColor: f.accentColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                'Pilih Jadwal',
                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 3 — Form jadwal & data
// ─────────────────────────────────────────────────────────────────────────────

class _FormView extends StatelessWidget {
  const _FormView({
    required this.fasilitas,
    required this.dates,
    required this.selectedDate,
    required this.selectedSesi,
    required this.jumlahPeserta,
    required this.namaCtrl,
    required this.unitCtrl,
    required this.catatanCtrl,
    required this.isSubmitting,
    required this.onDateSelect,
    required this.onSesiSelect,
    required this.onPesertaChange,
    required this.onSubmit,
  });

  final _Fasilitas fasilitas;
  final List<DateTime> dates;
  final DateTime? selectedDate;
  final String? selectedSesi;
  final int jumlahPeserta;
  final TextEditingController namaCtrl, unitCtrl, catatanCtrl;
  final bool isSubmitting;
  final ValueChanged<DateTime> onDateSelect;
  final ValueChanged<String> onSesiSelect;
  final ValueChanged<int> onPesertaChange;
  final VoidCallback onSubmit;

  Color get _accent => fasilitas.accentColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Pilih Tanggal ──────────────────────────────────────
                _SectionLabel('Pilih Tanggal'),
                const SizedBox(height: 8),
                SizedBox(
                  height: 72,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: dates.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final d        = dates[i];
                      final selected = selectedDate != null &&
                          selectedDate!.year  == d.year  &&
                          selectedDate!.month == d.month &&
                          selectedDate!.day   == d.day;
                      return GestureDetector(
                        onTap: () => onDateSelect(d),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 52,
                          decoration: BoxDecoration(
                            color: selected ? _accent : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selected ? _accent : Colors.grey.shade200,
                            ),
                            boxShadow: selected
                                ? [BoxShadow(color: _accent.withValues(alpha: 0.3), blurRadius: 6, offset: const Offset(0, 2))]
                                : [],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _dayAbbr(d),
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: selected ? Colors.white.withValues(alpha: 0.8) : AppColors.textGrey,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${d.day}',
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: selected ? Colors.white : AppColors.textDark,
                                ),
                              ),
                              Text(
                                _monthAbbr(d),
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: selected ? Colors.white.withValues(alpha: 0.8) : AppColors.textGrey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // ── Pilih Sesi ─────────────────────────────────────────
                _SectionLabel('Pilih Sesi'),
                const SizedBox(height: 8),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 3.2,
                  ),
                  itemCount: _kSesi.length,
                  itemBuilder: (_, i) {
                    final sesi     = _kSesi[i];
                    final selected = sesi == selectedSesi;
                    return GestureDetector(
                      onTap: () => onSesiSelect(sesi),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        decoration: BoxDecoration(
                          color: selected ? _accent : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selected ? _accent : Colors.grey.shade200,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            sesi,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: selected ? Colors.white : AppColors.textDark,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),

                // ── Jumlah Peserta ─────────────────────────────────────
                _SectionLabel('Jumlah Peserta'),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.people_outline, size: 20, color: AppColors.textGrey),
                      const SizedBox(width: 10),
                      Text(
                        'Peserta',
                        style: GoogleFonts.inter(fontSize: 13, color: AppColors.textDark),
                      ),
                      const Spacer(),
                      _QtyButton(
                        icon: Icons.remove,
                        color: _accent,
                        onTap: jumlahPeserta > 1
                            ? () => onPesertaChange(jumlahPeserta - 1)
                            : null,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          '$jumlahPeserta',
                          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
                        ),
                      ),
                      _QtyButton(
                        icon: Icons.add,
                        color: _accent,
                        onTap: jumlahPeserta < fasilitas.kapasitas
                            ? () => onPesertaChange(jumlahPeserta + 1)
                            : null,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 2),
                  child: Text(
                    'Kapasitas maksimum: ${fasilitas.kapasitas} orang',
                    style: GoogleFonts.inter(fontSize: 10, color: AppColors.textGrey),
                  ),
                ),
                const SizedBox(height: 20),

                // ── Data Pemesan ───────────────────────────────────────
                _SectionLabel('Data Pemesan'),
                const SizedBox(height: 8),
                _InputField(ctrl: namaCtrl,    label: 'Nama Lengkap',       icon: Icons.person_outline),
                const SizedBox(height: 10),
                _InputField(ctrl: unitCtrl,    label: 'Blok / Unit',        icon: Icons.home_outlined),
                const SizedBox(height: 10),
                _InputField(ctrl: catatanCtrl, label: 'Catatan (opsional)', icon: Icons.notes_outlined, maxLines: 2),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),

        // ── Sticky submit ──────────────────────────────────────────────
        Container(
          color: Colors.white,
          padding: EdgeInsets.fromLTRB(
            16, 12, 16, MediaQuery.of(context).padding.bottom + 12,
          ),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: isSubmitting ? null : onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                disabledBackgroundColor: Colors.grey.shade300,
              ),
              child: isSubmitting
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                  : Text('Kirim Permohonan', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ],
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({required this.icon, required this.color, this.onTap});
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: enabled ? color : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: enabled ? Colors.white : Colors.grey.shade400),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 4 — Confirmed
// ─────────────────────────────────────────────────────────────────────────────

class _ConfirmedView extends StatelessWidget {
  const _ConfirmedView({
    required this.bookingId,
    required this.fasilitas,
    required this.tanggal,
    required this.sesi,
    required this.jumlahPeserta,
    required this.namaUser,
    required this.blokUnit,
    required this.onReset,
    required this.onBack,
  });

  final String      bookingId;
  final _Fasilitas  fasilitas;
  final String      tanggal, sesi, namaUser, blokUnit;
  final int         jumlahPeserta;
  final VoidCallback onReset, onBack;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        24, 32, 24, MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        children: [
          // ── Success icon ─────────────────────────────────────────────
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 54),
          ),
          const SizedBox(height: 16),
          Text(
            'Permohonan Terkirim!',
            style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark),
          ),
          const SizedBox(height: 6),
          Text(
            'Menunggu persetujuan dari admin',
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textGrey),
          ),
          const SizedBox(height: 24),

          // ── Booking ID ───────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              color: fasilitas.bgColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Text('No. Booking', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textGrey)),
                const SizedBox(height: 4),
                Text(
                  bookingId,
                  style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: fasilitas.accentColor),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Status notice ────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.hourglass_top_rounded, color: Colors.orange.shade700, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Permohonan kamu sedang diproses oleh admin. Kamu akan mendapat notifikasi setelah disetujui atau ditolak.',
                    style: GoogleFonts.inter(fontSize: 12, color: Colors.orange.shade800, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Detail booking ───────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Detail Booking', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                const SizedBox(height: 12),
                _DetailRow(label: 'Fasilitas',   value: '${fasilitas.emoji}  ${fasilitas.name}'),
                _DetailRow(label: 'Tanggal',     value: tanggal),
                _DetailRow(label: 'Sesi',        value: sesi),
                _DetailRow(label: 'Peserta',     value: '$jumlahPeserta orang'),
                _DetailRow(label: 'Nama',        value: namaUser),
                _DetailRow(label: 'Blok / Unit', value: blokUnit, last: true),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // ── Buttons ──────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: onReset,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text('Booking Lagi', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: onBack,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.grey.shade300),
                foregroundColor: AppColors.textDark,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text('Kembali ke Layanan', style: GoogleFonts.inter(fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value, this.last = false});
  final String label, value;
  final bool last;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textGrey)),
          ),
          Expanded(
            child: Text(value, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark)),
          ),
        ],
      ),
      if (!last) const Divider(height: 14),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared small widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark),
  );
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.ctrl,
    required this.label,
    required this.icon,
    this.maxLines = 1,
  });

  final TextEditingController ctrl;
  final String label;
  final IconData icon;
  final int maxLines;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: ctrl,
    maxLines: maxLines,
    style: GoogleFonts.inter(fontSize: 14),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.textGrey),
      prefixIcon: Icon(icon, size: 20, color: AppColors.textGrey),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    ),
  );
}
