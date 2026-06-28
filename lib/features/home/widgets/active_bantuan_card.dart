import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/bantuan_service.dart';

class ActiveBantuanCard extends StatelessWidget {
  const ActiveBantuanCard({
    super.key,
    required this.request,
    required this.onCancel,
  });

  final BantuanRequest request;
  final VoidCallback onCancel;

  Color get _statusColor {
    switch (request.status) {
      case BantuanStatus.onMyWay:
        return const Color(0xFF0284C7); // biru
      default:
        return AppColors.primary;
    }
  }

  IconData get _statusIcon {
    switch (request.status) {
      case BantuanStatus.onMyWay:
        return Icons.directions_walk_rounded;
      default:
        return Icons.access_time_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _statusColor.withValues(alpha: 0.25), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _statusColor.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Header kartu ─────────────────────────────────────────────────
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: _statusColor.withValues(alpha: 0.07),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Icon(_statusIcon, size: 16, color: _statusColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    request.statusLabel,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _statusColor,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                // Tombol batal hanya saat PENDING
                if (request.status == BantuanStatus.pending)
                  GestureDetector(
                    onTap: onCancel,
                    child: Text(
                      'Batalkan',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.red.shade600,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── Body ─────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.support_agent_rounded,
                      color: _statusColor, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.kategori,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Blok ${request.blok} – Unit ${request.nomorUnit}',
                        style: GoogleFonts.inter(
                            fontSize: 13, color: AppColors.textGrey),
                      ),
                      if (request.catatan.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          request.catatan,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                              fontSize: 12, color: AppColors.textGrey),
                        ),
                      ],
                    ],
                  ),
                ),
                if (request.status == BantuanStatus.pending)
                  PulseDot(color: _statusColor),
              ],
            ),
          ),

          // ── Progress bar steps ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: MiniTimeline(status: request.status),
          ),
        ],
      ),
    );
  }
}

class PulseDot extends StatefulWidget {
  const PulseDot({super.key, required this.color});
  final Color color;

  @override
  State<PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<PulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color.withValues(alpha: 0.4 + 0.6 * _ctrl.value),
        ),
      ),
    );
  }
}

class MiniTimeline extends StatelessWidget {
  const MiniTimeline({super.key, required this.status});
  final BantuanStatus status;

  @override
  Widget build(BuildContext context) {
    final steps = ['Terkirim', 'Menuju Lokasi', 'Selesai'];
    final activeIndex = status == BantuanStatus.onMyWay ? 1 : 0;

    return Row(
      children: List.generate(steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          final lineIndex = i ~/ 2;
          final filled = lineIndex < activeIndex;
          return Expanded(
            child: Container(
              height: 2,
              color: filled ? AppColors.primary : Colors.grey.shade200,
            ),
          );
        }
        final stepIndex = i ~/ 2;
        final isDone   = stepIndex < activeIndex;
        final isActive = stepIndex == activeIndex;
        final color    = isDone || isActive
            ? AppColors.primary
            : Colors.grey.shade300;

        return Column(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDone || isActive ? color : Colors.grey.shade100,
                border: Border.all(color: color, width: 1.5),
              ),
              child: isDone
                  ? const Icon(Icons.check_rounded,
                      size: 12, color: Colors.white)
                  : isActive
                      ? Center(
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: color,
                            ),
                          ),
                        )
                      : null,
            ),
            const SizedBox(height: 4),
            Text(
              steps[stepIndex],
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                color: isActive ? AppColors.textDark : AppColors.textGrey,
              ),
            ),
          ],
        );
      }),
    );
  }
}
