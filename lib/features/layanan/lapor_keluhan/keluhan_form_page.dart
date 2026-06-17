import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/keluhan_service.dart';
import 'lapor_keluhan_page.dart';

class KeluhanFormPage extends StatefulWidget {
  const KeluhanFormPage({super.key, required this.category});

  final KeluhanCategory category;

  @override
  State<KeluhanFormPage> createState() => _KeluhanFormPageState();
}

class _KeluhanFormPageState extends State<KeluhanFormPage> {
  final _formKey            = GlobalKey<FormState>();
  final _judulController    = TextEditingController();
  final _deskripsiController = TextEditingController();
  final _picker             = ImagePicker();

  // Uint8List agar kompatibel web & Android (tidak bergantung dart:io)
  final List<Uint8List> _selectedImages = [];

  bool _isLoading = false;
  static const _maxImages = 3;

  @override
  void dispose() {
    _judulController.dispose();
    _deskripsiController.dispose();
    super.dispose();
  }

  // ── Pilih foto dari galeri ────────────────────────────────────────────────
  Future<void> _pickImage() async {
    if (_selectedImages.length >= _maxImages) return;
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 1024,
      maxHeight: 1024,
    );
    if (image == null) return;
    final bytes = await image.readAsBytes();
    setState(() => _selectedImages.add(bytes));
  }

  void _removeImage(int index) =>
      setState(() => _selectedImages.removeAt(index));

  // ── Kirim ke Firestore via KeluhanService ─────────────────────────────────
  Future<void> _kirimLaporan() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final (result, fotoErrors) = await KeluhanService.sendKeluhan(
      kategori  : widget.category.title,
      judul     : _judulController.text.trim(),
      deskripsi : _deskripsiController.text.trim(),
      fotos     : _selectedImages,
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
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    // Sukses — kembali ke lapor_keluhan_page (2 pop)
    if (mounted) {
      Navigator.pop(context);   // keluhan_form_page
      Navigator.pop(context);   // kembali ke lapor_keluhan_page

      if (fotoErrors.isNotEmpty) {
        // Laporan terkirim tapi ada foto yang gagal
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Laporan terkirim, tapi ${fotoErrors.length} foto gagal diupload. '
                    'Pastikan koneksi stabil dan coba lagi.',
                    style: GoogleFonts.inter(fontSize: 13),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.orange.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 5),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Laporan berhasil dikirim. Tim kami akan segera menindaklanjuti.',
                    style: GoogleFonts.inter(fontSize: 13),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
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
        centerTitle: false,
        titleSpacing: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Info kategori ───────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(widget.category.icon,
                            color: AppColors.primary, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.category.description,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.primary,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Judul keluhan ───────────────────────────────────────
                  _FieldLabel('JUDUL KELUHAN'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _judulController,
                    style: _inputTextStyle(),
                    decoration:
                        _inputDecoration(hint: 'Ringkasan singkat masalah Anda'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty)
                            ? 'Judul tidak boleh kosong'
                            : null,
                  ),

                  const SizedBox(height: 20),

                  // ── Deskripsi ───────────────────────────────────────────
                  _FieldLabel('DESKRIPSI'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _deskripsiController,
                    maxLines: 4,
                    maxLength: 300,
                    style: _inputTextStyle(),
                    decoration: _inputDecoration(
                        hint: 'Jelaskan masalah secara detail...'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty)
                            ? 'Deskripsi tidak boleh kosong'
                            : null,
                  ),

                  const SizedBox(height: 20),

                  // ── Foto bukti ──────────────────────────────────────────
                  _FieldLabel('FOTO BUKTI (OPSIONAL)'),
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
                                  color: AppColors.primary.withValues(alpha: 0.4),
                                  width: 1.5,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate_outlined,
                                      color: AppColors.primary, size: 28),
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

                  const SizedBox(height: 32),

                  // ── Tombol kirim ────────────────────────────────────────
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

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  Widget _FieldLabel(String text) => Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.textGrey,
          letterSpacing: 0.8,
        ),
      );

  TextStyle _inputTextStyle() =>
      GoogleFonts.inter(fontSize: 14, color: AppColors.textDark);

  InputDecoration _inputDecoration({required String hint}) => InputDecoration(
        hintText: hint,
        hintStyle:
            GoogleFonts.inter(fontSize: 14, color: AppColors.textGrey),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
      );
}
