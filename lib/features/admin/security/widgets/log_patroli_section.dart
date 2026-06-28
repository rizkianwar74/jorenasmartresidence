import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../models/security_models.dart';
import 'log_aktivitas_section.dart';

class LogPatroliSection extends StatelessWidget {
  const LogPatroliSection({super.key, required this.logs, required this.onTap});
  final List<PatroliItem> logs;
  final ValueChanged<PatroliItem> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: Row(children: [
              Text('Log Patroli Hari Ini', style: GoogleFonts.inter(
                  fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark)),
              if (logs.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D9488), borderRadius: BorderRadius.circular(10)),
                  child: Text('${logs.length}', style: GoogleFonts.inter(
                      fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ],
            ]),
          ),
          const SizedBox(height: 12),
          Container(
            color: const Color(0xFFF8FAFC),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: const Row(children: [
              SizedBox(width: 90, child: ColH('WAKTU')),
              Expanded(flex: 2, child: ColH('PETUGAS')),
              Expanded(flex: 2, child: ColH('BLOK / AREA')),
              Expanded(flex: 3, child: ColH('KETERANGAN')),
              SizedBox(width: 90, child: ColH('STATUS')),
              SizedBox(width: 40, child: ColH('')),
            ]),
          ),
          if (logs.isEmpty)
            Padding(
              padding: const EdgeInsets.all(28),
              child: Center(child: Text('Belum ada log patroli hari ini.',
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.textGrey))),
            )
          else
            ...logs.map((log) => PatroliRow(log: log, onTap: () => onTap(log))),
        ],
      ),
    );
  }
}

class PatroliRow extends StatelessWidget {
  const PatroliRow({super.key, required this.log, required this.onTap});
  final PatroliItem log;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasFoto = log.fotoUrls.isNotEmpty;
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey.shade100))),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(children: [
          SizedBox(width: 90, child: Text(log.waktu, style: GoogleFonts.inter(
              fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textDark))),
          Expanded(flex: 2, child: Text(log.petugas, style: GoogleFonts.inter(
              fontSize: 13, color: AppColors.textDark))),
          Expanded(flex: 2, child: Text(log.lokasi, style: GoogleFonts.inter(
              fontSize: 13, color: AppColors.textDark))),
          Expanded(flex: 3, child: Text(log.catatan, style: GoogleFonts.inter(
              fontSize: 13, color: AppColors.textDark), overflow: TextOverflow.ellipsis)),
          SizedBox(width: 90, child: log.selesai
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6)),
                  child: Text('Selesai', style: GoogleFonts.inter(
                      fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textGrey)))
              : Row(children: [
                  Container(width: 8, height: 8,
                      decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text('Berjalan', style: GoogleFonts.inter(
                      fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                ])),
          // Arrow + foto indicator
          SizedBox(
            width: 40,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (hasFoto)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Icon(Icons.photo_outlined,
                        size: 14, color: const Color(0xFF0D9488).withValues(alpha: 0.8)),
                  ),
                Icon(Icons.chevron_right, size: 18, color: Colors.grey.shade400),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}
