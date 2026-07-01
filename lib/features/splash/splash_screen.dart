import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/router/app_router.dart';
import '../auth/auth_repository.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Animasi logo: fade + scale naik
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  // Animasi tagline: fade muncul setelah logo
  late Animation<double> _taglineFade;

  // Animasi loading dots di bawah
  late Animation<double> _dotsFade;

  @override
  void initState() {
    super.initState();

    // Sembunyikan status bar agar full screen
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _scaleAnim = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );

    _taglineFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.75, curve: Curves.easeOut),
      ),
    );

    _dotsFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.65, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.forward();

    // Cek sesi Firebase Auth + navigasi setelah minimal 3 detik splash
    Future.wait([
      Future.delayed(const Duration(milliseconds: 3000)),
      AuthRepository.tryRestoreSession(),
    ]).then((results) {
      if (!mounted) return;

      // Kembalikan status bar sebelum pindah halaman
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

      final sessionRestored = results[1] as bool;
      Navigator.pushReplacementNamed(
        context,
        // Sesi valid → langsung ke home (router handle redirect per role)
        // Sesi tidak ada/expired → ke login
        sessionRestored ? AppRouter.home : AppRouter.login,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Konten tengah: logo + tagline
            Expanded(
              child: Center(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (_, __) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo
                        FadeTransition(
                          opacity: _fadeAnim,
                          child: ScaleTransition(
                            scale: _scaleAnim,
                            child: Image.asset(
                              'assets/images/jorena_logo.jpg',
                              width: 220,
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Tagline
                        FadeTransition(
                          opacity: _taglineFade,
                          child: Column(
                            children: [
                              Text(
                                'Smart Residence',
                                style: GoogleFonts.inter(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF0D141B),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Kelola hunian Anda dengan mudah',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: const Color(0xFF94A3B8),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),

            // Loading indicator + versi di bawah
            AnimatedBuilder(
              animation: _dotsFade,
              builder: (_, __) {
                return Opacity(
                  opacity: _dotsFade.value,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 48),
                    child: Column(
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: const Color(0xFF1173D4),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'SMART RESIDENCE V1.0.0',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: const Color(0xFF94A3B8),
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}