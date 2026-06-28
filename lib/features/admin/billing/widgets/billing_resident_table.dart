import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../pembayaran/models/tagihan_model.dart';
import '../models/resident_summary.dart';
import 'billing_shared_widgets.dart';

// ── Tabel per warga ───────────────────────────────────────────────────────────
class BillingResidentTable extends StatelessWidget {
  const BillingResidentTable({
    super.key,
    required this.items,
    required this.onHubungi,
    required this.onDetail,
  });
  final List<ResidentSummary>          items;
  final ValueChanged<TagihanModel>      onHubungi;
  final ValueChanged<TagihanModel>      onDetail;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          color: const Color(0xFFF8FAFC),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: const Row(
            children: [
              Expanded(flex: 3, child: HeaderText('WARGA')),
              Expanded(flex: 2, child: HeaderText('TUNGGAKAN')),
              Expanded(flex: 2, child: HeaderText('TOTAL UTANG')),
              Expanded(flex: 2, child: HeaderText('LUNAS S/D')),
              Expanded(flex: 2, child: HeaderText('STATUS')),
              Expanded(flex: 2, child: HeaderText('AKSI')),
              SizedBox(width: 56, child: HeaderText('DETAIL')),
            ],
          ),
        ),
        ...items.map((r) => _ResidentRow(
              item     : r,
              onHubungi: onHubungi,
              onDetail : onDetail,
            )),
      ],
    );
  }
}

class _ResidentRow extends StatelessWidget {
  const _ResidentRow({
    required this.item,
    required this.onHubungi,
    required this.onDetail,
  });
  final ResidentSummary           item;
  final ValueChanged<TagihanModel> onHubungi;
  final ValueChanged<TagihanModel> onDetail;

  bool get _hasTunggakan => item.tunggakanCount > 0;

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

          // Tunggakan
          Expanded(
            flex: 2,
            child: _hasTunggakan
                ? Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: item.overallStatus == StatusTagihan.jatuhTempo
                          ? Colors.orange.shade50
                          : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${item.tunggakanCount} bulan',
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: item.overallStatus ==
                                  StatusTagihan.jatuhTempo
                              ? Colors.orange.shade700
                              : Colors.red.shade700),
                    ),
                  )
                : Text('–',
                    style: GoogleFonts.inter(
                        fontSize: 13, color: AppColors.textGrey)),
          ),

          // Total utang
          Expanded(
            flex: 2,
            child: Text(
              _hasTunggakan ? formatRupiah(item.totalUtang) : '–',
              style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight:
                      _hasTunggakan ? FontWeight.w600 : FontWeight.normal,
                  color: _hasTunggakan
                      ? AppColors.textDark
                      : AppColors.textGrey),
            ),
          ),

          // Lunas s/d
          Expanded(
            flex: 2,
            child: Text(
              item.lunasSampai ?? 'Belum ada',
              style: GoogleFonts.inter(
                  fontSize: 12,
                  color: item.lunasSampai != null
                      ? Colors.green.shade600
                      : AppColors.textGrey),
            ),
          ),

          // Status
          Expanded(flex: 2, child: StatusBadge(status: item.overallStatus)),

          // Aksi — Hubungi jika ada tunggakan
          Expanded(
            flex: 2,
            child: _hasTunggakan
                ? OutlinedButton.icon(
                    onPressed: () => onHubungi(item.anyTagihan),
                    icon : const Icon(Icons.phone_in_talk, size: 14),
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

          // Detail — eye icon → AdminPaymentDetailPage
          SizedBox(
            width: 56,
            child: Center(
              child: Tooltip(
                message: 'Lihat detail pembayaran',
                child: InkWell(
                  onTap: () => onDetail(item.anyTagihan),
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
            ),
          ),
        ],
      ),
    );
  }
}
