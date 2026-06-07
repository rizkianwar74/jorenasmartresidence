// lib/features/profile/profil_page.dart
// Update:
// - Semua data (nama, email, blok, unit, role) dari AuthRepository
// - Badge role dinamis (PEMILIK UNIT / SATPAM / ADMINISTRATOR)
// - Avatar dari initial nama jika tidak ada foto
// - Tombol Keluar aktif dengan konfirmasi dialog + navigate ke login

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/router/app_router.dart';
import '../auth/auth_repository.dart';
import 'widgets/profile_avatar.dart';
import 'widgets/unit_info_card.dart';
import 'widgets/personal_info_card.dart';
import 'widgets/profile_menu_item.dart';

class ProfilPage extends StatelessWidget {
  const ProfilPage({super.key});

  static const double _contentMaxWidth = 600.0;

  // ── Label & warna badge per role ────────────────────────────────────────
  String _roleLabel(UserRole role) => switch (role) {
        UserRole.admin   => 'ADMINISTRATOR',
        UserRole.satpam  => 'PETUGAS KEAMANAN',
        UserRole.user    => 'PEMILIK UNIT',
      };

  Color _roleBgColor(UserRole role) => switch (role) {
        UserRole.admin   => Colors.amber.shade50,
        UserRole.satpam  => Colors.teal.shade50,
        UserRole.user    => AppColors.primaryLight,
      };

  Color _roleTextColor(UserRole role) => switch (role) {
        UserRole.admin   => Colors.amber.shade800,
        UserRole.satpam  => Colors.teal.shade700,
        UserRole.user    => AppColors.primary,
      };

  // ── Avatar URL dari inisial nama ────────────────────────────────────────
  String _avatarUrl(String nama) {
    final encoded = Uri.encodeComponent(nama);
    return 'https://ui-avatars.com/api/?name=$encoded&background=1173D4&color=fff&size=200';
  }

  // ── Konfirmasi logout ────────────────────────────────────────────────────
  Future<void> _onLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Keluar dari Akun?',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Anda akan keluar dan perlu login kembali untuk mengakses aplikasi.',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.textGrey,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Batal',
              style: GoogleFonts.inter(color: AppColors.textGrey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Keluar',
              style: GoogleFonts.inter(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AuthRepository.logout();
      if (context.mounted) {
        // Kembali ke login, hapus semua route sebelumnya
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRouter.login,
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ambil data dari AuthRepository — sudah terisi saat login
    final user = AuthRepository.currentUser;
    final namaLengkap = user?.namaLengkap ?? 'Pengguna';
    final email       = user?.username ?? '-';
    final blok        = user?.blok ?? '-';
    final nomorUnit   = user?.nomorUnit ?? '-';
    final role        = user?.role ?? UserRole.user;

    // Info card — dinamis dari data user
    final infoItems = [
      PersonalInfoItem(
        icon: Icons.email_outlined,
        value: email,
        label: 'Email',
      ),
      PersonalInfoItem(
        icon: Icons.apartment_outlined,
        value: blok.isEmpty || blok == '-' ? 'Belum diisi' : blok,
        label: 'Blok',
      ),
      PersonalInfoItem(
        icon: Icons.door_front_door_outlined,
        value: nomorUnit.isEmpty || nomorUnit == '-' ? 'Belum diisi' : 'No. $nomorUnit',
        label: 'Nomor Unit',
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F7F8),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back_ios_new, size: 20),
        ),
        title: Text(
          'Profil Saya',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 40),
            child: Column(
              children: [
                const SizedBox(height: 24),

                // ── Avatar dari inisial nama ───────────────────────────
                ProfileAvatar(
                  imageUrl: _avatarUrl(namaLengkap),
                  onEditTap: () {
                    // TODO: ganti foto profil
                  },
                ),

                const SizedBox(height: 16),

                // ── Nama dari database ─────────────────────────────────
                Text(
                  namaLengkap,
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                // ── Badge role dinamis ─────────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _roleBgColor(role),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _roleLabel(role),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _roleTextColor(role),
                      letterSpacing: 0.8,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Kartu Blok/Unit — dari database ───────────────────
                UnitInfoCard(
                  blockName: blok == '-' || blok.isEmpty ? '-' : blok,
                  unitNumber: nomorUnit == '-' || nomorUnit.isEmpty ? '-' : nomorUnit,
                ),

                const SizedBox(height: 28),

                // ── Informasi Pribadi — dari database ─────────────────
                PersonalInfoCard(items: infoItems),

                const SizedBox(height: 28),

                // ── Menu ──────────────────────────────────────────────
                ProfileMenuItem(
                  icon: Icons.settings_outlined,
                  label: 'Pengaturan Akun',
                  isFirst: true,
                  onTap: () {
                    // TODO: navigasi ke pengaturan akun
                  },
                ),
                ProfileMenuItem(
                  icon: Icons.security_outlined,
                  label: 'Keamanan & Privasi',
                  isLast: true,
                  onTap: () {
                    // TODO: navigasi ke keamanan & privasi
                  },
                ),

                const SizedBox(height: 28),

                // ── Tombol Keluar — aktif dengan konfirmasi ───────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: OutlinedButton.icon(
                    onPressed: () => _onLogout(context),
                    icon: const Icon(
                      Icons.logout_rounded,
                      color: Colors.red,
                      size: 20,
                    ),
                    label: Text(
                      'Keluar',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.red,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                      side: const BorderSide(color: Colors.red, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Footer versi ───────────────────────────────────────
                Text(
                  'SMART RESIDENCE V2.4.1',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textGrey,
                    letterSpacing: 0.6,
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}