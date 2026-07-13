import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/data/sos_repository.dart';

class SosStatusPage extends StatefulWidget {
  const SosStatusPage({super.key, required this.alertId, required this.type});

  final String alertId;
  final SosType type;

  @override
  State<SosStatusPage> createState() => _SosStatusPageState();
}

class _SosStatusPageState extends State<SosStatusPage>
    with SingleTickerProviderStateMixin {
  StreamSubscription<SosAlert?>? _sub;
  SosAlert? _alert;
  bool _isCancelling = false;

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _sub = SosRepository.watchAlert(widget.alertId).listen((alert) {
      if (!mounted) return;
      setState(() => _alert = alert);

      // Auto pop setelah 2 detik jika sudah resolved
      if (alert?.status == SosStatus.resolved) {
        _pulseController.stop();
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.pop(context);
        });
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _onCancel() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text('Batalkan Panggilan?',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Text(
          'Apakah Anda yakin ingin membatalkan panggilan ini?',
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textGrey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Tidak',
                style: GoogleFonts.inter(color: AppColors.textGrey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Ya, Batalkan',
                style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isCancelling = true);
    await SosRepository.cancelAlert(widget.alertId);
    if (mounted) Navigator.pop(context);
  }

  // ── Step index dari status ────────────────────────────────────────────────
  int get _stepIndex {
    switch (_alert?.status) {
      case SosStatus.onMyWay:
        return 1;
      case SosStatus.resolved:
        return 2;
      default:
        return 0;
    }
  }

  bool get _isSos => widget.type == SosType.sos;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _alert?.status == SosStatus.resolved ||
          _alert?.status == SosStatus.cancelled,
      child: Scaffold(
        backgroundColor:
            _isSos ? const Color(0xFFFFF5F5) : const Color(0xFFF0F4FF),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              children: [
                // ── Top bar ────────────────────────────────────────────────
                Row(
                  children: [
                    if (_alert?.status == SosStatus.resolved)
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                        color: AppColors.textDark,
                      )
                    else
                      const SizedBox(width: 48),
                    const Spacer(),
                    Text(
                      _isSos ? 'SOS Darurat' : 'Panggil Satpam',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 48),
                  ],
                ),

                const SizedBox(height: 32),

                // ── Animasi pulse / resolved icon ──────────────────────────
                _buildCenterIcon(),

                const SizedBox(height: 28),

                // ── Status text ────────────────────────────────────────────
                Text(
                  _alert?.statusLabel ?? 'Menghubungi...',
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  _statusSubtitle(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textGrey,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 36),

                // ── Timeline steps ─────────────────────────────────────────
                _buildTimeline(),

                const Spacer(),

                // ── Info warga ─────────────────────────────────────────────
                if (_alert != null) _buildInfoCard(),

                const SizedBox(height: 20),

                // ── Tombol batal (hanya saat PENDING) ─────────────────────
                if (_alert?.status == SosStatus.pending)
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      onPressed: _isCancelling ? null : _onCancel,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isCancelling
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              'Batalkan Panggilan',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textGrey,
                              ),
                            ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCenterIcon() {
    if (_alert?.status == SosStatus.resolved) {
      return Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4),
          shape: BoxShape.circle,
          border: Border.all(
              color: const Color(0xFF16A34A).withValues(alpha: 0.3), width: 2),
        ),
        child: const Icon(Icons.check_rounded,
            size: 52, color: Color(0xFF16A34A)),
      );
    }

    final baseColor = _isSos ? Colors.red : AppColors.primary;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (_, __) {
        final scale = 1.0 + (_pulseController.value * 0.15);
        return Stack(
          alignment: Alignment.center,
          children: [
            // Pulse ring luar
            Transform.scale(
              scale: scale,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: baseColor.withValues(alpha: 0.1),
                ),
              ),
            ),
            // Pulse ring tengah
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: baseColor.withValues(alpha: 0.15),
              ),
            ),
            // Icon utama
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: baseColor,
              ),
              child: Icon(
                _isSos
                    ? Icons.warning_rounded
                    : Icons.support_agent_rounded,
                size: 36,
                color: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTimeline() {
    final steps = [
      (label: 'Menunggu Respon', icon: Icons.access_time_rounded),
      (label: 'Satpam Menuju Lokasi', icon: Icons.directions_walk_rounded),
      (label: 'Selesai', icon: Icons.check_circle_outline_rounded),
    ];

    return Column(
      children: List.generate(steps.length, (i) {
        final isDone = i < _stepIndex;
        final isActive = i == _stepIndex;
        final color = isDone || isActive
            ? (_isSos ? Colors.red.shade700 : AppColors.primary)
            : Colors.grey.shade300;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDone || isActive ? color : Colors.grey.shade200,
                  ),
                  child: Icon(
                    isDone ? Icons.check_rounded : steps[i].icon,
                    size: 16,
                    color: isDone || isActive ? Colors.white : Colors.grey,
                  ),
                ),
                if (i < steps.length - 1)
                  Container(
                    width: 2,
                    height: 28,
                    color: isDone ? color : Colors.grey.shade200,
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                steps[i].label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight:
                      isActive ? FontWeight.w600 : FontWeight.w400,
                  color: isActive ? AppColors.textDark : AppColors.textGrey,
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.location_on_outlined,
                color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _alert!.namaWarga,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Blok ${_alert!.blok} – Unit ${_alert!.nomorUnit}',
                  style: GoogleFonts.inter(
                      fontSize: 13, color: AppColors.textGrey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _statusSubtitle() {
    switch (_alert?.status) {
      case SosStatus.onMyWay:
        return 'Satpam sedang dalam perjalanan\nmenuju lokasi Anda.';
      case SosStatus.resolved:
        return 'Panggilan telah ditangani.\nTerima kasih telah menggunakan layanan.';
      case SosStatus.cancelled:
        return 'Panggilan dibatalkan.';
      default:
        return _isSos
            ? 'Permintaan darurat dikirim.\nSatpam akan segera merespons.'
            : 'Permintaan bantuan dikirim.\nSatpam akan segera merespons.';
    }
  }
}
