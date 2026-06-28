import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../pembayaran/models/tagihan_model.dart';
import 'billing_shared_widgets.dart';

// ── Tabel tagihan ────────────────────────────────────────────────────────────
class BillingTagihanTable extends StatelessWidget {
  const BillingTagihanTable({
    super.key,
    required this.items,
    required this.onHubungi,
    required this.onEditStatus,
    required this.onDetail,
    required this.latestLunasPerUser,
  });
  final List<TagihanModel> items;
  final ValueChanged<TagihanModel> onHubungi;
  final ValueChanged<TagihanModel> onEditStatus;
  final ValueChanged<TagihanModel> onDetail;
  final Map<String, String> latestLunasPerUser;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header row
        Container(
          color: const Color(0xFFF8FAFC),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: const Row(
            children: [
              Expanded(flex: 3, child: HeaderText('WARGA')),
              Expanded(flex: 2, child: HeaderText('PERIODE')),
              Expanded(flex: 2, child: HeaderText('JUMLAH')),
              Expanded(flex: 2, child: HeaderText('STATUS')),
              Expanded(flex: 2, child: HeaderText('METODE')),
              Expanded(flex: 2, child: HeaderText('AKSI')),
              SizedBox(width: 80, child: HeaderText('EDIT')),
            ],
          ),
        ),
        ...items.map((t) => _TagihanRow(
              item: t,
              onHubungi: onHubungi,
              onEditStatus: onEditStatus,
              onDetail: onDetail,
              latestLunasPeriode: latestLunasPerUser[t.userId],
            )),
      ],
    );
  }
}

class _TagihanRow extends StatelessWidget {
  const _TagihanRow({
    required this.item,
    required this.onHubungi,
    required this.onEditStatus,
    required this.onDetail,
    required this.latestLunasPeriode,
  });
  final TagihanModel item;
  final ValueChanged<TagihanModel> onHubungi;
  final ValueChanged<TagihanModel> onEditStatus;
  final ValueChanged<TagihanModel> onDetail;
  /// Periode lunas terakhir milik user ini (null = belum pernah lunas).
  final String? latestLunasPeriode;

  bool get _unpaid =>
      item.status == StatusTagihan.belumBayar ||
      item.status == StatusTagihan.jatuhTempo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          // Warga
          Expanded(
            flex: 3,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primaryLight,
                  child: Text(
                    (item.namaResiden.isNotEmpty
                            ? item.namaResiden[0]
                            : '?')
                        .toUpperCase(),
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.namaResiden,
                          style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark)),
                      Text(item.unitLabel,
                          style: GoogleFonts.inter(
                              fontSize: 11, color: AppColors.textGrey)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Periode — baris 1: periode tagihan ini; baris 2: lunas s/d
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(item.periodeLabel,
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppColors.textDark)),
                const SizedBox(height: 2),
                Text(
                  latestLunasPeriode != null
                      ? 'Lunas s/d $latestLunasPeriode'
                      : 'Belum ada lunas',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: latestLunasPeriode != null
                        ? Colors.green.shade600
                        : AppColors.textGrey,
                  ),
                ),
              ],
            ),
          ),
          // Jumlah
          Expanded(
            flex: 2,
            child: Text(item.jumlahFormatted,
                style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark)),
          ),
          // Status
          Expanded(flex: 2, child: StatusBadge(status: item.status)),
          // Metode bayar
          Expanded(flex: 2, child: MetodeBadge(metode: item.metodeBayar)),
          // Kolom AKSI — tombol Hubungi (hanya untuk yang belum bayar)
          Expanded(
            flex: 2,
            child: _unpaid
                ? OutlinedButton.icon(
                    onPressed: () => onHubungi(item),
                    icon: const Icon(Icons.phone_in_talk, size: 14),
                    label: Text('Hubungi',
                        style: GoogleFonts.inter(
                            fontSize: 11, fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(color: AppColors.primaryLight),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      minimumSize: const Size(0, 30),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          // Kolom EDIT — eye (detail) + pensil (edit)
          SizedBox(
            width: 80,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Tooltip(
                  message: 'Lihat detail pembayaran',
                  child: InkWell(
                    onTap: () => onDetail(item),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Icon(Icons.remove_red_eye_outlined,
                          size: 15, color: Colors.blue.shade600),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Tooltip(
                  message: 'Ubah status pembayaran',
                  child: InkWell(
                    onTap: () => onEditStatus(item),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Icon(Icons.edit_outlined,
                          size: 15, color: AppColors.textGrey),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
