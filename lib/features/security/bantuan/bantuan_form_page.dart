import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/data/bantuan_repository.dart';
import '../../../core/router/app_router.dart';
import 'bantuan_satpam_page.dart';

class BantuanFormPage extends StatefulWidget {
  const BantuanFormPage({super.key, required this.category});

  final BantuanCategory category;

  @override
  State<BantuanFormPage> createState() => _BantuanFormPageState();
}

class _BantuanFormPageState extends State<BantuanFormPage> {
  final _catatanController = TextEditingController();
  final _picker = ImagePicker();

  // Simpan sebagai Uint8List agar kompatibel web & Android (tidak pakai dart:io)
  final List<Uint8List> _selectedImages = [];
  bool _isLoading = false;
  String _lokasi = 'Memuat...';

  static const _maxImages = 3;

  @override
  void initState() {
    super.initState();
    _loadLokasi();
  }

  Future<void> _loadLokasi() async {
    final lokasi = await BantuanRepository.getUserLokasi();
    if (mounted) setState(() => _lokasi = lokasi);
  }

  Future<void> _pickImage() async {
    if (_selectedImages.length >= _maxImages) return;
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 60,
      maxWidth: 800,
      maxHeight: 600,
    );
    if (image == null) return;
    final bytes = await image.readAsBytes();
    setState(() => _selectedImages.add(bytes));
  }

  void _removeImage(int index) =>
      setState(() => _selectedImages.removeAt(index));

  @override
  void dispose() {
    _catatanController.dispose();
    super.dispose();
  }

  Future<void> _kirimLaporan() async {
    setState(() => _isLoading = true);

    final result = await BantuanRepository.sendRequest(
      kategori: widget.category.title,
      catatan: _catatanController.text.trim(),
      fotos: _selectedImages,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal mengirim laporan. Coba lagi.',
            style: GoogleFonts.inter(fontSize: 13),
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    // Sukses — kembali ke home, status tampil di sana sebagai kartu
    if (mounted) {
      Navigator.popUntil(
        context,
        ModalRoute.withName(AppRouter.home),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F7F8),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          color: AppColors.textDark,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.category.title,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Info kategori ─────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(widget.category.icon,
                            color: AppColors.primary, size: 26),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.category.title,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.category.subtitle,
                            style: GoogleFonts.inter(
                                fontSize: 13, color: AppColors.textGrey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── Lokasi (otomatis dari profil) ─────────────────────────
                _sectionLabel('LOKASI'),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          color: AppColors.primary, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _lokasi,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.textDark,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        'Otomatis',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: AppColors.textGrey),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Catatan ───────────────────────────────────────────────
                _sectionLabel('CATATAN (OPSIONAL)'),
                const SizedBox(height: 8),
                TextField(
                  controller: _catatanController,
                  maxLines: 4,
                  maxLength: 200,
                  style: GoogleFonts.inter(
                      fontSize: 14, color: AppColors.textDark),
                  decoration: InputDecoration(
                    hintText: 'Jelaskan situasi secara singkat...',
                    hintStyle: GoogleFonts.inter(
                        fontSize: 14, color: AppColors.textGrey),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.all(16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: Colors.grey.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: AppColors.primary, width: 1.5),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ── Upload foto bukti ─────────────────────────────────────
                _sectionLabel('TAMBAH FOTO BUKTI (OPSIONAL)'),
                const SizedBox(height: 8),
                SizedBox(
                  height: 100,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      if (_selectedImages.length < _maxImages)
                        GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            width: 100,
                            height: 100,
                            margin: const EdgeInsets.only(right: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color:
                                    AppColors.primary.withValues(alpha: 0.4),
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate_outlined,
                                  color: AppColors.primary,
                                  size: 28,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Tambah foto',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ..._selectedImages.asMap().entries.map((e) {
                        return Stack(
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              margin: const EdgeInsets.only(right: 10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                image: DecorationImage(
                                  image: MemoryImage(e.value),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 14,
                              child: GestureDetector(
                                onTap: () => _removeImage(e.key),
                                child: Container(
                                  width: 22,
                                  height: 22,
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close,
                                      color: Colors.white, size: 14),
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Maksimal $_maxImages foto',
                  style: GoogleFonts.inter(
                      fontSize: 11, color: AppColors.textGrey),
                ),

                const SizedBox(height: 16),

                // ── Estimasi respons ──────────────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.access_time_rounded,
                          color: AppColors.primary, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Estimasi respons satpam: 3–5 menit',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // ── Tombol kirim ──────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _kirimLaporan,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      disabledBackgroundColor:
                          AppColors.primary.withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.send_rounded, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'Kirim Laporan',
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
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
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.textGrey,
          letterSpacing: 0.8,
        ),
      );
}
