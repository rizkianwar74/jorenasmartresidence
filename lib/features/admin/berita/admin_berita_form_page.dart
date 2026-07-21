import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/onesignal_service.dart';
import '../data/admin_repository.dart';
import '../../berita/models/berita_doc.dart';
import 'widgets/berita_form_header.dart';
import 'widgets/berita_form_fields.dart';
import 'widgets/berita_form_footer.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Dialog Tambah/Edit Berita.
//
// Field-field form (judul, penulis, kategori, konten, upload thumbnail) dan
// header/footer dialog dipecah ke folder widgets/ agar file ini fokus pada
// state management & logika submit saja.
// ─────────────────────────────────────────────────────────────────────────────

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
        final beritaId = await repo.createBerita({
          ...data,
          'authorUid': repo.currentAdminUid,
          'viewCount': 0,
        });
        // Notifikasi ke semua warga hanya saat publish (bukan draft).
        // Server juga memeriksa ulang isPublished sebelum menyiarkan.
        if (!asDraft) {
          OneSignalService.instance.sendBeritaBaru(docId: beritaId);
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
              BeritaFormHeader(
                isEditMode: _isEditMode,
                isDraft: _isDraft,
                onToggleDraft: () => setState(() => _isDraft = !_isDraft),
                onClose: () => Navigator.pop(context),
              ),

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
                            Expanded(
                                child: BeritaJudulField(
                                    controller: _judulCtrl)),
                            const SizedBox(width: 16),
                            Expanded(
                                child: BeritaPenulisField(
                                    controller: _penulisCtrl)),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Kategori
                        BeritaKategoriDropdown(
                          value: _kategori,
                          options: _kategoriOptions,
                          onChanged: (v) => setState(() => _kategori = v),
                        ),

                        const SizedBox(height: 16),

                        // Konten editor
                        BeritaKontenEditor(controller: _kontenCtrl),

                        const SizedBox(height: 16),

                        // Upload thumbnail
                        BeritaUploadArea(
                          thumbnailBytes: _thumbnailBytes,
                          existingImageUrl: _existingImageUrl,
                          onTap: _onUploadThumbnail,
                          onRemove: () => setState(() {
                            _thumbnailFile    = null;
                            _thumbnailBytes   = null;
                            _existingImageUrl = '';
                          }),
                        ),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Footer buttons ───────────────────────────────────────────
              BeritaFormFooter(
                isEditMode: _isEditMode,
                isDraft: _isDraft,
                isLoading: _isLoading,
                onCancel: () => Navigator.pop(context),
                onSubmit: () => _onSubmit(asDraft: _isDraft),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
