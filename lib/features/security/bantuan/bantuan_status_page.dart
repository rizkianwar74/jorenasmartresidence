import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/data/bantuan_repository.dart';

class BantuanStatusPage extends StatefulWidget {
  const BantuanStatusPage({super.key, required this.requestId});

  final String requestId;

  @override
  State<BantuanStatusPage> createState() => _BantuanStatusPageState();
}

class _BantuanStatusPageState extends State<BantuanStatusPage>
    with SingleTickerProviderStateMixin {
  StreamSubscription<BantuanRequest?>? _sub;
  BantuanRequest? _request;
  bool _isCancelling = false;

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _sub = BantuanRepository.watchRequest(widget.requestId).listen((req) {
      if (!mounted) return;
      setState(() => _request = req);

      if (req?.status == BantuanStatus.resolved) {
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
        title: Text('Batalkan Laporan?',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Text(
          'Apakah Anda yakin ingin membatalkan laporan ini?',
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
    await BantuanRepository.cancelRequest(widget.requestId);
    if (mounted) Navigator.pop(context);
  }

  int get _stepIndex {
    switch (_request?.status) {
      case BantuanStatus.onMyWay:
        return 1;
      case BantuanStatus.resolved:
        return 2;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isResolved = _request?.status == BantuanStatus.resolved;
    final isCancelled = _request?.status == BantuanStatus.cancelled;

    return PopScope(
      canPop: isResolved || isCancelled,
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F4FF),
        body: SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              children: [
                // ── Top bar ────────────────────────────────────────────────
                Row(
                  children: [
                    if (isResolved)
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                        color: AppColors.textDark,
                      )
                    else
                      const SizedBox(width: 48),
                    const Spacer(),
                    Text(
                      'Laporan Bantuan',
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
                _buildCenterIcon(isResolved),

                const SizedBox(height: 28),

                // ── Status text ────────────────────────────────────────────
                Text(
                  _request?.statusLabel ?? 'Mengirim...',
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

                // ── Timeline ───────────────────────────────────────────────
                _buildTimeline(),

                const Spacer(),

                // ── Info laporan ───────────────────────────────────────────
                if (_request != null) _buildInfoCard(),

                const SizedBox(height: 20),

                // ── Tombol batal (hanya saat PENDING) ─────────────────────
                if (_request?.status == BantuanStatus.pending)
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
                              child: CircularProgressIndicator(
                                  strokeWidth: 2),
                            )
                          : Text(
                              'Batalkan Laporan',
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

  Widget _buildCenterIcon(bool isResolved) {
    if (isResolved) {
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

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (_, __) {
        final scale = 1.0 + (_pulseController.value * 0.15);
        return Stack(
          alignment: Alignment.center,
          children: [
            Transform.scale(
              scale: scale,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.1),
                ),
              ),
            ),
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.15),
              ),
            ),
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary,
              ),
              child: const Icon(Icons.support_agent_rounded,
                  size: 36, color: Colors.white),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTimeline() {
    final steps = [
      (label: 'Laporan Dikirim', icon: Icons.send_rounded),
      (label: 'Satpam Menuju Lokasi', icon: Icons.directions_walk_rounded),
      (label: 'Selesai', icon: Icons.check_circle_outline_rounded),
    ];

    return Column(
      children: List.generate(steps.length, (i) {
        final isDone = i < _stepIndex;
        final isActive = i == _stepIndex;
        final color = isDone || isActive ? AppColors.primary : Colors.grey.shade300;

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
                    color: isDone || isActive
                        ? color
                        : Colors.grey.shade200,
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
                  color: isActive
                      ? AppColors.textDark
                      : AppColors.textGrey,
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildInfoCard() {
    final req = _request!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.support_agent_rounded,
                    color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      req.kategori,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Blok ${req.blok} – Unit ${req.nomorUnit}',
                      style: GoogleFonts.inter(
                          fontSize: 13, color: AppColors.textGrey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (req.catatan.isNotEmpty) ...[
            const SizedBox(height: 12),
            Divider(height: 1, color: Colors.grey.shade100),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.notes_rounded,
                    size: 16, color: AppColors.textGrey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    req.catatan,
                    style: GoogleFonts.inter(
                        fontSize: 13, color: AppColors.textGrey),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _statusSubtitle() {
    switch (_request?.status) {
      case BantuanStatus.onMyWay:
        return 'Satpam sedang dalam perjalanan\nmenuju lokasi Anda.';
      case BantuanStatus.resolved:
        return 'Laporan telah ditangani.\nTerima kasih telah menggunakan layanan.';
      case BantuanStatus.cancelled:
        return 'Laporan dibatalkan.';
      default:
        return 'Laporan terkirim.\nSatpam akan segera merespons.';
    }
  }
}
