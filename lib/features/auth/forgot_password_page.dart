import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../auth/auth_repository.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _isLoading = false;
  bool _isSuccess = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _onSend() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final error = await AuthRepository.resetPassword(_emailController.text);
    if (!mounted) return;

    setState(() => _isLoading = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error, style: GoogleFonts.inter(fontSize: 13)),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    setState(() => _isSuccess = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
              child: _isSuccess ? _buildSuccess() : _buildForm(),
            ),
          ),
        ),
      ),
    );
  }

  // ── Form state ──────────────────────────────────────────────────────────────

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.lock_reset_rounded,
              size: 32,
              color: AppColors.primary,
            ),
          ),

          const SizedBox(height: 24),

          Text(
            'Lupa Password?',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Masukkan email yang terdaftar. Kami akan mengirimkan\nlink untuk mengatur ulang password Anda.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textGrey,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 36),

          // Email label
          Text(
            'Email',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),

          const SizedBox(height: 8),

          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: GoogleFonts.inter(
                fontSize: 14, color: AppColors.textDark),
            decoration: InputDecoration(
              hintText: 'Masukkan email terdaftar',
              hintStyle: GoogleFonts.inter(
                  fontSize: 14, color: AppColors.textGrey),
              prefixIcon: const Icon(Icons.email_outlined,
                  color: AppColors.textGrey, size: 20),
              filled: true,
              fillColor: const Color(0xFFF6F7F8),
              contentPadding: const EdgeInsets.symmetric(
                  vertical: 16, horizontal: 16),
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
                borderSide: const BorderSide(
                    color: AppColors.primary, width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Colors.red, width: 1.5),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Colors.red, width: 1.5),
              ),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Email tidak boleh kosong';
              }
              if (!v.contains('@') || !v.contains('.')) {
                return 'Format email tidak valid';
              }
              return null;
            },
          ),

          const SizedBox(height: 28),

          // Kirim button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _onSend,
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
                          color: Colors.white, strokeWidth: 2.5),
                    )
                  : Text(
                      'KIRIM LINK RESET',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 24),

          // Kembali ke login
          Center(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: RichText(
                text: TextSpan(
                  style: GoogleFonts.inter(
                      fontSize: 14, color: AppColors.textGrey),
                  children: [
                    const TextSpan(text: 'Ingat password? '),
                    TextSpan(
                      text: 'Masuk',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Success state ───────────────────────────────────────────────────────────

  Widget _buildSuccess() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 32),

        // Checkmark circle
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            shape: BoxShape.circle,
            border: Border.all(
                color: const Color(0xFF16A34A).withOpacity(0.3), width: 2),
          ),
          child: const Icon(
            Icons.check_rounded,
            size: 40,
            color: Color(0xFF16A34A),
          ),
        ),

        const SizedBox(height: 28),

        Text(
          'Email Terkirim!',
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),

        const SizedBox(height: 12),

        Text(
          'Link reset password telah dikirim ke',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
              fontSize: 14, color: AppColors.textGrey, height: 1.5),
        ),

        const SizedBox(height: 4),

        Text(
          _emailController.text.trim(),
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          'Periksa folder Inbox atau Spam Anda.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
              fontSize: 13, color: AppColors.textGrey, height: 1.5),
        ),

        const SizedBox(height: 36),

        // Info box
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: const Color(0xFFF59E0B).withOpacity(0.4)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline_rounded,
                  size: 18, color: Color(0xFFD97706)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Link reset hanya berlaku selama 1 jam. Jika tidak menerima email, coba kirim ulang.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF92400E),
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // Kirim ulang
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _onSend,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5),
                  )
                : Text(
                    'KIRIM ULANG',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
          ),
        ),

        const SizedBox(height: 16),

        // Kembali ke login
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.grey.shade300),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'KEMBALI KE LOGIN',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
                letterSpacing: 1.1,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
