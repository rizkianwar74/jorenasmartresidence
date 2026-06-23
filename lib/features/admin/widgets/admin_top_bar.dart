import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../auth/auth_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AdminTopBar — reusable di semua halaman admin
//
// Cara pakai (tanpa action):
//   AdminTopBar(searchHint: 'Search...')
//
// Cara pakai (dengan tombol aksi):
//   AdminTopBar(
//     searchHint: 'Search residents...',
//     actionButton: ElevatedButton.icon(
//       onPressed: () {},
//       icon: const Icon(Icons.add),
//       label: const Text('Tambah Data'),
//     ),
//   )
// ─────────────────────────────────────────────────────────────────────────────

class AdminTopBar extends StatelessWidget {
  const AdminTopBar({
    super.key,
    required this.searchHint,
    this.actionButton,
    this.adminName = 'Admin Utama',
    this.adminRole = 'Super Admin',
  });

  final String searchHint;

  /// Widget opsional di sebelah kanan search bar (misal tombol "+ Tambah Data")
  final Widget? actionButton;

  final String adminName;
  final String adminRole;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          // ── Search bar ────────────────────────────────────────────────
          Expanded(
            child: Container(
              height: 40,
              constraints: const BoxConstraints(maxWidth: 480),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  Icon(Icons.search, size: 18, color: AppColors.textGrey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      searchHint,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textGrey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 16),

          // ── Action button (opsional) ──────────────────────────────────
          if (actionButton != null) ...[
            actionButton!,
            const SizedBox(width: 16),
          ],

          // ── Admin profile + dropdown ──────────────────────────────────
          PopupMenuButton<String>(
            offset: const Offset(0, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 8,
            color: Colors.white,
            onSelected: (value) async {
              if (value == 'logout') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    title: Text('Keluar',
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold)),
                    content: Text(
                      'Apakah Anda yakin ingin keluar dari akun admin?',
                      style: GoogleFonts.inter(fontSize: 14),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text('Batal',
                            style: GoogleFonts.inter(
                                color: AppColors.textGrey)),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text('Keluar',
                            style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await AuthRepository.logout();
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRouter.login,
                      (_) => false,
                    );
                  }
                }
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem<String>(
                enabled: false,
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      adminName,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      adminRole,
                      style: GoogleFonts.inter(
                          fontSize: 11, color: AppColors.textGrey),
                    ),
                    const SizedBox(height: 8),
                    Divider(height: 1, color: Colors.grey.shade200),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'logout',
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Icon(Icons.logout,
                        size: 17, color: Colors.red.shade600),
                    const SizedBox(width: 10),
                    Text(
                      'Keluar',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.red.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                  child: Text(
                    adminName.isNotEmpty ? adminName[0] : 'A',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      adminName,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      adminRole,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textGrey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 6),
                Icon(Icons.keyboard_arrow_down,
                    size: 16, color: AppColors.textGrey),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper: tombol "+ Tambah Data" yang dipakai di banyak halaman admin
// ─────────────────────────────────────────────────────────────────────────────

class AdminAddButton extends StatelessWidget {
  const AdminAddButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.add, size: 18, color: Colors.white),
      label: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
