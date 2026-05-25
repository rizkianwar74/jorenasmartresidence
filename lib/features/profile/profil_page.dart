import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/router/app_router.dart';
import 'widgets/profile_avatar.dart';
import 'widgets/unit_info_card.dart';
import 'widgets/personal_info_card.dart';
import 'widgets/profile_menu_item.dart';

class ProfilPage extends StatelessWidget {
  const ProfilPage({super.key});

  static const double _contentMaxWidth = 600.0;

  static const _infoItems = [
    PersonalInfoItem(
      icon: Icons.email_outlined,
      value: 'alex.pratama@email.com',
      label: 'Email',
    ),
    PersonalInfoItem(
      icon: Icons.smartphone_outlined,
      value: '+62 812 3456 7890',
      label: 'Nomor HP',
    ),
    PersonalInfoItem(
      icon: Icons.badge_outlined,
      value: 'SR-9921042',
      label: 'ID Pelanggan',
    ),
  ];

  @override
  Widget build(BuildContext context) {
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

                // --- Avatar ---
                ProfileAvatar(
                  imageUrl: 'https://i.pravatar.cc/200?img=8',
                  onEditTap: () {
                    // TODO: ganti foto profil
                  },
                ),

                const SizedBox(height: 16),

                // --- Nama ---
                Text(
                  'Alex Pratama',
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),

                const SizedBox(height: 8),

                // --- Badge role ---
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'PEMILIK UNIT',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // --- Kartu Blok/Unit ---
                const UnitInfoCard(
                  blockName: 'Blok A',
                  unitNumber: 'No. 42',
                ),

                const SizedBox(height: 28),

                // --- Informasi Pribadi ---
                const PersonalInfoCard(items: _infoItems),

                const SizedBox(height: 28),

                // --- Menu ---
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

                // --- Tombol Keluar ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // TODO: logout
                    },
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

                // --- Footer versi ---
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