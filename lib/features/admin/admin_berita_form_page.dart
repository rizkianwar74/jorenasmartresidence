import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/onesignal_service.dart';
import 'data/admin_repository.dart';
import 'models/berita_doc.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Kategori options
// ─────────────────────────────────────────────────────────────────────────────

const _kategoriOptions = [
  'Fasilitas',
  'Keamanan',
  'Lingkungan',
  'Agenda',
  'Umum',
];

// ─────────────────────────────────────────────────────────────────────────────
// Show helper
// ─────────────────────────────────────────────────────────────────────────────

Future<void> showBeritaFormDialog(
  BuildContext context, {
  BeritaDoc? editDoc,
}) {
  return showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.4),
    builder: (_) => _BeritaFormDialog(editDoc: editDoc),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Dialog widget
// ─────────────────────────────────────────────────────────────────────────────

class _BeritaFormDialog extends StatefulWidget {
  const _BeritaFormDialog({this.editDoc});
  final BeritaDoc? editDoc;

  @override
  State<_BeritaFormDialog> createState() => _BeritaFormDialogState();
}

class _BeritaFormDialogState extends State<_BeritaFormDialog> {
  final _formKey     = GlobalKey<FormState>();
  late final TextEditingController _judulCtrl;
  late final TextEditingController _penulisCtrl;
  late final TextEditingController _kontenCtrl;

  late String _kategori;
  late bool   _isDraft;
  bool        _isLoading       = false;
  XFile?      _thumbnailFile;
  Uint8List?  _thumbnailBytes;
  String      _existingImageUrl = '';

  bool get _isEditMode => widget.editDoc != null;

  @override
  void initState() {
    super.initState();
    final doc = widget.editDoc;
    _judulCtrl   = TextEditingController(text: doc?.judul   ?? '');
    _penulisCtrl = TextEditingController(text: 'Admin Panel');
    _kontenCtrl  = TextEditingController(text: doc?.konten  ?? '');
    _kategori    = _normalizeKategori(doc?.kategori) ?? 'Fasilitas';
    _isDraft     = doc != null ? !doc.isPublished : false;
    _existingImageUrl = doc?.imageUrl ?? '';
  }

  String? _normalizeKategori(String? raw) {
    if (raw == null) return null;
    final lower = raw.toLowerCase();
    return _kategoriOptions.firstWhere(
      (k) => k.toLowerCase() == lower,
      orElse: () => 'Fasilitas',
    );
  }

  @override
  void dispose() {
    _judulCtrl.dispose();
    _penulisCtrl.dispose();
    _kontenCtrl.dispose();
    super.dispose();
  }

  Future<void> _onUploadThumbnail() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 60,   // kompres supaya ukuran kecil
      maxWidth: 800,
      maxHeight: 600,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() {
      _thumbnailFile  = picked;
      _thumbnailBytes = bytes;
    });
  }

  Future<void> _onSubmit({required bool asDraft}) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      // 1. Konversi gambar ke base64 data URL (disimpan langsung di Firestore)
      String imageUrl = _existingImageUrl;
      if (_thumbnailBytes != null) {
        final base64Str = base64Encode(_thumbnailBytes!);
        imageUrl = 'data:image/jpeg;base64,$base64Str';
      }

      // 2. Simpan/update lewat AdminRepository (akses Firestore terpusat)
      final repo = AdminRepository.instance;
      final data = {
        'judul'      : _judulCtrl.text.trim(),
        'kategori'   : _kategori.toLowerCase(),
        'konten'     : _kontenCtrl.text.trim(),
        'imageUrl'   : imageUrl,
        'isPublished': !asDraft,
        'publishedAt': FieldValue.serverTimestamp(),
      };

      if (_isEditMode) {
        await repo.updateBerita(widget.editDoc!.id, data);
      } else {
        await repo.createBerita({
          ...data,
          'authorUid': repo.currentAdminUid,
          'viewCount': 0,
        });
        // Notifikasi ke semua warga hanya saat publish (bukan draft).
        if (!asDraft) {
          OneSignalService.instance.sendBeritaBaru(
            judul: _judulCtrl.text.trim(),
          );
        }
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditMode
                  ? 'Berita berhasil diperbarui.'
                  : asDraft ? 'Draft berhasil disimpan.' : 'Berita berhasil diterbitkan.',
              style: GoogleFonts.inter(fontSize: 13),
            ),
            backgroundColor:
                asDraft ? Colors.orange.shade700 : Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan: $e',
                style: GoogleFonts.inter(fontSize: 13)),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 32,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header ───────────────────────────────────────────────────
              _buildHeader(),

              // ── Form body ────────────────────────────────────────────────
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24),

                        // Judul & Penulis (row)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildJudulField()),
                            const SizedBox(width: 16),
                            Expanded(child: _buildPenulisField()),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Kategori
                        _buildKategoriDropdown(),

                        const SizedBox(height: 16),

                        // Konten editor
                        _buildKontenEditor(),

                        const SizedBox(height: 16),

                        // Upload thumbnail
                        _buildUploadArea(),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Footer buttons ───────────────────────────────────────────
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 20, 20, 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade100),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEditMode ? 'Edit Berita' : 'News Editor',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _isEditMode
                      ? 'Perbarui konten berita yang sudah diterbitkan.'
                      : 'Create and broadcast community news to all residents.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textGrey,
                  ),
                ),
              ],
            ),
          ),
          // Draft Mode toggle
          GestureDetector(
            onTap: () => setState(() => _isDraft = !_isDraft),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _isDraft
                    ? Colors.amber.shade50
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _isDraft
                      ? Colors.amber.shade300
                      : Colors.grey.shade300,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isDraft ? Icons.edit_note : Icons.edit_note_outlined,
                    size: 15,
                    color: _isDraft
                        ? Colors.amber.shade700
                        : AppColors.textGrey,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Draft Mode',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _isDraft
                          ? Colors.amber.shade700
                          : AppColors.textGrey,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, size: 20),
            color: AppColors.textGrey,
            splashRadius: 18,
          ),
        ],
      ),
    );
  }

  // ── Judul field ───────────────────────────────────────────────────────────

  Widget _buildJudulField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Judul (Title)'),
        const SizedBox(height: 6),
        TextFormField(
          controller: _judulCtrl,
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textDark),
          decoration: _inputDecoration('Enter headline...'),
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Judul wajib diisi' : null,
        ),
      ],
    );
  }

  // ── Penulis field ─────────────────────────────────────────────────────────

  Widget _buildPenulisField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Penulis (Author)'),
        const SizedBox(height: 6),
        TextFormField(
          controller: _penulisCtrl,
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textDark),
          decoration: _inputDecoration('Nama penulis').copyWith(
            prefixIcon: Icon(Icons.person_outline,
                size: 18, color: AppColors.textGrey),
          ),
        ),
      ],
    );
  }

  // ── Kategori dropdown ─────────────────────────────────────────────────────

  Widget _buildKategoriDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Kategori (Category)'),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: _kategori,
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textDark),
          decoration: _inputDecoration(''),
          icon: const Icon(Icons.keyboard_arrow_down, size: 20),
          items: _kategoriOptions
              .map((k) => DropdownMenuItem(
                    value: k,
                    child: Text(k, style: GoogleFonts.inter(fontSize: 13)),
                  ))
              .toList(),
          onChanged: (v) {
            if (v != null) setState(() => _kategori = v);
          },
        ),
      ],
    );
  }

  // ── Konten editor ─────────────────────────────────────────────────────────

  Widget _buildKontenEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Konten (Content)'),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Toolbar
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200),
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(8),
                  ),
                ),
                child: Row(
                  children: [
                    _toolbarBtn(Icons.format_bold,      'Bold'),
                    _toolbarBtn(Icons.format_italic,    'Italic'),
                    _toolbarBtn(Icons.format_list_bulleted, 'List'),
                    _toolbarBtn(Icons.link,             'Link'),
                    _toolbarBtn(Icons.image_outlined,   'Image'),
                  ],
                ),
              ),
              // Text area
              TextField(
                controller: _kontenCtrl,
                minLines: 6,
                maxLines: 10,
                style: GoogleFonts.inter(
                    fontSize: 13, color: AppColors.textDark, height: 1.6),
                decoration: InputDecoration(
                  hintText: 'Write news content here...',
                  hintStyle: GoogleFonts.inter(
                      fontSize: 13, color: Colors.grey.shade400),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(14),
                ),
                onChanged: (_) => setState(() {}),
              ),
              // Character count
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Character count: ${_kontenCtrl.text.length}',
                    style: GoogleFonts.inter(
                        fontSize: 11, color: Colors.grey.shade400),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _toolbarBtn(IconData icon, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Icon(icon, size: 18, color: AppColors.textGrey),
        ),
      ),
    );
  }

  // ── Upload area ───────────────────────────────────────────────────────────

  Widget _buildUploadArea() {
    return GestureDetector(
      onTap: _onUploadThumbnail,
      child: Container(
        height: 110,
        decoration: BoxDecoration(
          color: const Color(0xFFF0F4FF),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: const Color(0xFFBFCFFF),
            style: BorderStyle.solid,
            width: 1.5,
          ),
        ),
        child: _thumbnailBytes == null && _existingImageUrl.isEmpty
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_upload_outlined,
                      size: 32, color: AppColors.primary),
                  const SizedBox(height: 8),
                  Text(
                    'Upload Thumbnail Image',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'SVG, PNG, JPG (max. 5MB). High quality recommended for community dashboard.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                        fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              )
            : Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: _thumbnailBytes != null
                        ? Image.memory(_thumbnailBytes!, fit: BoxFit.cover)
                        : Image.network(_existingImageUrl, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.grey.shade200,
                              child: Icon(Icons.image_not_supported_outlined,
                                  color: Colors.grey.shade400),
                            )),
                  ),
                  // Overlay tombol ganti
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _thumbnailFile    = null;
                        _thumbnailBytes   = null;
                        _existingImageUrl = '';
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Ganti',
                          style: GoogleFonts.inter(
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ── Footer ────────────────────────────────────────────────────────────────

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 16, 28, 20),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Cancel
          OutlinedButton(
            onPressed:
                _isLoading ? null : () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.grey.shade300),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                  fontSize: 13, color: AppColors.textDark),
            ),
          ),
          const SizedBox(width: 12),
          // Terbitkan Berita
          ElevatedButton.icon(
            onPressed:
                _isLoading ? null : () => _onSubmit(asDraft: _isDraft),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              elevation: 0,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            icon: _isLoading
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.send, size: 15, color: Colors.white),
            label: Text(
              _isEditMode ? 'Simpan Perubahan' : (_isDraft ? 'Simpan Draft' : 'Terbitkan Berita'),
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _label(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textDark,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle:
          GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade400),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.primary),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.red),
      ),
      filled: true,
      fillColor: Colors.white,
    );
  }
}
