import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Dekorasi input bersama untuk semua field di form berita
// ─────────────────────────────────────────────────────────────────────────────

InputDecoration beritaInputDecoration(String hint) {
  return InputDecoration(
    hintText: hint,
    hintStyle: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade400),
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

// ─────────────────────────────────────────────────────────────────────────────
// Label kecil di atas tiap field
// ─────────────────────────────────────────────────────────────────────────────

class BeritaFormLabel extends StatelessWidget {
  const BeritaFormLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textDark,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Field Judul (Title)
// ─────────────────────────────────────────────────────────────────────────────

class BeritaJudulField extends StatelessWidget {
  const BeritaJudulField({super.key, required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const BeritaFormLabel('Judul (Title)'),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textDark),
          decoration: beritaInputDecoration('Enter headline...'),
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Judul wajib diisi' : null,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Field Penulis (Author)
// ─────────────────────────────────────────────────────────────────────────────

class BeritaPenulisField extends StatelessWidget {
  const BeritaPenulisField({super.key, required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const BeritaFormLabel('Penulis (Author)'),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textDark),
          decoration: beritaInputDecoration('Nama penulis').copyWith(
            prefixIcon: Icon(Icons.person_outline,
                size: 18, color: AppColors.textGrey),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dropdown Kategori (Category)
// ─────────────────────────────────────────────────────────────────────────────

class BeritaKategoriDropdown extends StatelessWidget {
  const BeritaKategoriDropdown({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
  });
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const BeritaFormLabel('Kategori (Category)'),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textDark),
          decoration: beritaInputDecoration(''),
          icon: const Icon(Icons.keyboard_arrow_down, size: 20),
          items: options
              .map((k) => DropdownMenuItem(
                    value: k,
                    child: Text(k, style: GoogleFonts.inter(fontSize: 13)),
                  ))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Editor Konten (Content) — toolbar dummy + textarea + hitung karakter
// ─────────────────────────────────────────────────────────────────────────────

class BeritaKontenEditor extends StatelessWidget {
  const BeritaKontenEditor({super.key, required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const BeritaFormLabel('Konten (Content)'),
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
                    _ToolbarBtn(Icons.format_bold, 'Bold'),
                    _ToolbarBtn(Icons.format_italic, 'Italic'),
                    _ToolbarBtn(Icons.format_list_bulleted, 'List'),
                    _ToolbarBtn(Icons.link, 'Link'),
                    _ToolbarBtn(Icons.image_outlined, 'Image'),
                  ],
                ),
              ),
              // Text area
              TextField(
                controller: controller,
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
              ),
              // Character count — dengar perubahan controller sendiri,
              // tidak perlu setState dari parent.
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: AnimatedBuilder(
                    animation: controller,
                    builder: (context, _) => Text(
                      'Character count: ${controller.text.length}',
                      style: GoogleFonts.inter(
                          fontSize: 11, color: Colors.grey.shade400),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ToolbarBtn extends StatelessWidget {
  const _ToolbarBtn(this.icon, this.tooltip);
  final IconData icon;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
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
}

// ─────────────────────────────────────────────────────────────────────────────
// Area upload thumbnail
// ─────────────────────────────────────────────────────────────────────────────

class BeritaUploadArea extends StatelessWidget {
  const BeritaUploadArea({
    super.key,
    required this.thumbnailBytes,
    required this.existingImageUrl,
    required this.onTap,
    required this.onRemove,
  });
  final Uint8List? thumbnailBytes;
  final String existingImageUrl;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final hasImage = thumbnailBytes != null || existingImageUrl.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
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
        child: !hasImage
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
                    child: thumbnailBytes != null
                        ? Image.memory(thumbnailBytes!, fit: BoxFit.cover)
                        : Image.network(existingImageUrl, fit: BoxFit.cover,
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
                      onTap: onRemove,
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
}
