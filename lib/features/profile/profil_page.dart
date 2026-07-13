// lib/features/profile/profil_page.dart
// Update:
// - Semua data (nama, email, blok, unit, role) dari AuthRepository
// - Badge role dinamis (PEMILIK UNIT / SATPAM / ADMINISTRATOR)
// - Avatar dari initial nama jika tidak ada foto
// - Tombol Keluar aktif dengan konfirmasi dialog + navigate ke login

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../core/router/app_router.dart';
import '../auth/data/auth_repository.dart';
import 'widgets/profile_avatar.dart';
import 'widgets/unit_info_card.dart';
import 'widgets/personal_info_card.dart';
import 'widgets/profile_menu_item.dart';

class ProfilPage extends StatefulWidget {
  const ProfilPage({super.key});

  @override
  State<ProfilPage> createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage> {
  static const double _contentMaxWidth = 600.0;
  bool       _uploadingPhoto = false;
  Uint8List? _photoBytes;        // preview lokal sebelum tersimpan

  // ── Pilih foto → readAsBytes → encode base64 → simpan ke Firestore ───────
  Future<void> _pickAndUpload(ImageSource source) async {
    Navigator.pop(context);

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source      : source,
      imageQuality: 60,
      maxWidth    : 600,
    );
    if (picked == null) return;

    // Baca bytes — cara yang sama seperti upload thumbnail berita
    final bytes = await picked.readAsBytes();

    setState(() {
      _photoBytes    = bytes;
      _uploadingPhoto = true;
    });

    try {
      final base64Str = base64Encode(bytes);
      final dataUri   = 'data:image/jpeg;base64,$base64Str';
      await AuthRepository.updatePhotoUrl(dataUri);
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        // Batalkan preview lokal jika gagal simpan
        setState(() => _photoBytes = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan foto: $e',
                style: GoogleFonts.inter(fontSize: 13)),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _deletePhoto() async {
    Navigator.pop(context); // tutup bottom sheet

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Hapus Foto Profil?',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Text(
          'Foto profil akan dihapus dan diganti dengan inisial nama.',
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.textGrey, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal', style: GoogleFonts.inter(color: AppColors.textGrey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Hapus',
                style: GoogleFonts.inter(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() { _uploadingPhoto = true; _photoBytes = null; });
    try {
      await AuthRepository.removePhotoUrl();
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus foto: $e',
                style: GoogleFonts.inter(fontSize: 13)),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  void _showPickerSheet() {
    final hasPhoto = AuthRepository.currentUser?.photoUrl?.isNotEmpty == true
        || _photoBytes != null;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: Text('Ambil dari Kamera',
                    style: GoogleFonts.inter(fontSize: 15)),
                onTap: () => _pickAndUpload(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text('Pilih dari Galeri',
                    style: GoogleFonts.inter(fontSize: 15)),
                onTap: () => _pickAndUpload(ImageSource.gallery),
              ),
              if (hasPhoto)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: Text('Hapus Foto',
                      style: GoogleFonts.inter(fontSize: 15, color: Colors.red)),
                  onTap: _deletePhoto,
                ),
            ],
          ),
        ),
      ),
    );
  }

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
    final user         = AuthRepository.currentUser;
    final namaLengkap  = user?.namaLengkap   ?? 'Pengguna';
    final blok         = user?.blok           ?? '-';
    final nomorUnit    = user?.nomorUnit      ?? '-';
    final role         = user?.role           ?? UserRole.user;
    final email        = user?.email          ?? '-';
    final nomorHp      = user?.nomorHp        ?? '-';
    final tanggalLahir = user?.tanggalLahir   ?? '-';

    // Info card — email, no telepon, tanggal lahir
    final infoItems = [
      PersonalInfoItem(
        icon : Icons.email_outlined,
        label: 'Email',
        value: email.isEmpty || email == '-' ? 'Belum diisi' : email,
      ),
      PersonalInfoItem(
        icon : Icons.phone_outlined,
        label: 'No. Telepon',
        value: nomorHp.isEmpty || nomorHp == '-' ? 'Belum diisi' : nomorHp,
      ),
      PersonalInfoItem(
        icon : Icons.cake_outlined,
        label: 'Tanggal Lahir',
        value: tanggalLahir.isEmpty || tanggalLahir == '-' ? 'Belum diisi' : tanggalLahir,
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

                // ── Avatar ────────────────────────────────────────────
                Stack(
                  alignment: Alignment.center,
                  children: [
                    ProfileAvatar(
                      imageUrl : _photoBytes != null
                          ? 'data:image/jpeg;base64,${base64Encode(_photoBytes!)}'
                          : AuthRepository.currentUser?.photoUrl,
                      name     : namaLengkap,
                      onEditTap: _uploadingPhoto ? null : _showPickerSheet,
                    ),
                    if (_uploadingPhoto)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.4),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          ),
                        ),
                      ),
                  ],
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
                  isLast: true,
                  // Tunggu halaman Pengaturan ditutup, lalu setState supaya
                  // build() di atas membaca ulang AuthRepository.currentUser
                  // yang terbaru (mis. nama/no HP/alamat baru saja diganti).
                  // Tanpa ini, ProfilPage tetap menampilkan data lama karena
                  // Navigator.pop() tidak otomatis me-rebuild halaman di
                  // bawahnya.
                  onTap: () async {
                    await Navigator.pushNamed(context, AppRouter.pengaturan);
                    if (mounted) setState(() {});
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