import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Header dialog form berita: judul + toggle "Draft Mode" + tombol close
// ─────────────────────────────────────────────────────────────────────────────

class BeritaFormHeader extends StatelessWidget {
  const BeritaFormHeader({
    super.key,
    required this.isEditMode,
    required this.isDraft,
    required this.onToggleDraft,
    required this.onClose,
  });
  final bool isEditMode;
  final bool isDraft;
  final VoidCallback onToggleDraft;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
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
                  isEditMode ? 'Edit Berita' : 'News Editor',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isEditMode
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
            onTap: onToggleDraft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isDraft ? Colors.amber.shade50 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDraft ? Colors.amber.shade300 : Colors.grey.shade300,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isDraft ? Icons.edit_note : Icons.edit_note_outlined,
                    size: 15,
                    color: isDraft ? Colors.amber.shade700 : AppColors.textGrey,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Draft Mode',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDraft ? Colors.amber.shade700 : AppColors.textGrey,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close, size: 20),
            color: AppColors.textGrey,
            splashRadius: 18,
          ),
        ],
      ),
    );
  }
}
