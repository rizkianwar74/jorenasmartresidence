import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/router/app_router.dart';
import '../../core/utils/responsive_helper.dart';
import '../auth/auth_repository.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final _namaController        = TextEditingController();
  final _usernameController    = TextEditingController();
  final _passwordController    = TextEditingController();
  final _tanggalController     = TextEditingController();
  final _blokController        = TextEditingController();
  final _nomorController       = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _namaController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _tanggalController.dispose();
    _blokController.dispose();
    _nomorController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 20),
      firstDate: DateTime(1950),
      lastDate: DateTime(now.year - 10),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      _tanggalController.text =
          '${picked.day.toString().padLeft(2, '0')} / '
          '${picked.month.toString().padLeft(2, '0')} / '
          '${picked.year}';
    }
  }

  Future<void> _onDaftar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;
    setState(() => _isLoading = false);

    final error = AuthRepository.register(
      username: _usernameController.text,
      password: _passwordController.text,
      namaLengkap: _namaController.text,
      blok: _blokController.text,
      nomorUnit: _nomorController.text,
      tanggalLahir: _tanggalController.text,
    );

    if (!mounted) return;

    if (error != null) {
      // Gagal — tampilkan pesan error (misal username sudah dipakai)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error, style: GoogleFonts.inter(fontSize: 13)),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } else {
      // Berhasil — arahkan ke login
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Akun berhasil dibuat! Silakan masuk.',
            style: GoogleFonts.inter(fontSize: 13),
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
      Navigator.pushReplacementNamed(context, AppRouter.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTabletOrDesktop = !Responsive.isMobile(context);
    final horizontalPadding = isTabletOrDesktop ? 40.0 : 24.0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          color: AppColors.textDark,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'EstateFlow',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: 8,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Judul ---
                  Text(
                    'Daftar Akun Baru',
                    style: GoogleFonts.inter(
                      fontSize: isTabletOrDesktop ? 28 : 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Lengkapi data diri Anda',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.textGrey,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // --- Nama Lengkap ---
                  _FieldLabel('NAMA LENGKAP'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _namaController,
                    hint: 'Masukkan nama lengkap',
                    keyboardType: TextInputType.name,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Nama tidak boleh kosong'
                        : null,
                  ),

                  const SizedBox(height: 20),

                  // --- Username ---
                  _FieldLabel('USERNAME'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _usernameController,
                    hint: 'Pilih nama pengguna',
                    keyboardType: TextInputType.text,
                    inputFormatters: [
                      FilteringTextInputFormatter.deny(RegExp(r'\s')),
                    ],
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Username tidak boleh kosong';
                      }
                      if (v.trim().length < 3) {
                        return 'Username minimal 3 karakter';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  // --- Password ---
                  _FieldLabel('PASSWORD'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: _inputTextStyle(),
                    decoration: _inputDecoration(
                      hint: 'Buat kata sandi',
                      suffix: GestureDetector(
                        onTap: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                        child: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: AppColors.textGrey,
                          size: 20,
                        ),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'Password tidak boleh kosong';
                      }
                      if (v.length < 6) {
                        return 'Password minimal 6 karakter';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  // --- Tanggal Lahir ---
                  _FieldLabel('TANGGAL LAHIR'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _tanggalController,
                    readOnly: true,
                    onTap: _pickDate,
                    style: _inputTextStyle(),
                    decoration: _inputDecoration(
                      hint: 'DD / MM / YYYY',
                      suffix: const Icon(
                        Icons.calendar_month_outlined,
                        color: AppColors.textGrey,
                        size: 20,
                      ),
                    ),
                    validator: (v) => (v == null || v.isEmpty)
                        ? 'Tanggal lahir tidak boleh kosong'
                        : null,
                  ),

                  const SizedBox(height: 20),

                  // --- Alamat Rumah (Blok + Nomor) ---
                  _FieldLabel('ALAMAT RUMAH'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        flex: isTabletOrDesktop ? 2 : 3,
                        child: _buildTextField(
                          controller: _blokController,
                          hint: 'Blok',
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Wajib diisi'
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: isTabletOrDesktop ? 2 : 2,
                        child: _buildTextField(
                          controller: _nomorController,
                          hint: 'Nomor',
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Wajib diisi'
                              : null,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 36),

                  // --- Tombol Daftar ---
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _onDaftar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        disabledBackgroundColor:
                            AppColors.primary.withOpacity(0.6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Text(
                              'DAFTAR SEKARANG',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // --- Link Masuk ---
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Sudah punya akun? ',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.textGrey,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pushReplacementNamed(
                            context,
                            AppRouter.login,
                          ),
                          child: Text(
                            'Masuk',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // --- Ilustrasi gedung ---
                  Center(
                    child: SizedBox(
                      height: isTabletOrDesktop ? 180 : 140,
                      child: Image.asset(
                        'assets/images/building_illustration.png',
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.apartment_rounded,
                          size: isTabletOrDesktop ? 100 : 80,
                          color: Colors.grey.shade200,
                        ),
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

  // ── Helper builders ─────────────────────────────

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: _inputTextStyle(),
      decoration: _inputDecoration(hint: hint),
      validator: validator,
    );
  }

  TextStyle _inputTextStyle() => GoogleFonts.inter(
        fontSize: 14,
        color: AppColors.textDark,
      );

  InputDecoration _inputDecoration({required String hint, Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(fontSize: 14, color: AppColors.textGrey),
      suffixIcon: suffix != null
          ? Padding(
              padding: const EdgeInsets.only(right: 12),
              child: suffix,
            )
          : null,
      suffixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      filled: true,
      fillColor: const Color(0xFFF6F7F8),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
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
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
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
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.textGrey,
        letterSpacing: 0.8,
      ),
    );
  }
}