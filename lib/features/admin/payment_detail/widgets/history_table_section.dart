import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../pembayaran/models/tagihan_model.dart';
import '../models/tx_group.dart';
import 'payment_detail_shared_widgets.dart';

class HistoryTableSection extends StatelessWidget {
  const HistoryTableSection({super.key, required this.groups});
  final List<TxGroup> groups;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Riwayat Pembayaran Penghuni',
      child: Column(
        children: [
          // Header
          Container(
            color: const Color(0xFFF8FAFC),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: const [
                Expanded(flex: 2, child: TblHeader('TANGGAL')),
                Expanded(flex: 3, child: TblHeader('ORDER ID')),
                Expanded(flex: 2, child: TblHeader('JUMLAH')),
                Expanded(flex: 3, child: TblHeader('BULAN DIBAYAR')),
                Expanded(flex: 2, child: TblHeader('METODE')),
                Expanded(flex: 2, child: TblHeader('STATUS')),
                SizedBox(width: 40, child: TblHeader('AKSI')),
              ],
            ),
          ),
          if (groups.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text('Belum ada riwayat pembayaran.',
                    style: GoogleFonts.inter(
                        fontSize: 13, color: AppColors.textGrey)),
              ),
            )
          else
            ...groups.map((g) => HistoryRow(group: g)),
        ],
      ),
    );
  }
}

class HistoryRow extends StatelessWidget {
  const HistoryRow({super.key, required this.group});
  final TxGroup group;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          // Tanggal
          Expanded(
            flex: 2,
            child: Text(group.tanggalBayar,
                style: GoogleFonts.inter(
                    fontSize: 12, color: AppColors.textDark)),
          ),
          // Order ID
          Expanded(
            flex: 3,
            child: Text(
              group.orderId ?? '-',
              style: GoogleFonts.sourceCodePro(
                  fontSize: 11,
                  color: group.orderId != null
                      ? AppColors.primary
                      : AppColors.textGrey),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Jumlah
          Expanded(
            flex: 2,
            child: Text(formatRupiah(group.totalJumlah),
                style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark)),
          ),
          // Bulan dibayar
          Expanded(
            flex: 3,
            child: Text(group.periodeRangeClean,
                style: GoogleFonts.inter(
                    fontSize: 11, color: AppColors.textGrey)),
          ),
          // Metode
          Expanded(
            flex: 2,
            child: HistMetodeBadge(metode: group.metode),
          ),
          // Status
          Expanded(
            flex: 2,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text('Lunas',
                  style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700)),
            ),
          ),
          // Aksi
          SizedBox(
            width: 40,
            child: Center(
              child: Tooltip(
                message: 'Lihat detail',
                child: InkWell(
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Fitur ini segera hadir.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  ),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(Icons.remove_red_eye_outlined,
                        size: 14, color: AppColors.textGrey),
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
