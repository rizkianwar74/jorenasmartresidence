import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../auth/auth_repository.dart';

class SatpamCatatTamuPage extends StatefulWidget {
  const SatpamCatatTamuPage({super.key});

  @override
  State<SatpamCatatTamuPage> createState() => _SatpamCatatTamuPageState();
}

class _SatpamCatatTamuPageState extends State<SatpamCatatTamuPage> {
  static const double _contentMaxWidth = 600.0;

  // Controllers
  final _namaController       = TextEditingController();
  final _platController       = TextEditingController();
  final _keteranganController = TextEditingController();
  final _blokController       = TextEditingController();
  final _nomorRumahController = TextEditingController();

  // State
  String _jenisKendaraan    = 'Mobil';
  String? _kategoriKunjungan;
  bool   _saving            = false;

  static const _jenisOptions    = ['Mobil', 'Motor', 'Lainnya'];
  static const _kategoriOptions = [
    'Keluarga / Kerabat',
    'Teman',
    'Kurir / Delivery',
    'Tamu Bisnis',
    'Teknisi / Servis',
    'Lainnya',
  ];

  @override
  void dispose() {
    _namaController.dispose();
    _platController.dispose();
    _keteranganController.dispose();
    _blokController.dispose();
    _nomorRumahController.dispose();
    super.dispose();
  }

  // ── Validasi ─────────────────────────────────────────────────────────────
  String? _validate() {
    if (_namaController.text.trim().isEmpty)       return 'Nama tamu wajib diisi';
    if (_kategoriKunjungan == null)                return 'Kategori kunjungan wajib dipilih';
    if (_blokController.text.trim().isEmpty)       return 'Blok tujuan wajib diisi';
    if (_nomorRumahController.text.trim().isEmpty) return 'Nomor rumah tujuan wajib diisi';
    return null;
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.inter(fontSize: 13)),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ── Simpan ke Firestore ───────────────────────────────────────────────────
  Future<void> _simpan() async {
    final err = _validate();
    if (err != null) { _showError(err); return; }
    if (_saving) return;

    setState(() => _saving = true);

    try {
      final uid        = FirebaseAuth.instance.currentUser?.uid ?? '';
      final appUser    = AuthRepository.currentUser;
      final namaSatpam = appUser?.namaLengkap.isNotEmpty == true
          ? appUser!.namaLengkap
          : (FirebaseAuth.instance.currentUser?.displayName ?? 'Satpam');

      await FirebaseFirestore.instance.collection('catatantamu').add({
        'namaTamu'          : _namaController.text.trim(),
        'jenisKendaraan'    : _jenisKendaraan,
        'nomorPlat'         : _platController.text.trim().toUpperCase(),
        'kategoriKunjungan' : _kategoriKunjungan,
        'keterangan'        : _keteranganController.text.trim(),
        'blokTujuan'        : _blokController.text.trim().toUpperCase(),
        'nomorRumahTujuan'  : _nomorRumahController.text.trim(),
        'satpamUid'         : uid,
        'namaSatpam'        : namaSatpam,
        'status'            : 'MASUK',
        'waktuMasuk'        : FieldValue.serverTimestamp(),
        'waktuKeluar'       : null,
        'createdAt'         : FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Data tamu berhasil dicatat',
            style: GoogleFonts.inter(fontSize: 13),
          ),
          backgroundColor: const Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        _showError('Gagal menyimpan: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          color: const Color(0xFF0D1B2A),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Catat Tamu',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0D1B2A),
          ),
        ),
      ),
      body: Column(
        children: [
          Divider(height: 1, color: Colors.grey.shade200),

          // ── Scrollable form ──────────────────────────────────────────
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
                  child: Column(
                    children: [
                      // ── Section 1: Informasi Tamu ──────────────────
                      _FormSection(
                        icon: Icons.person_outline,
                        title: 'INFORMASI TAMU',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _FieldLabel(label: 'Nama Lengkap Tamu'),
                            const SizedBox(height: 6),
                            _StyledTextField(
                              controller: _namaController,
                              hint: 'Contoh: Budi Santoso',
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // ── Section 2: Detail Kendaraan ────────────────
                      _FormSection(
                        icon: Icons.directions_car_outlined,
                        title: 'DETAIL KENDARAAN',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _FieldLabel(label: 'Jenis Kendaraan'),
                            const SizedBox(height: 8),

                            // Toggle segmented
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.all(4),
                              child: Row(
                                children: _jenisOptions.map((opt) {
                                  final isActive = _jenisKendaraan == opt;
                                  return Expanded(
                                    child: GestureDetector(
                                      onTap: () => setState(
                                          () => _jenisKendaraan = opt),
                                      child: AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 150),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 10),
                                        decoration: BoxDecoration(
                                          color: isActive
                                              ? Colors.white
                                              : Colors.transparent,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          boxShadow: isActive
                                              ? [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withOpacity(0.08),
                                                    blurRadius: 6,
                                                    offset:
                                                        const Offset(0, 2),
                                                  )
                                                ]
                                              : null,
                                        ),
                                        child: Text(
                                          opt,
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            fontWeight: isActive
                                                ? FontWeight.bold
                                                : FontWeight.w500,
                                            color: isActive
                                                ? AppColors.primary
                                                : const Color(0xFF64748B),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),

                            const SizedBox(height: 14),
                            _FieldLabel(label: 'Nomor Plat Kendaraan'),
                            const SizedBox(height: 6),
                            _StyledTextField(
                              controller: _platController,
                              hint: 'B 1234 ABC',
                              textCapitalization:
                                  TextCapitalization.characters,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // ── Section 3: Tujuan Kunjungan ────────────────
                      _FormSection(
                        icon: Icons.assignment_outlined,
                        title: 'TUJUAN KUNJUNGAN',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _FieldLabel(label: 'Kategori Kunjungan'),
                            const SizedBox(height: 6),

                            // Dropdown
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: AppColors.primary.withOpacity(0.4)),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 2),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _kategoriKunjungan,
                                  isExpanded: true,
                                  hint: Text(
                                    'Pilih kategori...',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: const Color(0xFFB0BEC5),
                                    ),
                                  ),
                                  icon: const Icon(Icons.keyboard_arrow_down,
                                      color: Color(0xFF64748B)),
                                  items: _kategoriOptions
                                      .map((k) => DropdownMenuItem(
                                            value: k,
                                            child: Text(
                                              k,
                                              style: GoogleFonts.inter(
                                                  fontSize: 14,
                                                  color: const Color(
                                                      0xFF0D1B2A)),
                                            ),
                                          ))
                                      .toList(),
                                  onChanged: (v) =>
                                      setState(() => _kategoriKunjungan = v),
                                ),
                              ),
                            ),

                            const SizedBox(height: 14),
                            _FieldLabel(label: 'Keterangan Tambahan'),
                            const SizedBox(height: 6),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: AppColors.primary.withOpacity(0.4)),
                              ),
                              child: TextField(
                                controller: _keteranganController,
                                maxLines: 3,
                                style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: const Color(0xFF0D1B2A)),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.all(12),
                                  hintText:
                                      'Masukkan detail tambahan jika ada...',
                                  hintStyle: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: const Color(0xFFB0BEC5),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // ── Section 4: Tujuan Rumah ────────────────────
                      _FormSection(
                        icon: Icons.home_outlined,
                        title: 'TUJUAN RUMAH',
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _FieldLabel(label: 'Blok'),
                                  const SizedBox(height: 6),
                                  _StyledTextField(
                                    controller: _blokController,
                                    hint: 'Ex: A1',
                                    textCapitalization:
                                        TextCapitalization.characters,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _FieldLabel(label: 'Nomor Rumah'),
                                  const SizedBox(height: 6),
                                  _StyledTextField(
                                    controller: _nomorRumahController,
                                    hint: 'Ex: 08',
                                    keyboardType: TextInputType.number,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),

      // ── Bottom Buttons (fixed) ─────────────────────────────────────
      bottomNavigationBar: SafeArea(
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              // Simpan & Beri Akses
              Expanded(
                flex: 3,
                child: ElevatedButton(
                  onPressed: _saving ? null : _simpan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.primary.withOpacity(0.6),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.how_to_reg_outlined,
                                color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Simpan & Beri Akses',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(width: 12),
              // Batal
              Expanded(
                flex: 2,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Batal',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
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
// Section card dengan background biru muda
// ─────────────────────────────────────────────────────────────────────────────
class _FormSection extends StatelessWidget {
  const _FormSection({
    required this.icon,
    required this.title,
    required this.child,
  });
  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Label field
// ─────────────────────────────────────────────────────────────────────────────
class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: const Color(0xFF0D1B2A),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TextField dengan border primary
// ─────────────────────────────────────────────────────────────────────────────
class _StyledTextField extends StatelessWidget {
  const _StyledTextField({
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.words,
  });
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withOpacity(0.5)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        style: GoogleFonts.inter(
            fontSize: 14, color: const Color(0xFF0D1B2A)),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
          hintText: hint,
          hintStyle: GoogleFonts.inter(
            fontSize: 14,
            color: const Color(0xFFB0BEC5),
          ),
        ),
      ),
    );
  }
}
