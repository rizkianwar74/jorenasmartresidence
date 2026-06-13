import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_colors.dart';
import '../auth/auth_repository.dart';

class PengaturanPage extends StatefulWidget {
  const PengaturanPage({super.key});

  @override
  State<PengaturanPage> createState() => _PengaturanPageState();
}

class _PengaturanPageState extends State<PengaturanPage> {
  static const double _contentMaxWidth = 600.0;

  // Local state — sinkron dengan AuthRepository.currentUser saat init
  late String _username;
  late String _nomorHp;
  late String _tanggalLahir;
  late String _blok;
  late String _nomorUnit;

  @override
  void initState() {
    super.initState();
    final user   = AuthRepository.currentUser;
    _username    = user?.username     ?? '-';
    _nomorHp     = user?.nomorHp      ?? '-';
    _tanggalLahir = user?.tanggalLahir ?? '-';
    _blok        = user?.blok         ?? '-';
    _nomorUnit   = user?.nomorUnit    ?? '-';
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      _SettingItem(
        icon : Icons.person_outline,
        label: 'Username',
        value: _username,
        onTap: () => _showEditDialog(
          context,
          title        : 'Ganti Username',
          fieldLabel   : 'Username baru',
          currentValue : _username == '-' ? '' : _username,
          onSave       : (val) => _saveField('username', val,
              () => setState(() => _username = val.trim())),
        ),
      ),
      _SettingItem(
        icon : Icons.lock_outline,
        label: 'Password',
        value: '••••••••',
        onTap: () => _showPasswordDialog(context),
      ),
      _SettingItem(
        icon : Icons.phone_outlined,
        label: 'No. HP',
        value: _nomorHp,
        onTap: () => _showEditDialog(
          context,
          title        : 'Ganti Nomor HP',
          fieldLabel   : 'Nomor HP baru',
          currentValue : _nomorHp == '-' ? '' : _nomorHp,
          keyboardType : TextInputType.phone,
          onSave       : (val) => _saveField('nomorHp', val,
              () => setState(() => _nomorHp = val.trim())),
        ),
      ),
      _SettingItem(
        icon : Icons.cake_outlined,
        label: 'Tanggal Lahir',
        value: _tanggalLahir,
        onTap: () => _showEditDialog(
          context,
          title        : 'Ganti Tanggal Lahir',
          fieldLabel   : 'Tanggal lahir (cth: 01/01/1990)',
          currentValue : _tanggalLahir == '-' ? '' : _tanggalLahir,
          onSave       : (val) => _saveField('tanggalLahir', val,
              () => setState(() => _tanggalLahir = val.trim())),
        ),
      ),
      _SettingItem(
        icon : Icons.location_on_outlined,
        label: 'Alamat',
        value: _blok == '-' && _nomorUnit == '-'
            ? '-'
            : 'Blok $_blok – No. $_nomorUnit',
        onTap: () => _showAlamatDialog(context),
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F7F8),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Pengaturan Akun',
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
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            children: [
              Text(
                'Informasi Akun',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textGrey,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: List.generate(items.length, (i) {
                    final isLast = i == items.length - 1;
                    return Column(
                      children: [
                        items[i],
                        if (!isLast)
                          Divider(
                            height: 1,
                            color: Colors.grey.shade100,
                            indent: 56,
                            endIndent: 20,
                          ),
                      ],
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Simpan field ke Firestore + update in-memory + update local state ─────
  Future<void> _saveField(
      String field, String value, VoidCallback onSuccess) async {
    try {
      await AuthRepository.updateProfile(field, value);
      onSuccess();
      if (mounted) _showSnack(context, 'Berhasil diperbarui', success: true);
    } catch (e) {
      if (mounted) _showSnack(context, 'Gagal memperbarui: $e');
    }
  }

  // ── Dialog edit field teks biasa ─────────────────────────────────────────
  void _showEditDialog(
    BuildContext context, {
    required String title,
    required String fieldLabel,
    required String currentValue,
    required Future<void> Function(String) onSave,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final ctrl    = TextEditingController(text: currentValue);
    final formKey = GlobalKey<FormState>();
    bool  saving  = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: Text(title,
              style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold, fontSize: 17)),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller  : ctrl,
              keyboardType: keyboardType,
              autofocus   : true,
              style: GoogleFonts.inter(fontSize: 14),
              decoration: InputDecoration(
                labelText: fieldLabel,
                labelStyle: GoogleFonts.inter(
                    fontSize: 13, color: AppColors.textGrey),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                      color: AppColors.primary, width: 1.5),
                ),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Tidak boleh kosong' : null,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Batal',
                  style: GoogleFonts.inter(color: AppColors.textGrey)),
            ),
            ElevatedButton(
              onPressed: saving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setLocal(() => saving = true);
                      await onSave(ctrl.text);
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : Text('Simpan', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Dialog ubah alamat (blok + nomor unit) ───────────────────────────────
  void _showAlamatDialog(BuildContext context) {
    final blokCtrl  = TextEditingController(
        text: _blok == '-' ? '' : _blok);
    final nomorCtrl = TextEditingController(
        text: _nomorUnit == '-' ? '' : _nomorUnit);
    final formKey   = GlobalKey<FormState>();
    bool  saving    = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: Text('Ubah Alamat',
              style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold, fontSize: 17)),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: blokCtrl,
                  autofocus : true,
                  style     : GoogleFonts.inter(fontSize: 14),
                  decoration: InputDecoration(
                    labelText : 'Blok',
                    labelStyle: GoogleFonts.inter(
                        fontSize: 13, color: AppColors.textGrey),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                          color: AppColors.primary, width: 1.5),
                    ),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Blok tidak boleh kosong'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller  : nomorCtrl,
                  keyboardType: TextInputType.number,
                  style       : GoogleFonts.inter(fontSize: 14),
                  decoration  : InputDecoration(
                    labelText : 'Nomor Unit',
                    labelStyle: GoogleFonts.inter(
                        fontSize: 13, color: AppColors.textGrey),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                          color: AppColors.primary, width: 1.5),
                    ),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Nomor unit tidak boleh kosong'
                      : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Batal',
                  style: GoogleFonts.inter(color: AppColors.textGrey)),
            ),
            ElevatedButton(
              onPressed: saving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setLocal(() => saving = true);
                      try {
                        final b = blokCtrl.text.trim();
                        final n = nomorCtrl.text.trim();
                        await AuthRepository.updateAlamat(b, n);
                        setState(() { _blok = b; _nomorUnit = n; });
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          _showSnack(context, 'Alamat berhasil diperbarui',
                              success: true);
                        }
                      } catch (e) {
                        setLocal(() => saving = false);
                        if (ctx.mounted) {
                          _showSnack(context, 'Gagal memperbarui: $e');
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : Text('Simpan',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Dialog ganti password ─────────────────────────────────────────────────
  void _showPasswordDialog(BuildContext context) {
    final oldCtrl  = TextEditingController();
    final newCtrl  = TextEditingController();
    final confCtrl = TextEditingController();
    final formKey  = GlobalKey<FormState>();
    bool  saving   = false;
    bool  showOld  = false;
    bool  showNew  = false;
    bool  showConf = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: Text('Ganti Password',
              style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold, fontSize: 17)),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _PwField(
                  ctrl      : oldCtrl,
                  label     : 'Password lama',
                  show      : showOld,
                  onToggle  : () => setLocal(() => showOld = !showOld),
                  validator : (v) => v == null || v.isEmpty
                      ? 'Wajib diisi'
                      : null,
                ),
                const SizedBox(height: 12),
                _PwField(
                  ctrl      : newCtrl,
                  label     : 'Password baru',
                  show      : showNew,
                  onToggle  : () => setLocal(() => showNew = !showNew),
                  validator : (v) {
                    if (v == null || v.isEmpty) return 'Wajib diisi';
                    if (v.length < 6) return 'Minimal 6 karakter';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _PwField(
                  ctrl      : confCtrl,
                  label     : 'Konfirmasi password baru',
                  show      : showConf,
                  onToggle  : () => setLocal(() => showConf = !showConf),
                  validator : (v) => v != newCtrl.text
                      ? 'Password tidak cocok'
                      : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Batal',
                  style: GoogleFonts.inter(color: AppColors.textGrey)),
            ),
            ElevatedButton(
              onPressed: saving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setLocal(() => saving = true);
                      try {
                        final authUser =
                            FirebaseAuth.instance.currentUser!;
                        // Re-autentikasi dengan password lama
                        final cred = EmailAuthProvider.credential(
                          email   : authUser.email!,
                          password: oldCtrl.text,
                        );
                        await authUser.reauthenticateWithCredential(cred);
                        await authUser.updatePassword(newCtrl.text);
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          _showSnack(context, 'Password berhasil diubah',
                              success: true);
                        }
                      } on FirebaseAuthException catch (e) {
                        setLocal(() => saving = false);
                        if (ctx.mounted) {
                          String msg = 'Gagal mengubah password';
                          if (e.code == 'wrong-password' ||
                              e.code == 'invalid-credential') {
                            msg = 'Password lama tidak sesuai';
                          }
                          _showSnack(context, msg);
                        }
                      } catch (e) {
                        setLocal(() => saving = false);
                        if (ctx.mounted) {
                          _showSnack(context, 'Terjadi kesalahan: $e');
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : Text('Simpan',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnack(BuildContext context, String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.inter(fontSize: 13)),
        backgroundColor:
            success ? const Color(0xFF16A34A) : Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

// ── Row item pengaturan ───────────────────────────────────────────────────────

class _SettingItem extends StatelessWidget {
  const _SettingItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String   label;
  final String   value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textGrey,
                        fontWeight: FontWeight.w500,
                      )),
                  const SizedBox(height: 2),
                  Text(value,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      )),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: Color(0xFFB0BEC5), size: 20),
          ],
        ),
      ),
    );
  }
}

// ── Field password dengan toggle show/hide ────────────────────────────────────

class _PwField extends StatelessWidget {
  const _PwField({
    required this.ctrl,
    required this.label,
    required this.show,
    required this.onToggle,
    required this.validator,
  });

  final TextEditingController ctrl;
  final String                label;
  final bool                  show;
  final VoidCallback          onToggle;
  final String? Function(String?) validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller    : ctrl,
      obscureText   : !show,
      style         : GoogleFonts.inter(fontSize: 14),
      validator     : validator,
      decoration: InputDecoration(
        labelText : label,
        labelStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.textGrey),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            show ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            size: 20,
            color: AppColors.textGrey,
          ),
          onPressed: onToggle,
        ),
      ),
    );
  }
}
