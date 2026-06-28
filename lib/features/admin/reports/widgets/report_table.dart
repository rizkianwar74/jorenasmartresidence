import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/keluhan_service.dart';
import 'reports_shared_widgets.dart';

class ReportTable extends StatelessWidget {
  const ReportTable({
    super.key,
    required this.reports,
    required this.selectedId,
    required this.onRowTap,
  });
  final List<KeluhanItem> reports;
  final String? selectedId;
  final ValueChanged<KeluhanItem> onRowTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          color: const Color(0xFFF8FAFC),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
          child: Row(children: const [
            SizedBox(width: 6),
            Expanded(flex: 2, child: ColH('PELAPOR & UNIT')),
            Expanded(flex: 2, child: ColH('KATEGORI')),
            Expanded(flex: 3, child: ColH('JUDUL')),
            Expanded(flex: 2, child: ColH('TANGGAL')),
            Expanded(flex: 2, child: ColH('DITUGASKAN KE')),
            SizedBox(width: 110, child: ColH('STATUS')),
          ]),
        ),

        if (reports.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Center(child: Text('Tidak ada laporan.',
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.textGrey))),
          )
        else
          ...reports.map((r) => ReportRow(
            item       : r,
            isSelected : selectedId == r.id,
            onTap      : () => onRowTap(r),
          )),
      ],
    );
  }
}

class ReportRow extends StatelessWidget {
  const ReportRow({
    super.key,
    required this.item,
    required this.isSelected,
    required this.onTap,
  });
  final KeluhanItem item;
  final bool isSelected;
  final VoidCallback onTap;

  Color get _strip => switch (item.status) {
    StatusKeluhan.menunggu => const Color(0xFFF97316),
    StatusKeluhan.diproses => AppColors.primary,
    StatusKeluhan.selesai  => const Color(0xFF16A34A),
    StatusKeluhan.ditolak  => Colors.red,
  };

  @override
  Widget build(BuildContext context) {
    final tgl = DateFormat('dd MMM yy', 'id_ID').format(item.createdAt);
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.04) : Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade100)),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: _strip),
              const SizedBox(width: 16),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(children: [
                    // Pelapor
                    Expanded(flex: 2, child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(item.namaWarga, style: GoogleFonts.inter(
                            fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                        Text('Blok ${item.blok} – ${item.nomorUnit}',
                            style: GoogleFonts.inter(fontSize: 11, color: AppColors.textGrey)),
                      ],
                    )),
                    // Kategori
                    Expanded(flex: 2, child: KategoriBadge(item.kategori)),
                    // Judul
                    Expanded(flex: 3, child: Text(item.judul,
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.textGrey, height: 1.4),
                        overflow: TextOverflow.ellipsis, maxLines: 2)),
                    // Tanggal
                    Expanded(flex: 2, child: Text(tgl,
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.textGrey))),
                    // Ditugaskan ke
                    Expanded(flex: 2, child: item.assignedName != null
                        ? Row(children: [
                            Icon(Icons.person_pin_outlined, size: 13, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Flexible(child: Text(item.assignedName!,
                                style: GoogleFonts.inter(fontSize: 12, color: AppColors.primary,
                                    fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis)),
                          ])
                        : Text('—', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textGrey))),
                    // Status
                    SizedBox(width: 110, child: StatusBadgeRow(item.status)),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
