import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../models/insiden_snap.dart';

class SecurityHeatmap extends StatelessWidget {
  const SecurityHeatmap({
    super.key,
    required this.items,
    required this.onLihatSemua,
  });
  final List<InsidenSnap> items;
  final VoidCallback       onLihatSemua;

  static String relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} mnt lalu';
    if (diff.inHours   < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays    == 1) return 'kemarin';
    return DateFormat('dd MMM', 'id_ID').format(dt);
  }

  Color _severityColor(int sev) => switch (sev) {
    2 => const Color(0xFFDC2626),
    1 => const Color(0xFFF59E0B),
    _ => const Color(0xFF22C55E),
  };

  Widget _statusBadge(String status) {
    final (bg, fg) = switch (status) {
      'BARU'      => (const Color(0xFFFFE4E6), const Color(0xFFDC2626)),
      'DITANGANI' => (const Color(0xFFFEF3C7), const Color(0xFFD97706)),
      'SELESAI'   => (const Color(0xFFDCFCE7), const Color(0xFF16A34A)),
      _           => (Colors.grey.shade100, AppColors.textGrey),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(status,
          style: GoogleFonts.inter(
              fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Security & Incidents',
                    style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark)),
                GestureDetector(
                  onTap: onLihatSemua,
                  child: Text('Lihat Semua',
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            color: const Color(0xFFF8FAFC),
            child: Row(children: const [
              SizedBox(width: 8),
              Expanded(flex: 3, child: ThWidget('TIPE KEJADIAN')),
              Expanded(flex: 3, child: ThWidget('LOKASI')),
              SizedBox(width: 110, child: ThWidget('STATUS')),
              SizedBox(width: 80,  child: ThWidget('WAKTU')),
            ]),
          ),

          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(28),
              child: Center(
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.check_circle_outline,
                      size: 18, color: Color(0xFF16A34A)),
                  const SizedBox(width: 8),
                  Text('Tidak ada insiden.',
                      style: GoogleFonts.inter(
                          fontSize: 13, color: AppColors.textGrey)),
                ]),
              ),
            )
          else
            ...items.map((item) => Container(
              decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.grey.shade100))),
              child: IntrinsicHeight(
                child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Container(
                    width: 4,
                    color: _severityColor(item.severity),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      child: Row(children: [
                        Expanded(flex: 3,
                            child: Text(item.kategori,
                                style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textDark))),
                        Expanded(flex: 3,
                            child: Text(item.lokasi,
                                style: GoogleFonts.inter(
                                    fontSize: 13, color: const Color(0xFF374151)),
                                overflow: TextOverflow.ellipsis)),
                        SizedBox(width: 110, child: _statusBadge(item.status)),
                        SizedBox(
                          width: 80,
                          child: Text(
                            relativeTime(item.waktu),
                            style: GoogleFonts.inter(
                                fontSize: 12, color: AppColors.textGrey),
                          ),
                        ),
                      ]),
                    ),
                  ),
                ]),
              ),
            )),

          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class ThWidget extends StatelessWidget {
  const ThWidget(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Text(text,
      style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.textGrey,
          letterSpacing: 0.5));
}
