import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../models/security_models.dart';
import 'security_shared_widgets.dart';

class LogAktivitasSection extends StatelessWidget {
  const LogAktivitasSection({super.key, required this.items, required this.onTap});
  final List<LogItem> items;
  final ValueChanged<LogItem> onTap;

  @override
  Widget build(BuildContext context) {
    final today = DateFormat('dd MMMM yyyy', 'id_ID').format(DateTime.now());
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
              Text('Log Aktivitas', style: GoogleFonts.inter(
                  fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark)),
              const SizedBox(width: 8),
              if (items.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(10)),
                  child: Text('${items.length}', style: GoogleFonts.inter(
                      fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              const Spacer(),
              Text(today, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textGrey)),
            ]),
          ),
          const SizedBox(height: 10),
          Container(
            color: const Color(0xFFF8FAFC),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: const Row(children: [
              SizedBox(width: 70, child: ColH('WAKTU')),
              SizedBox(width: 32),
              Expanded(flex: 2, child: ColH('KEJADIAN')),
              Expanded(flex: 2, child: ColH('UNIT / WARGA')),
              SizedBox(width: 110, child: ColH('STATUS')),
              SizedBox(width: 50, child: ColH('')),
            ]),
          ),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(28),
              child: Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.check_circle_outline, size: 18, color: Color(0xFF16A34A)),
                const SizedBox(width: 8),
                Text('Tidak ada aktivitas hari ini.',
                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.textGrey)),
              ])),
            )
          else
            ...items.map((item) => LogRow(item: item, onTap: () => onTap(item))),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class ColH extends StatelessWidget {
  const ColH(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Text(text, style: GoogleFonts.inter(
    fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textGrey, letterSpacing: 0.4,
  ));
}

class LogRow extends StatelessWidget {
  const LogRow({super.key, required this.item, required this.onTap});
  final LogItem item;
  final VoidCallback onTap;

  (Color, IconData) get _typeStyle => switch (item.type) {
    LogType.sos     => (const Color(0xFFDC2626), Icons.emergency_outlined),
    LogType.bantuan => (AppColors.primary,       Icons.support_agent_outlined),
    LogType.patroli => (const Color(0xFF0D9488), Icons.shield_outlined),
  };

  Color get _statusColor {
    final s = item.status;
    if (s == 'Selesai')        return const Color(0xFF16A34A);
    if (s == 'Menuju Lokasi')  return AppColors.primary;
    if (s == 'Menunggu')       return const Color(0xFFF97316);
    return AppColors.textGrey;
  }

  @override
  Widget build(BuildContext context) {
    final (typeColor, typeIcon) = _typeStyle;
    final waktu = DateFormat('HH:mm').format(item.waktu);
    final hasFoto = item.fotoUrls.isNotEmpty;

    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
            border: Border(top: BorderSide(color: Colors.grey.shade100))),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(children: [
          SizedBox(width: 70, child: Text(waktu, style: GoogleFonts.inter(
              fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark))),
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(color: typeColor.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(typeIcon, size: 15, color: typeColor),
          ),
          const SizedBox(width: 8),
          Expanded(flex: 2, child: Text(item.judul, style: GoogleFonts.inter(
              fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textDark))),
          Expanded(flex: 2, child: Text(item.sub, style: GoogleFonts.inter(
              fontSize: 12, color: AppColors.textGrey), overflow: TextOverflow.ellipsis)),
          SizedBox(width: 110, child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 6, height: 6,
                  decoration: BoxDecoration(color: _statusColor, shape: BoxShape.circle)),
              const SizedBox(width: 5),
              Flexible(child: Text(item.status, style: GoogleFonts.inter(
                  fontSize: 11, fontWeight: FontWeight.w600, color: _statusColor),
                  overflow: TextOverflow.ellipsis)),
            ]),
          )),
          // Tombol detail
          SizedBox(
            width: 50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (hasFoto)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Icon(Icons.photo_outlined,
                        size: 14, color: AppColors.primary.withValues(alpha: 0.7)),
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
